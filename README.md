# Wringer

**Put your files through the wringer.**

Convert and compress images entirely on your own computer. No uploads, no
account, no telemetry — and a way for you to check that yourself instead of
taking our word for it.

> **Status: pre-alpha.** No releases yet. To follow along or build it
> yourself, see [For contributors](#for-contributors).

## Install

*(Available once the first release ships.)*

1. Download `Wringer-<version>-x64-setup.exe` from the
   [Releases page](../../releases/latest).
2. Verify the published SHA-256 before running it.
3. Run the installer. Windows SmartScreen will warn you about an unsigned or
   new publisher — see [Why does Windows warn me?](#why-does-windows-warn-me).

## What it does

- **Convert** between PNG, JPEG, WebP, AVIF, TIFF, BMP, and more. Formats are
  detected by the file's actual contents, not its extension, so mislabelled
  files still work.
- **Compress** four ways: optimise in place, convert losslessly, set a quality
  level, or aim for a maximum file size.
- **Remove private metadata** — GPS coordinates, camera model and serial,
  timestamps — by default. The colour profile is always kept. The app tells
  you what it removed, per file.
- **Batch** whole folders, with real progress and per-file cancellation.

## What it does not do

Video, audio, PDF, office documents, OCR, AI upscaling, accounts, telemetry,
auto-update. It also never touches the network. That last one is the whole
point, so:

## Verify it yourself

Don't trust the claim — test it:

1. Disconnect from the internet.
2. Convert a folder of images. Everything works.

Then, if you want to go further: run a packet capture, or add an outbound
Windows Firewall rule blocking `wringer.exe`, and confirm nothing changes.

Full method, including how to check the binaries you downloaded, is in
[`docs/PRIVACY.md`](docs/PRIVACY.md). The threat model is there too — it says
plainly what this app does *not* protect you against.

## Why does Windows warn me?

Code signing certificates cost money and this is a young project. If the
installer is unsigned you'll get SmartScreen warnings until enough people have
downloaded it. Verify the SHA-256 from the release page before running
anything — that's good practice regardless of who signed it.

---

# For contributors

Everything below is for people building, auditing, or modifying Wringer.

## Why the source is public

Two reasons, and neither is sentimentality.

**The licence requires it.** Wringer is GPL-3.0-or-later. Publishing a binary
means offering the corresponding source.

**The privacy claim requires it.** An offline tool that won't show you how it
works is just a converter with better copywriting. You can read every line
here, run the no-network checks in `docs/PRIVACY.md`, and confirm the claim
rather than believing it.

## A note on the AI harness

Wringer is built with a coding agent, and the harness that governs that work
is committed alongside the code. `AGENTS.md` holds the rules the agent
operates under; `docs/` holds the specification it implements, the plan, the
task list, and the architecture decisions.

That's deliberate, and it's the more interesting half of the repository. You
can see not only what the code does, but what the agent was asked to build and
what it was explicitly forbidden from doing — no network dependencies, no
hand-rolled codecs, no weakening tests to make them pass. If you want to know
whether this project is careful, the harness is where to look.

## Building

Prerequisites: Node.js 20+, the Rust toolchain with the MSVC C++ build tools,
and the WebView2 runtime (preinstalled on Windows 11 and current Windows 10).

```powershell
npm install
.\scripts\fetch-engines.ps1
npm run tauri dev
```

Tests and lint:

```powershell
cargo test --manifest-path src-tauri/Cargo.toml
cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings
npm test
```

## How this repository is organised

| Path | What's in it |
|---|---|
| `AGENTS.md` | The rulebook. Hard rules, workflow, style. Read this first. |
| `docs/SPEC.md` | Behaviour contract: format matrix, modes, invariants. |
| `docs/PLAN.md` | Milestones with observable exit criteria. |
| `docs/TASKS.md` | The work list, one task at a time, with acceptance criteria. |
| `docs/WORKLOG.md` | Append-only record: the plan and evidence for each task. |
| `scripts/verify.ps1` | The definition of done. One command, PASS/FAIL/SKIP. |
| `docs/DECISIONS.md` | Architecture decision records — why Tauri, why libvips, why GPL. |
| `docs/LICENSING.md` | Every bundled component and its obligations. |
| `docs/PRIVACY.md` | Threat model and user-verifiable offline checks. |
| `docs/RESEARCH-competitors.md` | Landscape research, with sources. |
| `docs/engines/` | Pinned CLI flags for the bundled image engine. |

## Contributing

Start with `AGENTS.md`. It contains the operating protocol, and it is written
to be read by agents as much as by people.

### Working on a task

Tasks are sequential and live in `docs/TASKS.md`. The protocol in `AGENTS.md`
§1 is short:

- `start <T-###>` — the agent checks that earlier tasks are done, records a
  plan in `docs/WORKLOG.md` **before writing code**, implements, runs
  `scripts/verify.ps1`, presents its evidence, and stops.
- `commit` — once you have read the diff and you are satisfied, the agent
  updates the task status and commits.
- `reject <reason>` — discard the work and start over.

The two things the protocol guarantees: nothing is implemented before its plan
is written down in the repository, and nothing is committed that you have not
looked at.

### Branching and releases

`main` is a release ledger: exactly **one commit per released version**, and it
is never developed on. Work for a version happens on a single branch, which is
squash-merged onto `main` when the version is complete and then deleted. See
`AGENTS.md` §6 and ADR-009.

So if you are looking at `main`, you are looking at releases. The per-task
history lives on the development branch while it exists.

If you're using your own agent, pointing it at `AGENTS.md` is enough — it is
the whole contract.

Found a privacy problem — the app making any network request at all? That's
the most serious bug this project can have. See [`SECURITY.md`](SECURITY.md).

## Licence

GPL-3.0-or-later. See `LICENSE` and `docs/LICENSING.md`.
