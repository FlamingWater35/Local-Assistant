# Local Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.41-blue?logo=flutter)](https://flutter.dev)
[![Latest release](https://img.shields.io/github/v/release/FlamingWater35/Local-Assistant)](https://github.com/FlamingWater35/Local-Assistant/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/FlamingWater35/Local-Assistant/create-draft-release.yml?label=build)](https://github.com/FlamingWater35/Local-Assistant/actions/workflows/create-draft-release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-Android-purple)

A private, fully on-device AI assistant built with Flutter. **Local Assistant** runs large language models (LLMs) directly on your device hardware, ensuring that your conversations, images, and documents never leave your phone. Nothing is more important than your privacy.

## ✨ Features

- **Fully Local**: No API keys or internet connection required for chatting.
- **Multiple Models**: Choose from a growing collection of on-device models:
  - **Gemma 4** — Multimodal (image + audio), with thinking mode.
  - **Gemma 3 Nano** — Multimodal (image), with thinking mode.
  - **Qwen3** — Lightweight and fast, with thinking mode.
- **Multimodal Support**:
  - **Images**: Analyze photos and visual data.
  - **Audio**: Process `.wav` audio files.
  - **Documents**: Import text-based files (`.txt`, `.md`, `.csv`).
- **Thinking Mode**: See the model's reasoning process before it answers (available on supported models).
- **Configurations**: Create and switch between multiple setting profiles (e.g., Creative, Precise) — each with its own model, context size, temperature, and system prompt.
- **Smart Memory**: Optional "Global Memory" allows the AI to reference facts across different chat sessions.
- **Flexible Backend**: Choose between GPU, NPU, or CPU inference to match your device's capabilities.
- **Material Design 3**: A modern, clean UI with dynamic color support and smooth animations.
- **Auto-Updater**: Integrated update system to keep the app in top shape.
- **Multilingual**: Available in five languages (as of version 1.2.0).

## 🚀 Getting Started

### System Requirements

- **Android**: SDK 26 (Android 8.0) or higher.
- **Hardware**: A device with a 64-bit ARM processor (`arm64-v8a` architecture support).
  - **4 GB+ RAM** recommended for Gemma 4 E2B and smaller models.
  - **6 GB+ RAM** recommended for Gemma 3n E4B and larger models.

### Setup

1. **Download a Model**: On first launch, the app will guide you through downloading a model. Gemma 4 E2B is recommended for most devices.
2. **HuggingFace Token**: Some models (e.g., Gemma 3 Nano) require a HuggingFace read-access token to download. Visit [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) to create one.
3. **Start Chatting**: Once the model is installed, inference is handled by your device's processor.

## 📸 Screenshots (v1.1.4)

<table width="100%">
  <tr>
    <td align="center">
      <p><b>Chat Interface</b></p>
      <img src="assets\screenshots\ChatScreen-2026-04-18.png" alt="Main chatting interface" width="400">
    </td>
    <td align="center">
      <p><b>Settings Interface</b></p>
      <img src="assets\screenshots\SettingsScreen-2026-04-18.png" alt="Application settings menu" width="400">
    </td>
  </tr>
</table>

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Database**: [Hive CE](https://pub.dev/packages/hive_ce)
- **Inference Engine**: [Flutter Gemma](https://pub.dev/packages/flutter_gemma)
- **UI Components**: [Flyer Chat UI](https://pub.dev/packages/flutter_chat_ui)

## 🔒 Privacy

Your data is rightfully yours, and no one should collect it without your consent. Local Assistant does not track usage, collect telemetry, or upload your messages to any cloud server. The internet permission is used solely for:

1. Downloading the AI model files initially.
2. Checking GitHub for app updates.

## 📜 License

Released under the **MIT License**.
See the [LICENSE](LICENSE) file for full details.
