# libvips

**Pinned version:** TBD — set in T-002.
**Distribution source (Windows):** TBD, confirm before pinning. Candidates are
the official libvips Windows release archives. Verify which archive is
redistributable and ships the binaries we need.

**Status of this document:** UNVERIFIED. It is a starting point compiled from
the libvips CLI conventions. Every entry below must be confirmed against the
pinned version, by running it, before any code depends on it. Confirmations
should replace `UNVERIFIED` with the version they were checked on.

---

## Probing

```
vipsheader -a <file>
```

Prints all header fields as `key: value`, one per line. Fields we need:
`width`, `height`, `bands`, `format`, `interpretation`, `vips-loader`.

UNVERIFIED: exact output format and whether `format` is the loader name or the
pixel format. Check with a PNG and a JPEG and record the real output here.

Magic-byte detection is done in our own Rust code, not here — but the engine's
loader should agree with it. If they disagree for some file, that is worth
knowing about.

## Converting / re-encoding

```
vips copy <in> <out>
```

with save options passed as `<out>[opt=value,opt=value]`.

UNVERIFIED: whether `copy` is the right verb for forced re-encoding, or whether
`vips copy` will pass through without re-encoding when the format is unchanged.
If pass-through occurs, `Optimize` mode will silently do nothing. **Test this
explicitly** — it is exactly the kind of failure that looks fine.

Illustrative save options to verify per saver:

| Saver | Options to verify |
|---|---|
| `pngsave` | `compression` (0–9), `interlace`, `effort`, `palette`, `Q`, `dither`, `bitdepth`, `profile`, `keep` |
| `jpegsave` | `Q`, `optimize_coding`, `interlace`, `subsample_mode`, `trellis_quant`, `overshoot_deringing`, `optimize_scans`, `quant_table`, `profile`, `keep` |
| `webpsave` | `Q`, `lossless`, `effort` (0–6), `near_lossless`, `smart_subsample`, `preset`, `profile`, `keep` |
| `heifsave` | `Q`, `lossless`, `effort` (0–10), `compression` (av1/hevc), `profile`, `keep` |
| `tiffsave` | `compression` (none/lzw/deflate/zstd/jpeg), `predictor`, `tile`, `profile` |

Confirm the default for `keep`. Metadata policy depends on it: we need to know
whether metadata is preserved or dropped by default, because either way we must
be explicit rather than relying on the default.

## Lossless verification

We must prove lossless modes are pixel-identical, not assume it.

Candidate approaches, in order of preference — confirm which exists in the
pinned version:

1. `vips ssim <a> <b>` — UNVERIFIED whether this operation exists.
2. `vips subtract <a> <b> diff.v` then check the maximum absolute value is 0.
3. Compare raw pixel dumps directly in a Rust test.

Whichever is used, the test must compare **pixel data**, never file hashes or
file sizes.

## Metadata

- ICC profile: needs an explicit `profile=` or `keep` option on the save side.
  Confirm how to preserve the input profile rather than converting.
- EXIF orientation: confirm how to apply the orientation to pixels
  (`vips autorot` is the candidate) and confirm the tag is then dropped.
  Order matters: autorot first, then strip.
- Stripping: confirm which option removes metadata wholesale and whether we
  can strip selectively (GPS only, or all except ICC).

UNVERIFIED: selective stripping. If libvips can only strip everything or
nothing, that changes the metadata design in `SPEC.md` §7 and is a decision
for a human, not an implementation detail.

## Progress and cancellation

```
vips --vips-progress copy <in> <out>
```

UNVERIFIED: whether progress goes to stderr, what the output looks like, and
whether it is line-buffered when stderr is a pipe. If it is not line-buffered,
T-008 needs a different approach.

`VIPS_CONCURRENCY` and `--vips-concurrency` control the engine's internal
thread count. This interacts with our own job concurrency cap — 4 concurrent
jobs each spawning 8 threads will thrash. Decide the policy and record it here.

Cancellation is a process kill on our side. Also verify that the engine leaves
no temp files of its own behind when killed.

## Known limitations

Record here as they are discovered. Anything the engine cannot do becomes a
documented limitation, never a hand-rolled workaround.
