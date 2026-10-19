# Architecture Decision Records

One entry per decision. Append, never rewrite. If a decision is reversed,
add a new ADR that supersedes the old one and say why.

Format: date · status · decision · context · consequences.

---

## ADR-001 — Tauri v2 rather than Electron

**Status:** accepted · **Date:** 2026-10-17

**Decision:** Build the shell with Tauri v2 (Rust core, system WebView).

**Context:** This is a small utility users download from a landing page.
Benchmarks across 2026 consistently show Tauri installers at roughly 3–15 MB
and 30–80 MB idle RAM, against 80–200 MB and 150–300 MB for equivalent
Electron apps. Tauri's capability model is deny-by-default, which matters
because we make an auditable "no network" claim.

**Consequences:** Learn Rust. WebView2 on Windows is a single engine, so the
usual cross-webview pain does not apply — we are Windows-only. Rust compile
times will dominate CI cold builds; cache the `target` directory.

---

## ADR-002 — libvips as the image engine

**Status:** accepted · **Date:** 2026-10-17

**Decision:** Bundle libvips and drive it as a subprocess. Do not write codecs.

**Context:** Alternatives were ImageMagick and hand-rolled encoding.
ImageMagick's delegate chain is a licensing hazard — it will call out to
Ghostscript, which is AGPL. libvips is LGPL-2.1+, streams rather than loading
whole images into memory, and is substantially faster for batch work. Writing
codecs ourselves is out of the question: it is the single most reliable way
to corrupt users' files.

**Consequences:** LGPL obligations attach to the redistributed binary (see
`LICENSING.md`). Using it as a separate process rather than linked code keeps
our obligations simple. The engine's version and CLI flags are pinned in
`docs/engines/libvips.md`; upgrading it is a task, not an incidental change.

---

## ADR-003 — Engine as a subprocess, not FFI

**Status:** accepted · **Date:** 2026-10-17

**Decision:** Invoke the engine as a child process with an argument vector.

**Context:** FFI to libvips would be faster per call and would avoid process
startup, at the cost of an unsafe boundary we cannot fuzz, a hard-linked LGPL
obligation, and a crash in C code taking down the app. Per-file process
startup is a few milliseconds against image work measured in hundreds.

**Consequences:** Cancellation is a process kill, which is robust. Progress
must be parsed from engine output. Argument construction must never use shell
interpolation — arguments are vectors, always.

---

## ADR-004 — GPL-3.0 licence

**Status:** accepted · **Date:** 2026-10-17

**Decision:** Licence the application GPL-3.0-or-later.

**Context:** A privacy tool makes a claim the user cannot see. Publishing the
source makes that claim checkable, which is the whole point. It also removes
every downstream licensing obstacle: GPL and AGPL engines may be bundled
without negotiation.

**Consequences:** Anyone distributing a modified build must publish source.
If the project ever needs a proprietary edition, engines with copyleft
licences must be re-evaluated first — that is a new ADR and a legal review,
not a rename.

---

## ADR-005 — Windows only for v1

**Status:** accepted · **Date:** 2026-10-17

**Decision:** Ship Windows x86-64 only. No macOS, no Linux, no ARM.

**Context:** Each platform adds an engine build to pin, a packaging path to
maintain, and a signing story to fund. Cross-platform support is the most
common way projects in this category die before reaching quality.

**Consequences:** macOS and Linux are additive later work, not a rewrite —
the Rust core stays portable. WebView2 is the only engine we must test against.

---

## ADR-006 — No auto-update

**Status:** accepted · **Date:** 2026-10-17

**Decision:** The app never contacts a server, including for updates. Users
download new versions manually.

**Context:** An auto-updater is a network client, a remote-code-execution
surface, and a telemetry channel by accident. It contradicts the product.

**Consequences:** Security fixes require users to act. The README must make
that trade explicit and honest rather than pretending it is cost-free.

---

## ADR-007 — Strip metadata by default

**Status:** accepted · **Date:** 2026-10-17

**Decision:** Remove GPS, camera, timestamp, and software metadata by default.
Always preserve the ICC colour profile. Always apply EXIF orientation to
pixels before removing the orientation tag.

**Context:** People compressing photos before sending them are exactly the
people who do not want their home coordinates embedded. Preserving ICC is not
a preference — removing it silently shifts colours.

**Consequences:** Stripping is destructive, so it must be visible: the UI
reports what was removed for each file, and keeping metadata is one click.

---

## ADR-008 — The name is Wringer

**Status:** accepted · **Date:** 2026-10-18

**Decision:** The application is called **Wringer**. Executable `wringer.exe`;
crate, npm package, and Tauri product name all `wringer`.

