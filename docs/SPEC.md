# Wringer — Specification

Status: draft v0.1. This document is the source of truth for behaviour.
If code and this document disagree, one of them is a bug.

## 1. Purpose

Convert and compress image files entirely on the user's machine, with no
network access of any kind, so that files never leave the device.

The only claim that matters: **a user can verify, without trusting us, that
no data leaves their computer.**

## 2. Platforms

- Windows 10 21H2+ and Windows 11, x86-64.
- No Linux, no macOS, no ARM in v1.

## 3. Scope

### In scope

- Reading and writing common raster image formats.
- Re-encoding to a smaller file, either losslessly or with a quality target.
- A "target file size" mode that searches for the best quality fitting a cap.
- Batch processing.
- Metadata handling, including removal of location data.

### Out of scope (permanently, for this app)

Video, audio, PDF, office documents, OCR, AI upscaling/downscaling, cloud
storage, user accounts, telemetry, auto-update, plug-ins, RAW developer
features (some RAW *input* may be added later via the engine, nothing more).

## 4. Format matrix

Format detection is by **magic bytes**, never by file extension. Extensions
lie; the app must not.

| Input | Support | Notes |
|---|---|---|
| PNG | full | |
| JPEG | full | |
| WebP | full | |
| AVIF | full | required for v1; needs libheif + AV1 in the bundled engine, confirmed in T-002 |
| TIFF | full | single- and multi-page read; single-page write only |
| BMP | full | |
| GIF | partial | **first frame only**; must warn the user, never silently drop frames |
| ICO | read-only | multi-resolution; must let the user pick a size |
| HEIC/HEIF | conditional | only if the bundled engine was built with libheif; capability-detected at startup |
| RAW (CR2, NEF, ARW, DNG) | not in v1 | listed here so it is a deliberate decision, not an oversight |
| SVG | never | vector; out of category. Reject with a clear message. |

### Output formats

PNG, JPEG, WebP, AVIF, TIFF. Plus the implicit pseudo-target
"same format, just smaller".

## 5. Compression modes

Every job specifies exactly one mode.

| Mode | Meaning | Must never |
|---|---|---|
| **Optimize** | Re-encode in the same format with no pixel change (e.g. JPEG Huffman optimisation, maximal PNG deflate). Metadata policy still applies. | alter any pixel value |
| **Lossless** | Convert to a format offering lossless encoding (PNG, WebP-lossless, AVIF-lossless, TIFF) with no pixel change. | alter any pixel value |
| **Quality** | Lossy encode at a user-supplied quality Q (0–100). | silently clamp Q |
| **Target size** | User supplies a maximum output size. The app searches for the highest quality that fits. | exceed the cap |

### Mode-specific rules

- `Optimize` on a lossy source (JPEG) must be pixel-identical. If the engine's
  "optimise" path re-encodes, it does not qualify.
- `Target size` must use a bounded search (binary search on Q, max 8 engine
  invocations). It must report the Q it settled on and the resulting size.
- `Target size` must be honest when it fails: if even Q=1 exceeds the cap,
  report failure rather than emitting an oversized file.

## 6. Invariants

These are testable and must be tested.

1. **Never lose pixels in a lossless mode.** Verify by diffing input and
   output pixel data, not by trusting the engine's exit code.
2. **Never produce an output larger than the input** unless the user
   explicitly chose a mode where growth is possible. Default behaviour when
   `output_size >= input_size`: keep the original, report "already optimal".
3. **Never overwrite or modify a source file.** Ever. Output goes to a
   distinct path; collisions are resolved by suffixing, not overwriting.
4. **Never leave a partial file behind.** Write to a temp path in the
   destination directory and rename on success. On cancel or failure, remove
   the temp file.
5. **Never strip the ICC profile.** Colour correctness depends on it. If the
   source has an ICC profile and the target format supports one, carry it over.
   If the target cannot carry it, convert pixels to sRGB first.
6. **Always apply EXIF orientation to pixels** before stripping the
   orientation tag, on every path that writes a file. Doing this in the wrong
   order silently rotates users' photos — it is the single most common bug in
   this category.

