# Phase 2 scope and preservation plan

Original author: Anabella Phelps. Foundation: initial commit `3360f00`.

The selected target is the author's second milestone: dinner discussion, chat,
voting, and a win/lose screen. Keep the existing room, movement, connection service,
Session roster, puzzle, collaboration/capture, and report tracker. Extend GameServer
and its existing request/host-message RPC structure. Put dinner presentation in a
small new DinnerPanel and ballot rules in DinnerLogic; do not rewrite Hud or the
original game architecture.

1. Check the unmodified baseline and read the spec before implementation.
2. Add deterministic ballot rules and tests (plurality, Skip/ties, invalid and duplicate votes).
3. Add host-owned scheduled/emergency dinners, paused clock/movement, living-only chat and voting.
4. Add student victory on TA vote-out, TA victory on semester timeout or too few
   students, end-screen reveal, and use the existing return-to-lobby flow.
5. Test the inherited rules and three connected instances with accelerated timers.
6. Report each requirement honestly in README, preserve spec.md, and record prompts.

Out of scope for this update: full campus/restaurant art, task-progress and grading
bars, new minigames, professor reporting, Pitt gameplay, showers, emergencies,
online relay hosting, and release exports. The README marks these as unfinished.
The student's personal HANDOFF_REPORT.md remains the student's responsibility.