**Context:** The name had to survive expansion beyond images, so anything
image-specific was disqualified from the start. The best fit is a
*transformation* metaphor — something that takes raw material and puts out a
refined, smaller result — with the privacy angle as flavour rather than the
core. A wringer squeezes things down, and "put it through the wringer" means
thorough processing. It reads as compression specifically, which is half the
product, and "wring a PDF" works as well as "wring a PNG".

Names rejected after searching, with the reason:

| Name | Rejected because |
|---|---|
| Kiln | A direct competitor — `kilnimage.app` — already ships almost exactly our v1 spec, plus multiple live `KILN` trademarks (a Paris fintech, Kiln Holdings, Kiln Enterprises, Microsoft). |
| Coffer | Six or more products, several of them privacy-first local-first apps with near-identical positioning. |
| Hearth | `hearth-software.com` markets itself as "private, local-first Windows apps" — our positioning verbatim — plus three other products. |
| Anneal | Seven products, including two AI startups. |
| Sluice | Four products, two of them competing workflow apps. |
| Loom, Vault, Ember, Flint, Larder, Slate, Quill, Faraday | All in active use. Faraday in particular is a Ruby HTTP client, which is an unfortunate clash for a no-network application. |

**Consequences:** The rename was free at this point — no code existed. It would
have been painful after the first release, which is why it was settled before
T-001.

**Outstanding:** Formal clearance has *not* been done. Before the first public
release, check USPTO TESS and EUIPO in Nice class 9 (software) and class 42;
check `crates.io`, npm, and PyPI for the package name; check `.com` and `.app`
domains; and check for a `winget` package ID collision. See ADR-004 for why
this matters less than it otherwise would — GPL-3.0 avoids most bundled-engine
licensing risk, but not trademark risk.

---

## ADR-009 — Develop on a branch; land one commit per version on main

**Status:** accepted · **Date:** 2026-10-18
**Supersedes:** the trunk-based policy previously stated in `AGENTS.md` §6.

**Decision:** `main` is a release ledger holding **exactly one commit per
released version**. All development for a version happens on a single
long-lived branch. When the version is complete, the branch is squash-merged
onto `main` as one commit and then deleted.

**Context:** The alternative, and the initial policy, was trunk-based: every
task lands on `main` as its own commit, giving per-task granularity —
`git log --grep T-014` to see what a task did, `git bisect` to find which task
introduced a bug, and reverting one task without reverting a release.

The trade is real, and it should be understood rather than glossed. Squashing
means the per-task history is not in `main`, and once the development branch is
deleted it is not reachable from any ref. Within a version, grep and bisect
still work on the branch. Across versions, they do not.

What the branch buys: `main` reads as a list of releases and nothing else, and
a public repository is legible to someone who only wants to see what shipped.

**Consequences:** The task-ID convention in commit messages (`AGENTS.md` §5)
now serves the development branch rather than `main`. `AGENTS.md` §6 carries
the current branch name so sessions do not have to guess it. Per-task history
is recoverable only while the branch exists, or from a remote that has it.

**If this is reversed later:** landing each task directly on `main` is a
two-line change to §6, and granularity returns for future versions. Versions
already squashed stay squashed.

---

## ADR-010 — Golden fixtures are committed test data, frozen on arrival

**Status:** accepted · **Date:** 2026-10-19

**Decision:** The test corpus lives in `tests/fixtures/`, is committed as
binary data, and is never edited once committed. Each fixture's provenance and
SHA-256 is recorded in `tests/fixtures/README.md`. A fixture that turns out to
be wrong is replaced by a new file, never edited in place.

**Context:** Four tasks assert against fixtures that had no owner: the original
task list assumed a corpus without giving any task responsibility for creating
one, so T-005 would have been the first task to dead-end. The alternatives were
to generate the fixtures at test time, fetch them, or commit them. Generating
at test time makes the corpus mutable, and a test that builds its own input
cannot detect that the input changed — the assertion becomes circular. Fetching
contradicts the no-network rule outright.

**Consequences:** The repository carries a small amount of binary data, bounded
at 2 MB by T-004. Because the files are frozen, a rule-6 violation shows up as a
diff rather than as a silently different test baseline. Fixture generation, if
scripted, lives under `tests/fixtures/` rather than `scripts/`, which rule 7
gates behind explicit approval.

**Supersedes nothing.** This fills a gap in the original task list rather than
reversing a decision. Task IDs were renumbered at the same time to make room for
T-004; that is recorded in `docs/TASKS.md`.

---

## ADR-011 — Each gate stage is judged on its own result

