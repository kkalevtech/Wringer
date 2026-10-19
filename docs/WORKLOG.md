# Work log

Append-only. Newest entries at the bottom.

Purpose: the plan and its evidence live in the repository, not in a chat
window. `AGENTS.md` §1.5 requires the plan to be written here **before**
implementation starts, so it cannot be retrofitted afterwards to match
whatever got built.

Rules:

- Never edit or delete a past entry. If one was wrong, append a correction.
- One entry per task, opened at `start`, completed at `commit`.
- An open entry with no commit means that task is in progress.
- Keep it short. This is a record, not an essay.

---

## Entry format

~~~markdown
## T-005 — probe an image

**Started:** 2026-10-18 · **Committed:** <hash or "not yet">

**Plan**
- files: `src-tauri/src/probe/mod.rs`, `src-tauri/src/error.rs`
- approach: call `vipsheader -a`, parse `key: value` lines into a typed
  struct; magic-byte detection stays in our own code, not the engine
- new dependencies: none

**Questions**
- Q: should `ImageInfo` carry bit depth? Not specified in `SPEC.md` §4.
  → A: no, add it when a mode needs it. Recorded in `SPEC.md` §4.

**Verification**

<paste of .\scripts\verify.ps1 output>

**Acceptance criteria**
1. four fixtures return exact expected values — `test probe::tests::png_fixture ... ok`
2. a text file returns `UnsupportedFormat` — `test probe::tests::not_an_image ... ok`

**Not verified**
- EXIF presence detection on TIFF; no fixture exists yet. Raised as a new
  task.

**Docs changed**
- `docs/SPEC.md` §4 — clarified that `ImageInfo` is extensible
~~~

---

## H-001 — harness revision from the readiness review

**Started:** 2026-10-19 · **Committed:** folded into the bootstrap commit on
`main` — the repository's only commit — at the human's direction.

**Git**

- This working copy arrived as a zip extract with no `.git`. Connected to
  `origin` (`github.com/kkalevtech/Wringer`) and reset onto the only commit on
  `main`. The working diff was exactly the seven files above, nothing else.
- Direction: fold the change into that commit rather than add a second, so
  `main` keeps its single bootstrap commit. Amended locally, authored and
  committed as `kkalevtech <kkalev.tech@gmail.com>`, message unchanged.
- **Not pushed.** Rule 10 and §6 reserve pushing to the human (ADR-014), and no
  credential is cached, so the human runs the `--force-with-lease` push.
- §6 says a `pre-v1-setup` tag preserves the pre-renumber task list. The remote
  has no tags. Left as written; flagged for later.

Not a numbered task. Requested directly by the human after an external
readiness review, under the rule 10 exception for harness and documentation
changes. Decisions are recorded as `DECISIONS.md` ADR-012…ADR-015.

**Plan**

- files: `AGENTS.md`, `docs/SPEC.md`, `docs/TASKS.md`, `docs/DECISIONS.md`,
  `docs/WORKLOG.md`, `README.md`, `scripts/verify.ps1`
- approach: fix the contradictions and coverage holes the review found,
  without changing the execution model. Add tasks for the `SPEC.md`
  §4/§5/§10 behaviour that had no owner; give the release path an explicit
  authority rule; make the gate enforce the contract ADR-011 already states;
  make the gate's prerequisites explicit.
- new dependencies: none added here. A pre-approved baseline is recorded
  (ADR-015) so T-001 can start.

**Questions asked before implementing**

- Q: no `.git` in this working copy, yet §6 assumes `main`, the
  `pre-v1-setup` tag and an `origin` remote.
  → A: the human has the real repository; this copy is a zip extract, so no
  harness change is needed. Git-dependent evidence runs against the clone.
- Q: add coverage tasks, or declare the milestone lists normative?
  → A: add tasks, and leave every existing ID alone (letter suffixes).
- Q: `SPEC.md` §13.1 makes AVIF mandatory while T-016 let it be dropped.
  → A: AVIF stays required; T-002 gains the engine-capability question.
- Q: rule 9 has no approval channel, blocking T-001.
  → A: pre-approve the Tauri scaffold baseline.
- Q: rule 7 approval to edit `scripts/verify.ps1`.
  → A: granted.

**Verification**

`.\scripts\verify.ps1`, run from the repository root:

