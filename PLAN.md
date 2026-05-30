# FastGuesser Current Plan

This document replaces the original prototype-only plan. The project is now beyond the first prototype and has a playable core loop, a generated 3D lobby, progression systems, and monetization scaffolding.

## Project Status

Current state of the repository:

- playable 2-player matchmaking and round flow
- two implemented game modes
- generated 3D lobby with interactive stations
- coin rewards, daily claim, and cosmetic shop flow
- DataStore-backed progression and win/streak stats
- Developer Product purchase plumbing present in code

The project is no longer in "build the first version" mode. It is now in "finish incomplete systems, reduce technical debt, and polish toward a more shippable MVP" mode.

## Completed Work

### Gameplay

- classic 4-digit mode
- 1-100 higher/lower mode
- secret validation
- turn-based guessing
- round resolution
- tie handling with final response turn for player two
- rematch / replay flow
- post-round secret reveal

### Lobby / Session Flow

- generated lobby world in `Workspace`
- game pads for both implemented modes
- shop prompt and modal flow
- rewards prompt and modal flow
- leaderboard prompt and modal flow
- ready-up state before a match starts
- mode-specific matchmaking queues

### Economy / Progression

- match rewards for win / loss / tie
- daily reward claim
- coin balance persistence
- owned/equipped cosmetic persistence
- receipt tracking for Developer Product fulfillment
- Studio session fallback when DataStores are unavailable

### UI

- menu screen
- ready-up screen
- match screen
- result screen
- shop modal
- rewards modal
- leaderboard modal
- coin pack modal
- coin HUD

## Incomplete Features

### High Priority

- validate live/studio purchase flow with the configured product IDs
- turn the rewards wheel into a real spin system
- add stronger automated testing for core gameplay and economy flows

### Medium Priority

- expand cosmetic catalog beyond the current small starter set
- improve leaderboard experience beyond current per-server presentation
- improve lobby presentation and art polish
- align cosmetic descriptions with actual visible in-game behavior

### Structural / Tech Debt

- split `GameSessionService` into smaller modules
- break up `FastGuesserDevGui.client.luau` into focused controllers
- break up `FastGuesserDevGuiBuilder.luau` into smaller UI builders
- improve testability of round/session/economy systems

## Known Constraints

- matchmaking is currently server-local
- the current architecture appears centered on one active 2-player round flow at a time
- most practical testing still happens through Roblox Studio local multiplayer
- smoke tests exist, but are still lightweight and not part of a robust automated harness
- monetization UI is present, and the configured product IDs still need end-to-end Studio/live validation

## Roadmap Phases

## Phase 1: Monetization Validation

Goal: make coin packs real and safe to test.

Tasks:

- verify each coin pack opens the purchase prompt
- verify receipt processing grants the correct amount of coins
- verify duplicate receipt protection works as expected

Definition of done:

- all three coin packs use non-zero product IDs
- purchase prompt opens for each configured pack
- successful purchases grant the correct coin reward exactly once

## Phase 2: Rewards Feature Completion

Goal: resolve the current "wheel later" placeholder.

Tasks:

- decide whether the rewards station remains a daily-claim-plus-wheel feature or daily claim only
- if wheel stays, implement weighted roll selection from the configured reward segments
- add client feedback for spin outcome
- prevent duplicate claims and define cooldown/eligibility rules clearly
- update rewards copy to match the final mechanic

Definition of done:

- rewards station behavior matches what players see in the lobby and UI
- no placeholder "future feature" messaging remains in the player-facing flow

## Phase 3: Stability and Test Coverage

Goal: reduce regression risk in the core loop.

Tasks:

- add automated tests for `MatchService`
- add automated tests for `EconomyService`
- cover tie resolution and rematch edge cases
- cover higher/lower validation and result behavior
- make smoke-test flow easier to run repeatedly

Definition of done:

- critical round rules are covered by repeatable tests
- economy reward logic is verified outside manual playtesting

## Phase 4: Codebase Decomposition

Goal: make the project easier to extend safely.

Tasks:

- extract matchmaking responsibilities from `GameSessionService`
- extract round orchestration responsibilities from `GameSessionService`
- extract remote wiring / state broadcasting responsibilities from `GameSessionService`
- split large client UI logic into screen- or feature-specific modules
- split UI builder into reusable sections/components

Definition of done:

- the largest scripts no longer own several unrelated responsibilities
- new features can be added without growing the current monoliths further

## Phase 5: Content and Polish

Goal: improve player-facing quality after systems are stable.

Tasks:

- add more cosmetics
- improve cosmetic preview clarity
- upgrade lobby art, lighting, and station presentation
- improve leaderboard presentation
- refine copy and onboarding/help text

Definition of done:

- the game feels less like a dev prototype and more like a cohesive MVP

## Phase 6: Pending Features Expansion

Goal: turn the current backlog of partially implemented or missing player-facing systems into a deliberate feature slate.

Tasks:

- decide whether the leaderboard remains server-session only or graduates to a broader persisted/global presentation
- expand the cosmetic catalog with items that have clearly visible in-game effects
- replace placeholder cosmetic descriptions with final player-facing copy
- decide whether to keep the current generated lobby presentation or invest in a more polished environment pass
- review whether additional game modes, reward loops, or progression hooks should be added before broader polish work
- document which pending features are committed for MVP and which should be deferred to post-MVP

Definition of done:

- pending feature work is grouped into an intentional scope instead of an open-ended backlog
- each feature has a clear status: ship in MVP, postpone, or cut
- player-facing placeholder copy and ambiguous feature intent are reduced across the project

## Current Recommended Priority Order

1. Validate the configured Developer Product purchase flow.
2. Finish or simplify the rewards wheel.
3. Add better automated coverage for gameplay and economy.
4. Split the monolithic session and client/UI files.
5. Expand content and visual polish.
6. Triage the remaining pending feature backlog into explicit MVP vs post-MVP scope.

## Working Principles

- keep shared game rules separate from presentation logic
- let the server remain authoritative for match state, rewards, and purchase fulfillment
- prefer small focused modules over growing top-level scripts
- avoid adding new feature scope before unfinished monetization, rewards, and stability work are resolved
- treat Studio multiplayer testing as necessary, but continue moving important logic toward repeatable automated verification
