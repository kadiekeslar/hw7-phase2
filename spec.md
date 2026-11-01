# Study Buddies — Game Design Doc

Oct 28, 2026 · @Anabella Phelps

## Overview

Study Buddies is a 5–8 player online social-deduction game set over one CMU semester: students race to finish their coursework, and one player is secretly a TA trying to finish grading first.

- **Genre:** social deduction with mini-puzzle tasks
- **Players:** 5–8 per lobby, exactly 1 secret TA
- **Engine:** Godot 4, 2D top-down, networked multiplayer
- **Session length:** one semester = 15 in-game weeks, roughly 15–22 real minutes (see Timing)
- **Core tension:** some tasks can only be unlocked by collaborating, and any student you collaborate with could be the TA.

## Art direction

Modernized 16-bit pixel art seen from an angled bird's-eye view, in a soft, warm, dreamlike palette with cozy-fantasy and Ghibli-like undertones.

**Reference mood board:**

&#91;image: Reference 1: cozy garden courtyard with greenhouses, warm stone, dense flowers\]

&#91;image: Reference 2: autumn stone bridge over a creek, orange foliage, soft light\]

&#91;image: Reference 3: snowy town square with a clean, simpler tile style and a calendar/day HUD\]

**What to take from each:**

| Reference | Take | Leave |
| --- | --- | --- |
| 1. Garden courtyard | Warm stone and brick, soft violet-tinted shadows, lived-in props, gentle light | The density: this much foliage hides players |
| 2. Autumn bridge | The autumn palette and glow, with no harsh black outlines | — |
| 3. Snowy town | Clear readable layout, simple shapes, and a top HUD bar like its day/season banner | The flat, straight-down camera |

**Style spec (proposed):**

- **Camera:** angled bird's-eye. See the open decision on projection below.
- **Resolution:** 16×16 tiles, characters about 16×24 px, rendered at a 480×270 base resolution and scaled up by whole numbers. In Godot, use nearest-neighbor filtering and pixel snapping so nothing blurs.
- **Palette:** about 32–48 colors. Warm golden-hour key light; shadows tinted violet or blue, never black; muted sage greens; terracotta and cream brick, which also fits CMU's look; soft outlines in a darker shade of each object's color instead of black.
- **Semester as seasons:** weeks 1–5 late-summer green, 6–11 autumn (reference 2), 12–15 finals snow (reference 3). The map itself shows how much semester is left. Do this as a color-grade shader plus a few swapped props, not redrawn tiles. Roughly 6–10 hrs.

**Readability rules (non-negotiable for social deduction):**

- **Players must pop against the scenery.** Reserve the most saturated colors for the 8 player outfits plus name tags, and keep the environment softer and lower in contrast. Among Us uses flat bold colors for exactly this reason. If players blend into the flowers, nobody can say "I saw Theo" with confidence.
- **Interactables glow:** grading stations (red-pen glint while in use), task stations and the professor's door get a subtle pulse.
- **Walls and roofs fade** when a player walks behind them, so a stealth game never hides the people you need to watch.
- Keep dense foliage to edges and decoration, never between rooms and doorways.

**What this costs:** the detail in references 1–2 is far past true 16-bit and is the slowest kind of pixel art to make. Rough estimates for 9 locations, 8 characters with 4-direction walk cycles, and props:

| Approach | Art hours (rough) |
| --- | --- |
| Draw everything at reference-1 detail yourself | 120–200+ |
| Start from a free cozy pixel-art pack (CC0 preferred), recolor to the palette, draw only CMU-specific props and characters | 30–60 |
| Placeholder shapes until milestone 3, then art | 0 until gameplay is proven fun |

These hours are **on top of** the 115–180 hr build estimate. Recommend the third row first, then the second: art is the easiest thing to sink hours into before you know the game is fun.

**Open decision: projection.** "Angled bird's-eye" covers two different builds:

- **Isometric (references 1–2):** diamond tiles and buildings on diagonals. It looks the most like your references, but every sprite needs diagonal facings, sorting gets harder, and line-of-sight math runs on a skewed grid.
- **3/4 top-down (between references 2 and 3):** square grid with the camera tilted, so you see building fronts and roofs. It's simpler for tilemaps, wall cutaways and line-of-sight. You can still get most of the warmth from the palette and lighting.

Recommend 3/4 top-down for a first game with stealth and line-of-sight. Choose before any tile is drawn; switching later means redrawing everything.

