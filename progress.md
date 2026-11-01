# Progress

Last updated: Oct 28, 2026

## Where we are

**Milestone 1 (networked slice): built over LAN, waiting on Anabella's playtest.** Online play by room code isn't built yet.

## Milestone 1 status

| Piece | Status |
| --- | --- |
| Project setup: Godot 4.7.2, Git LFS, pixel-perfect 480×270 display, input map, balance config | Done |
| LAN / direct-IP hosting and joining (`NetworkService`) | Done |
| Online play by room code (noray relay) | Not started: needs a cloud account for the relay server |
| Lobby: name and color saved locally, unique colors, Start at 5 players | Done |
| Temporary dev-mode checkbox on the main menu: 2–4 players, host can pick the TA | Done |
| Host-authoritative movement, 20 Hz sync, client prediction and smoothing | Done |
| Secret role assignment (each player is told only their own role) | Done |
| In-game semester clock, "Semester over" screen, back to lobby | Done |
| UC 3rd floor lounge placeholder room with a sight-blocking bookshelf | Done |
| Shared minigame interface plus the Proof Chain problem set | Done |
| Collaboration: a **Collaborate with [name]** button at a task station (replaced pressing E), accept or decline, 10 s timeout | Done |
| TA capture (captured student sees "You failed the class" and disappears) | Done |
| Line of sight on the host plus the TA's report popup (1-week expiry, 2-week cooldown; filing does nothing else yet) | Done |
| Unit tests for clock, report limits, roles, line of sight and the puzzle (26 passing) | Done |
| Windows / macOS builds on GitHub Releases | Not started |

## How it was tested

Scripted bot runs (see `autoload/dev_tools.gd`) with 3 copies of the game on one Mac covered:

- connecting
- roles
- finishing the puzzle together
- the report popup with and without line of sight
- decline, timeout and capture
- semester over
- three games in a row

All passed with no errors. Nobody has played it on 3 separate machines yet.

## Sign-off checklist (Anabella)

- [ ] 3 machines connect over LAN
- [ ] Each player sees only their own role
- [ ] Movement feels responsive
- [ ] Two students finish the puzzle together
- [ ] The TA gets the popup only when they have line of sight
- [ ] Capture works
- [ ] The decline and the 10-second timeout work

## Next steps

1. **Anabella:** playtest the checklist above on 3 machines. Each needs Godot 4.7.2 and a clone of the repo; the README explains hosting and joining.
2. **Anabella:** create a Google Cloud account for the relay server, then the developer sets up noray and adds room codes.
3. **Developer:** set up Windows/macOS export builds if testers shouldn't have to run the game from Godot.
4. After sign-off: Milestone 2 (Rev Noodle dinners, chat, voting, win/lose screens). That needs 5+ testers, so line up a test group.

## Decisions to confirm

- A capture cancels any pending report, since captures and reports share one cooldown.
- F11 toggles fullscreen.
