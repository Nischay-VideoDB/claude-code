---
description: Update VideoDB recorder dependencies (videodb SDK, electron)
---

Run the update script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-recorder.sh"
```

This will:
1. Stop the recorder if running
2. Run `npm update` in the skills directory to pull latest dependency versions
3. Show before/after version diff
4. Restart the recorder automatically if config is ready

If the restart fails, check `/tmp/videodb-recorder.log` for errors.
