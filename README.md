# Study Buddies

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
godot --headless --path . -s addons/gut/gut_cmdln.gd
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
| Tab | Task list |
| Enter | Open chat (dinners) |
| Esc | Menu |
| F11 | Toggle fullscreen |