## 7. Metadata policy

Default: **strip.** The app is a privacy tool.

| Metadata | Default | Option |
|---|---|---|
| GPS / location | removed | can be kept |
| Camera make/model/serial | removed | can be kept |
| Date/time taken | removed | can be kept |
| Software / edit history | removed | can be kept |
| ICC colour profile | **kept, always** | not optional |
| Orientation | applied to pixels, then removed | not optional |

When a job removes metadata, the UI must say so per file: "removed GPS
location and camera info". Silent stripping is a privacy feature; silent
stripping the user doesn't know about is a surprise. Show it.

## 8. Architecture

```
frontend (web UI)
      │  Tauri IPC: commands + events
      ▼
src-tauri/src/commands.rs      thin Tauri glue, no logic
src-tauri/src/job/             job engine: queue, state machine, cancel
src-tauri/src/engine/          subprocess wrapper around vips
src-tauri/src/probe/           format detection + image info
src-tauri/src/error.rs         typed error taxonomy
```

Rules:

- `job/`, `engine/`, `probe/`, `error.rs` must not reference Tauri types, so
  they are testable headlessly.
- `commands.rs` contains no business logic — it deserialises, delegates,
  and serialises.
- One engine subprocess per job at a time. `Target size` (§5) runs a bounded
  sequence of up to 8 of them, one after another. Concurrency is capped across
  jobs (see §10).
- Cancellation kills the child process; it does not wait politely.

## 9. UI requirements

- Drag and drop of files and folders, plus a file picker.
- A queue list: filename, detected format, dimensions, input size, status.
- Per-file settings, with an "apply to all" action.
- Real progress. Progress must come from the engine, never from a timer.
- Cancel per job and cancel all.
- On completion, per file: output path, output size, delta as an absolute
  number and a percentage, and a "open containing folder" action.
- Errors are per file and specific ("unsupported format: SVG" is good;
  "conversion failed" is not).
- The app must be fully usable with the network cable pulled.

## 10. Performance targets

Measured on a 4-core laptop, warm start:

- 20× 12 MP JPEGs, quality mode: under 30 seconds total.
- UI stays responsive throughout; no work on the UI thread.
- Peak memory under 1 GB regardless of input size. The engine streams;
  we do not load whole images into our own buffers.
- Concurrency: default to `min(4, logical_cores)`, user-adjustable 1–16.

## 11. Failure taxonomy

Every error maps to exactly one of these, and each has a UI string:

- `UnsupportedFormat` — magic bytes matched nothing we handle
- `CorruptInput` — engine rejected the file
- `EngineMissing` — bundled binary absent or failed its checksum
- `EngineFailed { code, stderr_tail }` — non-zero exit; stderr tail is shown
- `OutputNotSmaller` — result would not have been an improvement
- `TargetUnreachable` — target size mode gave up
- `Cancelled`
- `Io(io::Error)` — disk full, permission denied, path too long

`AppError` must never be a bare `String`.

## 12. Configuration

- Presets: named, saved to a local config file (`%APPDATA%`), user-editable.
- Minimum: `PNG lossless`, `JPEG q85 web`, `WebP q80`, `AVIF q60`,
  `Screenshot to PNG`, `Email-friendly under 500 KB`.
- No config file is ever synced or sent anywhere.

## 13. Acceptance for v1

The app ships when all of these hold:

1. Every mode in §5 works for every output format in §4 — AVIF included. If
   the pinned engine cannot encode it, that stops the release (T-002); it does
   not shrink this list.
2. All invariants in §6 have automated tests that fail when the invariant is broken.
3. The no-network test in `docs/PRIVACY.md` passes in CI.
4. The installer is signed and installs cleanly on a machine with no dev tools.
5. `THIRD-PARTY-NOTICES` is generated by the build and is complete.

These are demonstrated, not assumed. The demonstration is task **T-036** in
`docs/TASKS.md`, and its report in `docs/V1-VERIFICATION.md` is what the
release tag is placed against. A condition that cannot be demonstrated is not
met, however true it seems.
