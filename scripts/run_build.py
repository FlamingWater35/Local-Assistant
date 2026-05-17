import subprocess
import shutil
import os
import platform
import sys
import threading
import re
import glob
from colorama import Fore, Style, init as colorama_init

# --- Initial Setup ---
colorama_init(autoreset=True)

APP_NAME = "Local-Assistant"
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))

APK_OUTPUT_DIR = os.path.join(PROJECT_ROOT, "build", "app", "outputs", "apk", "release")
RELEASE_DIR = os.path.join(PROJECT_ROOT, "release")

# --- Core Functions ---


def get_sanitized_version():
    """Reads the version from pubspec.yaml and removes build metadata."""
    try:
        with open(os.path.join(PROJECT_ROOT, "pubspec.yaml"), "r") as f:
            content = f.read()
            match = re.search(r"version:\s*([0-9A-Za-z\-+.]+)", content)
            if match:
                full_version = match.group(1)
                sanitized_version = full_version.split("+")[0]
                return sanitized_version
    except Exception as e:
        print(Fore.RED + f"Could not read version from pubspec.yaml: {e}")
        return "1.0.0"


def stream_pipe(pipe, prefix, color, encoding="utf-8"):
    """Streams output from a subprocess pipe in real-time."""
    try:
        for line_bytes in iter(pipe.readline, b""):
            if not line_bytes:
                break
            try:
                line = line_bytes.decode(encoding).rstrip("\r\n")
                if "\r" in line_bytes.decode(
                    encoding, errors="ignore"
                ) and not "\n" in line_bytes.decode(encoding, errors="ignore"):
                    print(
                        color + prefix + line_bytes.decode(encoding, errors="ignore"),
                        end="\r",
                    )
                elif line:
                    print(color + prefix + line)
                sys.stdout.flush()
            except UnicodeDecodeError:
                print(color + prefix + f"[RAW BYTES (decode error)]: {line_bytes!r}")
                sys.stdout.flush()
    except Exception as e:
        if not (hasattr(e, "winerror") and e.winerror == 232):
            print(Fore.RED + f"Error streaming {prefix}: {e}")
    finally:
        if hasattr(pipe, "close") and not pipe.closed:
            pipe.close()


def run_command_realtime_colored(
    command_parts, step_name, CWD=PROJECT_ROOT, interactive=False
):
    """Executes a command and prints its output in real-time with colors."""
    print(Style.BRIGHT + Fore.CYAN + "-" * 60)
    print(Style.BRIGHT + Fore.CYAN + f"Starting: {step_name}")
    command_str = " ".join(command_parts)
    print(Style.BRIGHT + Fore.CYAN + f"Executing: {command_str} (in {CWD})")
    print(Style.BRIGHT + Fore.CYAN + "-" * 60)

    use_shell = platform.system() == "Windows"

    try:
        if interactive:
            process = subprocess.Popen(command_parts, cwd=CWD, shell=use_shell)
            process.wait()
            return_code = process.returncode
        else:
            process = subprocess.Popen(
                command_parts,
                cwd=CWD,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                shell=use_shell,
            )

            stdout_thread = threading.Thread(
                target=stream_pipe, args=(process.stdout, "[INFO]  ", Fore.GREEN)
            )
            stderr_thread = threading.Thread(
                target=stream_pipe, args=(process.stderr, "[WARN]  ", Fore.YELLOW)
            )

            stdout_thread.start()
            stderr_thread.start()
            stdout_thread.join()
            stderr_thread.join()

            return_code = process.wait()

        if return_code != 0:
            print(
                Fore.RED
                + Style.BRIGHT
                + f"\nWARNING: {step_name} exited with code {return_code}."
            )
            return False

        print(Fore.GREEN + Style.BRIGHT + f"\nCompleted: {step_name} successfully.")
        return True

    except FileNotFoundError:
        print(
            Fore.RED
            + Style.BRIGHT
            + f"ERROR: Command '{command_parts[0]}' not found. Make sure it's in your system's PATH."
        )
        return False
    except Exception as e:
        print(
            Fore.RED
            + Style.BRIGHT
            + f"ERROR: An unexpected error occurred during {step_name}: {e}"
        )
        return False
    except KeyboardInterrupt:
        print(
            Fore.YELLOW + Style.BRIGHT + f"\nProcess '{step_name}' interrupted by user."
        )
        return False


