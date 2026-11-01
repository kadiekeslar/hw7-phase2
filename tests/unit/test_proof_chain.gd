extends GutTest


func _make(seed_value: int, length := 7, decoys := 2) -> ProofChain:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return ProofChain.new(length, decoys, 2.0, rng)


func _matching_cards(puzzle: ProofChain, seat: int) -> Array[int]:
	var matches: Array[int] = []
	for i: int in puzzle.hands[seat].size():
		var card: Vector2i = puzzle.hands[seat][i]
		if card.x == puzzle.current_end():
			matches.append(i)
	return matches


func test_hands_have_half_the_clues_plus_decoys() -> void:
	var puzzle := _make(1)
	assert_eq(puzzle.hands[0].size(), 3 + 2)
	assert_eq(puzzle.hands[1].size(), 3 + 2)
	assert_eq(puzzle.chain.size(), 1)


func test_exactly_one_matching_card_each_turn() -> void:
	for seed_value: int in 200:
		var puzzle := _make(seed_value)
		while not puzzle.is_complete():
			var matches := _matching_cards(puzzle, puzzle.turn)
			assert_eq(matches.size(), 1, "seed %d step %d" % [seed_value, puzzle.chain.size()])
			if matches.size() != 1:
				return
			puzzle.handle_action(puzzle.turn, {"card": matches[0]}, 0.0)
		assert_eq(puzzle.chain, puzzle.solution)


func test_turns_alternate_starting_with_seat_zero() -> void:
	var puzzle := _make(7)
	assert_eq(puzzle.turn, 0)
	puzzle.handle_action(0, {"card": _matching_cards(puzzle, 0)[0]}, 0.0)
	assert_eq(puzzle.turn, 1)


func test_playing_out_of_turn_does_nothing() -> void:
	var puzzle := _make(7)
	var before := puzzle.hands[1].size()
	puzzle.handle_action(1, {"card": 0}, 0.0)
	assert_eq(puzzle.chain.size(), 1)
	assert_eq(puzzle.hands[1].size(), before)


func test_wrong_card_locks_the_hand() -> void:
	var puzzle := _make(3)
	var right := _matching_cards(puzzle, 0)[0]
	var wrong := 0 if right != 0 else 1
	var feedback := puzzle.handle_action(0, {"card": wrong}, 10.0)
	assert_eq(feedback.get("wrong_card"), wrong)
	assert_eq(puzzle.turn, 0, "still your turn")
	puzzle.handle_action(0, {"card": right}, 11.0)
	assert_eq(puzzle.chain.size(), 1, "locked for 2 s")
	assert_almost_eq(puzzle.payload_for(0, 11.0)["locked_for"], 1.0, 0.001)
	puzzle.handle_action(0, {"card": right}, 12.0)
	assert_eq(puzzle.chain.size(), 2)


func test_bad_card_index_is_ignored() -> void:
	var puzzle := _make(3)
	assert_eq(puzzle.handle_action(0, {"card": 99}, 0.0), {})
	assert_eq(puzzle.handle_action(0, {}, 0.0), {})
	assert_eq(puzzle.chain.size(), 1)


func test_payload_hides_partner_hand() -> void:
	var puzzle := _make(3)
	var payload := puzzle.payload_for(0, 0.0)
	assert_eq(payload["hand"].size(), puzzle.hands[0].size())
	assert_true(payload["my_turn"])
	assert_false(puzzle.payload_for(1, 0.0)["my_turn"])
