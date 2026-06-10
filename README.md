<!-- content-guard: allow private-ipv4 file -->
# obsctl

`kubectl`-style multi-host wrapper around [grigio/obs-cmd](https://github.com/grigio/obs-cmd) for managing OBS Studio over the LAN.

If you've got OBS running on more than one machine (a streaming box + a recording box, your desktop + your laptop, whatever), you want one CLI that knows about all of them. Define your hosts once in a config file, then:

```bash
obsctl studio recording toggle
obsctl laptop scene switch "Camera"
obsctl studio info
```

instead of typing out `obs-cmd -w obsws://host:port/password ...` every time.

## What this is, what it isn't

This is a thin bash wrapper. The actual OBS WebSocket work is done by [grigio/obs-cmd](https://github.com/grigio/obs-cmd), which is a v5-protocol-native client written in Rust. `obsctl` just registers your hosts and shells out to `obs-cmd` with the right URL.

If you only have one OBS instance, `obs-cmd` alone is enough. `obsctl` earns its keep once you have two or more.

## Requirements

- bash 4+ (uses uppercase parameter expansion `${var^^}`)
- [`obs-cmd`](https://github.com/grigio/obs-cmd/releases) on your `$PATH`
- OBS Studio 28+ (built-in WebSocket 5.x) on each host, with **Tools → WebSocket Server Settings → Enable WebSocket server** turned on

## Install

```bash
git clone https://github.com/solomonneas/obsctl
cd obsctl
./install.sh        # installs to ~/.local/bin/obsctl
```

Or copy `obsctl` somewhere on your `$PATH` yourself:

```bash
sudo install -m 0755 obsctl /usr/local/bin/obsctl
```

## Quick start

Write a starter config:

```bash
obsctl init
```

That creates `~/.config/obsctl/hosts.env` (mode 0600) with a single `local` host pointing at `127.0.0.1:4455`. Open it, paste the password from OBS's WebSocket Server Settings, save.

Try it:

```bash
obsctl local info
obsctl local scene list
```

Add more hosts by extending the `HOSTS` array and the `<ALIAS>_HOST/_PORT/_PASS` variables:

```bash
HOSTS=(local studio laptop)

LOCAL_HOST=127.0.0.1
LOCAL_PORT=4455
LOCAL_PASS='xxxxxxxxxxxxx'

STUDIO_HOST=192.168.1.42
STUDIO_PORT=4455
STUDIO_PASS='yyyyyyyyyyyyy'

LAPTOP_HOST=192.168.1.137
LAPTOP_PORT=4455
LAPTOP_PASS='zzzzzzzzzzzzz'
```

Aliases are case-insensitive on the command line (`obsctl studio` resolves the same `STUDIO_*` vars).

## All `obs-cmd` verbs are available

`obsctl <host> <whatever>` becomes `obs-cmd <whatever>` with `OBS_WEBSOCKET_URL` set to the right `obsws://` URL (in the environment, not on the command line, so the password never shows up in `ps`). So anything `obs-cmd` understands works:

```bash
obsctl studio scene list
obsctl studio scene switch "Camera"
obsctl studio recording start
obsctl studio recording stop
obsctl studio streaming toggle
obsctl studio replay save
obsctl studio audio toggle "Mic/Aux"
obsctl studio virtual-camera toggle
```

Run `obs-cmd help` for the full upstream list.

## Setting up OBS WebSocket on each host

Inside OBS:

1. `Tools → WebSocket Server Settings`
2. Check **Enable WebSocket server**
3. Set or read the **Server Password**
4. Apply, OK

On the OBS host, allow inbound TCP `4455` from your LAN (or just the workstation running `obsctl`). On Linux + ufw:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 4455 proto tcp
```

On Windows, PowerShell as admin:

```powershell
New-NetFirewallRule -DisplayName "OBS WebSocket" `
    -Direction Inbound -Action Allow -Protocol TCP `
    -LocalPort 4455 -Profile Private -Enabled True
```

## Config file format

`~/.config/obsctl/hosts.env` (or whatever `$OBSCTL_CONFIG` points at) is plain shell. It's sourced by `obsctl` at run time. Two requirements:

1. `HOSTS=(alias1 alias2 ...)`, a bash array of the aliases you want to register.
2. For each alias, set three variables in uppercase: `<ALIAS>_HOST`, `<ALIAS>_PORT`, `<ALIAS>_PASS`.

Aliases may only contain letters, digits, and underscores, and must not start with a digit, because they become shell variable names. Use `streaming_pc`, not `streaming-pc`.

That's the whole format. Keep it mode 0600 so other users on your box can't read the passwords.

## Why bash, why not Python / Go / Rust?

Because the actual work, talking to OBS, is done by `obs-cmd`. All `obsctl` does is dispatch the right URL to it. A 100-line bash wrapper has fewer moving parts than any of the alternatives. If you want a richer client, write your `obs-cmd` calls in your language of choice; this script is one possible UX, not the only one.

## Development

Lint and test (this is exactly what CI runs):

```bash
shellcheck obsctl install.sh hooks/pre-push test/smoke.sh
bash test/smoke.sh
```

This repo keeps its git hooks in the tracked `hooks/` directory. They are not active on a fresh clone; opt in with:

```bash
git config core.hooksPath hooks
```

The `pre-push` hook scans tracked files with [content-guard](https://github.com/solomonneas/content-guard) before anything leaves your machine. See [AGENTS.md](AGENTS.md) for the conventions it enforces.

## See also

- [grigio/obs-cmd](https://github.com/grigio/obs-cmd): the v5-protocol-native CLI we wrap
- [obsproject/obs-websocket](https://github.com/obsproject/obs-websocket): the WebSocket plugin bundled in OBS 28+
- [solomonneas/deckctl](https://github.com/solomonneas/deckctl): Stream Deck driver that wires OBS actions through these same hosts

## License

MIT. See [LICENSE](LICENSE).
