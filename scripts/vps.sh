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
OUT="$LOG_DIR/sshx.out"
: > "$OUT"

# Khoi dong sshx nen (session song theo job, Keep-Alive giu job khong ket thuc)
nohup sudo script -q -e -c "SSHX_KEEP_ALIVE=true sshx" "$LOG_DIR/sshx.pty" >> "$OUT" 2>&1 &

# Doi URL toi da ~60s
URL=""
for i in $(seq 1 20); do
  URL="$(sed -r 's/\x1B\[[0-9;]*[mK]//g' "$OUT" 2>/dev/null \
    | grep -oE 'https://sshx\.io/[^[:space:]"]+' | tail -n 1 || true)"
  [ -n "$URL" ] && break
  sleep 3
done

echo "SSHX_URL: ${URL:-pending}"
if [ -n "$URL" ]; then
  printf '{"sshx_url":"%s","username":"root","hostname":"root"}\n' "$URL" > ssh_url.txt
fi
echo "Session keep-alive will run in workflow step."
exit 0
