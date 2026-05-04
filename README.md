# Fast Guesser

Fast Guesser is a Roblox multiplayer deduction game project built with Rojo. The current codebase has moved beyond the original prototype and now supports a playable 3D lobby, two working head-to-head game modes, round rewards, a coin economy foundation, cosmetic shop flows, and a replay loop.

This README documents the repository as it exists in code today. It is intended for:

- the current developer maintaining the project
- future collaborators joining mid-stream
- AI agents that need accurate project context before continuing work

## Project Overview

Players spawn into a 3D lobby and use world prompts to interact with game systems:

- enter a mode-specific match flow from a game pad in the lobby
- ready up with another player queued for the same mode
- submit a hidden secret
- take alternating turns guessing
- finish the round, reveal both secrets, award coins, and optionally rematch

The current experience is still built around a single live two-player round managed by server state, but the surrounding lobby, UI, and economy systems are much more developed than the original prototype plan.

## Core Gameplay Modes

### Classic 4-Digit

- Each player submits a 4-digit secret string.
- Turns alternate after both secrets are set.
- A guess returns exact-position matches only.
- Exact-position matches become permanently locked for the guessing player.
- A player solves the opponent secret when all four positions are locked.
- If player one solves first, player two still gets one final answering turn to force a tie.

### 1-100 Higher/Lower

- Each player submits a secret integer from 1 to 100.
- On each turn, the guesser receives one of `Higher`, `Lower`, or `Correct`.
- There are no locked digits in this mode.
- Guess history becomes the main deduction aid.
- The same tie rule is used: player two gets a final equalizing turn if player one solves first.

## Current Feature List

### Implemented gameplay

- 2-player match creation and round state
- secret submission validation
- turn-based guessing
- winner detection
- tie handling via final response turn
- rematch / replay flow
- post-round secret reveal
- mode-aware input validation and UI copy

### Implemented lobby/world

- generated 3D lobby shell in `Workspace`
- game area with separate pads for both implemented modes
- shop station with prompt
- rewards station with prompt
- leaderboard station with prompt
- world spawn and path lighting

### Implemented economy/progression

- coin balance tracking
- win / loss / tie rewards
- daily claim style reward
- shop purchase and equip state
- cosmetic state broadcasting to clients
- DataStore-backed progression and leaderboard stats
- Studio session fallback when DataStores are unavailable

### Implemented UI

- lobby-world state with overlay hidden
- mode menu screen
- ready-up screen
- match screen
- result / replay screen
- coin HUD
- shop modal
- rewards modal
- leaderboard modal
- coin pack modal

## Current Lobby Features

The lobby is generated at runtime by [`src/ServerScriptService/Services/LobbyWorldService.luau`](src/ServerScriptService/Services/LobbyWorldService.luau).

Current world areas:

- `Game Area`: contains two separate play pads
  - `Classic 4-Digit`
  - `1-100 Higher/Lower`
- `Shop Station`
- `Rewards Station`
- `Leaderboard Station`

Important current-world notes:

- There is no separate physical `Modes` station anymore. Mode choice is now primarily tied to the game pads in the `Game Area`.
- The rewards area visually includes a spin wheel, but it is decorative scaffolding right now.
- The lobby is functional but still clearly code-generated rather than art-passed.

## Economy / Coin System Summary

### Match rewards

Defined in [`src/ServerScriptService/Services/EconomyService.luau`](src/ServerScriptService/Services/EconomyService.luau):

- Win: `35` coins
- Loss: `12` coins
- Tie: `20` coins
- Daily claim: `25` coins

### Shop catalog

Current catalog entries:

- `trail_neon`
- `theme_midnight`
- `tag_quick_cracker`
- `spark_lobby`

These are saved as owned/equipped items. Some are already visible in-game:

- `trail_neon`: visible trail on the character
- `tag_quick_cracker`: visible overhead title
- `spark_lobby`: visible lobby particle/light effect while in lobby states
- `theme_midnight`: changes local UI theme colors

### Persistence

Progression is persisted with DataStores:

- coins
- owned items
- equipped items
- processed Developer Product receipts
- last daily reward claim day

Leaderboard stats are also persisted separately:

- total wins
- current streak

### Robux purchases

