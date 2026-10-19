# Security policy

## Reporting a vulnerability

Please report security problems privately, not in a public issue. Use
GitHub's [private vulnerability reporting](../../security/advisories/new)
if it is available, or contact the maintainer directly.

Include what you did, what happened, and what you expected. A packet capture
is worth more than a description.

## The most serious bug this project can have

**Wringer making a network request.** The entire product is the claim that
files never leave the machine. If you find the app opening a connection to
anything, that is a critical vulnerability regardless of what it sends, and
it will be treated as one.

Also serious:

- A source file being modified or deleted.
- A lossless mode altering pixel data.
- Metadata that `docs/PRIVACY.md` says is stripped surviving into the output.
- An output file being written outside the destination the user chose.
- A malformed input file causing a crash or unbounded memory use.

## Not in scope

- Vulnerabilities in the operating system or the WebView2 runtime.
- The app being unable to protect files from someone who already has access
  to the machine. See the threat model in `docs/PRIVACY.md`.
- Payloads embedded inside image files that affect *other* software. Wringer
  is not an image sanitiser and does not claim to be.
- Denial of service from processing deliberately enormous files, unless it
  crashes the app rather than failing cleanly.

## Our commitments

- Acknowledged within a few days.
- Fixed in a release, with credit unless you prefer otherwise.
- Published clearly in the changelog. There is no auto-update, so security
  fixes require users to download a new version — we say so rather than
  pretending the upgrade is automatic.
