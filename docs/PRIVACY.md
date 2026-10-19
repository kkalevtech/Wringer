# Privacy

## The claim

Wringer performs all work on your computer. It does not send your files,
your filenames, or anything about your usage anywhere. There is no account,
no telemetry, no crash reporting, and no update check.

That claim is only worth something if you can check it. This document exists
so you can, using tools we do not control.

## Threat model

**We protect against:**

- A conversion service retaining, inspecting, or monetising your files.
- Metadata leaking from files you share afterwards: GPS coordinates, camera
  serial numbers, timestamps, edit history.
- Silent network behaviour by the tool itself, including "anonymous" usage
  statistics.

**We do not protect against:**

- Malware already present on your machine.
- Someone with access to your computer reading your files directly.
- Files that misrepresent their own type — we detect by content, but a file
  can be a valid image and still contain a payload your *other* software
  might mishandle. We do not sanitise images for downstream vulnerabilities.
- Windows itself doing whatever Windows does.

## Why this is different from an online converter

Online services are not necessarily malicious. Published policies across the
major ones typically promise deletion somewhere between one hour and seven
days, and several log metadata — input and output file types, IP address,
conversion outcomes — independently of whether they keep the file. Some
providers now run conversion in the browser via WebAssembly, in which case
nothing is uploaded at all.

The difference is not intent. It is that all of those arrangements require you
to trust a policy you cannot audit, about files you cannot get back. We remove
the trust requirement instead of asking for it.

We deliberately do not name or accuse specific competitors. Retention policies
change; our own claim should stand on its own evidence.

## Verifying the claim yourself

### 1. The simplest check

1. Disconnect your computer from the network (unplug the cable, or disable
   Wi-Fi).
2. Launch the app and convert a folder of images.
3. Everything works.

If the app needed the network for anything, step 3 would fail.

### 2. See the traffic for yourself

Run a packet capture while you use the app and confirm that no outbound
connection is opened to any address. Use any tool of your choosing — Wireshark,
or your router's per-device traffic log.

Expected result: no outbound traffic attributable to the app. Note that
*other* software on the machine will be talking; look for connections owned
by the Wringer process specifically.

### 3. Block it and see what breaks

Create an outbound Windows Firewall rule blocking `Wringer.exe` entirely,
then use the app normally.

Expected result: nothing breaks, because nothing was being sent.

### 4. Verify the installed binary

The release page publishes a SHA-256 for each installer. Verify it before
installing. Builds are reproducible from the tagged source in this repository;
if you do not trust our binary, build it yourself.

### 5. Read the source

It is GPL-3.0. The engine wrapper is a few hundred lines. Search it for
`http`, `reqwest`, `ureq`, and any socket API. There should be none.

## What the app does do locally

- Reads your input files and writes output files where you tell it to.
- Writes a small configuration file to `%APPDATA%` containing your presets.
  This never leaves your machine and you can delete it.
- Spawns an engine process per job to do the image work.

## How we keep this true

Enforced in CI, so it cannot quietly regress:

1. **Dependency guard.** CI fails if a network-capable crate appears in
   `cargo tree`, or a network-capable package in `package.json`.
2. **Bundle guard.** CI fails if the frontend bundle contains a fetch target
   outside a small, documented allow-list.
3. **Offline integration test.** A full conversion runs with outbound traffic
   blocked. The test is validated by confirming it *fails* against a build
   that deliberately calls out, so we know the test detects real traffic.

## Reporting a privacy problem

If you find the app making a network request, that is a security bug and the
most serious kind we can have. Please report it as such, with the capture.
