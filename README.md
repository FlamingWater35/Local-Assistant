# Local Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.41-blue?logo=flutter)](https://flutter.dev)
[![Build Status](https://img.shields.io/github/actions/workflow/status/FlamingWater35/Local-Assistant/create-draft-release.yml?label=build)](https://github.com/FlamingWater35/Local-Assistant/actions/workflows/create-draft-release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-Android-purple)

A private, fully on-device AI assistant built with Flutter. **Local Assistant** runs large language models (LLMs) directly on your device hardware, ensuring that your conversations, images, and documents never leave your phone. Nothing is more important than your privacy.

## ✨ Features

- **Fully Local**: No API keys or internet connection required for chatting.
- **Multimodal Support**:
  - **Images**: Analyze photos and visual data.
  - **Audio**: Process `.wav` audio files.
  - **Documents**: Import text-based files (`.txt`, `.md`, `.csv`).
- **Smart Memory**: Optional "Global Memory" allows the AI to reference facts across different chat sessions.
- **Material Design 3**: A modern, clean UI with dynamic color support and smooth animations.
- **Auto-Updater**: Integrated update system to keep the app in top shape.

## 🚀 Getting Started

### System Requirements

- **Android**: SDK 26 (Android 8.0) or higher.
- **Hardware**: A device with a 64-bit ARM processor (`arm64-v8a`) and at least 4GB of RAM is recommended for Gemma 2B models.

### Setup

1. **Download a Model**: On the first boot, the app will guide you through downloading a model.
2. **HuggingFace Token**: Some models may require a HuggingFace read-access token to download (check a guide if unsure how to proceed).
3. **Start Chatting**: Once the model is installed, inference is handled by your device's GPU/NPU.

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
