#!/usr/bin/env sh
# install.sh — installs the Respond.io Help Docs MCP for Claude Desktop (and Claude Code if present)
# Usage: curl -LsSf https://raw.githubusercontent.com/nicholaschuah-rocketbots/respond-helpdoc-mcp/main/install.sh | sh

set -e

INSTALL_DIR="$HOME/.local/share/respond-helpdoc-mcp"
REPO_URL="https://github.com/nicholaschuah-rocketbots/respond-helpdoc-mcp.git"

echo ""
echo "Respond.io Help Docs MCP — Installer"
echo "======================================"
echo ""

# ── 1. Prerequisites ──────────────────────────────────────────────────────────

echo "→ Checking prerequisites..."

if ! command -v git >/dev/null 2>&1; then
  echo ""
  echo "❌  git not found."
  echo "    On macOS, run: xcode-select --install"
  echo "    Then re-run this installer."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo ""
  echo "❌  python3 not found."
  echo "    On macOS, run: xcode-select --install"
  echo "    Then re-run this installer."
  exit 1
fi

# ── 2. Install uv if missing ──────────────────────────────────────────────────

if ! command -v uv >/dev/null 2>&1; then
  echo "→ Installing uv (Python package manager)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Make uv available in this shell session
  export PATH="$HOME/.local/bin:$PATH"
  echo "   uv installed."
else
  echo "   uv already installed — skipping."
fi

# ── 3. Clone or update the repo ───────────────────────────────────────────────

echo "→ Installing to $INSTALL_DIR ..."
mkdir -p "$(dirname "$INSTALL_DIR")"

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "   Existing install found — updating..."
  git -C "$INSTALL_DIR" pull --ff-only --quiet
else
  git clone --depth 1 --quiet "$REPO_URL" "$INSTALL_DIR"
  echo "   Downloaded."
fi

# ── 4. Install Python dependencies ────────────────────────────────────────────

echo "→ Installing Python dependencies..."
cd "$INSTALL_DIR"
uv sync --quiet
echo "   Done."

# ── 5. Build the help index ───────────────────────────────────────────────────

echo "→ Building help index (fetching ~200 articles — takes about 30 seconds)..."
uv run python build_index.py 2>&1 | grep -E "^(Found|Built|ERROR)" || true
echo "   Index built."

# ── 6. Register with Claude Desktop ───────────────────────────────────────────
# Claude Desktop does not inherit the shell PATH, so we must pass the absolute
# path to `uv`. We edit its JSON config directly (no CLI exists for this).

UV_PATH="$(command -v uv)"

case "$(uname -s)" in
  Darwin) CLAUDE_DESKTOP_DIR="$HOME/Library/Application Support/Claude" ;;
  Linux)  CLAUDE_DESKTOP_DIR="$HOME/.config/Claude" ;;
  *)      CLAUDE_DESKTOP_DIR="" ;;
esac

if [ -n "$CLAUDE_DESKTOP_DIR" ]; then
  echo "→ Registering MCP server with Claude Desktop..."
  mkdir -p "$CLAUDE_DESKTOP_DIR"
  CLAUDE_DESKTOP_CFG="$CLAUDE_DESKTOP_DIR/claude_desktop_config.json"
  python3 - "$CLAUDE_DESKTOP_CFG" "$UV_PATH" "$INSTALL_DIR" <<'PY'
import json
import sys
from pathlib import Path

cfg_path = Path(sys.argv[1])
uv_path = sys.argv[2]
install_dir = sys.argv[3]

if cfg_path.exists() and cfg_path.read_text().strip():
    try:
        cfg = json.loads(cfg_path.read_text())
    except json.JSONDecodeError:
        print(f"   WARNING: {cfg_path} is not valid JSON — not modifying it.")
        print(f"   Add this manually under mcpServers: ")
        print(f'     "respond-help": {{"command": "{uv_path}",')
        print(f'       "args": ["--directory", "{install_dir}", "run", "python", "server.py"]}}')
        sys.exit(0)
else:
    cfg = {}

cfg.setdefault("mcpServers", {})["respond-help"] = {
    "command": uv_path,
    "args": ["--directory", install_dir, "run", "python", "server.py"],
}

cfg_path.write_text(json.dumps(cfg, indent=2) + "\n")
print(f"   Registered in {cfg_path}")
PY
else
  echo "   Unsupported OS for Claude Desktop auto-registration — skipping."
fi

# ── 7. Register with Claude Code (if installed) ───────────────────────────────

if command -v claude >/dev/null 2>&1; then
  echo "→ Registering MCP server with Claude Code..."
  claude mcp remove respond-help --scope user 2>/dev/null || true
  claude mcp add respond-help --scope user uv -- --directory "$INSTALL_DIR" run python server.py
  echo "   Registered."
else
  echo "   Claude Code CLI not found — skipping (only Claude Desktop was set up)."
fi

# ── Done ──────────────────────────────────────────────────────────────────────

cat <<EOF

✅  All done!

   Help index:   $INSTALL_DIR/index.md
   To refresh:   cd "$INSTALL_DIR" && uv run python build_index.py

Next step: fully quit Claude Desktop (Cmd+Q on Mac, right-click tray icon →
Quit on Windows/Linux) and reopen it. Then try asking:

   "What does respond.io help say about connecting WhatsApp?"
EOF
