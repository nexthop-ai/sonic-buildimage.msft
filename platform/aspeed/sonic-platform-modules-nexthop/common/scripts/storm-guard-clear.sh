#!/bin/bash
#
# Reboot-storm guard: clear the consecutive-WDT-reset counter once SONiC has
# reached steady state (past the last boot stage). U-Boot increments this
# counter on each WDT0-caused reset and halts autoboot at the limit, so a
# successful boot must reset it for the limit to count only consecutive
# failures.

STORMGUARD_COUNT=0x12C027FC

if ! busybox devmem "$STORMGUARD_COUNT" 32 0; then
    echo "storm-guard-clear: failed to clear reboot-storm counter at $STORMGUARD_COUNT" >&2
    exit 1
fi
