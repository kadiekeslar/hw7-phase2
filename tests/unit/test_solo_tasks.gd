extends GutTest


func test_grading_cannot_be_submitted_before_host_timer() -> void:
	var grading := GradingTask.new(15.0)
	grading.payload_for(0, 100.0)
	grading.handle_action(0, {"submit": true}, 114.99)
	assert_false(grading.is_complete())
	grading.handle_action(0, {"submit": true}, 115.0)
	assert_true(grading.is_complete())


func test_grading_rejects_wrong_seat_and_unstarted_work() -> void:
	var grading := GradingTask.new(15.0)
	grading.handle_action(0, {"submit": true}, 1000.0)
	assert_false(grading.is_complete())
	grading.payload_for(0, 1000.0)
	grading.handle_action(1, {"submit": true}, 1015.0)
	assert_false(grading.is_complete())


func test_grading_payload_reports_elapsed_host_time() -> void:
	var grading := GradingTask.new(15.0)
	grading.payload_for(0, 20.0)
	assert_eq(grading.payload_for(0, 25.0)["seconds_left"], 10.0)


func test_programming_has_five_distinct_shuffled_blocks_without_solution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var task := ProgrammingTask.new(rng)
	var payload := task.payload_for(0, 0)
	assert_eq(payload["cards"].size(), 5)
	assert_false(payload.has("answer"))
	assert_true(payload["selected"].is_empty())


func test_programming_rejects_invalid_card_types_indices_and_seats() -> void:
	var task := ProgrammingTask.new(RandomNumberGenerator.new())
	for action: Dictionary in [{"card": -1}, {"card": 99}, {"card": "0"}, {}]:
		task.handle_action(0, action, 0)
	for index: int in 5:
		task.handle_action(9, {"card": index}, 0)
	assert_true(task.payload_for(0, 0)["selected"].is_empty())
	assert_false(task.is_complete())


func test_programming_is_solvable_without_duplicate_credit_and_can_reset() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 234
	for attempt: int in 12:
		var task := ProgrammingTask.new(rng)
		for step: int in 5:
			for index: int in 5:
				task.handle_action(0, {"card": index}, 0)
		assert_true(task.is_complete())
		assert_eq(task.payload_for(0, 0)["selected"].size(), 5)
		for index: int in 5:
			task.handle_action(0, {"card": index}, 0)
		assert_eq(task.payload_for(0, 0)["selected"].size(), 5)
	var unfinished := ProgrammingTask.new(rng)
	for index: int in 5:
		unfinished.handle_action(0, {"card": index}, 0)
	unfinished.handle_action(0, {"reset": true}, 0)
	assert_true(unfinished.payload_for(0, 0)["selected"].is_empty())
