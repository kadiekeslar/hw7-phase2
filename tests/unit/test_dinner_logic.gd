extends GutTest

var dinner: DinnerLogic


func before_each() -> void:
	dinner = DinnerLogic.new([1, 2, 3, 4, 5])


func test_plurality_can_eliminate_without_absolute_majority() -> void:
	dinner.cast_vote(1, 3)
	dinner.cast_vote(2, 3)
	dinner.cast_vote(3, 2)
	dinner.cast_vote(4, 1)
	dinner.cast_vote(5, 0)
	assert_eq(dinner.result(), 3)
	assert_true(dinner.all_voted())


func test_skip_ties_the_leader_so_no_one_is_out() -> void:
	dinner.cast_vote(1, 3)
	dinner.cast_vote(2, 0)
	assert_eq(dinner.result(), 0)


func test_tie_between_players_eliminates_nobody() -> void:
	dinner.cast_vote(1, 2)
	dinner.cast_vote(2, 1)
	assert_eq(dinner.result(), 0)


func test_skip_with_most_votes_and_no_ballots_eliminate_nobody() -> void:
	assert_eq(dinner.result(), 0)
	dinner.cast_vote(1, 0)
	dinner.cast_vote(2, 0)
	dinner.cast_vote(3, 2)
	assert_eq(dinner.result(), 0)


func test_ineligible_voters_and_targets_are_rejected() -> void:
	assert_false(dinner.cast_vote(99, 1))
	assert_false(dinner.cast_vote(1, 99))
	assert_true(dinner.votes.is_empty())


func test_one_ballot_per_player() -> void:
	assert_true(dinner.cast_vote(1, 3))
	assert_false(dinner.cast_vote(1, 0))
	assert_eq(dinner.votes[1], 3)


func test_disconnect_removes_the_voter_and_abstains_votes_for_that_player() -> void:
	dinner.cast_vote(1, 2)
	dinner.cast_vote(2, 3)
	dinner.remove_voter(2)
	assert_false(2 in dinner.voters)
	assert_false(dinner.votes.has(2))
	assert_eq(dinner.result(), 0)
	assert_false(dinner.cast_vote(1, 3), "surviving players cannot cast a second ballot")
	assert_false(dinner.cast_vote(2, 1))
	assert_false(dinner.cast_vote(1, 2))
