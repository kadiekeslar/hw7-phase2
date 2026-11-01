extends GutTest

var work: CourseworkTracker


func before_each() -> void:
	work = CourseworkTracker.new([2, 3], [&"problem_set", &"programming"])


func test_each_student_has_two_assignments() -> void:
	assert_eq(work.fraction(), 0.0)
	assert_false(work.is_complete())
	assert_true(work.credit(2, &"problem_set"))
	assert_eq(work.fraction(), 0.25)


func test_repeated_task_and_unknown_player_never_farm_progress() -> void:
	work.credit(2, &"problem_set")
	assert_false(work.credit(2, &"problem_set"))
	assert_false(work.credit(1, &"problem_set"), "TA is not assigned real coursework")
	assert_false(work.credit(2, &"grading_west"))
	assert_eq(work.fraction(), 0.25)


func test_collaborators_can_each_earn_their_own_credit() -> void:
	work.credit(2, &"problem_set")
	work.credit(3, &"problem_set")
	assert_eq(work.fraction(), 0.5)
	assert_eq(work.completed_for(2), [&"problem_set"])


func test_every_assignment_is_required_for_victory() -> void:
	work.credit(2, &"problem_set")
	work.credit(3, &"problem_set")
	work.credit(2, &"programming")
	assert_false(work.is_complete())
	work.credit(3, &"programming")
	assert_true(work.is_complete())


func test_no_assignments_does_not_create_an_instant_win() -> void:
	var empty := CourseworkTracker.new([], [])
	assert_false(empty.is_complete())


func test_coursework_wins_simultaneous_race() -> void:
	assert_eq(WinConditions.work_winner(1.0, 1.0), "students")
	assert_eq(WinConditions.work_winner(0.99, 1.0), "ta")
	assert_eq(WinConditions.work_winner(1.0, 0.0), "students")
	assert_eq(WinConditions.work_winner(0.99, 0.99), "")
