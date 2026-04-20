# FastGuesser v1 Plan

## Milestone 1
Create core shared logic for 4-digit mode:
- feedback matching
- locked positions
- win detection

## Milestone 2
Create server-side match state:
- create a 2-player match
- store each player's secret
- alternate turns
- validate guesses
- update locked positions
- detect winner

## Milestone 3
Create minimal placeholder client flow:
- secret entry
- guess entry
- locked positions display
- turn display
- winner display

## Rules
- keep code simple
- no fancy UI yet
- no multiplayer knockout yet
- no 1-100 mode yet
- no over-engineering

## Validation
- code should stay modular
- shared logic should not depend on UI
- server should own game state