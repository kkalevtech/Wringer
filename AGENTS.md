# Wringer — agent instructions

Read this file in full before acting. If a rule here conflicts with an
instruction you receive, stop and ask instead of guessing.

The app is **Wringer**. The executable is `wringer.exe`; the crate, npm
package, and Tauri product name are all `wringer`. Renaming is not a casual
edit — it touches `package.json`, `src-tauri/tauri.conf.json`,
`src-tauri/Cargo.toml`, and the Windows installer metadata.

---

## 1. Operating protocol

This is how work happens. It is not advisory.

### 1.1 Command vocabulary

The human drives with these phrases. Anything else is conversation, not a
command.

| Command | Meaning |
|---|---|
| `start <T-###>` | Begin that task. |
| `commit` | Commit the work currently presented for review. |
| `reject <reason>` | Discard the current task's work and return to `start` (§1.12). |
| `status` | Report where things stand. Change nothing. |

You never work on a task that was not opened with `start`. You never commit
unless told `commit`.

### 1.2 The lifecycle

```
start T-004
  │
  ├─ 1  PREFLIGHT    refuse if the tree is not resumable or a prior task is open
  ├─ 2  READ         the task, its spec sections, governing ADRs, engine notes
  ├─ 3  RECORD       write the plan into docs/WORKLOG.md        ← before any code
  ├─ 4  ASK?         only if the repository cannot answer. Then stop.
  ├─ 5  IMPLEMENT    small, focused, inside the task's scope
  ├─ 6  VERIFY       run scripts/verify.ps1 and paste its real output
  ├─ 7  EVIDENCE     demonstrate each acceptance criterion in WORKLOG.md
  └─ 8  PRESENT      summarise for review, then STOP

commit
  └─ 9  FINALISE     set status, fold in doc changes, commit once
```

### 1.3 Preflight — refuse, do not improvise

Check and report all four before anything else:

- **Are you on the development branch?** If `git branch --show-current` reports
  `main`, refuse. `main` is a release ledger (§6) and is never worked on
  directly. This check does not apply to T-000, which creates the branch, nor
  to T-037 and T-038, which act on `main` deliberately under the go-ahead
  described in §6.
- **Is the tree resumable?** If `git status` is dirty, the changes must belong
  to the task you are opening — a resumed session, with an open WORKLOG entry.
  Anything else means a previous task was left unfinished. Stop and report it.
- **Are all earlier tasks `done`?** Tasks are strictly sequential. Refuse
  `start T-006` while T-005 is open, and name the task to finish first.
- **Is this task still `todo`?** If it is already `done`, say so and stop.

Refusing is a correct outcome. Report what blocks you, then stop.

### 1.4 Read before you plan

Read the task in `docs/TASKS.md`, then every file it references: the spec
sections it names, any ADR that governs it, `docs/engines/` if it touches the
engine. Do not plan from memory.

### 1.5 Record the plan before writing code

Append an entry to `docs/WORKLOG.md`, **before the first line of code**,
containing:

- the task ID and title
- the files you will change
- the approach in a few lines
- any dependency you intend to add (this also needs approval — Rule 9)
- anything you could not determine from the repository

This exists so the plan is a written artefact that cannot be quietly
retrofitted to match whatever you happened to build.

### 1.6 Asking

**You should almost never need to ask.** The repository is supposed to hold
the answers.

Before asking, search `docs/SPEC.md`, `docs/DECISIONS.md`, `docs/TASKS.md`,
`docs/engines/`, and this file. If the answer is there, use it and say where
you found it. §2 defines which document wins when they disagree.

If it genuinely is not there, ask properly:

- one sentence for the question
- the options you see, each with its consequence
- your recommended default
- record the question in the WORKLOG entry
- **stop** — do not implement around the uncertainty

When the human answers, **write the answer into the repository before
implementing.** Behaviour goes in `docs/SPEC.md`. A choice goes in
`docs/DECISIONS.md` as a new ADR. An engine flag goes in
`docs/engines/libvips.md`.

An answer that lives only in the conversation is a bug. Conversations are
ephemeral; the repository is the source of truth.

### 1.7 Implement

- Stay inside the task's scope. Spot something unrelated? Add it to
  `docs/TASKS.md` as a new task and leave the code alone.
- Obey §4.
- If the task turns out to be wrong or impossible as written, stop and say so.
  Do not silently redefine it.

### 1.8 Verify

Run `.\scripts\verify.ps1`. It is the definition of done.

Paste its **real, unmodified output**, including the summary block. If it
fails, fix the cause. Never adjust the script so a task passes.