A Developer Product purchase flow exists in code and reads coin pack IDs from [`src/ServerScriptService/Config/MonetizationConfig.luau`](src/ServerScriptService/Config/MonetizationConfig.luau). Product IDs are still `0` by default, so real Robux coin purchases become live only after the dashboard IDs are filled in.

## Current Project Structure

### Top-level

- `default.project.json`: Rojo project mapping
- `rokit.toml`: toolchain pinning for `rojo` and `lune`
- `sourcemap.json`: source tree map
- `PLAN.md`: early prototype plan; now out of date in several areas
- `run_smoketest.luau`: local smoke-test entry script

### Source tree

```text
src/
  ReplicatedStorage/
    Shared/
      FeedbackLogic.luau
      ModeCopy.luau
      RemoteEvents.luau
  ServerScriptService/
    ServerBootstrap.server.luau
    Config/
      MonetizationConfig.luau
    Services/
      EconomyService.luau
      GuessValidator.luau
      LeaderboardService.luau
      LobbyWorldService.luau
      MatchService.luau
      MonetizationService.luau
      GameSessionService.luau
      PrototypeMatchServer.luau
    Tests/
      FeedbackLogicTests.server.luau
      SmokeTest.server.luau
  StarterGui/
    FastGuesserDevGui.client.luau
    FastGuesserDevGuiBuilder.luau
  StarterPlayer/
    StarterPlayerScripts/
      GameClient.client.luau
```

## Architecture Summary

### Server

- [`ServerBootstrap.server.luau`](src/ServerScriptService/ServerBootstrap.server.luau)
  - entrypoint
  - starts `GameSessionService`

- [`GameSessionService.luau`](src/ServerScriptService/Services/GameSessionService.luau)
  - orchestrates the active playable experience
  - owns player session flow, matchmaking queues, lobby states, round states, rematch flow, reward distribution, and remote wiring

- [`PrototypeMatchServer.luau`](src/ServerScriptService/Services/PrototypeMatchServer.luau)
  - legacy compatibility wrapper that returns `GameSessionService`

- [`MatchService.luau`](src/ServerScriptService/Services/MatchService.luau)
  - pure round rules and match state
  - supports both game modes

- [`EconomyService.luau`](src/ServerScriptService/Services/EconomyService.luau)
  - coins, shop, reward state, cosmetics state, progression persistence

- [`LeaderboardService.luau`](src/ServerScriptService/Services/LeaderboardService.luau)
  - win/streak tracking and leaderboard state

- [`LobbyWorldService.luau`](src/ServerScriptService/Services/LobbyWorldService.luau)
  - procedural lobby construction and station prompts

- [`MonetizationService.luau`](src/ServerScriptService/Services/MonetizationService.luau)
  - Developer Product coin pack flow and receipt processing

- [`MonetizationConfig.luau`](src/ServerScriptService/Config/MonetizationConfig.luau)
  - server-side Developer Product ID config points and coin pack definitions

### Shared

- [`FeedbackLogic.luau`](src/ReplicatedStorage/Shared/FeedbackLogic.luau)
  - exact-match and locked-digit helpers for 4-digit mode

- [`ModeCopy.luau`](src/ReplicatedStorage/Shared/ModeCopy.luau)
  - shared mode-specific UI wording used by the client controller

- [`RemoteEvents.luau`](src/ReplicatedStorage/Shared/RemoteEvents.luau)
  - creates/finds the game’s RemoteEvents folder and all event objects

### Client

- [`FastGuesserDevGuiBuilder.luau`](src/StarterGui/FastGuesserDevGuiBuilder.luau)
  - builds the full current UI tree at runtime

- [`FastGuesserDevGui.client.luau`](src/StarterGui/FastGuesserDevGui.client.luau)
  - main UI controller
  - handles screen flow, commerce panels, cosmetics rendering, and remote listeners

- [`GameClient.client.luau`](src/StarterPlayer/StarterPlayerScripts/GameClient.client.luau)
  - currently just notes that working local UI logic lives in `StarterGui`

## Development Environment / Setup

Current intended setup:

- Windows 11 host
- VS Code
- WSL2 Ubuntu
- Roblox Studio
- Rojo
- Git / GitHub

### Prerequisites

Install or confirm:

- Roblox Studio
- `rojo` 7.x
- `lune`
- Git

This repository already pins `rojo` and `lune` in `rokit.toml`.

### Recommended workflow

