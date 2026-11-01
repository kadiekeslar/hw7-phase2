# Phase 2 prompt log

Tool: Codex desktop, GPT-6.1 Sol (selected in the chat UI), using Git, shell,
GitHub connector, and the installed Godot 4.7.2 for validation. No Phase 1 prompt
log was present in the inherited repository; this file records Phase 2 work only.

## Important user prompts (verbatim excerpts)

Initial review/preservation request:

> okay now here is my repo that i created from this phase 2 step 0 here is the writeup, i need to first see what the project does so far, what should be my next steps and following all of the rules especially

Preservation instruction supplied by the user (verbatim):

> You must keep at least 75% of the original work. You may reorganize, refactor, extend, and fix. You may not quietly discard the foundation and rebuild it in your own image. We compare your final submission against the initial commit of what you received.

Subsequent review prompts:

> okay so what are things that still need completed that arent finished yet

Implementation and push authorization:

> okay using the spec work on some things it is missing and you can just push them to my git then tell me how to look at those changes

## Scope used for implementation

The assistant selected the next milestone in the original spec: dinners, discussion
chat, voting, and winner/TA-reveal screens. Existing gameplay classes and logic were
extended in place; DinnerLogic and DinnerPanel were added. No request was made to
replace the engine, rewrite the puzzle, rename the original classes, or redesign
the campus. The original spec is unchanged. See PHASE2_PLAN.md and the README.

## Actual unwanted tool effects and corrections

Running Godot's editor import automatically changed nine existing GUT `.png.import`
files, which were unrelated to the requested gameplay changes. The source images
were inherited Git LFS pointer text rather than PNG bytes. The assistant caught
the unrelated changes in `git diff` and restored the import metadata instead of
committing it. It then separately restored the nine original upstream GUT images,
accepting each only if size and SHA-256 matched the inherited pointer. This keeps
the dependency's original content rather than inventing replacement art.

The first AI-written all-dinners smoke test also stopped after seven seconds,
before the accelerated semester could finish once meeting pauses were included.
The timeout assertion failed. The assistant inspected the logs, kept the game's
clock behavior, and extended that test's run duration to eleven seconds.

These are observed workflow mistakes and corrections, not invented user feedback.
No AI-generated personal handoff report is included.

## Second increment: user playtest and follow-up authorization

User feedback (verbatim):

> okay all of that works, what else needs added and also currently there is only one task spot to be done

User implementation request (verbatim):

> okay add what you think i have time for and what will get me lots of progres maybe the ta grading

The assistant scoped this to the existing task framework: one additional solo
programming puzzle, private assignment checklists, host-side deduplicated coursework,
dinner-only public progress, four grading desks and private TA grading. Original
classes, puzzle, movement, room and networking remain. The README explicitly marks
the smaller assignment list, one-room station placement and short balance as partial
implementation of the full spec. The student confirmed the previous increment's
manual checks; the assistant does not claim the student has tested this increment yet.