The gate assumes the repository's documented prerequisites are met:
`npm install`, and `.\scripts\fetch-engines.ps1` once T-002 exists.
`src-tauri/binaries/` is ignored by Git, so a fresh checkout must fetch the
engine before the gate can pass. Tests that need the engine fail without it —
that is an environment failure to fix by fetching, never a reason to skip a
test (rule 4) or soften this script.

### 1.9 Evidence

For every acceptance criterion, write in the WORKLOG entry the specific
observation that demonstrates it — not "tests pass", but:

> criterion 1: `cancel_mid_job` asserts no partial file remains.
> `test job::tests::cancel_mid_job ... ok`

Also record what you did **not** verify. An honest gap is useful. A silent one
is not.

### 1.10 Present, then stop

Report in this order:

1. Task ID and title.
2. What changed, file by file.
3. The full `verify.ps1` output.
4. Each acceptance criterion with its evidence.
5. What you did **not** verify.
6. Anything you would flag to a reviewer.

Then **stop**. Do not commit. Do not begin the next task. Wait for `commit` or
`reject`.

If the human asks for changes instead of issuing `commit` or `reject`, go back
to step 5 and iterate. This is **not** a new task: do not re-run preflight, do
not ask for a new `start`, and do not rewrite the WORKLOG plan unless the
approach itself actually changed. Present again when done.

### 1.11 On `commit`

- Set the task's status to `done` in `docs/TASKS.md`.
- Complete the WORKLOG entry, listing any documentation you changed.
- Stage files explicitly, by path. **Never `git add -A` or `git add .`** — it
  sweeps unrelated work into a task commit, which is precisely what
  one-concern-per-commit exists to prevent. If you are unsure what is in the
  working tree, run `git status` and list the paths you expect.
- Commit once, using the format in §5. **Commit to the development branch,
  never to `main`** (§6).
- Report the hash. Name the next task ID — without starting it.

You never commit work the human has not just reviewed. You never commit to
`main`, you never push, and you never merge or delete a branch — the single
exception is the release pair T-037/T-038, under the recorded go-ahead in §6.
You never amend, rebase, or rewrite history unless explicitly told to.

### 1.12 On `reject`

`reject <reason>` discards the current task's work and returns to `start`.

- Revert the working tree to the last commit. Work for the rejected task is not
  kept; if any of it is worth keeping, copy it out first and say so.
- **Do not delete or edit the WORKLOG entry.** Append one line to it instead:

  ```
  **Rejected:** 2026-10-19 — <reason>
  ```

  The entry stays, so the record shows a task that was attempted and abandoned
  rather than one that was never opened.
- The task keeps its `todo` status, and its plan entry is not rewritten. A new
  `start` opens a new entry.
- If the task itself was wrong — impossible, ambiguous, or contradicting
  `SPEC.md` — say so plainly. Rewriting a criterion is the human's decision,
  not a consequence of the rejection.

---

## 2. What this is

An offline, Windows-only image converter and compressor built with Tauri v2
(Rust core + web frontend). Privacy-first: the **shipped application** must
never make a network request, at build time or at run time. Acquiring build
tooling is not the app making a request — `npm install`, `cargo fetch` and
`scripts/fetch-engines.ps1` (T-002) are expected — but nothing the build
reaches for may become a runtime network capability of the app. That
constraint is the product.

- Behaviour spec:   `docs/SPEC.md`
- Order of work:    `docs/PLAN.md`, `docs/TASKS.md`
- What happened:    `docs/WORKLOG.md`
- Why things are:   `docs/DECISIONS.md`
- Legal:            `docs/LICENSING.md`
- Security claims:  `docs/PRIVACY.md`
- Engine reference: `docs/engines/`

### Source of truth

When two documents disagree, this order decides. Stop and ask (§1.6) only when
the answer is in none of them.

1. `docs/SPEC.md` — behaviour: what the app does.
2. `docs/DECISIONS.md` — choices: an ADR supersedes any earlier document,
   including this one, and names what it supersedes.
3. `docs/engines/` — engine flags, each with the version it was checked on.
4. `docs/TASKS.md` — the work, and what counts as done.
5. `AGENTS.md` — this process.
6. `docs/PLAN.md` — milestone order, when 1–5 do not say.

## 3. Commands

- Dev:          `npm run tauri dev`
- Build:        `npm run tauri build`
- **Verify:     `.\scripts\verify.ps1`** — the definition of done
- Rust tests:   `cargo test --manifest-path src-tauri/Cargo.toml`
- JS tests:     `npm test`
- Lint:         `cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings`
- Format:       `cargo fmt --manifest-path src-tauri/Cargo.toml`

