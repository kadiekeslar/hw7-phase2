# Study Buddies

Original game design and Phase 1 foundation: **Anabella Phelps**. Phase 2 extensions: **Kadie Keslar**, with Codex assistance.

A 5–8 player online social-deduction game set over one CMU semester. See [spec.md](spec.md) for the full design.

## Requirements

- **Godot 4.7.2 stable** (pinned). Don't open the project in a different version; upgrade only by deliberate decision and update this line.
- Git LFS (`git lfs install` once per machine) for images, audio and Aseprite files.

On macOS:

```sh
brew install git-lfs
brew install --cask godot
git lfs install
```

## Running

Open the project in Godot and press F5, or from the repo root:

```sh
godot --path .
```

## Playing a test game (Milestone 1: LAN)

1. One player clicks **Host game (LAN)**. The lobby shows their IP addresses.
2. Everyone else types that IP into the join box (port 7777 by default) and clicks **Join**.
3. Players can change their name and pick a free color in the lobby.
4. The host clicks **Start game**. It needs 5 players, or 2 with the temporary **Dev mode** checkbox ticked on the host's main menu. In dev mode the host can also pick who is TA.

Online play by room code needs the noray relay server, which isn't set up yet.

If joining fails between machines, check that everyone is on the same network and that the host's firewall allows Godot on UDP port 7777.

## Testing on one machine

Run several instances (Debug → Customize Run Instances in the editor, or `godot --path .` in multiple terminals). Debug builds also accept scripted flags after `--`, documented at the top of [autoload/dev_tools.gd](autoload/dev_tools.gd). For example, a 3-player game where the bots collaborate in view of the TA:

```sh
godot --path . -- --name=Ana --host --dev --autostart=3 --force-ta=Ana --bot-goto=350,180 &
godot --path . -- --name=Ben --join=127.0.0.1 --bot-goto=338,110 --bot-collab --bot-play &
godot --path . -- --name=Cal --join=127.0.0.1 --bot-goto=362,110 --bot-respond=accept --bot-play &
```

## Unit tests

