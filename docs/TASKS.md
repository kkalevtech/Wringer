# Wringer — Tasks

## How tasks are consumed

- **Sequential.** Work in ID order. `start T-006` while T-005 is not `done`
  must be refused, naming the blocking task. See `AGENTS.md` §1.3.
- **One per session.** Opened with `start <T-###>`, closed with `commit`.
- **Observable acceptance only.** Every criterion must be something you can
  check and show. If you cannot describe how you would verify it, the task is
  not ready — rewrite it before starting.
- **Never edit a criterion to match what was built.** If it is wrong, stop and
  say so. Changing it is a decision, not an implementation detail.
- **The plan goes in `docs/WORKLOG.md` before implementation.** §1.5.
- **Mark `done` only at `commit`.** There is no `doing` status; an open
  WORKLOG entry means a task is in progress.
- **IDs are bookkeeping, and frozen once used.** The list was renumbered once,
  before any task work began, to make room for T-004. That was safe because
  nothing outside `docs/` binds to an ID yet. It is not safe again: once the
  first task commits, its ID is in the commit message and the WORKLOG. The
  pre-renumber list is preserved in the tag `pre-v1-setup`.
- **Work added later gets a letter suffix** — `T-013a` runs after `T-013` and
  before `T-014`. Existing IDs never change, so inserting work into a milestone
  renumbers nothing. The tasks ADR-012 added use this.

Status values: `todo` · `blocked` · `done`

---

## M0 — Repository setup

### T-000 — Create the v1 development branch · todo

Before any code. `main` is a release ledger and is never developed on — see
`AGENTS.md` §6.

- Choose the development branch name. It is your call.
- Create it from the current `main` and switch to it.
- Record the name in `AGENTS.md` §6, so later sessions do not have to guess it.

Nothing else. No code, no configuration.

**Acceptance:** `git branch --show-current` reports the chosen name and not
`main`. `main` is unchanged. The name appears in `AGENTS.md` §6.

---

## M1 — Plumbing

### T-001 — Scaffold the Tauri app · todo
Create the Tauri v2 project targeting Windows x86-64, with the `src-tauri`
layout from `docs/SPEC.md` §8. No features.

**Acceptance:** `npm run tauri dev` opens a window. `cargo tree` contains no
network-capable crate. `.\scripts\verify.ps1` exits 0 and reports PASS for
every stage whose prerequisites now exist. Introducing a deliberate `clippy`
warning makes it exit 1 and names the failing stage; removing the warning makes
it pass again. (The gate is only trustworthy once it has been seen to fail.)

---

### T-002 — Fetch, verify, and pin the engine · todo

Two jobs, one owner: get the binary, then establish what it actually does.
M2 is built on the second job being done, so it is not optional.

**Fetch.** `scripts/fetch-engines.ps1` downloads the pinned libvips Windows
build, verifies a hardcoded SHA-256, and extracts it to `src-tauri/binaries/`.
Idempotent: a second run is a no-op if the hash already matches.

**Verify the flags.** Run the pinned binary and resolve every `UNVERIFIED`
entry in `docs/engines/libvips.md`, replacing each with the version it was
checked on and the observed output. The four that downstream tasks inherit, in
order of blast radius:

1. Whether `vips copy` re-encodes or passes through when the format is
   unchanged — if it passes through, `Optimize` silently does nothing and
   **T-006 is wrong, not merely slow**.
2. Whether `--vips-progress` output is line-buffered when stderr is a pipe —
   if it is not, **T-008 is unbuildable as specified**.
3. Whether metadata can be stripped selectively (keep ICC, drop GPS) — the
   metadata model in `SPEC.md` §7 depends on the answer.
4. A pixel-comparison path that exists in this build for the lossless tests
   (`vips ssim`, or subtract-and-check-max — see the candidate list in
   `docs/engines/libvips.md`). Rule 1 permits a decode-only helper used only by
   tests if the engine offers neither; anything that ships goes through the
   engine.
5. Whether the build can encode **AVIF** (libheif + AV1) and read **HEIC**.
   `SPEC.md` §4 marks AVIF full and §13.1 requires every output format, so a
   build without AV1 is a stop-and-ask before M3 (ADR-013), not a quiet
   reduction of the format list.

