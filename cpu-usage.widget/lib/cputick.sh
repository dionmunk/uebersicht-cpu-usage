#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# Compile the Swift helper on first run (or after source changes)
if [ ! -x "$DIR/cputick" ] || [ "$DIR/cputick.swift" -nt "$DIR/cputick" ]; then
    swiftc -O "$DIR/cputick.swift" -o "$DIR/cputick" 2>/dev/null
fi

# Kernel_task CPU% as a throttling proxy on Apple Silicon.
# top is slow (~1.5s) so we refresh asynchronously every ~5s and cache the result.
KCACHE="$DIR/.kerneltask.cache"
KLOCK="$DIR/.kerneltask.lock"
NOW=$(date +%s)
KSTAMP=0
[ -f "$KCACHE" ] && KSTAMP=$(date -r "$KCACHE" +%s 2>/dev/null)
AGE=$((NOW - KSTAMP))
# Clear a stale lock left by a sampler that was killed before it could clean up
# (system sleep, Übersicht restart, display change). A sample takes ~1.5s, so a lock
# older than 15s is dead — without this the refresh below would never run again and
# the cached value would freeze permanently.
if [ -f "$KLOCK" ]; then
    LSTAMP=$(date -r "$KLOCK" +%s 2>/dev/null || echo 0)
    [ $((NOW - LSTAMP)) -gt 15 ] && rm -f "$KLOCK"
fi
if [ "$AGE" -gt 4 ] && [ ! -f "$KLOCK" ]; then
    (
        : > "$KLOCK"
        ktask=$(top -l 2 -s 1 -n 50 -stats command,cpu 2>/dev/null | awk '/^kernel_task/ {v=$2} END {print v+0}')
        echo "${ktask:-0}" > "$KCACHE"
        rm -f "$KLOCK"
    ) > /dev/null 2>&1 &
fi

KTASK=0
[ -f "$KCACHE" ] && KTASK=$(cat "$KCACHE" 2>/dev/null)

# Output: <user> <system> <idle> <nice> <kernel_task_cpu>
echo "$("$DIR/cputick") ${KTASK:-0}"
