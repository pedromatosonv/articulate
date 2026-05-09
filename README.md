# Articulate

**A web app for conversational English practice powered by OpenAI Realtime.**

Articulate helps users practice spoken and written English with a focused AI coach. The app keeps the previous product shape from the macOS version: practice modes, proficiency levels, persistent chat history, search, rename/delete actions, typed fallback, realtime voice, and adjustable content zoom.

The web migration uses a React/Vite client and a small local Express server. The browser connects to OpenAI Realtime with WebRTC through the server-side unified `/v1/realtime/calls` setup flow, so the `OPENAI_API_KEY` stays out of client JavaScript.

![Articulate web app](artifacts/web-app-concept.png)

## Features

- Browser-based practice interface built with React and TypeScript.
- Realtime voice interaction using OpenAI Realtime and `gpt-realtime-2`.
- WebRTC microphone capture and model audio playback.
- Dedicated practice modes for Conversation, Interview, Pronunciation, and Small Talk.
- Persistent local chat history with saved sessions, search, rename, clear, and delete actions.
- Text fallback for environments where speaking is not convenient.
- Settings panel for current chat behavior and content zoom.
- Responsive layout for desktop, compact desktop, and mobile screens.
- Express API server for secure Realtime session initialization.

## Technical Stack

- React 19, Vite, and TypeScript for the web client.
- Express for the local API server.
- WebRTC data channels and media tracks for Realtime events and audio.
- Vitest for focused unit coverage.

## Requirements

- Node.js 24 or newer.
- npm 11 or newer.
- An OpenAI API key with available API credits.

## Setup

Create a local environment file:

```bash
cp .env.example .env.local
```

Then add your API key:

```bash
OPENAI_API_KEY=your_api_key_here
PORT=8787
```

`PORT` is optional and defaults to `8787`. The `.env.local` file is ignored by Git and should not be committed.

Install dependencies:

```bash
npm install
```

## Run

Start the API server and Vite dev server together:

```bash
npm run dev
```

Then open:

```text
http://localhost:5173
```

The API server runs on `http://localhost:8787`; Vite proxies `/api` calls to it during development.

## Build And Test

```bash
npm run lint
npm run test
npm run build
```

After building, the Express server can also serve the compiled app:

```bash
npm run server
```

## Status

Articulate is now a web app. The native macOS SwiftUI implementation has been removed from this migration branch.
