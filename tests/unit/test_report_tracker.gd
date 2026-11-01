extends GutTest

const WEEK := 60.0
var tracker: ReportTracker


func before_each() -> void:
	tracker = ReportTracker.new(1 * WEEK, 2 * WEEK)


func test_creates_report_when_ready() -> void:
	assert_true(tracker.create_report(0.0, [2, 3]))
	assert_true(tracker.has_pending())
	assert_eq(tracker.pending_ids, [2, 3] as Array[int])


func test_only_one_pending_report() -> void:
	tracker.create_report(0.0, [2, 3])
	assert_false(tracker.create_report(5.0, [4, 5]))
	assert_eq(tracker.pending_ids, [2, 3] as Array[int])


func test_pending_report_expires_after_one_week() -> void:
	tracker.create_report(10.0, [2, 3])
	assert_false(tracker.expire_if_due(10.0 + WEEK - 0.1))
	assert_true(tracker.expire_if_due(10.0 + WEEK))
	assert_false(tracker.has_pending())
	assert_false(tracker.on_cooldown(10.0 + WEEK), "expiry does not start a cooldown")


func test_cannot_file_expired_report() -> void:
	tracker.create_report(0.0, [2, 3])
	assert_false(tracker.file_report(WEEK + 1.0, 2))


func test_filing_needs_a_listed_name() -> void:
	tracker.create_report(0.0, [2, 3])
	assert_false(tracker.file_report(1.0, 9))
	assert_true(tracker.has_pending())


func test_filing_starts_two_week_cooldown() -> void:
	tracker.create_report(0.0, [2, 3])
	assert_true(tracker.file_report(30.0, 3))
	assert_false(tracker.has_pending())
	assert_true(tracker.on_cooldown(30.0 + 2 * WEEK - 0.1))
	assert_false(tracker.can_create_report(30.0 + 2 * WEEK - 0.1))
	assert_true(tracker.can_create_report(30.0 + 2 * WEEK))


func test_capture_shares_cooldown_and_clears_pending() -> void:
	tracker.create_report(0.0, [2, 3])
	assert_true(tracker.can_capture(1.0))
	tracker.record_capture(1.0)
	assert_false(tracker.has_pending())
	assert_false(tracker.can_capture(1.0 + 2 * WEEK - 0.1))
	assert_false(tracker.can_create_report(1.0 + 2 * WEEK - 0.1))
	assert_true(tracker.can_capture(1.0 + 2 * WEEK))


func test_forgetting_last_student_clears_report() -> void:
	tracker.create_report(0.0, [2, 3])
	tracker.forget_student(2)
	assert_eq(tracker.pending_ids, [3] as Array[int])
	tracker.forget_student(3)
	assert_false(tracker.has_pending())
