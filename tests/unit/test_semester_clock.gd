extends GutTest


func test_starts_in_week_one() -> void:
	var clock := SemesterClock.new(60.0, 15)
	assert_eq(clock.week(), 1)
	assert_false(clock.is_over())


func test_week_advances_every_week_length() -> void:
	var clock := SemesterClock.new(60.0, 15)
	clock.advance(59.9)
	assert_eq(clock.week(), 1)
	clock.advance(0.1)
	assert_eq(clock.week(), 2)
	assert_almost_eq(clock.seconds_left_in_week(), 60.0, 0.001)


func test_semester_ends_after_last_week() -> void:
	var clock := SemesterClock.new(60.0, 15)
	clock.advance(15 * 60.0 - 0.5)
	assert_false(clock.is_over())
	assert_eq(clock.week(), 15)
	clock.advance(10.0)
	assert_true(clock.is_over())
	assert_eq(clock.week(), 15, "stays on the last week")
	assert_eq(clock.elapsed_sec, clock.total_sec(), "does not run past the end")
