class_name GameBalance
extends Resource
## Every tunable number in the game. Edit game_balance.tres between playtests.

@export_group("Clock")
## Real seconds per in-game week.
@export var week_length_sec: float = 60.0
@export var semester_weeks: int = 15

@export_group("Movement")
## Walking speed in pixels per second (16 px = 1 tile).
@export var move_speed_px: float = 64.0
## How far behind real time other players are drawn, to smooth network jitter.
@export var interpolation_delay_ms: int = 100

@export_group("Vision")
## Fixed sight radius used for the TA's line-of-sight check, in pixels (16 px = 1 tile).
@export var vision_radius_px: float = 96.0

@export_group("Collaboration")
## How close a player must be to a task station and to the partner to press E.
@export var interact_radius_px: float = 24.0
## Seconds the asked player has to accept before the request expires.
@export var collab_request_timeout_sec: float = 10.0

@export_group("Problem set (Proof Chain)")
## Symbols in the finished chain, including the starting one. Max 8.
@export var proof_chain_length: int = 7
## Decoy clue cards added to each player's hand.
@export var proof_chain_decoys: int = 2
## Seconds a player's hand locks after playing a wrong card.
@export var proof_chain_wrong_lock_sec: float = 2.0

@export_group("Reports and capture")
## A pending report expires after this many in-game weeks.
@export var report_expiry_weeks: float = 1.0
## Shared cooldown after a report or capture, in in-game weeks.
@export var report_cooldown_weeks: float = 2.0

@export_group("Networking")
@export var default_port: int = 7777
@export var position_sync_hz: int = 20
@export var min_players: int = 5
## Minimum players when the dev-mode toggle is on.
@export var dev_min_players: int = 2
@export var max_players: int = 8