The screenshots are private references only. Don't trace them or ship them, and use "cozy fantasy" rather than "Ghibli" in anything public.

## Roles and win conditions

Students win by filling the shared task bar or voting out the TA; the TA wins by finishing all grading first.

| Role | Count | Goal | Wins when | Loses when |
| --- | --- | --- | --- | --- |
| Student | 4–7 | Finish every assigned task before the semester ends | Shared task bar hits 100%, or the TA is voted out at Rev Noodle. Students also win if both bars hit 100% at the same moment | Semester ends with the bar under 100% (everyone gets a failing grade), or the TA finishes grading first |
| Secret TA | 1 | Finish all grading in secret, without being identified | Grading reaches 100% before the students' task bar does, or the semester ends with the bar under 100% | Voted out at Rev Noodle |

- A student voted out as the TA **fails the class**: they become a Pitt student (see Pitt students).
- A student the TA successfully reports for collaborating also becomes a Pitt student.
- **Proposed rule :** if fewer than 2 living CMU students remain, collaborative tasks can no longer be unlocked, so the TA wins automatically.

## Tasks

Each student gets a different task list, so students spread across campus but must meet up to unlock collaborative work; every task fills the shared task bar.

| Task | Type | Mini-puzzle (proposed) | Unlocks (proposed) |
| --- | --- | --- | --- |
| Group project | Collab (2–3 players) | Each player holds half a circuit/code diagram; connect the pieces | Final presentation |
| Problem set | Collab (2 players) | Split logic puzzle: each sees half the clues | Quiz |
| Presentation | Collab (2–3 players) | Timed slide-ordering, players alternate | — |
| Study group | Collab (2 players) | Matching flashcards across two screens | Midterm / final |
| Studying (solo) | Solo | Memory-match cards | — |
| Quiz | Solo | 30-second multiple-choice sprint | — |
| Test / midterm | Solo | Longer timed puzzle, harder variant of quiz | — |
| Final | Solo | Hardest timed puzzle, unlocks in week 13 | — |
| Programming assignment | Solo | Drag code blocks into the right order to pass test cases | — |
| Eat at Rev Noodle | Mandatory group | Not a task: happens at every dinner and doesn't fill the bar | — |
| Shower | Upkeep | Hold-to-shower, \~10 s | Refills shower meter |

**TA's tasks:** the TA gets a fake student task list for cover (it does not fill the task bar) plus real **grading** tasks done in secret. Grading tasks happen at fixed stations (e.g., a TA office desk, a laptop in a study lounge). There are at least 4 stations spread across the map, so students can't camp one and lock the TA out. Being seen grading is the main way the TA gets exposed.

The task mini-puzzles above are placeholders. Each one is a separate scene you build once and reuse, so start with 3–4 and add more later.

## Collaboration, capture and reporting

The TA removes students in two ways: by capturing a student who asks them to collaborate, or by reporting a collaboration they witnessed to the professor.

**Capture:** when a student asks the TA to collaborate, the TA secretly chooses to capture them or to help for real. Helping completes the task normally, so a finished collab proves nothing. Capturing turns the student into a Pitt student; anyone in the room sees them vanish, and it uses the same 2-week cooldown as reports.&#32;

**Reporting flow:**

1. Two or more students collaborate within the TA's line of sight. Every player sees the same fixed radius around their character, and walls block sight.
2. A report button pops up on the TA's screen listing those students' names.
3. The TA leaves the room and walks to the professor's office, a separate room with a non-player professor NPC.
4. The TA picks one name from the list and files the report. Only that student becomes a Pitt student; the other collaborators stay in.
5. If any student sees the TA heading into the professor's office, that is strong evidence to bring to Rev Noodle.

**Limits:**

- Each report removes exactly one student, **the TA can hold only one pending report at a time, and there is a 2-week cooldown after each report**.
- a pending report expires after 1 in-game week, so the TA can't bank reports indefinitely. (approved)&#32;
- &#32;the report button only triggers for collaborations in the TA's line of sight, never map-wide. Map-wide detection would make the TA too strong. (approved)

**Office hours:** the only safe place to collaborate. Collaborations there can't be reported or captured, and office hours are open only during limited windows (see Timing). **A****p****p****r****o****v****e****d****:** put office hours next to the professor's office. That gives students a legitimate reason to be in that hallway, so a TA heading there isn't automatically exposed.

