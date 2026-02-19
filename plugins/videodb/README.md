# VideoDB Plugin for Claude Code

Process videos using the [VideoDB](https://videodb.io) Python SDK — upload, transcode, search, edit, and capture real-time screen and audio with AI transcription and indexing.

## Installation

```
/plugin marketplace add video-db/claude-code
/plugin install videodb@videodb
```

## Setup

1. **Get a VideoDB API key** from [console.videodb.io](https://console.videodb.io)

2. **Configure the environment** — create a `.env` file inside the skill directory (`skills/videodb/.env`):

   ```
   VIDEO_DB_API_KEY=your-api-key-here
   ```

3. **Set up the virtual environment** — the skill will auto-run this on first use, or you can do it manually:

   ```
   /videodb setup the virtual environment
   ```

   This runs `scripts/setup_venv.py` which creates `.venv/` and installs all dependencies from `requirements.txt`.

## Usage

Invoke the skill with `/videodb`:

```
/videodb upload this video: https://www.youtube.com/watch?v=...
/videodb search for "machine learning" across all my videos
/videodb create a compilation of all scenes mentioning AI
/videodb add subtitles to my latest video
```

## Skill Documentation

- [SKILL.md](skills/videodb/SKILL.md) — Main skill reference and setup
- [REFERENCE.md](skills/videodb/REFERENCE.md) — Full SDK API reference
- [SEARCH.md](skills/videodb/SEARCH.md) — Search capabilities
- [EDITOR.md](skills/videodb/EDITOR.md) — Video editing
- [GENERATIVE.md](skills/videodb/GENERATIVE.md) — Generative AI features
- [MEETINGS.md](skills/videodb/MEETINGS.md) — Meeting processing
- [RTSTREAM.md](skills/videodb/RTSTREAM.md) — Real-time streaming
- [CAPTURE.md](skills/videodb/CAPTURE.md) — Screen and audio capture
- [USE_CASES.md](skills/videodb/USE_CASES.md) — Example use cases

## Requirements

- Python 3.8+
- VideoDB API key
