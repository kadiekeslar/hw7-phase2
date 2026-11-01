class_name ProofChain
extends TaskLogic
## Problem Set: two players alternate playing clue cards ("A -> B") to extend a
## chain of symbols. Seat 0 holds the real clues for steps 1, 3, 5...; seat 1
## for steps 2, 4, 6... Each hand also has decoys that never match on its own
## turn, so on your turn exactly one of your cards is right.

const SYMBOL_COUNT := 8

var solution: Array[int] = []
var chain: Array[int] = []
## hands[seat] is an Array of Vector2i(from_symbol, to_symbol).
var hands: Array[Array] = [[], []]
var turn: int = 0
var wrong_lock_sec: float
var _lock_until: Array[float] = [0.0, 0.0]


func _init(length: int, decoys: int, p_wrong_lock_sec: float, rng: RandomNumberGenerator) -> void:
	assert(length >= 2 and length <= SYMBOL_COUNT)
	seat_count = 2
	wrong_lock_sec = p_wrong_lock_sec
	var symbols: Array[int] = []
	for i: int in SYMBOL_COUNT:
		symbols.append(i)
	_shuffle(symbols, rng)
	solution = symbols.slice(0, length)
	chain = [solution[0]]
	for step: int in range(1, length):
		hands[_seat_for_step(step)].append(Vector2i(solution[step - 1], solution[step]))
	for seat: int in 2:
		_add_decoys(seat, decoys, rng)
		_shuffle(hands[seat], rng)


func current_end() -> int:
	return chain[-1]


func is_complete() -> bool:
	return chain.size() == solution.size()


func payload_for(seat: int, now: float) -> Dictionary:
	var hand: Array = []
	for card: Vector2i in hands[seat]:
		hand.append([card.x, card.y])
	return {
		"chain": chain.duplicate(),
		"length": solution.size(),
		"hand": hand,
		"my_turn": turn == seat and not is_complete(),
		"locked_for": maxf(0.0, _lock_until[seat] - now),
		"complete": is_complete(),
	}


func handle_action(seat: int, action: Dictionary, now: float) -> Dictionary:
	var index: int = action.get("card", -1)
	if is_complete() or seat != turn or now < _lock_until[seat]:
		return {}
	if index < 0 or index >= hands[seat].size():
		return {}
	var card: Vector2i = hands[seat][index]
	if card.x != current_end() or card.y != solution[chain.size()]:
		_lock_until[seat] = now + wrong_lock_sec
		return {"wrong_card": index}
	hands[seat].remove_at(index)
	chain.append(card.y)
	turn = 1 - turn
	return {}


## Step n (1-based) is played by seat 0 when n is odd.
static func _seat_for_step(step: int) -> int:
	return (step - 1) % 2


func _add_decoys(seat: int, count: int, rng: RandomNumberGenerator) -> void:
	# A decoy's left symbol must never be the chain end on this seat's turns.
	var own_ends: Array[int] = []
	for step: int in range(1, solution.size()):
		if _seat_for_step(step) == seat:
			own_ends.append(solution[step - 1])
	var lefts: Array[int] = []
	for s: int in SYMBOL_COUNT:
		if s not in own_ends:
			lefts.append(s)
	var added := 0
	var attempts := 0
	while added < count and attempts < 100:
		attempts += 1
		var left := lefts[rng.randi_range(0, lefts.size() - 1)]
		var right := rng.randi_range(0, SYMBOL_COUNT - 1)
		var card := Vector2i(left, right)
		if right == left or card in hands[seat]:
			continue
		hands[seat].append(card)
		added += 1


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp
