# Changelog

All notable changes to obsctl are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-10

### Added

- Multi-host wrapper around [grigio/obs-cmd](https://github.com/grigio/obs-cmd):
  `obsctl <alias> <obs-cmd args...>` against hosts registered in
  `~/.config/obsctl/hosts.env` (or `$OBSCTL_CONFIG`).
- `obsctl init` to write a starter config (mode 0600).
- `obsctl --list` / `--hosts` to show configured hosts.
- `obsctl -V` / `--version`.
- `install.sh` installer targeting `~/.local/bin`.
- CI: shellcheck gate plus a smoke test of `init`, flag handling, and the
  error paths.

### Fixed

- Invalid host aliases (for example `my-host` with a hyphen) now fail with a
  clear message and exit code 2 instead of a raw bash "invalid variable name"
  error.

### Security

- The OBS WebSocket password is passed to `obs-cmd` via the
  `OBS_WEBSOCKET_URL` environment variable instead of argv, so it is no
  longer visible to other local users in `ps` output.
