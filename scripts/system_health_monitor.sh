#!/usr/bin/env bash
set -euo pipefail

# Thresholds can be overridden with env vars.
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEM_THRESHOLD="${MEM_THRESHOLD:-80}"
DISK_THRESHOLD="${DISK_THRESHOLD:-80}"
PROC_THRESHOLD="${PROC_THRESHOLD:-300}"
# Optional log file for alerts (stdout if empty).
LOG_FILE="${LOG_FILE:-}"

emit() {
  if [[ -n "${LOG_FILE}" ]]; then
    printf '%s\n' "$1" >> "${LOG_FILE}"
  else
    printf '%s\n' "$1"
  fi
}

read_cpu() {
  # Read CPU counters from /proc/stat.
  local _cpu user nice system idle iowait irq softirq steal
  read -r _cpu user nice system idle iowait irq softirq steal _ < /proc/stat
  local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  local idle_all=$((idle + iowait))
  printf '%s %s\n' "${total}" "${idle_all}"
}

cpu_usage_percent() {
  # Compute CPU usage over a 1s interval.
  local total1 idle1 total2 idle2 delta_total delta_idle
  read -r total1 idle1 < <(read_cpu)
  sleep 1
  read -r total2 idle2 < <(read_cpu)
  delta_total=$((total2 - total1))
  delta_idle=$((idle2 - idle1))
  if ((delta_total <= 0)); then
    printf '0\n'
  else
    printf '%s\n' $(( (100 * (delta_total - delta_idle)) / delta_total ))
  fi
}

mem_usage_percent() {
  # Calculate used memory from /proc/meminfo.
  awk '
    /MemTotal/ {t=$2}
    /MemAvailable/ {a=$2}
    END {
      if (t > 0 && a > 0) {
        printf("%d\n", (100 * (t - a)) / t)
      } else {
        print 0
      }
    }' /proc/meminfo
}

disk_usage_percent() {
  # Get root filesystem usage percentage.
  df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}

process_count() {
  # Count running processes.
  ps -e --no-headers | wc -l | tr -d ' '
}

timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
cpu_usage="$(cpu_usage_percent)"
mem_usage="$(mem_usage_percent)"
disk_usage="$(disk_usage_percent)"
proc_count="$(process_count)"

# Print a one-line summary.
emit "timestamp=${timestamp} cpu=${cpu_usage}% mem=${mem_usage}% disk=${disk_usage}% procs=${proc_count}"

alerts=()
if ((cpu_usage > CPU_THRESHOLD)); then
  alerts+=("ALERT: CPU usage ${cpu_usage}% > ${CPU_THRESHOLD}%")
fi
if ((mem_usage > MEM_THRESHOLD)); then
  alerts+=("ALERT: Memory usage ${mem_usage}% > ${MEM_THRESHOLD}%")
fi
if ((disk_usage > DISK_THRESHOLD)); then
  alerts+=("ALERT: Disk usage ${disk_usage}% > ${DISK_THRESHOLD}%")
fi
if ((proc_count > PROC_THRESHOLD)); then
  alerts+=("ALERT: Process count ${proc_count} > ${PROC_THRESHOLD}")
fi

if ((${#alerts[@]} > 0)); then
  # Print alerts and return non-zero for monitoring systems.
  for alert in "${alerts[@]}"; do
    emit "${alert}"
  done
  exit 1
fi