If an answer contradicts `SPEC.md`, a task, or an ADR, **stop and ask** (§1.6).
A wrong engine assumption is a decision, not an implementation detail. Record
the answer in the spec or a new ADR before continuing, then resume.

**Acceptance:** Running with the correct hash exits 0 and populates the
directory. Running with a deliberately wrong hash exits non-zero and writes
nothing. Neither run leaves a temp file behind. `docs/engines/libvips.md`
contains no `UNVERIFIED` entry, and every claim it does make names the version
it was observed on. Each of the five questions above has a one-line answer
recorded there.

---

### T-003 — Engine subprocess wrapper · todo
`engine::run()` invokes the engine with arguments, captures stdout/stderr,
enforces a timeout, and returns a typed result. No shell string
interpolation anywhere — arguments are passed as a vector.

**Acceptance:** Unit test with a fake binary that exits non-zero returns
`EngineFailed` with the stderr tail. A path containing spaces and an emoji
works. An argument containing a quote character is passed through verbatim.

---

### T-004 — Golden fixtures · todo

The test corpus everything downstream asserts against. T-005, T-006, T-018 and
T-020 all read it, and **Rule 6 freezes it**: once committed, these files are
golden data and are never edited. A fixture that needs to change is a new
fixture, not an edit to this one.

Commit `tests/fixtures/` containing, at minimum:

- `probe/` — one clean sample each of PNG, JPEG, WebP and TIFF, for T-005.
- `probe/` also needs one sample each of BMP, GIF (more than one frame) and ICO
  (more than one size), for T-013a.
- `vector.svg` — a small valid SVG, for T-013a's rejection path.
- `fixture-large.png` — large enough that optimising it is meaningfully
  smaller, for T-006.
- `exif/gps.jpg` — a real GPS EXIF record, with an orientation tag.
- `exif/orientation-6.jpg` and `exif/orientation-6-upright.jpg` — a rotated
  file and its already-upright twin, which must come out visually identical.
  T-018 asserts this pair.
- `not-an-image.txt` — plain text, for the `UnsupportedFormat` path.

Also:

- `tests/fixtures/README.md` recording, per file: where it came from or how it
  was produced, and its SHA-256.
- Keep the whole directory under 2 MB.
- No generator script in `scripts/` — Rule 7. If generation is scripted at all,
  the script lives under `tests/fixtures/` and is part of the corpus.

**Acceptance:** `tests/fixtures/` contains every file listed above and each is
tracked by Git (`git ls-files tests/fixtures`). Every SHA-256 in
`tests/fixtures/README.md` reproduces when recomputed. The directory totals
under 2 MB. `git status` shows nothing changed under `scripts/`.

---

### T-005 — Probe an image · todo
`probe::inspect(path) -> ImageInfo` where `ImageInfo` carries format, width,
height, bands, alpha, ICC presence, EXIF presence, and input size.

**Acceptance:** Unit tests against the four fixtures in `tests/fixtures/probe/`
(T-004) return exact expected values. A text file returns `UnsupportedFormat`,
not a panic.

---

### T-006 — Compress one PNG, losslessly · todo
`engine::png_optimize(input, output)`. Hardcoded path; the real pipeline comes
in T-010.

**Acceptance:** Output is smaller than input for `fixture-large.png` (T-004).
Pixel data is byte-identical to the input. Test compares pixels, not file
hashes.

---

## M2 — Job engine

### T-007 — Job model and queue · todo
Typed `Job` and a queue with the state machine from the spec. No UI.

**Acceptance:** Unit tests drive a job through every legal transition. Illegal
transitions return a typed error rather than being silently ignored.

---

### T-008 — Progress reporting · todo
Parse progress from the engine's own output. No timers, no estimates.

**Acceptance:** A test asserts that reported progress is monotonically
non-decreasing and reaches 100 only after the engine process has exited.

---

### T-009 — Cancellation · todo
Cancel kills the child process and cleans up.

**Acceptance:** Cancelling mid-job leaves no output file and no `.part` file.
The process table contains no orphaned engine process after the test.

---

### T-010 — Output paths and atomic writes · todo
Naming rules, collision suffixing, temp file plus rename, cleanup on failure.

**Acceptance:** Converting `a.png` when `a.optimized.png` exists produces
`a.optimized-2.png`. The source file is never opened for writing — assert
this by setting the source read-only and confirming the job still succeeds.

