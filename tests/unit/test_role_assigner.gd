extends GutTest


func test_picks_one_of_the_players() -> void:
	var rng := RandomNumberGenerator.new()
	var ids: Array[int] = [1, 20, 300]
	for i: int in 50:
		assert_has(ids, RoleAssigner.pick_ta(ids, rng))


func test_every_player_can_be_picked() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var ids: Array[int] = [1, 2, 3]
	var seen := {}
	for i: int in 200:
		seen[RoleAssigner.pick_ta(ids, rng)] = true
	assert_eq(seen.size(), 3)


func test_forced_ta_wins_when_valid() -> void:
	var rng := RandomNumberGenerator.new()
	var ids: Array[int] = [1, 2, 3]
	for i: int in 20:
		assert_eq(RoleAssigner.pick_ta(ids, rng, 2), 2)


func test_invalid_forced_ta_falls_back_to_random() -> void:
	var rng := RandomNumberGenerator.new()
	var ids: Array[int] = [1, 2, 3]
	assert_has(ids, RoleAssigner.pick_ta(ids, rng, 99))
