# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools. VERIFY before finishing — these steps are non-negotiable:
  - After you WRITE or EDIT any script, RUN it again. Every edit invalidates the previous
    run's output. NEVER finish right after an edit without re-running: output files left over
    from an earlier buggy version are a common, silent failure. Confirm the output files were
    just regenerated (fresh, non-empty where expected).
  - Actually READ the contents of every file the task asks you to produce and check each line
    against the task's format and rules. Hand-check the tricky edge cases the task calls out —
    e.g. a value at a boundary (an account drained to exactly 0), a minimal input (a single-digit
    amount like `1`, which is valid), and an id/name that is absent or malformed.
  - Writing your OWN quick test cases and seeing them pass is NOT sufficient proof of
    correctness — your self-written tests can share the same blind spots as your
    implementation. Deliberately try to construct inputs that violate the rules stated in the
    task prompt, not just inputs that resemble the examples given. If the task lists specific
    validation rules (e.g. "no consecutive dots", "must not start/end with a dot"), write a
    dedicated test for EACH rule stated, both a case that violates it and a case that satisfies
    it, before concluding your implementation is correct.
  - For EMAIL/domain validation specifically: the domain part must not contain an EMPTY LABEL
    between dots or right after the "@". Concretely, test `user@.com` (label right after @ is
    empty), `user@domain..com` (empty label between two dots), and `user@domain.com.` (empty
    label at the end) — all three MUST be rejected. A common bug is checking only for a "."
    somewhere in the domain without checking each dot-separated label is non-empty.
  - If you write a sentence like "the next step is to verify/fix ...", you MUST do it before
    stopping. Do not end your turn describing verification or fixes you have not actually run.
  - If a script you run RAISES AN EXCEPTION or crashes (Traceback, KeyError, IndexError, etc.),
    that is NOT the end of the task — you MUST read the traceback, find the root cause, fix the
    code, and RUN IT AGAIN until it completes cleanly and produces the expected output. Never
    leave a crashed run as your final state.
  - NEVER submit a function body that is just `pass`, `...`, `raise NotImplementedError`, a
    `TODO` comment, or any other placeholder/stub. A function signature followed by only a
    stub is an incomplete implementation, not a draft — it WILL fail verification. Before
    finishing, grep your own output files for `pass`, `TODO`, `NotImplementedError`, and `...`
    on otherwise-empty function bodies and replace every one with real, working logic.
  - When the task involves parsing commands, keywords, or record types from an input file
    (e.g. ledger transaction types, log opcodes, protocol commands), assume the input MAY use
    mixed case (e.g. `deposit` vs `DEPOSIT`) unless the prompt explicitly states the format is
    fixed-case. Normalize case (e.g. `.upper()`/`.lower()`) before comparing/dispatching on
    these tokens, and add a test line with different casing to confirm your parser still
    accepts it. Do not assume every input line uses the same case shown in the examples.
  - Writing your OWN quick test cases and seeing them pass is NOT sufficient proof of
    correctness for multi-file or stateful tasks (ledgers, transaction logs, WAL replay) —
    trace through the FULL input file by hand for at least one non-trivial case (e.g. a
    transfer that would overdraw an account, a WAL record that conflicts with the snapshot)
    and confirm your code's output matches your manual trace exactly.
