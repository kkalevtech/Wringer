# Wringer — Plan

One milestone at a time. A milestone is done only when its exit criteria are
observably true. Do not start the next milestone early.

---

## M0 — Decisions and harness

Write the docs, pick the engine, resolve licensing. No application code.

**Exit criteria**

- `docs/SPEC.md`, `DECISIONS.md`, `LICENSING.md`, `PRIVACY.md` exist and agree.
- `AGENTS.md` exists and lists real, runnable commands.
- Engine chosen, pinned version noted, license checked.
- Git repository initialised, first commit made.
- The v1 development branch exists and its name is recorded in `AGENTS.md` §6
  (T-000).

---

## M1 — Prove the plumbing

The riskiest part of this app is not image processing. It is the boundary
between the UI, the Rust core, and a bundled external binary. Prove that
works before building anything on top of it.

**Deliverables**

- Tauri v2 app scaffolded, window opens, frontend and Rust talk to each other.
- `vips` binary fetched and verified by a script, bundled as a sidecar.
- Rust can probe a file: call the engine, parse its output, return typed data.
- Rust can run one hardcoded compression job end to end.
- `tests/fixtures/` committed as golden data, with provenance and hashes
  recorded (T-004).
- Tests: probe and one compression path, headless, against those fixtures.

**Exit criteria**

- `npm run tauri dev` opens a window and can compress a selected PNG.
- Compressing a PNG produces a smaller, pixel-identical file.
- The engine path is resolved at runtime, not hardcoded to a dev machine path.
- No network crates in `cargo tree`.
- The fixture corpus exists, is tracked by Git, and is frozen (T-004).

**Explicitly not in this milestone:** batch, queue, progress, cancel, UI polish,
any format other than PNG.

---

## M2 — The job engine

This is where the app's quality is decided. Get the state machine right.

**Deliverables**

- Typed `Job` and a queue with a real state machine: `Queued → Running →
  {Done, Failed, Cancelled}`.
- Real progress parsed from the engine, not a timer.
- Cancellation that kills the child process promptly.
- Concurrency cap, per §10 of the spec.
- Output path rules, temp-file-and-rename, cleanup on failure.
- Full error taxonomy from §11, with a message per variant.

**Exit criteria**

- Cancelling a job leaves no partial file in the output directory.
- Killing the app mid-job leaves no partial file and no zombie process.
- 50 queued jobs complete without deadlock, and peak memory stays under 1 GB.
- Every error variant has a unit test that produces it.

---

## M3 — Formats and modes

Fill in the matrix. This is mostly mechanical if the engine wrapper is clean.

**Deliverables**

- Magic-byte format detection with a typed rejection path.
- All input and output formats from §4 the engine supports, capability-detected
  at startup.
- `Optimize`, `Lossless`, `Quality`, `Target size` for every applicable pair.
- Metadata policy from §7, including orientation handling.
- Invariant tests from §6, each one written so that it fails if the invariant
  is violated.

**Exit criteria**

- The (input × output × mode) table is covered by tests, or explicitly skipped
  with a documented reason.
- Every §6 invariant has a test that has been *observed failing* at least once
  before being made to pass.
- GIF first-frame-only and ICO size selection warn the user.

---

## M4 — Design

Decide what the app looks like before writing any of it. Designs are static
HTML, so this milestone needs no toolchain and can run at any point once M3 is
settled.

**Deliverables**

- Three distinct design directions, viewable side by side in a browser.
- A chosen direction refined across all states: empty, queued, running, done,
  failed.
- `docs/DESIGN.md`: tokens, layout, states, motion, and explicit non-goals.
- The frontend framework decided as an ADR.
- A screenshot script, so the agent can see its own output.

**Exit criteria**

- The human has reviewed rendered designs and said so, and the chosen direction
  is recorded in writing.
- `docs/DESIGN.md` names every value the design uses.
- No application code exists yet.

---

## M5 — Interface

Now make it pleasant. Not before — a beautiful UI over a broken engine is a
worse product than an ugly one that works.

**Deliverables**

- Drag and drop, file picker, folder recursion.
- Queue view with per-file settings and apply-to-all.
- Presets from §12.
- Per-file results, including which metadata was removed.
- Keyboard accessibility, and no blocking the UI thread.
- Implements `docs/DESIGN.md`. A deviation from it is a decision, not a drift.

**Exit criteria**

- A non-technical user can compress a folder of photos without instructions.
- The UI stays responsive during a 50-file batch.

---

## M6 — Packaging

**Deliverables**

- The engine fetched by `scripts/fetch-engines.ps1` in M1 (T-002) is bundled
  inside the installer; there is no separate install step for the user.
- NSIS installer and/or MSI, built by CI.
- `THIRD-PARTY-NOTICES` generated from the actual dependency set (T-029).
- Code signing, and a note in the README about SmartScreen reputation (T-030).

**Exit criteria**

- A clean Windows VM with no dev tools installs the app and compresses an image
  (T-028).
- Installer size is documented and justified (T-028).
- A checksum mismatch in `fetch-engines.ps1` aborts the build loudly (T-002).

---

## M7 — Privacy verification and release

**Deliverables**

- A CI pipeline that runs the local gate on every push (T-031).
- CI check: fail if a network-capable dependency is present in `cargo tree`
  or `package.json` (T-032).
- CI check: the composited frontend bundle contains no `http://` or `https://`
  fetch targets (allow-list documented for things like schema strings) (T-032).
- Integration test: conversion succeeds with the network namespace / firewall
  rule disabling outbound traffic (T-033).
- `docs/PRIVACY.md` published with user-verifiable steps (T-034).
- `CHANGELOG.md` and an SBOM generated from the build (T-035).
- README and version 1.0.

**Exit criteria**

- T-036's report shows every condition passing, with no unaccounted cells in
  the coverage matrix.
- v1 lands on `main` as a single commit (T-037) and the development branch is
  deleted (T-038).
- `v1.0.0` is tagged on `main`, annotated, at the landing commit.
- A user can follow `PRIVACY.md` and independently confirm the app works
  offline, using tools we do not control.