1. Open the repo in VS Code inside WSL2.
2. Use the pinned Rokit tools or your installed equivalents.
3. Start a Rojo server.
4. Open the place in Roblox Studio and connect with the Rojo plugin.
5. Test multiplayer flows with local Studio test clients.

## How To Run / Test Locally

### Run with Rojo

From the repo root:

```bash
rojo serve
```

Then connect from Roblox Studio using the Rojo plugin.

### Studio testing

Use Roblox Studio local multiplayer testing for the real gameplay loop:

- spawn 2 test players
- enter one of the game pads
- ready both players
- submit secrets
- verify guess flow, result flow, rewards, and rematch

### Local script/test notes

- `FeedbackLogicTests.server.luau` and `SmokeTest.server.luau` are Roblox-style scripts, not a standalone test harness.
- `run_smoketest.luau` currently does not run cleanly under plain `lune` because the smoke test still expects Roblox’s `game:GetService` runtime.
- Practical testing is currently Studio-first rather than CLI-first.

## Current Gameplay Flow

1. Player spawns in the 3D lobby.
2. Player walks to a game pad in the `Game Area`.
3. Triggering the pad opens the menu for that mode.
4. Pressing `Play Match` enters matchmaking for that selected mode.
5. Two queued players for the same mode appear in the ready-up screen.
6. Both players press ready.
7. Server creates a 2-player match.
8. Both players submit secrets.
9. Turn-based guessing begins.
10. Guess feedback is shown according to the active mode.
11. When the round ends, both secrets are revealed and rewards are granted.
12. Players can ready a rematch from the result flow.

## Implemented Systems vs Placeholders

### Implemented now

- classic 4-digit mode
- 1-100 higher/lower mode
- ready-up and matchmaking queue by mode
- round rewards
- DataStore-backed daily reward claim
- replay/rematch flow
- DataStore-backed progression
- DataStore-backed wins/streak leaderboard
- shop ownership and equip state
- visible cosmetic application for several items
- Developer Product coin pack config and receipt flow

### Implemented but still rough

- coin pack purchase UI until real Developer Product IDs are configured
- reward wheel foundation / segment presentation
- smoke-test scripts
- generated lobby presentation

### Placeholder / incomplete

- real spin wheel behavior and animation
- real rewards wheel claim mechanic beyond daily claim
- configured Developer Product IDs
- broader cosmetic catalog
- more robust automated testing
- deeper session-service decomposition beyond the first naming cleanup

## Known Limitations / Pending Roadmap

### High-priority gaps

- Robux coin packs are not live because product IDs are unset.
- The rewards wheel has server-owned segment data but no spin action yet.
- Testing is mostly manual in Studio.

### Structural limitations

- `GameSessionService` now has the correct top-level name, but it still owns several responsibilities that should eventually split into smaller matchmaking, round orchestration, and remote wiring modules.
- Matchmaking is server-local and appears designed for one active 2-player round flow at a time.
- A lot of client behavior still lives in one large LocalScript, though mode-specific copy has been moved to a shared module.
- The UI builder and UI controller are both large monolithic files.

### Product/feature limitations

- Shop catalog is small.
- Leaderboard is server-session presentation backed by per-player persisted stats, not a global ordered board UI.
- The lobby is functional but not highly polished.
- Some item descriptions still describe themselves as placeholders even when partial effects now exist.

## Suggested Next Development Priorities

1. Split `GameSessionService` into smaller matchmaking, round orchestration, and remote wiring modules.
2. Fill real Developer Product IDs and validate the purchase flow in Studio/live test.
3. Convert the rewards wheel foundation into a real spin action, or simplify the world station if daily rewards remain the only reward loop.
4. Break up `FastGuesserDevGui.client.luau` into smaller controller modules for lobby, match, results, shop, rewards, and cosmetics.
5. Add better automated tests around `MatchService`, `EconomyService`, and replay edge cases.
6. Expand the cosmetic catalog and make shop descriptions match actual visible behavior.
7. Improve lobby art/polish now that the core loop is playable.

## Repository Reality Check

This repository is no longer just a prototype, but it also is not fully productionized. The core loop is genuinely playable, both implemented modes are present in code, and the lobby/economy shell is functional. The main unfinished areas are real product ID configuration/testing, reward-wheel completion, codebase cleanup, and polish.
