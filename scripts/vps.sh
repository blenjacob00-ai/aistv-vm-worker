#!/usr/bin/env bash
set -u
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Keep-Alive chong bi ngat ket noi do idle
export SSHX_KEEP_ALIVE=true

# Cai sshx (neu chua co) va cho phep sudo tim thay no
if ! command -v sshx >/dev/null 2>&1; then
  curl -sSf https://sshx.io/get | sh
  export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
fi
SSHX_BIN="$(command -v sshx || true)"
if [ -n "$SSHX_BIN" ] && ! sudo sh -c 'command -v sshx' >/dev/null 2>&1; then
  sudo cp "$SSHX_BIN" /usr/local/bin/sshx 2>/dev/null || true
fi

LOG_DIR="$HOME/sshx_logs"
mkdir -p "$LOG_DIR"
chmod 777 "$LOG_DIR" 2>/dev/null || true
SSHX_PID=""
SSHX_URL=""
MINS="${DURATION_MINUTES:-60}"
DEADLINE=$(( $(date +%s) + MINS * 60 ))

restart_sshx() {
  sudo script -q -e -c "SSHX_KEEP_ALIVE=true sshx" "$LOG_DIR/sshx.pty" >> "$LOG_DIR/sshx.out" 2>&1 &
  SSHX_PID=$!
}

extract_url() {
  cat "$LOG_DIR/sshx.out" "$LOG_DIR/sshx.pty" 2>/dev/null \
    | sed -r 's/\x1B\[[0-9;]*[mK]//g' \
    | grep -oE 'https://sshx\.io/[^[:space:]"]+' \
    | tail -n 1 || true
}

restart_sshx
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if ! kill -0 "$SSHX_PID" 2>/dev/null; then
    restart_sshx
  fi
  NEW_URL="$(extract_url)"
  if [ -n "$NEW_URL" ] && [ "$NEW_URL" != "$SSHX_URL" ]; then
    SSHX_URL="$NEW_URL"
    echo "SSHX_URL: $SSHX_URL"
  fi
  sleep 15
done
echo "Username: AISTV"
echo "Hostname: AISTV"
echo "SSHX_URL: ${SSHX_URL:-pending}"
echo "Session finished after ${MINS} minutes."
exit 0