## Rev Noodle dinners and voting

Every 3 in-game weeks, all living players, TA included, are pulled to Rev Noodle for dinner to discuss suspicions and task progress, then vote. Outside of dinners, living players can't chat at all; Pitt students can chat only with each other.

- **Scheduled dinners:** weeks 3, 6, 9 and 12, which gives 4 per semester. The semester ends at the end of week 15, with no dinner.
- **Called dinners:** any living player can call an emergency dinner, the TA included, so calling one isn't a tell. **Proposed:** one call per player per game.
- **Discussion:** players share what they saw (e.g., "I saw Jordan grading in the lounge") and claim task progress. The shared task bar updates only when a dinner starts, so players can check whether claimed progress actually moved it.
- **Vote:** each living player votes for a suspect or skips. Whoever gets the most votes is out, unless skip gets the most.
  - Voted out and **was the TA** → game ends, students win.
  - Voted out and **was a student** → they fail the class and become a Pitt student.
  - Tie or majority skip → no one is out.
- **Proposed:** discussion 60 s, voting 20 s, matching defaults so meetings don't drag.

## Shower meter

Every player has a shower meter that drains from full to empty over one in-game month (4 weeks); low meters slow you down, and an empty meter fails a student but only cripples the TA's grading.

| Meter level | Student effect (approved) | TA effect (approved) |
| --- | --- | --- |
| 100–51% | Normal | Normal |
| 50–26% | Movement −15% | Movement −15%, grading −25% |
| 25–1% | Movement −35% | Movement −35%, grading −50% |
| 0% | Fails the class → becomes a Pitt student | Stays in game, grading −75% |

- Showering takes \~10 s at a dorm shower and refills the meter to 100%.
- The TA's **movement** must slow exactly like a student's, otherwise a smelly-but-fast player is an obvious tell.
- **Built-in clue:** a player whose meter should have hit 0% but who is still in the game is probably the TA. That's a fair, observable tell, so keep the meter hidden from other players and let them infer it from who they've seen at the showers.
- Showers are a shared location on a schedule, which gives students alibis ("I was showering") and gives the TA windows to grade unseen.

## TA emergencies

The TA can trigger two emergencies from a hidden menu: a pop quiz costs students progress, and no hot water pulls students to the basement and dorm, opening grading windows elsewhere.

| Emergency | What happens (proposed) | Penalty if ignored (proposed) |
| --- | --- | --- |
| Pop quiz | A quiz station opens in one room; every living student has 45 s to reach it and finish a short solo quiz | Each student who misses it costs the shared task bar 5% |
| No hot water | All showers are disabled until someone fixes the boiler in the basement (solo, \~8 s) | Meters keep draining with no way to refill; at worst, students start failing |

- **A****p****p****r****o****v****e****d** **cooldown:** one emergency per 2 in-game weeks, and none during a dinner.
- The TA must also show up to the pop quiz and fake it, or their absence is a tell.
- No hot water hurts the TA too, since their own grading slows as their meter drops. That's a deliberate trade-off.

## Pitt students (failed players)

A student who fails (voted out, reported, captured or shower meter at 0%) transfers to Pitt: they stay in the game as a Pitt student who can help but can't talk to CMU students. A banner announces "\[Name\] failed the class" to everyone the moment it happens.

- **Can:** move around campus, do solo tasks (these still fill the shared task bar), see everything, chat with other Pitt students.
- **Can't:** talk to living players, vote, call or attend dinners as a participant, collaborate, or be seen by living players.
- **Visual:** Pitt colors (blue and gold) and semi-transparent, visible only to other Pitt students.
- **Why it matters:** this keeps eliminated players engaged instead of quitting the lobby,
- **A****p****p****r****o****v****e****d****:** collaborative tasks a student still owed when they failed become solo versions that take 2× as long, so the task bar can still reach 100%. Pitt students have no shower meter.

## Map and timing

A starting map of 9 locations and a 60-second in-game week gives a \~20-minute game; every number here is a first guess to tune in playtests.

**Locations (proposed):**