---

### T-011 — Error taxonomy · todo
`AppError` per spec §11, each variant with a UI message and a test.

**Acceptance:** Every variant is reachable by at least one test. No
`AppError::Other(String)` catch-all.

---

### T-012 — Tauri command boundary · todo
Commands `inspect_files`, `enqueue_jobs`, `cancel_job`, `cancel_all`, and
events for progress and completion. Thin glue only.

**Acceptance:** Commands contain no business logic — every one is a
deserialise, delegate, serialise. Reviewer can verify by reading.

---

## M3 — Formats and modes

### T-013 — Magic-byte detection · todo
Replace extension-based dispatch. Extensions become hints for the UI only.

**Acceptance:** `photo.jpg` containing PNG data is detected as PNG. `.txt`
containing JPEG data is detected as JPEG.

---

### T-013a — Legacy and non-raster input handling · todo

The rest of `SPEC.md` §4. BMP, GIF, ICO and SVG were in the format matrix with
no task behind them (ADR-012). Deciding this before the UI is written is the
point — each of these carries a behaviour the user must be told about.

- **BMP** reads as ordinary raster input.
- **GIF** is first frame only. Its frame count must reach the UI, never a silent
  drop (`SPEC.md` §4, §7).
- **ICO** is read-only and multi-resolution. Enumerate its sizes so T-027a can
  offer a choice; never pick one silently.
- **SVG** returns `UnsupportedFormat` with a message naming the format
  (`SPEC.md` §9, §11).
- **HEIC** is offered only when the engine reports libheif support, through the
  same capability path T-016 uses for AVIF.

**Acceptance:** the BMP, GIF, ICO and SVG fixtures from T-004 return the exact
expected `ImageInfo` or typed error. A multi-frame GIF reports its frame count.
A multi-size ICO reports every embedded size. SVG returns `UnsupportedFormat`
with a message naming SVG. HEIC appears only when the engine supports it, and
its absence is recorded in `docs/engines/libvips.md`.

---

### T-014 — JPEG: optimize and quality modes · todo
**Acceptance:** Optimize mode is pixel-identical. Quality mode honours Q.
Progressive and chroma-subsampling options are exposed.

---

### T-015 — WebP: lossless and lossy · todo
**Acceptance:** Lossless output is pixel-identical to the input. Lossy honours Q.

---

### T-016 — AVIF · todo
Capability-detect at startup. `SPEC.md` §4 requires AVIF, so a build without
AV1 support is a stop-and-ask (ADR-013) rather than a quietly reduced format
list — but the capability check still stops the app offering a format that
would fail at run time.

**Acceptance:** AVIF is offered only when the engine reports AV1 support. When
the engine lacks it, the task stops and says so; it does not ship a reduced
format list.

---

### T-016a — TIFF read and write · todo

TIFF is a full input and a listed output in `SPEC.md` §4, and §13.1 requires
every mode for every output format. No task owned it (ADR-012).

- Read single- and multi-page.
- Write single page only.
- Lossless per §5; the saver's other options are confirmed in T-002 and
  recorded in `docs/engines/libvips.md`.
- Metadata policy from §7 applies exactly as for every other format.

**Acceptance:** a TIFF fixture probes correctly. A lossless TIFF output is
pixel-identical to its input, proven the way T-019 proves losslessness. A
multi-page TIFF reads; asking for more than one output page returns a typed
error rather than truncating silently.

---

### T-017 — Target size mode · todo
Binary search on quality, bounded to 8 engine invocations, reporting the Q used.

**Acceptance:** A 2 MB JPEG with a 400 KB cap yields an output of at most
400 KB. An impossible cap (1 KB) returns `TargetUnreachable` and writes no file.

---

### T-017a — Mode × format coverage matrix · todo

`SPEC.md` §13.1 requires every mode in §5 for every output format in §4.
T-014, T-015, T-016 and T-016a cover formats one at a time; this proves the
product of them, so nothing falls between tasks (ADR-012).

- Enumerate the (input × output × mode) table from §4 and §5, cell by cell.
- Fill the gaps the enumeration exposes. `Optimize` for WebP and AVIF, and
  `Lossless` for AVIF, are the pairs the per-format tasks do not already state.