[GUT](https://github.com/bitwes/Gut) tests live in `tests/unit`. Run them before every release:

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

## Code layout

| Path | What's there |
| --- | --- |
| `autoload/` | `App` (scenes, fullscreen), `NetworkService` (all connection code), `Session` (lobby roster, profile, your role), `DevTools` (debug-only test flags) |
| `scripts/logic/` | Pure rules with unit tests: clock, report limits, roles, line of sight |
| `scripts/tasks/` | Host-side task rules (`TaskLogic`) and the task registry |
| `scenes/game/` | The game scene: room, players, HUD, and `GameServer` (host-only game state) |
| `scenes/tasks/` | Minigame scenes implementing the shared `Minigame` interface |

## Balance values

All tunable numbers live in [config/game_balance.tres](config/game_balance.tres). Edit them between playtests; there is no in-game settings menu.

## Local config

Machine-specific settings such as the relay server address go in `config/local.cfg`, which is git-ignored. Never commit server addresses or keys.

## Controls

| Key | Action |
| --- | --- |
| WASD / arrows | Move |
| Mouse | Click **Collaborate with [name]** when you're at a task station next to someone |
| E | Interact (not used yet) |
| Tab | Task list (not implemented yet) |
| Enter | Focus chat during dinners; Enter again sends |
| Esc | Menu |
| F11 | Toggle fullscreen |

## Phase 2: dinners and voting

The original LAN slice, movement, role assignment, Proof Chain puzzle, collaboration,
capture, report tracking, and host/client architecture are retained. This update
extends the author's next milestone instead of replacing the game. The original
`spec.md` is unchanged. No original gameplay class or puzzle was discarded or renamed.

New behavior:

- At the **start of weeks 3, 6, 9, and 12**, living connected players see a
  **Rev Noodle dinner overlay**. There is no separate restaurant map yet.
- The semester clock and movement pause during meetings. Unfinished puzzles and
  invitations are cancelled; puzzle progress is lost. Pending report expiry and
  cooldowns use semester time, so they pause too.
- Each living player, including the TA, can use **Call dinner (1/game)** once,
  while free to act. This opens an emergency dinner without consuming a scheduled
  dinner. The button is hidden during puzzles, popups, menus, and meetings.
- Discussion lasts **60 seconds**, then voting lasts up to **20 seconds**.
  Chat is available only to living connected dinner participants, during discussion
  and voting. Messages have a 120-character limit and a one-second rate limit.
- Vote for a player or **Skip**. Each participant gets one final ballot. Voting
  resolves early if everyone votes. Abstaining is allowed. Skip tied with the
  leading candidate, a tie between candidates, or no votes eliminates nobody.
- Voting out the TA gives **Students win!**; a wrong vote eliminates that student.
  Fewer than two living students gives **The TA wins!**. The semester expiring
  also gives the TA victory because overall coursework is not implemented yet.
- All players see the winner, reason, and TA identity. The host can return everyone
  to the lobby and start another game. Eliminated students remain behind the
  inherited failure screen; Pitt gameplay is still missing.
- In the two-player dev-only test setup, the fewer-than-two-students auto-win is
  disabled so testing is possible. It applies in games starting with 3+ players.

### Try the changes on one Mac

1. Stop the running game, then pull the new commits in GitHub Desktop.
2. Reopen the project in Godot **4.7.2**; allow import to finish.
3. Use **Debug → Customize Run Instances**, enable 3 instances, and run the project.
4. Host one instance with **Dev mode** checked. Give the other instances different
   names and join `127.0.0.1`, port `7777`. Start from the host lobby.
5. For an immediate test, click **Call dinner (1/game)** in a living player's window.
6. Send chat in each window. After 60 seconds, cast votes in all three windows.
   Voting out the TA wins for students; voting out a student in this 3-player test
   leaves only one student and wins for the TA. You can force the TA in the dev lobby.
7. Choose **Back to lobby** in the host window to play again. For scheduled meetings,
   wait until week 3 (two minutes of active gameplay), then weeks 6, 9, and 12.

For faster scripted tests, the inherited debug flags now also support
`--discussion-sec=N --voting-sec=N --result-sec=N`, `--bot-vote=NAME` (or `skip`),
`--bot-chat=TEXT`, and `--bot-call-dinner=SECONDS`. These flags only work in debug
builds. They do not change the normal 60/20-second defaults.

### Code map additions

| File | Responsibility |
| --- | --- |
| `scripts/logic/dinner_logic.gd` | Eligible voters, validated ballots, disconnect abstentions, plurality and Skip/tie resolution |
| `scenes/game/dinner_panel.gd` | Meeting overlay, countdown, bounded chat history, vote buttons, emergency-call button |
| `scenes/game/game_server.gd` | Existing host rules, extended with meeting scheduling, phase transitions, validation, elimination and winner checks |
| `scenes/game/game.gd` | Existing game setup and RPCs, extended with dinner/chat/vote/result messages |
| `scenes/game/hud.gd` | Existing HUD, extended with dinner input blocking, correct failure reasons and winner text |
| `config/game_balance.tres` | Original balance resource plus meeting weeks, timers, call limits and chat limits |
| `tests/unit/test_dinner_logic.gd` | Regression cases for ballots, ties, Skip and disconnects |

### Requirements walkthrough

The inherited spec has no numbered acceptance-criteria section. The following
numbered rows map its concrete requirements and milestones to this submission.
**Met** describes implemented behavior, not a claim of human playtesting on 5–8
separate computers. Verification details and remaining limitations follow the table.

| # | Requirement from the original spec | Status and explanation |
| --- | --- | --- |
| 1 | Godot 4, typed GDScript, desktop project | **Met:** existing Godot 4.7.2 project and typed classes retained; packaged OS builds remain separate work. |
| 2 | WASD/arrows movement and player identification | **Met:** original movement, unique colors and name tags retained. |
| 3 | 480×270 pixel display and fullscreen toggle | **Met:** original display settings and F11 toggle retained. |
| 4 | Host-authoritative LAN/direct-IP multiplayer | **Met:** original ENet connection and host validation retained; automated local multiplayer checks passed. |
| 5 | 5–8-player lobby with 2–4-player debug testing | **Met:** original lobby limits and dev controls retained; human 5–8-machine testing remains undone. |
| 6 | Online room codes and noray relay | **Not met:** room-code control remains disabled; no relay was provisioned. |
| 7 | Secret assignment of exactly one TA | **Met:** original per-player role delivery retained; dinner messages do not reveal the TA before game end. |
| 8 | Locally saved name/color and unique lobby colors | **Met:** original Session profile and roster system retained. |
| 9 | Full campus with nine locations | **Partially met:** only the original UC lounge exists; dinners use an overlay. |
| 10 | A 15-week semester clock | **Met:** original clock retained and paused during dinner discussion, voting and result display. |
| 11 | Per-student task lists and prerequisites | **Not met:** Tab task list and prerequisite tracking are not implemented. |
| 12 | Shared coursework bar updated at dinners | **Not met:** completing Proof Chain does not contribute to persistent coursework progress. |
| 13 | Four starter minigames | **Partially met:** the inherited two-person Proof Chain Problem Set works; study group, programming assignment and quiz are missing. |
| 14 | Shared interface for independent minigame scenes | **Met:** original Minigame, TaskLogic and TaskRegistry remain in use. |
| 15 | Collaboration invitations and acceptance | **Met:** original station proximity, accept/decline and timeout behavior retained. |
| 16 | TA can capture or genuinely help a collaborator | **Met:** inherited TA invite choices retained; capture now also checks the auto-win rule. |
| 17 | Fixed-radius, wall-blocked host report detection | **Met:** original host line-of-sight and report tracker retained. |
| 18 | One pending report, one-week expiry, two-week shared cooldown | **Met:** original tracker and unit tests retained; timers pause with semester time at dinner. |
| 19 | Filing at a professor NPC removes exactly one student | **Not met:** no office/NPC exists, and report filing still only starts a cooldown. |
| 20 | Safe collaboration during limited office hours | **Not met:** no office-hours location or schedule. |
| 21 | Scheduled Rev Noodle dinners in weeks 3/6/9/12 | **Partially met:** correct schedule and mandatory meeting overlay are implemented; physical transport to a restaurant scene is not. |
| 22 | One emergency dinner per living player, TA included | **Met:** host tracks the per-player limit; meetings cannot be called while busy or during another meeting. |
| 23 | Timed discussion and voting | **Met:** normal defaults are 60 seconds discussion and up to 20 seconds voting, with early resolution when all vote. |
| 24 | Living-player chat restricted to dinners | **Met:** host permits chat only to current living connected participants during discussion/voting, with a 120-character limit. |
| 25 | Plurality voting, Skip and ties | **Met:** tested resolver prevents duplicate/invalid ballots and handles Skip and candidate ties. |
| 26 | Voting out the TA wins for students | **Met:** every connected client receives student victory, reason and TA reveal. |
| 27 | Wrongly voted-out students fail | **Partially met:** elimination, disappearance and failure reason work; Pitt conversion does not. |
| 28 | Fewer than two living students automatically wins for TA | **Met:** checked after capture/vote elimination in games starting with 3+ players; two-player dev exception documented above. |
| 29 | Semester timeout wins for TA when work is unfinished | **Met:** timeout shows TA victory and reveal; coursework is always unfinished in this slice. |
| 30 | Students can win by finishing coursework; simultaneous-bar tie favors students | **Not met:** neither overall progress bar exists. |
| 31 | Four grading stations and private TA grading progress | **Not met:** grading and its victory path are not implemented. |
| 32 | Shower meter, showering and movement/grading penalties | **Not met:** the shower system is not implemented. |
| 33 | Pop quiz/no-hot-water emergencies and shared cooldown | **Not met:** neither emergency exists. |
| 34 | Pitt movement, visibility, chat and solo task conversion | **Not met:** failed players still wait behind the inherited overlay. |
| 35 | Failure announcement to all players | **Met:** inherited failure banner retained for captures and extended to wrong votes. |
| 36 | End screen with winner, TA reveal and return to lobby | **Met:** winner/reason/reveal added; original host-controlled return to lobby retained. |
| 37 | Host disconnect returns clients to menu | **Met:** original NetworkService and Session handling retained. |
| 38 | Student/TA 60-second rejoin window and consequences | **Not met:** disconnected characters freeze; no rejoin recovery or expiry outcome is implemented. |
| 39 | Tunable values in one balance resource | **Met:** dinner/chat settings added to the original GameBalance resource. |
| 40 | Automated tests for all specified systems | **Partially met:** existing rules plus dinner ballots are covered; absent showers/Pitt/grading have no implementation to test. |
| 41 | Finished seasonal art, animations, wall fading and audio | **Not met:** the inherited placeholder visual approach remains. |
| 42 | Windows/macOS release downloads | **Not met:** run from the pinned Godot editor; no exported release builds provided. |

### Validation and known limits

- **33/33 GUT unit tests pass**, including all 26 inherited tests and seven new
  dinner ballot tests. Use the command in Unit tests above; `-gdir` explicitly
  selects the tests and `-gexit` exits afterward.
- Reproduce the local multiplayer smoke checks with
  `python3 tests/smoke_dinners.py --godot /path/to/Godot` (or omit `--godot` when
  it is on PATH). They use UDP ports 17871–17874 and write logs under the ignored
  `.godot/smoke-results/` folder.
- Automated three-instance LAN checks exercised scheduled meetings, chat delivery,
  voting out the TA, wrong-vote elimination and auto-win, all four meetings with
  Skip/resume, semester-timeout victory, and a student emergency call. These used
  accelerated debug timers. They are not a substitute for human multi-machine playtests.
- A rendered dinner screen was checked at the project's 480×270 base resolution.
- No grading or overall coursework victory exists. This is a playable voting
  extension of the inherited slice, not the full game described in the spec.
- A disconnect removes that player's dinner eligibility and ballot. Votes already
  cast for a disconnected candidate count as abstentions; those ballots remain
  locked. There is no host migration or implemented 60-second rejoin flow.
- Dinner chat has a 30-message local history, one message per second, and no Pitt
  channel. Chat is plain text. No identity is revealed by a correct collaboration.
- Nine bundled GUT PNGs arrived as Git LFS pointer text. Phase 2 restores the exact
  original images from GUT v9.7.1 after verifying their sizes and SHA-256 hashes
  against those pointers. Licenses remain in `CREDITS.md` and `addons/gut`.
- The new `.gitignore` excludes Godot's cache and `config/local.cfg`. The inherited
  README claimed the latter was ignored, but the downloaded repository lacked a
  `.gitignore`; this update makes that instruction accurate.

Next priorities: human LAN playtest, then shared coursework progress and TA grading
using the existing task interfaces, followed by professor reporting and Pitt
conversion. Preserve the original design and complete one requirement at a time.

`HANDOFF_REPORT.md` must be written personally by the student; it is deliberately
not generated by AI. Phase 2 prompts and workflow corrections are in `prompt_log.md`.
