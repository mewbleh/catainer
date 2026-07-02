#!/usr/bin/env sh
set -eu

REPO="${CATAINER_REPO:-mewbleh/catainer}"
BRANCH="${CATAINER_BRANCH:-main}"
INSTALL_URL="${CATAINER_INSTALL_URL:-https://raw.githubusercontent.com/${REPO}/${BRANCH}/catainer}"

if [ -n "${PREFIX:-}" ] && [ -d "${PREFIX}/bin" ]; then
  TARGET="${CATAINER_TARGET:-${PREFIX}/bin/catainer}"
else
  TARGET="${CATAINER_TARGET:-${HOME}/.local/bin/catainer}"
fi

log() {
  printf 'catainer installer: %s\n' "$*" >&2
}

fail() {
  printf 'catainer installer: error: %s\n' "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

download() {
  url="$1"
  output="$2"
  partial="${output}.part"
  total="$(content_length "$url" || true)"
  download_pid=""
  progress_pid=""
  status=0

  rm -f "$partial"

  if has_cmd curl; then
    curl -fL -sS "$url" -o "$partial" &
    download_pid=$!
  elif has_cmd wget; then
    wget -q -O "$partial" "$url" &
    download_pid=$!
  else
    fail "curl or wget is required"
  fi

  if progress_enabled; then
    show_download_progress "$partial" "${total:-0}" "$download_pid" &
    progress_pid=$!
  fi

  if wait "$download_pid"; then
    status=0
  else
    status=$?
  fi

  if [ -n "$progress_pid" ]; then
    wait "$progress_pid" 2>/dev/null || true
  fi

  if [ "$status" -ne 0 ]; then
    rm -f "$partial"
    return "$status"
  fi

  mv "$partial" "$output"
}

content_length() {
  url="$1"
  length=""

  if has_cmd curl; then
    length="$(
      curl -fsIL "$url" 2>/dev/null |
        awk 'tolower($1) == "content-length:" { len = $2 } END { gsub("\r", "", len); if (len ~ /^[0-9]+$/) print len }'
    )"
  elif has_cmd wget; then
    length="$(
      wget --spider --server-response "$url" 2>&1 |
        awk 'tolower($1) == "content-length:" { len = $2 } END { gsub("\r", "", len); if (len ~ /^[0-9]+$/) print len }'
    )"
  fi

  printf '%s\n' "$length"
}

progress_enabled() {
  case "${CAT_PROGRESS:-auto}" in
    always) return 0 ;;
    never) return 1 ;;
    auto) [ -t 2 ] ;;
    *) [ -t 2 ] ;;
  esac
}

format_bytes() {
  bytes="${1:-0}"
  awk -v bytes="$bytes" 'BEGIN {
    split("B KB MB GB TB", unit, " ")
    value = bytes + 0
    idx = 1
    while (value >= 1024 && idx < 5) {
      value = value / 1024
      idx++
    }
    if (idx == 1) {
      printf "%d %s", value, unit[idx]
    } else {
      printf "%.1f %s", value, unit[idx]
    }
  }'
}

repeat_char() {
  char="$1"
  count="$2"
  i=0

  while [ "$i" -lt "$count" ]; do
    printf '%s' "$char"
    i=$((i + 1))
  done
}

progress_file_size() {
  file="$1"

  if [ -f "$file" ]; then
    wc -c <"$file" | tr -d '[:space:]'
  else
    printf '0'
  fi
}

format_eta() {
  speed="${1:-0}"
  remaining="${2:-0}"

  if [ "$speed" -le 0 ] || [ "$remaining" -le 0 ]; then
    printf '%s' '--'
    return 0
  fi

  seconds=$((remaining / speed))
  if [ "$seconds" -lt 60 ]; then
    printf '%ss' "$seconds"
  elif [ "$seconds" -lt 3600 ]; then
    printf '%sm%02ss' "$((seconds / 60))" "$((seconds % 60))"
  else
    printf '%sh%02sm' "$((seconds / 3600))" "$(((seconds % 3600) / 60))"
  fi
}