- Every cell is either covered by a named test, or marked unsupported with the
  reason recorded in `SPEC.md` or `docs/engines/libvips.md`.

**Acceptance:** a test enumerates every cell and names what demonstrates it, or
the cell is on a documented unsupported list. No cell is unaccounted for. This
is the check T-036 makes on the finished product, run early enough to be cheap.

---

### T-018 — Metadata policy and orientation · todo
Strip per spec §7. Apply orientation to pixels before stripping the tag.

**Acceptance:** `exif/gps.jpg` (T-004) converts to an image with no GPS data,
correct on-screen orientation, and an intact ICC profile. The orientation-6
pair from T-004 comes out visually identical on both sides.

---

### T-019 — Invariant test suite · todo
One test per invariant in spec §6.

**Acceptance:** Each test has been observed failing against a deliberately
broken implementation before being made to pass. Record that in the commit
message.

---

### T-019a — Performance budget · todo

`SPEC.md` §10 sets targets nothing measured (ADR-012). The engine's internal
thread count interacts with the job cap, so the policy is decided here rather
than inherited from the engine's defaults (see `docs/engines/libvips.md`).

- 20 × 12 MP JPEGs in quality mode, warm start, under 30 seconds.
- Peak memory under 1 GB regardless of input size.
- Concurrency defaulting to `min(4, logical_cores)`, user-adjustable 1–16.
- The `VIPS_CONCURRENCY` policy, written down in `docs/engines/libvips.md`.

**Acceptance:** timing is asserted by a test; peak memory is measured on a
recorded run with the machine's spec beside the number. Inputs larger than the
T-004 corpus are generated by the run and cleaned up. Exceeding a target is a
finding, not a footnote.

---

### T-020 — Hostile input tests · todo
0-byte file, 1-pixel image, 300 MP image, Unicode/emoji filename, path at
260 characters, read-only source, wrong extension, truncated JPEG, CMYK JPEG,
a file that is a directory, a symlink loop.

**Acceptance:** No panic, no hang, and a specific error for each. Inputs not
already in the T-004 corpus are created by the test itself and cleaned up.

---

## M4 — Design

Decide what the app looks like before any of it is written. Design is reviewed
here, at a gate, rather than discovered at the interface milestone.
`AGENTS.md` §1.10 applies: changes asked for at these gates are the revise
loop, not new tasks.

### T-021 — Design directions · todo
Three genuinely different directions for the main surface, as static HTML with
fake data. Not three variations of one idea — three answers to the question of
what this app is.

- `design/index.html` shows all three side by side. That one file is all the
  human needs to open.
- Real CSS. No framework, no build step, no application code, no Rust.
- The fake data covers every state: empty, queued, running, done, failed.
- The metadata-removal report (spec §7) is a first-class element of every
  direction. It is the clearest thing this product claims.

**Acceptance:** The human opens one file and can compare all three directions
with no further instruction. The directions differ in at least layout, density
and type — not merely in colour. No application code is written.

---

### T-022 — Design system · todo
The human chooses a direction, or a combination of them. Record the choice, so
the interface milestone implements a written specification rather than a
recollection of a conversation.

- Refine the chosen direction until the human would ship it.
- Show every state, including a per-file error from spec §11.
- Extract the tokens — colour, spacing, type scale, radii, motion — into
  `docs/DESIGN.md`.
- Decide the frontend framework, as an ADR. Its weight and dependency tree bear
  directly on the installer size that T-028 must justify.

**Acceptance:** `docs/DESIGN.md` exists and names every value the design uses;
the design holds no literal colour outside the token block. An ADR records the
framework and its consequences. The design shows all five states.

---

### T-023 — Screenshot tooling · todo
Give the agent eyes. It writes CSS without ever seeing the result, which is the
single largest limit on how good the interface can get.

- A script renders a page at 1280×800 and 1920×1080 and writes PNGs.
- **Requires explicit human approval before starting** — rule 7 covers
  `scripts/`.

**Acceptance:** Running the script against the T-022 design writes both PNGs.
The agent then uses them to find and fix at least one real defect it could not
have seen otherwise, and records the before and after in the WORKLOG entry.

---

## M5 — Interface

### T-024 — Queue UI · todo
**Acceptance:** Dragging a folder with 20 images populates the queue with 20
rows. The UI still responds to clicks while a batch runs.

