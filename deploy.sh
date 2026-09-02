#!/usr/bin/env bash
# Build the site with the PINNED Hugo (Extended) and publish it to the web root.
#
#   ./deploy.sh                 # pull, build, publish to $WEBROOT
#   ./deploy.sh --no-pull       # build from the working tree as-is
#   WEBROOT=/path ./deploy.sh   # override the publish dir
#
# Hugo is a BUILD tool, not a runtime — pin it and update deliberately (bump
# .hugoversion, run locally, commit). There's no security clock forcing updates;
# the box's nginx / OS / certbot are what stay current. See README.
set -euo pipefail

cd "$(dirname "$0")"

WEBROOT="${WEBROOT:-/var/www/puckaround.misaki.fi}"
HUGO_VERSION="$(tr -d '[:space:]' < .hugoversion)"

# --- ensure the pinned Hugo Extended is available ---------------------------
# On the deploy target (Linux) we download + cache the pinned Extended binary so
# the box's system Hugo never decides the build — reproducible, no root. On macOS
# (local dev) Hugo ships only as a universal .pkg, so fall back to the system
# `hugo` (e.g. Homebrew) rather than fetch a nonexistent tarball.
BIN_DIR="${HOME}/.local/share/puckaround-hugo"
HUGO="${BIN_DIR}/hugo-${HUGO_VERSION}"

if [[ "$(uname -s)" == "Linux" ]]; then
  if [[ ! -x "$HUGO" ]]; then
    echo "Installing Hugo Extended ${HUGO_VERSION} → ${HUGO}"
    case "$(uname -m)" in
      x86_64|amd64) arch="amd64" ;;
      aarch64|arm64) arch="arm64" ;;
      *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
    esac
    url="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${arch}.tar.gz"
    mkdir -p "$BIN_DIR"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" -o "${tmp}/hugo.tar.gz"
    tar -xzf "${tmp}/hugo.tar.gz" -C "$tmp" hugo
    install -m 0755 "${tmp}/hugo" "$HUGO"
    rm -rf "$tmp"
  fi
else
  # Local dev (macOS et al.): use whatever `hugo` is on PATH.
  HUGO="$(command -v hugo || true)"
  [[ -x "$HUGO" ]] || { echo "No 'hugo' on PATH — install Hugo Extended." >&2; exit 1; }
  installed="$("$HUGO" version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tr -d v || true)"
  [[ "$installed" == "$HUGO_VERSION" ]] || \
    echo "Note: local hugo ${installed:-?} != pinned ${HUGO_VERSION} (fine for preview; the Linux deploy uses the pin)."
fi

# Guard: the build needs the EXTENDED build (fingerprint/minify asset pipeline).
if ! "$HUGO" version | grep -q "extended"; then
  echo "ERROR: ${HUGO} is not the Extended build." >&2
  exit 1
fi

# --- pull, build, publish ---------------------------------------------------
if [[ "${1:-}" != "--no-pull" ]]; then
  git pull --ff-only
fi

echo "Building with $("$HUGO" version)"
"$HUGO" --gc --minify --cleanDestinationDir -d "$WEBROOT"

echo "Published to ${WEBROOT}"