**Status:** accepted · **Date:** 2026-10-19

**Decision:** `scripts/verify.ps1` clears `$LASTEXITCODE` before running a
stage, captures `$?` immediately after it, and reports FAIL if the last command
failed *or* a non-zero exit code survived. A stage action must therefore own its
result: it runs a native command, or it ends with `exit <code>`.

**Context:** The gate previously passed or failed a stage on `$LASTEXITCODE`
alone. A native command that is missing from `PATH` fails as a *non-terminating*
error in PowerShell: it sets `$?` to `$false` but leaves `$LASTEXITCODE`
untouched. A stage whose tool was absent would therefore inherit the previous
stage's `0` and report a **false PASS** — the one failure a definition of done
cannot have. The same hazard applies to any stage action that is a PowerShell
script which returns or throws instead of exiting, which is exactly the shape of
the `check-no-network.ps1` stage T-032 adds.

**Consequences:** The gate can now be trusted to fail. It also imposes a
contract on every future stage script: a script that only writes output and
returns is an error, not a pass. `scripts/` remains approval-gated (rule 7); the
two scripts already named by tasks were pre-approved in writing at the same
time, so T-002 and T-032 do not stall on that rule.

---

## ADR-012 — The format matrix and the performance budget are owned by tasks

**Status:** accepted · **Date:** 2026-10-19

**Decision:** Every cell of `SPEC.md` §4 × §5, and every target in §10, is owned
by a task. The gaps were filled by `T-013a` (legacy and non-raster input),
`T-016a` (TIFF read and write), `T-017a` (the mode × format matrix) and `T-019a`
(the performance budget), with `T-027a` covering the UI affordances they imply.
T-004 gains the fixtures those tasks assert against.

**Context:** §13.1 requires every mode for every output format, and T-036 must
account for every cell. TIFF output, BMP/GIF/ICO/SVG input, the mode pairs
T-014–T-016 never reached, and all of §10 had no owning task, so T-036 could not
have passed against the plan as written.

**Consequences:** Tasks added later carry a letter suffix rather than renumbering
the list: `T-013a` runs after `T-013` and before `T-014`, so no existing ID
changes. The extra fixtures must be committed by T-004, because rule 6 and
ADR-010 freeze `tests/fixtures/` the moment T-004 lands.

---

## ADR-013 — AVIF and HEIC stay required, and T-002 proves the engine can do them

**Status:** accepted · **Date:** 2026-10-19

**Decision:** `SPEC.md` §4 keeps AVIF as full support and §13.1 keeps demanding
every output format. T-002 gains a fifth verification question: can the pinned
build encode AVIF (libheif + AV1) and read HEIC? A build that cannot is a
stop-and-ask before M3, not a quietly shortened format list.

**Context:** T-016 allowed a capability-less build to omit AVIF from the UI,
while §13.1 made it mandatory — and nothing checked the engine's AV1 support
before M3 depended on the answer.

**Consequences:** The archive chosen in T-002 must carry AVIF support, or the
human amends §4 and §13.1 deliberately. The same check covers HEIC, which §4
already marks conditional.

---

## ADR-014 — The agent never pushes; the release git operations need a recorded go-ahead

**Status:** accepted · **Date:** 2026-10-19

**Decision:** Pushing is the human's, always. The agent commits to `main`,
merges, and deletes a branch only for T-037 and T-038, and only after the
human's explicit go-ahead is written into that task's WORKLOG entry. Tags are
the human's.

**Context:** Rule 10 forbade pushing, merging and deleting a branch outright,
while T-031, T-032, T-033, T-037 and T-038 all required precisely those. A
literal agent would have refused the release path or breached the rulebook.

**Consequences:** CI acceptance criteria are met by the human pushing and the
agent reporting the run. T-032's scratch branch is permitted and is the human's
to delete. Rule 10, §1.11 and §6 now say the same thing.

---

## ADR-015 — A pre-approved dependency baseline for the scaffold

**Status:** accepted · **Date:** 2026-10-19

**Decision:** The Tauri v2 scaffold's dependency set is approved in advance:
Tauri v2 and first-party `@tauri-apps/*`; the Vite + TypeScript frontend
toolchain with one test runner and one linter; ordinary Rust crates for errors,
serialisation and file plumbing, none performing network I/O. Anything beyond
that is approved the §1.6 way and recorded here.

**Context:** Rule 9 required explicit approval per dependency with no channel to
give it, which blocked T-001 — the first code task — on a bulk decision it could
not obtain.

**Consequences:** `AGENTS.md` §4 carries the operational list. A dependency
outside the baseline still needs an approval recorded in this file.
