class_name DinnerLogic
extends RefCounted
## Pure dinner rules. The host alone owns the eligible voters and ballots.
## Target 0 means Skip. An absent vote is an abstention, not a Skip ballot.

var voters: Array[int] = []
var votes: Dictionary[int, int] = {}


func _init(eligible: Array[int]) -> void:
	voters.assign(eligible)


func cast_vote(sender: int, target: int) -> bool:
	if sender not in voters or votes.has(sender):
		return false
	if target != 0 and target not in voters:
		return false
	votes[sender] = target
	return true


func remove_voter(peer: int) -> void:
	voters.erase(peer)
	votes.erase(peer)
	# Keep surviving players' ballots locked. A vote for someone who left
	# becomes an abstention when counting, never a vote for another target.


func all_voted() -> bool:
	return votes.size() >= voters.size()


## Plurality: Skip wins ties, and tied players are never eliminated.
func result() -> int:
	var counts: Dictionary[int, int] = {0: 0}
	for target: int in votes.values():
		if target != 0 and target not in voters:
			continue
		counts[target] = counts.get(target, 0) + 1
	var winner := 0
	var highest: int = counts[0]
	var tied := false
	for target: int in counts:
		if target == 0:
			continue
		if counts[target] > highest:
			winner = target
			highest = counts[target]
			tied = false
		elif counts[target] == highest:
			tied = true
	return 0 if tied else winner