---

### T-025 — Per-file and apply-to-all settings · todo
**Acceptance:** Changing the quality on one row does not affect others;
"apply to all" does.

---

### T-026 — Presets · todo
The six presets from spec §12, persisted to `%APPDATA%`.

**Acceptance:** A preset survives an app restart. A corrupt config file falls
back to defaults instead of crashing.

---

### T-027 — Results view · todo
Per-file output path, size delta in bytes and percent, metadata-removal
report, open-containing-folder action.

**Acceptance:** The reported byte delta matches the file on disk exactly.

---

### T-027a — Odd-format affordances · todo

What T-013a detects has to be visible, or it is a silent surprise
(`SPEC.md` §4, §7, §9).

- A GIF with more than one frame warns that only the first is converted.
- An ICO offers its embedded sizes and the user picks one.
- An unsupported format shows the specific message — "unsupported format:
  SVG" — not a generic failure.

**Acceptance:** all three are visible in the running app and confirmed by a
recorded run or a UI test. None of them happens silently.

---

## M6 — Packaging

### T-028 — Installer and bundling · todo
**Acceptance:** A clean Windows VM with no dev tools installs and runs a
conversion. Installer size is recorded in `DECISIONS.md` with a justification.

---

### T-029 — THIRD-PARTY-NOTICES · todo
**Acceptance:** Generated by the build, lists every dependency and bundled
binary with its license, and is included in the installer.

---

### T-030 — Code signing · todo
**Acceptance:** The installer is signed and the signature validates. README
explains SmartScreen reputation to the user honestly.

---

## M7 — Privacy verification

### T-031 — CI skeleton · todo

`docs/PLAN.md` M7, `docs/PRIVACY.md` and T-032 all assume a pipeline that runs
on every push. It does not exist. This task creates the pipeline and nothing
else; what the pipeline checks is added by the tasks that follow, each as its
own stage.

- A CI configuration that runs on push and pull request on `windows-latest`,
  checks out the repository, installs the gate's prerequisites (`npm ci`, then
  `.\scripts\fetch-engines.ps1`), and runs `.\scripts\verify.ps1`. The gate
  does not fetch the engine itself (see `AGENTS.md` §1.8) and
  `src-tauri/binaries/` is not in Git, so a job that skips this step fails for
  the wrong reason.
- A non-zero gate exit fails the build.
- No secrets, no deployment step, and no network calls beyond the runner
  installing its own toolchain.
- Pushing is the human's (§6). The agent writes the configuration; the human
  pushes the development branch; the agent reads the run and records it.
- Record in `docs/DECISIONS.md` why CI runs the same gate the developer runs,
  and what it deliberately does not do.

**Acceptance:** A push by the human to the development branch shows the
pipeline running `verify.ps1`. A commit that deliberately fails the gate — a temporary `clippy`
warning — turns the build red, and reverting it turns the build green. The
configuration references no `secrets.*`.

---

### T-032 — No-network CI guard · todo

`scripts/check-no-network.ps1` is pre-approved (rule 7), and `verify.ps1`
already has a stage waiting for it. Per ADR-011 the script must own its result:
a script that only writes output and returns is a FAIL, so it ends with
`exit <code>`.

The `reqwest` test runs on a scratch branch. A scratch branch for this test is
permitted and is not a second development branch (§6); pushing it, and deleting
it afterwards, is the human's.

**Acceptance:** Adding `reqwest` to `Cargo.toml` on a scratch branch makes CI
fail with a clear message naming the offending dependency, and the run is the
human's push to read.

---

### T-033 — Offline integration test · todo
Run a full conversion with outbound traffic blocked.

If the block needs administrator rights or runner configuration the agent
cannot reach, the human runs it and the agent records the result as evidence
(§6 governs pushes).

**Acceptance:** The test passes with the network blocked and fails for a
deliberately network-calling build, proving the test actually detects traffic.

---

### T-034 — PRIVACY.md · todo
**Acceptance:** A person who has never seen the project can follow the
document and independently confirm offline operation using tools we do not
control.

---

### T-035 — CHANGELOG and release metadata · todo

`SECURITY.md` promises security fixes are "published clearly in the changelog",
and `docs/PLAN.md` M7 lists a changelog and an SBOM among the release
deliverables. No task owns either. This one does.