# --- Task-specific Functions ---


def run_builders():
    """Runs the code generators (build_runner and slang)."""
    print(Style.BRIGHT + Fore.MAGENTA + "\n>>> Running Code Generators...")
    run_command_realtime_colored(
        ["dart", "run", "build_runner", "build"],
        "Build Runner",
    )
    run_command_realtime_colored(["dart", "run", "slang"], "Build Localization")
    print(Style.BRIGHT + Fore.MAGENTA + ">>> Code generation finished.\n")


def run_full_build():
    """Executes the entire build and packaging process."""
    APP_VERSION = get_sanitized_version()
    final_release_dir = os.path.join(RELEASE_DIR, f"v{APP_VERSION}")

    print(Style.BRIGHT + Fore.MAGENTA + "=" * 60)
    print(
        Style.BRIGHT
        + Fore.MAGENTA
        + f"Starting full build for {APP_NAME} v{APP_VERSION}..."
    )
    print(Style.BRIGHT + Fore.MAGENTA + "=" * 60)

    # Core build steps
    if not run_command_realtime_colored(["flutter", "clean"], "Flutter Clean"):
        return
    if not run_command_realtime_colored(["flutter", "pub", "get"], "Flutter Pub Get"):
        return

    run_builders()

    # Build Android
    if not run_command_realtime_colored(
        ["flutter", "build", "apk", "--release", "--target-platform", "android-arm64"],
        "Android APK Build",
    ):
        return

    # Processing Android APKs
    print(Style.BRIGHT + Fore.CYAN + "\n" + "-" * 60)
    print(Style.BRIGHT + Fore.CYAN + "Processing Android APKs...")
    try:
        for apk_file in glob.glob(os.path.join(APK_OUTPUT_DIR, "app-release.apk")):
            filename = os.path.basename(apk_file)
            arch = "arm64-v8a"
            new_name = f"{APP_NAME}-{arch}.apk"
            new_path = os.path.join(APK_OUTPUT_DIR, new_name)
            os.rename(apk_file, new_path)
            print(Fore.GREEN + f"Renamed: {filename} -> {new_name}")
    except Exception as e:
        print(Fore.RED + f"Error processing APKs: {e}")

    # Consolidating Release Files
    print(Style.BRIGHT + Fore.CYAN + "\n" + "-" * 60)
    print(
        Style.BRIGHT
        + Fore.CYAN
        + f"Consolidating release files into: {final_release_dir}"
    )
    if os.path.exists(final_release_dir):
        shutil.rmtree(final_release_dir)
    os.makedirs(final_release_dir, exist_ok=True)

    try:
        for file in glob.glob(os.path.join(APK_OUTPUT_DIR, f"{APP_NAME}-*.apk")):
            shutil.copy(file, final_release_dir)
        print(Fore.GREEN + "All release files consolidated.")
    except Exception as e:
        print(Fore.RED + f"Error consolidating files: {e}")

    # Final summary
    print(Style.BRIGHT + Fore.MAGENTA + "\n" + "=" * 60)
    print(Style.BRIGHT + Fore.MAGENTA + "All build steps completed!")
    print(
        Style.BRIGHT
        + Fore.MAGENTA
        + f"--> Final release assets are located in: {final_release_dir}"
    )
    print(Style.BRIGHT + Fore.MAGENTA + "=" * 60)


# --- Main Application Loop ---


def main():
    """Presents the main menu and handles user input."""
    while True:
        print(Style.BRIGHT + Fore.WHITE + "\n" + "=" * 30)
        print(Style.BRIGHT + Fore.WHITE + "        Build Menu")
        print(Style.BRIGHT + Fore.WHITE + "=" * 30)
        print(Fore.CYAN + "1. Run Builders (build_runner & slang)")
        print(Fore.CYAN + "2. Build Application (Full Release Process)")
        print(Fore.CYAN + "0. Quit")
        print("-" * 30)

        choice = input(Fore.WHITE + "Enter your choice (0-2): ")

        if choice == "1":
            run_builders()
        elif choice == "2":
            run_full_build()
        elif choice == "0":
            print(Fore.YELLOW + "Exiting script.")
            break
        else:
            print(Fore.RED + "Invalid choice. Please enter a number between 0 and 2.")


if __name__ == "__main__":
    main()
