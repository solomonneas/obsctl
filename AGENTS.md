# AGENTS.md

Guidance for coding agents (and humans) working on this repo.

## Layout

This is a single-file bash CLI plus support scripts:

- `obsctl`: the whole program. Multi-host wrapper that resolves
  `<ALIAS>_HOST/_PORT/_PASS` variables from a sourced config and execs
  `obs-cmd` with `OBS_WEBSOCKET_URL` set in the environment.
- `install.sh`: copies `obsctl` to `~/.local/bin`.
- `hooks/pre-push`: content-guard scan, see below.
- `test/smoke.sh`: the test suite. No OBS or obs-cmd needed.
- `.github/workflows/ci.yml`: shellcheck gate + smoke test.

## Verify changes

Run both before claiming any change works:

```bash
shellcheck obsctl install.sh hooks/pre-push test/smoke.sh
bash test/smoke.sh
```

Both must be clean. CI runs exactly these, so a local pass means a green
check. If you add a script, add it to both the shellcheck list (here and in
`ci.yml`) and, where it makes sense, the smoke test.

Conventions to preserve:

- bash 4+ only (`${var^^}` and arrays are used deliberately).
- Exit codes are part of the interface: 1 config problems, 2 invalid alias,
  3 unconfigured host, 4 obs-cmd missing. The smoke test asserts them.
- The OBS password must never appear in argv. It is passed to `obs-cmd`
  via the `OBS_WEBSOCKET_URL` environment variable so it cannot be read
  from `ps` / `/proc/*/cmdline`. Do not reintroduce `-w "obsws://..."`.
- Host aliases map to shell variable names, so they are validated by
  `valid_alias()` before any indirect expansion. Keep new alias handling
  behind that check.

## content-guard pre-push hook

`hooks/pre-push` scans all tracked files with
[content-guard](https://github.com/solomonneas/content-guard) before
anything is pushed. It is tracked in-repo but only active on clones that
opt in:

```bash
git config core.hooksPath hooks
```

Important: `# content-guard: allow ...` comments (for example the
`allow private-ipv4 file` lines at the top of `obsctl` and `README.md`)
are load-bearing. Removing one will make the next push fail the scan.
Documentation IPs in examples should be RFC 5737 (`192.0.2.x`) or the
already-allowed private examples.

## Releases

- Keep `VERSION` in `obsctl` and `CHANGELOG.md` in sync.
- Accumulate changes under `## [Unreleased]` in the changelog.
- Do not tag or publish releases; the owner cuts tags on request.