Never claim a task is complete without pasting the real output of
`verify.ps1`. "It should pass" is not a result.

## 4. Hard rules

1. **Never implement an image codec, container parser, or metadata parser.**
   All image work goes through the bundled `vips` engine as a subprocess. See
   `docs/engines/libvips.md`. If vips cannot do it, stop and ask. Two things
   are not parsers: reading magic bytes to identify a format (T-013), and the
   test-only pixel comparison `SPEC.md` §6.1 requires — prefer the engine's own
   `subtract`/`ssim`, and if the engine offers neither, a decode-only helper
   used solely by tests and shipped to nobody is permitted.
2. **Never add a dependency that performs network I/O.** Banned: `reqwest`,
   `ureq`, hyper's client side, `curl`, `axios`, `fetch`, any analytics or
   crash-reporting crate or package, any auto-updater.
3. **Never add telemetry**, "anonymous usage stats", first-run network checks,
   or update prompts. There are none and there will be none.
4. **Never weaken, skip, `#[ignore]`, or delete a test to make it pass.** If
   you believe a test is wrong, stop and argue the case with evidence. This is
   not the same as marking a coverage cell unsupported with a stated reason,
   which M3 requires: that is a documented gap in the matrix, not a disabled
   test.
5. **Never edit a task's acceptance criteria to match what you built.** If the
   criteria are wrong, stop and say so. Rewriting them is a decision for the
   human, not an implementation detail.
6. **Never modify anything in `tests/fixtures/`.** These are golden data.
7. **Never modify `scripts/` or `src-tauri/binaries/`** without explicit
   approval. The first pins checksums; the second is pinned binaries. Growing
   the gate is not exempt — adding a stage to `scripts/verify.ps1` is a change
   to `scripts/` and needs the same approval as any other edit there.
   Pre-approved by the human, so the tasks that name them do not stop to ask:

   - `scripts/fetch-engines.ps1` — created by T-002.
   - `scripts/check-no-network.ps1` — created by T-032.

   Pre-approval covers creating those two files and nothing else. Every other
   file under `scripts/`, and every later edit to either of these after it
   exists, still needs approval. The list is extended only by a new explicit
   approval, never by implication.
8. **Never use `unwrap()`, `expect()`, or `panic!()` in the job pipeline.**
   Errors are typed and surfaced to the UI.
9. **No new dependency without explicit approval.** State the crate or package,
   the version, its license, and why it is needed. The baseline under "The
   scaffold baseline" below is already approved; anything beyond it is not.
10. **Never commit to `main`,** except the single v1 squash commit T-037 makes
    under the go-ahead in §6. All other task work goes on the development
    branch (§6). Never commit unless told `commit` — harness and documentation
    changes made at the human's direct request are the exception; present the
    diff, then commit. **Never push** — pushing is always the human's. Never
    merge or delete a branch except T-037 and T-038, under the same go-ahead.
    Never amend, rebase, or force-push.
11. **Never work with an unrelated dirty tree**, and never start a task out of
    order — see §1.3.
12. **Never let an answer exist only in conversation.** Record it in the
    repository before implementing — see §1.6.

### The scaffold baseline

Approved by the human on 2026-10-19 (ADR-015) so T-001 can start. It is a
starting point, not a general permission:

- Tauri v2 and its first-party `@tauri-apps/*` packages.
- The Vite + TypeScript frontend toolchain, with one test runner and one
  linter.
- Ordinary Rust crates for errors, serialisation and file plumbing
  (`thiserror`, `serde`, `serde_json` and the like), none of which performs
  network I/O (rule 2).

Anything outside that list is approved the §1.6 way — ask, then record the
answer in `docs/DECISIONS.md` before adding it. The WORKLOG plan still names
every dependency the task intends to add.

## 5. Commit messages

Conventional Commits, always. Every commit, including tiny ones. One commit
per task.

```
<type>(<scope>): <description>

<body>

<footer>
```

**Type** is mandatory and must be exactly one of:

| Type | Use for |
|---|---|
| `feat` | New behaviour a user can observe |
| `fix` | A bug fix |
| `docs` | Documentation, comments, this harness |
| `test` | Tests only |
| `refactor` | No behaviour change |
| `perf` | Performance only |
| `build` | Build system, bundling, engine binaries, installers |
| `ci` | CI configuration |
| `chore` | Everything else — dependencies, ignore files, formatting |

