#!/usr/bin/env bash
set -euo pipefail

# Default to a common Nginx access log if no file is provided.
LOG_FILE="${1:-/var/log/nginx/access.log}"
# How many top results to show.
TOP_N="${TOP_N:-5}"

if [[ ! -f "${LOG_FILE}" ]]; then
  echo "Log file not found: ${LOG_FILE}" >&2
  exit 1
fi

# Count total requests (lines) and total 404 responses.
total_requests="$(wc -l < "${LOG_FILE}" | tr -d ' ')"
total_404="$(awk '$9 == "404" {c++} END {print c+0}' "${LOG_FILE}")"

echo "Log file: ${LOG_FILE}"
echo "Total requests: ${total_requests}"
echo "404 responses: ${total_404}"
echo
echo "Top ${TOP_N} requested paths:"
# Extract paths, count, and show the most requested.
awk '{print $7}' "${LOG_FILE}" | \
  awk 'NF && $1 ~ /^\//' | \
  sort | uniq -c | sort -nr | head -n "${TOP_N}"

echo
echo "Top ${TOP_N} client IPs:"
# Extract client IPs, count, and show the most active.
awk '{print $1}' "${LOG_FILE}" | \
  awk 'NF' | \
  sort | uniq -c | sort -nr | head -n "${TOP_N}"
