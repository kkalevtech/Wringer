# Competitor research

Purpose: understand the landscape honestly, so our positioning is defensible
and does not rely on accusations we cannot support.

Two rules for this file:

1. **No claims without a source.** Every row cites the page it came from.
2. **No naming and shaming in the product.** This is internal research. The
   shipped app markets on verification, not on competitors' sins.

Policies change. Re-check this file before any marketing copy is written, and
record the date of each check.

## Snapshot — checked 2026-10-17

| Service | Retention stated | Metadata logged | Client-side option | Source |
|---|---|---|---|---|
| Convertio | Input deleted after conversion; output after 24h | IP, input/output types, conversion error rate | no | convertio.co/privacy, support.convertio.co |
| Zamzar / file-converter.org | 7 days for anonymous users; 35 days after account deactivation | filename | no | file-converter.org/privacy |
| FreeFileConvert | 12 hours | usage data "for internal analysis" | no | freefileconvert.com/privacy |
| File-Converter-Online.com | 3 hours; 24h for inactive uploads | not stated on summary page | no | file-converter-online.com/privacy-policy |
| online-file-converter.com | 1 hour, stated as "deleted forever" | not stated | no | online-file-converter.com |
| OnlineConvert.com | 1 hour, "irreversibly destroyed" | not stated in summary | partial (PDF suite via WASM) | onlineconvert.com/privacy |
| File Converts | server jobs: short window; most tools: never uploaded | minimal operational metadata for server jobs | yes, most tools | file-converts.com/privacy |
| FileConvert (freefileconverter.dev) | none — no uploads | anonymous aggregate analytics | yes, all | freefileconverter.dev/privacy |
| GroupDocs | not stated in the summary text | not stated | no | products.groupdocs.app |

## What this tells us

1. **The concern is real but not universal.** Retention windows range from
   one hour to seven days. Several providers are genuinely careful. A few
   do the conversion locally in the browser and never receive the file.

2. **Almost all server-side providers log metadata** even when they delete
   the file — at minimum IP address and the input/output file types. That
   metadata outlives the file and is not something a user can retrieve.

3. **"Deleted after N hours" is unverifiable.** It is a policy statement.
   That, not malice, is the actual problem worth solving.

4. **The client-side WASM approach is a real alternative** to a desktop app
   for many use cases. Our honest advantages over it: no browser, no CDN
   dependency (browser tools typically load their engine from a CDN, which
   is itself a third-party request), batch handling of large folders, and
   no need for the user to keep a tab open.

## Direct competitors — desktop apps, found 2026-10-17

Found while checking name availability. These matter more than the web
converters above, because they are the same product we are planning.

| Product | What it is | Source |
|---|---|---|
| **Kiln** | Desktop batch image converter/compressor. Reads JPEG, PNG, WebP, AVIF, HEIC, TIFF, BMP, GIF; writes JPEG, PNG, WebP, AVIF, TIFF. Non-destructive, filename templates, parallel batches, "fully offline, no telemetry, no uploads, no account". Public beta, Windows/macOS/Linux. Also does resize, watermark, rotate, and EXIF/IPTC/XMP editing. | kilnimage.app |
| **Localfile** | "Offline Privacy-First File Tools": merge PDFs, remove metadata, compress files, secure delete. No accounts, no uploads, no subscriptions. | localfile.tools |
| **Orion Utility Suite** | Open source, offline-first, built with Tauri v2 + React 19 + Rust. Batch image conversion, PDF tools, hash checker, QR generator. | GitHub: Firmandez/Orion-Utility-Suite |

**Kiln is the one to study.** Its published feature list is very close to our
v1 spec in `SPEC.md`, it is already in public beta, and it ships on three
platforms where we planned one. It is not GPL, it is not source-available, and
its offline claim is a statement rather than something a user can check — but
the feature overlap is real and should be treated as the baseline to beat, not
as a gap in the market.

### Consequence for our plan

"An offline image converter" is no longer a differentiator on its own. The
things in our spec that are still genuinely distinguishing:

1. **Windows-only polish.** Kiln spreads itself across three platforms.
   Being excellent on one is a real strategy.
2. **Verified, not asserted, offline behaviour.** CI-enforced no-network
   guarantees and user-followable verification steps in `PRIVACY.md`. Nobody
   in this list publishes a method the user can run.
3. **Metadata stripping as a first-class feature**, not a submenu. Kiln lists
   EXIF editing among many operations; we treat privacy as the reason the
   product exists.
4. **GPL-3.0 and fully open source.** Kiln is source-available under a
   fair-code model; Orion is open source.

Revisit this section before writing any marketing copy.

## Positioning consequence

Lead with: *"Your files stay on your machine, and here is how to prove it."*

Do not lead with: *"Other converters steal your files."* It is not
supportable, it invites a legal response, and it makes the product look
defensive rather than confident.

## Open questions to research before writing any marketing

- Do any of these services use subprocessors whose own retention is longer
  than the headline window? Check subprocessor lists and DPAs.
- Do any terms-of-service clauses permit use of uploaded content for model
  training? Check terms, not just privacy policies.
- Load-time third-party requests: what CDNs and analytics scripts does each
  site pull, and do any receive file content? Test with a network inspector
  on a file conversion path.
- Any disclosed security incidents involving uploaded user files?
