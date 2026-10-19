# Engine reference

This directory exists for one reason: **so that nobody, human or AI, has to
remember an engine's command-line flags from memory.**

Wrong flags are one of the most common and most expensive failures in AI-assisted
work: they look plausible, the code compiles, and the output is subtly wrong.
So we keep the exact flags we use here, pasted from the documentation of the
version we actually ship.

## Rules

1. **One file per engine**, named after the engine.
2. Every flag we rely on is listed **with the version it was verified against**.
3. Flags we have not verified are marked `UNVERIFIED`. Never mark something
   verified without actually running it and observing the result.
4. When the engine version is bumped, this file is updated **in the same
   commit**. A version bump with a stale flags file is a bug.
5. If the engine cannot do something we need, that goes in this file as a
   known limitation rather than being worked around by hand-rolling code.

## Files

- `libvips.md` — the image engine (see ADR-002).
