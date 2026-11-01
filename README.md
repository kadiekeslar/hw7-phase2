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
| E | Start nearby solo work, grade (TA only), or invite a nearby collaborator |
| Tab | Open/close your assignment checklist |
| Enter | Focus chat during dinners; Enter again sends |
| Esc | Menu |
| F11 | Toggle fullscreen |

## Phase 2: dinners, voting, and coursework race

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
  with unfinished coursework also gives the TA victory.
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
| 11 | Per-student task lists and prerequisites | **Partially met:** Tab shows a real two-assignment checklist; the full 8–10-task distribution and prerequisites remain missing. |
| 12 | Shared coursework bar updated at dinners | **Met:** host tracks each student assignment once and publishes a bar snapshot only when dinner starts. |
| 13 | Four starter minigames | **Partially met:** original Proof Chain plus solo programming are implemented; study group and quiz remain missing. Programming uses click-to-order rather than drag-and-drop. |
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
| 29 | Semester timeout wins for TA when work is unfinished | **Met:** timeout shows TA victory and reveal if neither side already won. |
| 30 | Students can win by finishing coursework; simultaneous-bar tie favors students | **Met:** all assigned work wins immediately; the deferred host check gives coursework priority if both goals finish in the same check. |
| 31 | Four grading stations and private TA grading progress | **Partially met:** four TA-only timed desks and private progress/win path work, but all desks are in the lounge and grading is not tuned to week 12–13. |
| 32 | Shower meter, showering and movement/grading penalties | **Not met:** the shower system is not implemented. |
| 33 | Pop quiz/no-hot-water emergencies and shared cooldown | **Not met:** neither emergency exists. |
| 34 | Pitt movement, visibility, chat and solo task conversion | **Not met:** failed players still wait behind the inherited overlay. |
| 35 | Failure announcement to all players | **Met:** inherited failure banner retained for captures and extended to wrong votes. |
| 36 | End screen with winner, TA reveal and return to lobby | **Met:** winner/reason/reveal added; original host-controlled return to lobby retained. |
| 37 | Host disconnect returns clients to menu | **Met:** original NetworkService and Session handling retained. |
| 38 | Student/TA 60-second rejoin window and consequences | **Not met:** disconnected characters freeze; no rejoin recovery or expiry outcome is implemented. |
| 39 | Tunable values in one balance resource | **Met:** dinner/chat settings added to the original GameBalance resource. |
| 40 | Automated tests for all specified systems | **Partially met:** existing rules, dinners, coursework, grading timers, programming and work-win priority are tested; absent shower/Pitt systems are not covered. |
| 41 | Finished seasonal art, animations, wall fading and audio | **Not met:** the inherited placeholder visual approach remains. |
| 42 | Windows/macOS release downloads | **Not met:** run from the pinned Godot editor; no exported release builds provided. |

### Validation and known limits

- **45/45 GUT unit tests pass**, including all 26 inherited tests, seven dinner
  ballot tests and twelve coursework/solo-task/race tests. Use the command in Unit tests above; `-gdir` explicitly
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
- This remains a small campus slice, not the full game described in the spec.
  There are two assignments per student, rather than 8–10, and four grading desks
  in one room rather than across campus. Grading takes four 15-second batches;
  the spec's week-12/13 balance target has not been implemented or playtested.
- Failed students' unfinished assignments remain in the coursework denominator.
  Without Pitt solo conversion (still missing), coursework may become impossible
  to finish after a failure; students can still win by voting out the TA.
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

Next priorities: human LAN playtest and balance tuning, fuller assignment lists and
new task types, followed by professor reporting and Pitt conversion. Preserve the original design and complete one requirement at a time.

`HANDOFF_REPORT.md` must be written personally by the student; it is deliberately
not generated by AI. Phase 2 prompts and workflow corrections are in `prompt_log.md`.

### Coursework and grading: second Phase 2 increment

