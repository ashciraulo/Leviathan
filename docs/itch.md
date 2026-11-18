# Putting Leviathan on itch.io

The upload is a GitHub Actions workflow, `.github/workflows/itch.yml`. It
uploads a GitHub release that has already been published (Actions > Build PC >
Run workflow, with `release` filled in). Nothing is uploaded until someone runs
it by hand with **Dry run** turned off.

## One-time setup

1. On itch.io, create a new project (Dashboard > Create new project). You can
   leave it as a **Draft** until launch.
   - **Kind of project:** HTML. This lets the web build play on the page,
     and the desktop downloads sit beside it.
   - **Pricing:** your choice. "No payments", "Donate" or a paid price all
     work with this pipeline.
2. Make an API key: itch.io > Settings > API keys > Generate new API key.
3. In the GitHub repository, go to Settings > Secrets and variables > Actions:
   - Under **Secrets**, add `BUTLER_API_KEY` with that key.
   - Under **Variables**, add `ITCH_GAME` with the page as `user/game`, the
     part of the page's address after `https://`, for example
     `someone/leviathan` for `someone.itch.io/leviathan`.

## Uploading a release

Go to Actions > Upload to itch.io > Run workflow, and fill in the release tag
(for example `v1.0.0`).

- **Dry run** (on by default) builds and gathers everything and checks it with
  `tools/itch_check.sh`. It then attaches the four folders to the run as the
  artifact `itch-channels-<tag>`, so you can download and try exactly what
  would go up. Nothing is uploaded.
- With Dry run off, the workflow pushes each folder with itch's `butler` tool
  to its own channel, tagged with the release's version:

| Channel   | Contents                         | On itch.io, mark it as |
|-----------|----------------------------------|------------------------|
| `web`     | the browser build (`index.html`) | "This file will be played in the browser" |
| `windows` | `Leviathan.exe` + licences       | Windows |
| `linux`   | `Leviathan.x86_64` + licences    | Linux |
| `mac`     | `Leviathan.app` + licences       | macOS |

butler uploads only what changed since the last push, so later updates are
small. After the first upload, open the page's Edit screen once to set the
platform of each file as in the table.

## Page settings for the browser build

- **Embed options:** "Manually set size", **1152 x 648**. This is three times
  the game's 384 x 216 screen, so the pixels stay crisp.
- Tick **Fullscreen button** and **Mobile friendly** (the web build has touch
  controls), with orientation **Landscape**.
- Leave **SharedArrayBuffer support** off. The web build doesn't use threads,
  so it needs no special headers.
- Saves live in the browser's storage for itch.io's game domain. Players can
  move a save between the browser and the desktop version from the file
  select (Export / Import).

## macOS

The macOS build is signed only ad hoc, not notarized, so on first launch macOS
says it can't check the app. Players right-click the app and choose Open, or go
to System Settings > Privacy & Security > Open Anyway. Say this in the page's
install notes until the build is notarized (that needs a paid Apple developer
account).
