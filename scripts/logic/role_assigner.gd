class_name RoleAssigner
extends RefCounted
## Secret role assignment. Runs on the host only.

enum Role { STUDENT, TA }


## Picks the TA uniformly at random, unless a valid forced peer is given (dev mode).
static func pick_ta(peer_ids: Array[int], rng: RandomNumberGenerator, forced_peer: int = 0) -> int:
	assert(not peer_ids.is_empty())
	if forced_peer in peer_ids:
		return forced_peer
	return peer_ids[rng.randi_range(0, peer_ids.size() - 1)]