show_download_progress() {
  file="$1"
  total="${2:-0}"
  pid="$3"
  width="${CAT_PROGRESS_WIDTH:-30}"
  mode="${CAT_PROGRESS_MODE:-compact}"
  step="${CAT_PROGRESS_STEP:-10}"
  interval="${CAT_PROGRESS_INTERVAL:-5}"
  start="$(date +%s)"
  last_line=""
  redraw=0
  next_percent=0
  next_elapsed=0

  case "$width" in
    ''|*[!0-9]*) width=30 ;;
  esac
  [ "$width" -ge 10 ] || width=10
  [ "$width" -le 60 ] || width=60
  case "$step" in
    ''|*[!0-9]*) step=10 ;;
  esac
  [ "$step" -ge 1 ] || step=1
  [ "$step" -le 50 ] || step=50
  case "$interval" in
    ''|*[!0-9]*) interval=5 ;;
  esac
  [ "$interval" -ge 1 ] || interval=1
  [ "$interval" -le 60 ] || interval=60

  case "$mode" in
    bar|redraw|single)
      if [ -t 2 ] && [ "${TERM:-}" != "dumb" ]; then
        redraw=1
      fi
      ;;
    compact|line|lines|"")
      redraw=0
      ;;
    *)
      redraw=0
      ;;
  esac

  while kill -0 "$pid" 2>/dev/null; do
    sleep 1
    kill -0 "$pid" 2>/dev/null || break

    bytes="$(progress_file_size "$file")"
    now="$(date +%s)"
    elapsed=$((now - start))
    [ "$elapsed" -gt 0 ] || elapsed=1
    speed=$((bytes / elapsed))

    if [ "$total" -gt 0 ]; then
      percent=$((bytes * 100 / total))
      [ "$percent" -le 100 ] || percent=100
      if [ "$redraw" -eq 0 ] && [ "$percent" -ge 100 ]; then
        continue
      fi
      if [ "$redraw" -eq 0 ] && [ "$percent" -lt "$next_percent" ] && [ "$percent" -lt 100 ]; then
        continue
      fi
      next_percent=$((((percent / step) + 1) * step))
      [ "$next_percent" -le 100 ] || next_percent=100
      filled=$((bytes * width / total))
      [ "$filled" -le "$width" ] || filled="$width"
      empty=$((width - filled))
      eta="$(format_eta "$speed" "$((total - bytes))")"
      line="$(printf 'Downloading [%s%s] %3d%% %s/%s %s/s ETA %s' \
        "$(repeat_char '#' "$filled")" "$(repeat_char '-' "$empty")" \
        "$percent" "$(format_bytes "$bytes")" "$(format_bytes "$total")" "$(format_bytes "$speed")" "$eta")"
    else
      if [ "$redraw" -eq 0 ] && [ "$elapsed" -lt "$next_elapsed" ]; then
        continue
      fi
      next_elapsed=$((elapsed + interval))
      line="$(printf 'Downloading [...] %s %s/s' "$(format_bytes "$bytes")" "$(format_bytes "$speed")")"
    fi

    if [ "$line" != "$last_line" ]; then
      if [ "$redraw" -eq 1 ]; then
        printf '\r\033[2K%s' "$line" >&2
      else
        printf '%s\n' "$line" >&2
      fi
      last_line="$line"
    fi
  done

  bytes="$(progress_file_size "$file")"
  if [ "$total" -gt 0 ]; then
    line="$(printf 'Downloading [%s] 100%% %s/%s complete' \
      "$(repeat_char '#' "$width")" "$(format_bytes "$bytes")" "$(format_bytes "$total")")"
  else
    line="$(printf 'Downloading [done] %s complete' "$(format_bytes "$bytes")")"
  fi
  if [ "$redraw" -eq 1 ]; then
    printf '\r\033[2K%s\n' "$line" >&2
  elif [ "$line" != "$last_line" ]; then
    printf '%s\n' "$line" >&2
  fi
}

if has_cmd pkg; then
  log "installing Termux dependencies"
  pkg install -y proot tar curl ca-certificates xz-utils gzip zstd coreutils
else
  log "Termux pkg not found; assuming runtime dependencies are already installed"
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

log "downloading ${INSTALL_URL}"
download "$INSTALL_URL" "$tmp"

mkdir -p "$(dirname "$TARGET")"
cp "$tmp" "$TARGET"
chmod +x "$TARGET"

log "installed ${TARGET}"
log "run: catainer"