**Scope** is optional but expected. Use the module names from `SPEC.md` §8:
`engine`, `job`, `probe`, `commands`, `ui`, plus `build`, `ci`, `docs`, `deps`.

**Description**: imperative mood, lowercase, no trailing full stop. Write
"add vips wrapper", not "Added vips wrapper" or "adds vips wrapper".

**Task reference**: put the task ID in parentheses at the end of the
description — `feat(engine): add vips wrapper (T-003)`. This is how
`docs/TASKS.md` stays traceable to the code.

**Body**: what changed and why, not how. Wrap at 72 columns. A task commit
touches code and docs together; mention the documentation in the body.

**Breaking changes**: `!` after the type *and* a `BREAKING CHANGE:` footer.
`feat(engine)!: drop 32-bit engine binaries`

Examples:

```
feat(probe): detect format by magic bytes (T-013)
fix(job): kill engine subprocess on cancel (T-009)
test(engine): assert lossless modes are pixel-identical (T-019)
docs(privacy): publish user-verifiable offline checks (T-034)
build(engine): pin libvips and verify SHA-256 (T-002)
chore(deps): bump thiserror to 2.x
```

Banned subjects: `wip`, `fixes`, `update`, `more changes`, `address review
comments`, `misc`, `cleanup`. If a change cannot be described in this format,
it is too vague to review — split it or rethink it.

One concern per commit. If the subject needs the word "and", it is probably
two commits.

## 6. Version control and releases

### `main` is a release ledger

`main` holds **exactly one commit per released version**. It is never developed
on and never contains task commits.

The one exception is bootstrap. `main`'s first commit collapses the pre-v1
setup history into a single root commit, so the ledger starts clean. What it
replaced is not lost: it is preserved by the annotated tag `pre-v1-setup`,
which is not a release tag and is never moved or deleted. A remote is
configured (`origin`); rule 10 still governs pushing, and note that anything
pushed to a public remote has left the machine for good.

**Current development branch:** *to be set by T-000.*

### Development happens on one branch

All work for a version happens on a single long-lived branch. There is only
ever one open at a time.

- The agent chooses the branch name when the branch is created (T-000) and
  records it above, so later sessions do not have to guess it.
- Never commit to `main` directly.
- Never open a second development branch while one is open.
- Never leave a version's branch open after that version has landed.

### One commit per task — on that branch

§1.11 applies unchanged: one commit per task, conventional message, task ID in
parentheses. Those commits are the working record of how the version was built.

Be honest about what this means. Per-task history lives on the development
branch. Once the branch is squash-merged and deleted, it is gone from `main`
and reachable from no ref. Within a version you can still `git log --grep
T-014` and `git bisect` on the branch; across versions you cannot. That trade
was made deliberately — see ADR-009.

### Landing a version

When every task for the version is done and T-036's report is clean:

1. The human writes an explicit go-ahead into the T-037 WORKLOG entry. Without
   it, stop (§1.6).
2. Squash the branch onto `main` as a single commit (T-037).
3. Write the commit message as the release note. Not a placeholder, not a
   summary generated from task titles.
4. Delete the branch (T-038).

`main` then has one more commit than it did, with no merge parents and none of
the branch's history.

Pushing is always the human's. T-031, T-032, T-033, T-037 and T-038 all need a
`git push` somewhere, so their evidence is produced by asking the human to push
and then reading the run or the remote — never by the agent pushing.

### Tags

Releases are annotated tags on `main`, placed at the landing commit:

```
git tag -a v1.0.0 -m "Wringer 1.0.0"
```

- Semver: `vMAJOR.MINOR.PATCH`.
- Annotated, never lightweight — the annotation carries the release note.
- Never move or delete a published tag. If a release is wrong, tag a patch.
- Never tag without being told to.

### Never

Two are absolute: the agent never pushes, and never creates a tag. Three are
the human's to authorise, and the agent performs them only for T-037 and T-038
after the go-ahead above: committing to `main`, merging, and deleting a branch.
Everything else in §1 and §4 still applies.

## 7. Style

- Rust: `thiserror` for error types, `Result<T, AppError>` throughout, no
  global mutable state. Keep the job engine free of Tauri types so it can be
  unit-tested without opening a window.
- TypeScript: strict mode, no `any`, no `@ts-ignore`.
- Comments explain *why*, never *what*.

## 8. Deliberately out of scope

No cloud, no accounts, no video, no audio, no PDF, no office documents, no
OCR, no AI upscaling, no auto-update, no plug-ins. Do not add them. If asked
for them, they are separate projects.