- `CHANGELOG.md` in Keep a Changelog form, newest first, with an `## Unreleased`
  section.
- The `v1.0.0` entry written by hand from what actually shipped — not generated
  from task titles.
- An SBOM covering Rust crates, npm packages and bundled binaries, generated by
  the build rather than maintained by hand.
- Reference both from the release checklist in `docs/LICENSING.md`.

**Acceptance:** `CHANGELOG.md` exists with a valid Keep a Changelog structure
and a complete `v1.0.0` entry. The entry describes shipped behaviour, not a
list of task IDs. Generating the SBOM twice from the same commit produces the
same file. `docs/LICENSING.md`'s checklist names both artefacts.

---

### T-036 — Verify v1 against the specification · todo

The last task before v1 ships. Its job is to **falsify**, not to confirm: to
find every reason v1 is not done. A report that finds nothing is only credible
if it says how hard it looked.

Deliverable: `docs/V1-VERIFICATION.md`, written against a fixed commit, with
evidence for every claim. The release tag does not exist yet — T-037 creates it
— so an interim tag such as `v1.0.0-rc1` is recorded instead if the human makes
one.

Notes:

- Findings that need code changes become new tasks. Fix them, then re-run this
  task — §1.3 permits re-opening T-036 after those tasks are done, even though
  they are numbered later. v1 does not ship on a partial report.
- Criteria 4 and 5 are executed by the **human**, not the agent. The agent
  wrote the code and cannot audit its own work on the user's behalf.

**Acceptance:**

1. Every condition in `docs/SPEC.md` §13 is a row in the report, with pass/fail
   and the command and observed output that demonstrates it — or an explicit
   exception with a stated reason.
2. The input × output × mode matrix from `SPEC.md` §4 and §5 is enumerated cell
   by cell. Every cell is either covered by a named test or marked unsupported
   with a reason. No cell is unaccounted for.
3. Every invariant in `SPEC.md` §6 is demonstrated by a named test, and for
   each one the report shows the test was observed **failing** against a
   deliberately broken implementation before being made to pass.
4. On a clean Windows VM with no Rust, no Node, and no dev tools: the released
   installer installs, and every preset in `SPEC.md` §12 runs successfully on a
   real folder of images. Executed by the human, recorded with the VM's Windows
   build number.
5. The no-network claim is confirmed **on that VM with its network adapter
   disabled** — not on a development machine.
6. The report records the commit hash it was run against, and, if the human
   made one, the interim tag. If any commit lands afterwards, the affected rows
   are re-run.
7. The report states plainly which checks the agent ran, which the human ran,
   and which were not run at all.

---

### T-037 — Land v1 on main as a single commit · todo

Runs once T-036's report is clean. `main` receives exactly one commit for v1.

- Do not start until the human has written an explicit go-ahead into this
  task's WORKLOG entry (§6). Pushing is still the human's.
- Squash the development branch onto `main`. The result must be a single
  commit with no merge parents and no branch history.
- Write the commit message as v1's release note. Not a placeholder, not a
  generated summary of task titles — an actual description of what v1 is.
- `main` must stand on its own: nothing in it may *depend* on a file or ref that
  exists only on the development branch. The branch-name line in `AGENTS.md` §6
  is expected to name a branch that no longer exists, and the next version's
  T-000 resets it — that is not a dependency.

**Acceptance:** `git log --oneline main` shows exactly one commit more than it
did before this task. `git log main --merges` is empty. `git diff main
<branch>` is empty — the tree matches the branch tip exactly. A fresh clone of
`main`, with the prerequisites in `README.md` met (`npm install`,
`fetch-engines.ps1`), passes `.\scripts\verify.ps1`.

---

### T-038 — Delete the development branch · todo

Runs after T-037 is verified.

- Delete the local development branch, under the go-ahead recorded for T-037
  (§6).
- Confirm `main` still passes `.\scripts\verify.ps1` (prerequisites per
  `README.md`).
- Pushing `main` is the human's — always, not only when a remote already
  exists (rule 10).

**Acceptance:** `git branch` no longer lists the development branch. `main` is
byte-identical to its state at the end of T-037 and still passes the gate. The
next version starts a fresh branch via a task equivalent to T-000.
