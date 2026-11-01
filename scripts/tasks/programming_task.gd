class_name ProgrammingTask
extends TaskLogic
## Arrange a tiny program in execution order. Only the host knows the solution.

const RECIPES := [
	["Compute the average of two scores", ["scores = [80, 100]", "total = sum(scores)", "average = total / len(scores)", "message = 'Average: ' + str(average)", "print(message)"]],
	["Count down from three", ["remaining = 3", "while remaining > 0:", "    print(remaining)", "    remaining -= 1", "print('Done')"]],
	["Print a personalized greeting", ["name = 'Student'", "greeting = 'Hello, ' + name", "message = greeting + '!'", "print(message)", "print('Welcome to class')"]],
]

var _cards: Array = []
var _answer: Array[int] = []
var _selected: Array[int] = []
var _goal: String
var _complete: bool = false


func _init(rng: RandomNumberGenerator) -> void:
	var recipe: Array = RECIPES[rng.randi_range(0, RECIPES.size() - 1)]
	_goal = recipe[0]
	var order: Array[int] = [0, 1, 2, 3, 4]
	# Shuffle with the supplied RNG so tests can reproduce a puzzle.
	for i: int in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	for index: int in order:
		_cards.append(recipe[1][index])
	for index: int in order.size():
		_answer.append(order.find(index))


func payload_for(_seat: int, _now: float) -> Dictionary:
	return {"kind": "programming", "goal": _goal, "cards": _cards.duplicate(),
		"selected": _selected.duplicate(), "complete": _complete}


func handle_action(seat: int, action: Dictionary, _now: float) -> Dictionary:
	if seat != 0 or _complete:
		return {}
	if action.get("reset", false) == true:
		_selected.clear()
		return {}
	if not action.has("card") or typeof(action["card"]) != TYPE_INT:
		return {}
	var index: int = action["card"]
	if index < 0 or index >= _cards.size() or index in _selected:
		return {}
	# Validate incrementally: a wrong card leaves the existing prefix intact.
	if index != _answer[_selected.size()]:
		return {"message": "That line cannot come next. Try another block."}
	_selected.append(index)
	_complete = _selected.size() == _cards.size()
	return {}


func is_complete() -> bool:
	return _complete
