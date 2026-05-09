# Articulate

**A native macOS coach for conversational English practice powered by OpenAI Realtime.**

Articulate is a native macOS application designed to help users refine their English speaking and listening skills through direct interaction with AI. Built with SwiftUI and integrated with the OpenAI Realtime API, the app provides a low-latency environment for natural, voice-based practice.

The application supports focused learning scenarios, ranging from casual small talk to professional interview preparation. By combining microphone capture, realtime audio streaming, assistant audio playback, and typed prompts, Articulate offers a practical space for active language practice without the friction of traditional learning tools.

## Features

- Native macOS interface built with SwiftUI.
- Realtime voice interaction using OpenAI Realtime and `gpt-realtime-2`.
- Microphone capture converted to 24 kHz mono PCM audio.
- Playback of AI-generated PCM audio responses through AVFoundation.
- Dedicated practice modes for Conversation, Interview, Pronunciation, and Small Talk.
- Persistent local chat history with saved sessions, search, rename, and delete actions.
- Text fallback for environments where speaking is not convenient.
- Adjustable content zoom through settings and keyboard shortcuts.
- Project-local build and run script for repeatable development.

## Technical Stack

- SwiftUI for the macOS interface.
- AVFoundation for microphone capture, PCM conversion, and audio playback.
- URLSession WebSocket client for OpenAI Realtime events.
- Swift Package Manager for build and test workflows.

## Requirements

- macOS 14 or newer.
- Xcode command line tools or a compatible Swift toolchain.
- An OpenAI API key with available API credits.

## Setup

Create a local environment file:

```bash
cp .env.example .env.local
```

Then add your API key:

```bash
OPENAI_API_KEY=your_api_key_here
```

The `.env.local` file is ignored by Git and should not be committed.

## Run

Build and launch the app as a macOS bundle:

```bash
./script/build_and_run.sh
```

The same script supports a process check:

```bash
./script/build_and_run.sh --verify
```

## Keyboard Shortcuts

- `Command + K`: Connect.
- `Command + N`: New chat.
- `Command + Space`: Start speaking.
- `Command + Shift + Space`: Stop speaking.
- `Command + =`: Zoom in.
- `Command + -`: Zoom out.
- `Command + 0`: Reset zoom.

## Test

```bash
swift test
```

## Why I Built This

I developed Articulate to bridge the gap between passive language study and active conversation. As a software engineer working in a globalized environment, I wanted a tool for consistent, low-stakes English practice that felt like a native part of my workspace.

This project is also a practical exploration of realtime AI interaction in a desktop app: audio capture, WebSocket event handling, streamed responses, and a focused SwiftUI interface built around a real personal workflow.

## Status

Articulate is an ongoing personal project. Feedback, issues, and implementation discussions are welcome.