```
=== Rust formatting ===
SKIP - 'src-tauri/Cargo.toml' does not exist yet

=== Rust lints ===
SKIP - 'src-tauri/Cargo.toml' does not exist yet

=== Rust tests ===
SKIP - 'src-tauri/Cargo.toml' does not exist yet

=== JS lint ===
SKIP - 'package.json' does not exist yet

=== JS tests ===
SKIP - 'package.json' does not exist yet

=== No network deps ===
SKIP - 'scripts/check-no-network.ps1' does not exist yet

===============================
 verify.ps1
===============================
  Rust formatting    SKIP
  Rust lints         SKIP
  Rust tests         SKIP
  JS lint            SKIP
  JS tests           SKIP
  No network deps    SKIP

All runnable stages passed. Skipped stages are not yet written.
```

Every stage SKIPs, because none of the files the stages key on exist until
T-001 and T-002. The gate therefore cannot demonstrate a document change, and
the ADR-011 fix was proven against the real `Invoke-Stage` instead — extracted
from `verify.ps1` unmodified and run with three probes:

```
-- PASS: probe-native-pass                                  (cmd /c exit 0)
-- FAIL: probe-native-fail (exit 3)                          (cmd /c exit 3)
-- FAIL: probe-return-only (no exit code - the stage must own its result (ADR-011))
```

Before this change the first probe reported PASS, which is the false PASS
ADR-011 exists to prevent.

**Acceptance criteria**

- requirement coverage: `T-013a`, `T-016a`, `T-017a`, `T-019a` and `T-027a`
  now own the `SPEC.md` §4 rows, the §5 mode pairs and the §10 targets that had
  none — `### T-016a - TIFF read and write`, `### T-019a - Performance budget`.
- release-path contradiction: rule 10, §1.11 and §6 now agree — "**Never push**
  — pushing is always the human's", with T-037/T-038 the sole carve-out under a
  recorded go-ahead. §1.3 preflight exempts them.
- CI push deadlock: T-031 and T-032 state that the human pushes and the agent
  reads the run; a scratch branch for T-032 is permitted.
- gate self-sufficiency: §1.8 names the prerequisites; T-031 installs them in
  CI; T-037's "fresh clone" accepts them.
- T-036 tag inversion: criterion 6 records a commit hash, with an interim tag
  only if the human made one.
- dependency approval: ADR-015 plus §4 "The scaffold baseline".
- build-vs-run network wording: §2 now scopes the claim to the shipped app.
- AVIF: §4 and §13.1 keep it required; T-002 gained question 5 (ADR-013).
- ADR-011 enforcement: shown by the probe above.
- also fixed: §1.5 cited Rule 8 for dependencies (now Rule 9); §6 counted four
  operations while listing five; `SPEC.md` §8's "one subprocess per job" now
  says "at a time", matching §5's eight invocations; rule 1 no longer reads as
  a ban on the test-only pixel comparison `libvips.md` offers; rule 4 separates
  a documented unsupported cell from a skipped test; §1.12 defines `reject`;
  README's clippy command gained `--all-targets`.

**Not verified**

- The gate cannot exercise these changes (all stages SKIP). Nothing here is
  code, so nothing is unit-testable; the evidence is the text plus the probe.
- No Git commands were run. This working copy is a zip extract with no `.git`,
  so no commit, `git status`, or fixture hashing could be checked.
- The new tasks are defined but not executed. Whether `T-017a`'s enumeration
  really accounts for every cell is only knowable when it runs.
- `T-019a` asserts timing; the 30-second target is inherited from `SPEC.md` §10
  and has never been measured.

**Docs changed**

- `AGENTS.md` — §1.1, §1.3, §1.5, §1.6, §1.8, §1.11, new §1.12, §2 (+ Source
  of truth), rules 1, 4, 9, 10, new "The scaffold baseline", §6 landing and
  Never.
- `docs/SPEC.md` — §4 AVIF row, §8 process count, §13.1.
- `docs/TASKS.md` — consuming rules, T-002, T-004, T-013a (new), T-016, T-016a
  (new), T-017a (new), T-019a (new), T-027a (new), T-031, T-032, T-033, T-036,
  T-037, T-038.
- `docs/DECISIONS.md` — ADR-012…ADR-015.
- `README.md` — lint command.
- `scripts/verify.ps1` — stage-owned results enforced (human-approved edit).