| Location | Purpose |
| --- | --- |
| The Cut | Central hub connecting everything |
| Gates Commons(cs labs) | Programming assignments, group projects |
| UC 3rd floor (study lounge) | Problem sets, studying, a TA grading station |
| Hunt Library | Studying, study groups |
| Doherty(lecture hall) | Quizzes, tests, midterms, finals, pop quiz station |
| Morewood Garden Dorm(showers) | Showers |
| Basement of dorm&#32; | Boiler (no-hot-water fix) |
| Office wing | Professor's office (reports) + office hours room |
| Rev Noodle | Dinners and voting |

**Timing (proposed):**

| Setting | Value |
| --- | --- |
| 1 in-game week | 60 s real time |
| Semester length | 15 weeks (15 min) + 4 dinners × \~80 s ≈ 20 min total |
| Shower meter full → empty | 4 weeks (4 min) |
| Office hours | Open 1 week out of every 3 |
| Emergency cooldown | 2 weeks |
| Report expiry / cooldown | 1 week / 2 weeks |
| Tasks per student | 8–10, at least 3 collaborative |
| TA grading | Tuned so an unslowed TA finishes around week 12–13 |

## Scope and build plan

| Piece |
| --- |
| Map + movement |
| 4 starter mini-games |
| Task system, shared bar, unlocks |
| Networking: lobby, sync, role assignment |
| Dinners, voting, chat |
| Reporting, professor NPC, line of sight |
| Shower meter |
| Emergencies |
| Pitt students |
| UI and menus |
| Hosting and playtesting |
|  |

**Milestones:**

1. **Networked slice :** 2–3 players connecting online by room code (ENet + noray relay), with LAN/direct IP as fallback, in one room, secret role assignment, one collaborative task, and the report button popping up for the TA. This tests the core question: is collaborating next to a possible TA tense?
2. **Dinner + vote :** add Rev Noodle, discussion chat, voting, win/lose screens.
3. **Full loop:** full map, 4 mini-games, shared task bar, grading stations, professor's office.
4. **Systems :** shower meter, emergencies, Pitt students.
5. **Playtest + tune:** run full 5–8 player online playtests and tune the numbers in Map and timing.

Every playtest from milestone 2 on needs 5+ people, so line up a regular test group before you get there.

## Technical implementation

Every decision below is final for v1. Anything marked **default** was chosen without an explicit answer from Anabella; change it before work starts if it's wrong.

### Platform, engine and input

| Area | Decision |
| --- | --- |
| Engine | Godot 4, latest stable release at project start. Pin the exact version in the README; upgrade only by deliberate decision. |
| Language | GDScript, with static typing enabled |
| Platforms | Windows and macOS desktop only. No Linux, web or mobile in v1. |
| Input | Keyboard + mouse only, no controller |
| Movement | WASD or arrow keys, 8 directions; sprites have 4 facings (diagonals reuse side frames) |
| Default keys | **Default:** WASD/arrows move, E interact/collaborate, Tab task list, Enter open chat at dinners, Esc menu. No rebinding in v1. |
| Display | Windowed with a fullscreen toggle. 480×270 base resolution, whole-number scaling, letterboxing on other aspect ratios, nearest-neighbor filtering, pixel snap on. |
| Camera | 3/4 top-down, square 16×16 tile grid, Y-sorted sprites, walls and roofs fade when a player is behind them |

### Networking

| Area | Decision |
| --- | --- |
| Host model | Listen server: one player hosts. The host is authoritative for all game state: roles, clock, task progress, meters, captures, reports, votes and win checks. Clients send only inputs and requests; the host validates every request. |
| Transport | Godot `ENetMultiplayerPeer`, with the netfox.noray addon for online play: NAT punchthrough first, relay through our server if punchthrough fails. Relay server: a self-hosted noray server on an always-free cloud VM ($0/month) under Anabella's account. Default: the developer sets it up and documents in the README how to restart and update it. |
| Connecting | Online (primary, built from milestone 1): room codes. The host clicks Host Game and gets a short room code; others click Join and type it. LAN / direct IP (fallback): others type the host's IP instead, for same-room playtests or if the relay is down. **Default** port 7777, editable in the join screen. No port forwarding is needed for online play. |
| Connection code | All connection code (online and LAN) lives in one `NetworkService` autoload, so gameplay code never knows which path connected the players. |
| Hidden information | Each client receives only what its player may know: its own role; the report popup, emergency menu, cooldowns and grading progress go only to the TA's client; the TA reveal and Pitt chat go only to Pitt clients. Known limitation: the host's own machine holds everything. Accepted for friends-only play. |
| Sync | Player positions via `MultiplayerSynchronizer` at **default** \~20 Hz with client interpolation. Game events (task complete, capture, report, vote, emergency) are reliable RPCs validated by the host. |
| Line of sight | Computed on the host with raycasts against the wall collision layer, inside a fixed vision radius identical for all players. Never trusted from the TA's client. |
| Player count | 5–8. The Start button enables at 5. A dev test mode (command-line flag, debug builds only) allows 2–4 players and forcing who is TA. |

