#!/bin/bash
# swss.service ExecCondition, so it runs before swss.sh reads the restart flags.
# After a fast-reboot kexec the ASIC is power-cycled, so swss and syncd must
# cold-init; clear the warm/fast restart state carried over in the STATE_DB dump.
# Always exits 0: any other ExecCondition exit status skips or fails swss.

log() {
  logger -t "fast_boot_cold_start" "$@"
}

main() {
  grep -qE '(^|\s)SONIC_BOOT_TYPE=fast-reboot(\s|$)' /proc/cmdline || return

  # Same wait as swss.sh wait_for_database_service
  until [[ $(sonic-db-cli PING | grep -c PONG) -gt 0 ]]; do
    sleep 1
  done

  if sonic-db-cli STATE_DB hset "FAST_RESTART_ENABLE_TABLE|system" "enable" "false" >/dev/null &&
     sonic-db-cli STATE_DB hset "WARM_RESTART_ENABLE_TABLE|system" "enable" "false" >/dev/null &&
     sonic-db-cli STATE_DB del "WARM_RESTART_TABLE|orchagent" "WARM_RESTART_TABLE|syncd" >/dev/null; then
    log "fast-reboot post-kexec: cleared FAST/WARM restart flags so swss/syncd cold-init"
  else
    log -p err "fast-reboot post-kexec: failed to clear FAST/WARM restart flags"
  fi
}

main
exit 0
