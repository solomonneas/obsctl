#!/usr/bin/env bash
# Smoke test for obsctl: exercises init, flag handling, config parsing, and
# the error paths. Needs no OBS instance and no obs-cmd binary.
set -uo pipefail

OBSCTL="$(cd "$(dirname "$0")/.." && pwd)/obsctl"
BASH_BIN="$(command -v bash)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export OBSCTL_CONFIG="$TMP/hosts.env"

fails=0
run=0

# check <desc> <expected-exit> <cmd...>
# Captures combined output in $OUT for follow-up expect_out checks.
check() {
    local desc="$1" want="$2"
    shift 2
    run=$((run + 1))
    OUT="$("$@" 2>&1)"
    local got=$?
    if [[ "$got" -ne "$want" ]]; then
        echo "FAIL: $desc (exit $got, wanted $want)"
        printf '%s\n' "$OUT" | sed 's/^/      /'
        fails=$((fails + 1))
    else
        echo "ok:   $desc"
    fi
}

expect_out() {
    local desc="$1" pattern="$2"
    run=$((run + 1))
    if printf '%s' "$OUT" | grep -q "$pattern"; then
        echo "ok:   $desc"
    else
        echo "FAIL: $desc (output did not match: $pattern)"
        printf '%s\n' "$OUT" | sed 's/^/      /'
        fails=$((fails + 1))
    fi
}

reject_out() {
    local desc="$1" pattern="$2"
    run=$((run + 1))
    if printf '%s' "$OUT" | grep -q "$pattern"; then
        echo "FAIL: $desc (output matched forbidden pattern: $pattern)"
        printf '%s\n' "$OUT" | sed 's/^/      /'
        fails=$((fails + 1))
    else
        echo "ok:   $desc"
    fi
}

# --- config-free commands -------------------------------------------------
check "--help exits 0" 0 "$OBSCTL" --help
expect_out "--help shows usage" "obsctl <host-alias>"

check "--version exits 0" 0 "$OBSCTL" --version
expect_out "--version prints a semver" "^obsctl [0-9][0-9.]*"
check "-V exits 0" 0 "$OBSCTL" -V

# --- missing config -------------------------------------------------------
check "missing config exits 1" 1 "$OBSCTL" local info
expect_out "missing config message" "cannot read"

# --- init -----------------------------------------------------------------
check "init exits 0" 0 "$OBSCTL" init
if [[ -f "$OBSCTL_CONFIG" ]]; then
    echo "ok:   init created the config"
else
    echo "FAIL: init did not create $OBSCTL_CONFIG"
    fails=$((fails + 1))
fi
run=$((run + 1))

mode="$(stat -c '%a' "$OBSCTL_CONFIG" 2>/dev/null || stat -f '%Lp' "$OBSCTL_CONFIG")"
run=$((run + 1))
if [[ "$mode" == "600" ]]; then
    echo "ok:   config mode is 600"
else
    echo "FAIL: config mode is $mode, wanted 600"
    fails=$((fails + 1))
fi

check "second init refuses to overwrite (exit 1)" 1 "$OBSCTL" init
expect_out "second init message" "already exists"

# --- alias validation -----------------------------------------------------
check "hyphenated alias exits 2" 2 "$OBSCTL" my-host info
expect_out "hyphenated alias friendly message" "invalid host alias 'my-host'"
reject_out "no raw bash error for hyphenated alias" "invalid variable name"

check "digit-leading alias exits 2" 2 "$OBSCTL" 2pc info

# --- unknown / unconfigured host -------------------------------------------
check "unknown host exits 3" 3 "$OBSCTL" missinghost info
expect_out "unknown host message" "not fully configured"

# --- config parsing and --list ---------------------------------------------
printf 'HOSTS=(local bad-alias)\nLOCAL_HOST=127.0.0.1\nLOCAL_PORT=4455\nLOCAL_PASS=dummy\n' \
    > "$OBSCTL_CONFIG"
check "--list exits 0" 0 "$OBSCTL" --list
expect_out "--list shows configured host" "local.*127.0.0.1:4455"
expect_out "--list flags invalid alias from config" "bad-alias.*invalid alias"
reject_out "--list survives invalid alias in config" "invalid variable name"

printf 'HOSTS=()\n' > "$OBSCTL_CONFIG"
check "empty HOSTS array exits 1" 1 "$OBSCTL" local info
expect_out "empty HOSTS message" "HOSTS array is empty"

# --- obs-cmd missing (exit 4) ----------------------------------------------
# Run with a PATH that has coreutils but cannot contain obs-cmd.
printf 'HOSTS=(local)\nLOCAL_HOST=127.0.0.1\nLOCAL_PORT=4455\nLOCAL_PASS=dummy\n' \
    > "$OBSCTL_CONFIG"
nobin="$TMP/no-obs-cmd-bin"
mkdir -p "$nobin"
for tool in cat dirname mkdir chmod stat grep sed; do
    src="$(command -v "$tool")" && ln -s "$src" "$nobin/$tool"
done
check "obs-cmd missing exits 4" 4 env PATH="$nobin" "$BASH_BIN" "$OBSCTL" local info
expect_out "obs-cmd missing message" "'obs-cmd' not found on PATH"

# ---------------------------------------------------------------------------
echo
echo "smoke: $((run - fails))/$run checks passed"
[[ "$fails" -eq 0 ]]