**Disconnects:**

| Who | What happens |
| --- | --- |
| Host quits or crashes | Game ends for everyone; all clients return to the menu with a "Host left" message |
| Student disconnects | Character freezes in place. Rejoin within 60 s with the same profile name to continue; otherwise they fail (banner fires, they become a Pitt student). |
| TA disconnects | Same 60 s window; if they don't return, students win and the TA is revealed |

### Game systems and data

| Area | Decision |
| --- | --- |
| Role assignment | Host picks the TA uniformly at random at game start |
| Balance values | Every tunable number (week length, meter drain, cooldowns, penalties, timers, vision radius, office-hours weeks) lives in one config resource, e.g. `config/game_balance.tres`. No in-game settings menu; Anabella or the developer edits the file between playtests. |
| Profiles | Name + color saved locally in `user://profile.cfg`, editable in the lobby. No accounts. |
| Player colors | 8 fixed colorblind-safe colors, unique per lobby, first come first served. Name tags always shown above characters. No hats or other customization. |
| Chat | Text only, and only during Rev Noodle dinners. Pitt students have a separate always-on Pitt-only channel. No profanity filter. **Default:** 120-character message limit. |
| Votes | Plurality. Skip wins if it ties or beats the top-voted player; a tie between players means no one is out. |
| TA auto-win | Yes: the TA wins as soon as fewer than 2 living CMU students remain |
| Pitt reveal | A student who fails is shown who the TA is |
| End screen | Winner + TA reveal, then return to lobby. No timeline recap. |
| Grading stations | 4: UC 3rd floor lounge, Hunt Library, Gates Commons, Doherty |
| First 4 minigames | Problem set (collab), study group (collab), programming assignment (solo), quiz (solo) |
| Quiz/test/final content | Themed abstract puzzles (pattern, logic, timing). No question bank. |
| Minigame architecture | Each minigame is a self-contained scene implementing one shared interface (start, progress, complete, cancel, collaborator count), so new tasks plug in without touching core code |
| Automated tests | GUT unit tests for win conditions, vote resolution, cooldowns, report expiry, shower-meter thresholds, Pitt conversion and the auto-win. Run before every release. |

### Art, audio and accessibility

| Area | Decision |
| --- | --- |
| Budget | $0. Every asset must be free and licensed for use in this project. Because the repo is public, licenses must also allow redistributing the raw files (CC0 is safest). Many free itch.io packs allow use in a game but forbid redistributing the files, so check before committing them. |
| Art pipeline | Colored-shape placeholders through milestone 3. Then a free cozy tileset recolored to the palette, plus custom CMU buildings and characters. |
| Characters | 8 color variants, 4 facings, idle and walk animations |
| Audio | Free licensed music and SFX libraries |
| Licenses | Every third-party asset (art, audio, fonts) listed in `CREDITS.md` with source link and license |
| Accessibility | Colorblind-safe palette for the 8 player colors, plus always-on name tags. No separate colorblind mode in v1. |

### Process and delivery

| Area | Decision |
| --- | --- |
| Repository | Public GitHub repo owned by Anabella (afphelps-wq); developer added as a collaborator with write access. No secrets or server credentials are ever committed; the relay server address and any keys live in an untracked local config file. Git LFS for images, audio and Aseprite files. |
| Builds | Windows and macOS builds attached to tagged GitHub Releases. Anyone with the link can download them; testers don't need a GitHub account. |
| macOS signing | **Default:** unsigned builds (the $0 budget rules out a paid Apple developer account). Testers right-click → Open the first time to get past Gatekeeper. |
| Release | The game is shared with friends, but the source and builds are public. Real CMU and Rev Noodle names will therefore be publicly visible; revisit them before promoting the game anywhere. |
| Milestone sign-off | **Default:** Anabella playtests each milestone against its checklist and approves it before the next one starts |
| Timeline | **Default:** no fixed deadline; the developer posts a progress update every 2 weeks |