Each real student is assigned **one Problem Set and one Programming Assignment**.
Press **Tab**, or click **Tasks (Tab)**, to inspect your own checklist. Completing
an assignment counts once. A student who finished the Problem Set can still help
another student who needs it; if both partners have finished it, no new session is
started. TA cover assignments are tracked privately but contribute zero student
progress. A TA helping a student complete the Problem Set still earns that student
legitimate credit, as described in the original spec.

The original Problem Set station stays at the whiteboard east of the bookshelf.
The **Programming (1)** station is beside the small round table farther east.
Stand in its yellow ring and click the prompt or press **E**. Click code blocks in
execution order; a wrong block gives feedback without erasing the correct prefix.
Finishing both assignments for every student immediately gives a coursework victory.
Public progress remains a dinner snapshot until the next dinner; each player sees
their own task completion immediately in their private checklist.

Four red **Grade papers** rings are spread around the same lounge. All players can
see them, but only the TA gets the action prompt or can start grading. Stand in a
ring and press **E**, stay in the grading screen for **15 seconds**, then click
**Finish grading batch**. Four batches win for the TA. Any desk can be reused;
there are four alternatives so one spot cannot be camped. Cancelling, leaving or
being interrupted by dinner loses the unfinished batch, not completed batches.
The grading counter is sent only to the TA and appears in their top bar. The host
validates the elapsed time, so an early client submit cannot finish a batch.

These short balance values match this two-assignment prototype, not the full
semester's intended 8–10 assignments. Edit `grading_batch_sec` and
`grading_batches_required` in the existing balance resource to tune them. Debug
runs also accept `--grading-sec=N --grading-batches=N` for quick tests.

| Added file | Responsibility |
| --- | --- |
| `scripts/logic/coursework_tracker.gd` | Assigned student tasks, duplicate-credit prevention and aggregate completion |
| `scripts/logic/win_conditions.gd` | Work-race outcome, with student priority for simultaneous completion |
| `scripts/tasks/programming_task.gd` | Host-validated shuffled code-order puzzle, with three short program variants |
| `scripts/tasks/grading_task.gd` | Host timer and completion validation for a grading batch |
| `scenes/tasks/solo_minigame.gd` / `.tscn` | New solo-task UI using the inherited Minigame interface |
| `tests/unit/test_coursework_tracker.gd` | Assignment counting, TA exclusion, duplicate prevention and winner priority |
| `tests/unit/test_solo_tasks.gd` | Programming input validation/solvability and grading timer validation |

Manual checks for this increment:

1. As a student, Tab shows two unfinished assignments. Finish the Problem Set and
   confirm just that entry changes to Done. Repeat with a partner who still needs
   it; the finished player's assignment must not count twice.
2. Complete programming in both student windows. With both students' Problem Sets
   complete too, all players should see **Students win!** with the coursework reason.
3. Restart and inspect a TA window. Grade a full batch, submit it, and confirm the
   counter advances by one. Student windows must not show that counter or offer
   grading actions. Finish four batches for **The TA wins!** with the grading reason.
4. Cancel a grading batch early, or call dinner from another player during grading:
   unfinished work must not count. Completed batches must remain.
5. Have the TA finish a programming cover assignment with students idle, then call
   dinner. The student bar must stay at 0%. Have a real student finish an assignment
   and call a later dinner to see the newly increased snapshot.

Pitt conversion is still missing. A task held by a failed student is not silently
removed to inflate the bar; this limitation is reported above.

Automated work-race checks can be reproduced with
`python3 tests/smoke_work.py --godot /path/to/Godot`. They use local UDP ports
17881–17883 and save logs to the ignored `.godot/work-smoke-results/` directory.
Three connected-instance scenarios passed: students complete the original puzzle
and the new solo task to win; the TA completes timed batches to win with no grading
counter delivered to students; and TA cover programming leaves the dinner bar at 0%.
All four earlier dinner/voting smoke scenarios also passed after this increment.
