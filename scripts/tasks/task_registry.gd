class_name TaskRegistry
extends RefCounted
## Every task the game knows about. To add a task: write a TaskLogic subclass,
## a Minigame scene, and add an entry here.

const PROBLEM_SET := &"problem_set"

const PROGRAMMING := &"programming"
const GRADING_DESKS := [&"grading_west", &"grading_south", &"grading_east", &"grading_north"]
const COURSEWORK_TASKS: Array[StringName] = [PROBLEM_SET, PROGRAMMING]

const TASKS := {
	PROGRAMMING: {"name": "Programming Assignment", "players": 1, "scene": "res://scenes/tasks/solo_minigame.tscn"},
	&"grading_west": {"name": "Grading desk", "players": 1, "scene": "res://scenes/tasks/solo_minigame.tscn"},
	&"grading_south": {"name": "Grading desk", "players": 1, "scene": "res://scenes/tasks/solo_minigame.tscn"},
	&"grading_east": {"name": "Grading desk", "players": 1, "scene": "res://scenes/tasks/solo_minigame.tscn"},
	&"grading_north": {"name": "Grading desk", "players": 1, "scene": "res://scenes/tasks/solo_minigame.tscn"},
	PROBLEM_SET: {
		"name": "Problem Set",
		"players": 2,
		"scene": "res://scenes/tasks/proof_chain_minigame.tscn",
	},
}


static func display_name(task_id: StringName) -> String:
	return TASKS[task_id]["name"]


static func player_count(task_id: StringName) -> int:
	return TASKS[task_id]["players"]


static func scene_path(task_id: StringName) -> String:
	return TASKS[task_id]["scene"]


static func create_logic(task_id: StringName, balance: GameBalance, rng: RandomNumberGenerator) -> TaskLogic:
	if is_grading(task_id):
		return GradingTask.new(balance.grading_batch_sec)
	match task_id:
		PROGRAMMING:
			return ProgrammingTask.new(rng)
		PROBLEM_SET:
			return ProofChain.new(balance.proof_chain_length, balance.proof_chain_decoys,
					balance.proof_chain_wrong_lock_sec, rng)
	push_error("Unknown task %s" % task_id)
	return null


static func is_grading(task_id: StringName) -> bool:
	return task_id in GRADING_DESKS
