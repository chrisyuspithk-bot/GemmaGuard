# GemmaGuard 🛡️

Offline Blue Team defense app powered by **Gemma 4** running locally on-device. Analyze network diagrams, log snippets, and security configurations with structured threat assessments — no cloud required.

Built for the **GDG Cloud HK Hackathon**.

## Features

- **Multimodal Analysis** — text prompts + image attachments (network diagrams, logs, configs)
- **Fully Offline** — Gemma 4 runs entirely on-device via `flutter_gemma`
- **Structured Reports** — threat level badge, summary, key findings, mitigations
- **Material 3** — light/dark theme, clean chat UI

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.38+)
- Android SDK / Xcode (for mobile builds)
- ~1.5 GB free storage (for the Gemma 4 model)

## Quick Start

```bash
# Clone
git clone https://github.com/chrisyuspithk-bot/GemmaGuard.git
cd GemmaGuard

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

On first launch, the app automatically downloads the **Gemma 4 E2B** model from Kaggle (~1.3 GB). The status bar in the app bar shows download progress. Once "Ready" appears, you can start chatting.

## Model Options

The default model is **Gemma 4 E2B** (2B parameters, CPU int8 quantized).  
To use the larger **E4B** variant, change the download URL in `lib/services/gemma_service.dart`:

```dart
// Replace the E2B URL with the E4B URL:
'https://www.kaggle.com/api/v1/models/google/gemma-4/flutterGemma/4B-it-gemma4-cpu-int4/download'
```

For manual asset bundling (no network on first launch), use `fromAsset()` instead of `fromNetwork()` in the service.

## Project Structure

```
lib/
├── main.dart                   # App entry, Material 3 theme
├── models/
│   └── chat_message.dart       # ChatMessage + AnalysisResult
├── services/
│   └── gemma_service.dart      # Model lifecycle (init, download, inference)
├── screens/
│   └── chat_screen.dart        # Main chat UI + Provider state
└── widgets/
    └── analysis_card.dart      # Threat analysis response card
```

## Tech Stack

| Package | Purpose |
|---|---|
| `flutter_gemma` | On-device LLM inference |
| `image_picker` | Camera & gallery image input |
| `provider` | State management |

## Building

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

## License

MIT

