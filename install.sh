#!/usr/bin/env sh
# install.sh — installs the Respond.io Help Docs MCP for Claude Code
# Usage: curl -LsSf https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/respond-help-mcp/main/install.sh | sh

set -e

INSTALL_DIR="$HOME/.local/share/respond-help-mcp"
REPO_URL="https://github.com/YOUR_GITHUB_USERNAME/respond-help-mcp.git"

echo ""
echo "Respond.io Help Docs MCP — Installer"
echo "======================================"
echo ""

# ── 1. Prerequisites ──────────────────────────────────────────────────────────

echo "→ Checking prerequisites..."

if ! command -v claude >/dev/null 2>&1; then
  echo ""
  echo "❌  Claude Code CLI not found."
  echo "    Install it from: https://claude.ai/claude-code"
  echo "    Then re-run this installer."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo ""
  echo "❌  git not found."
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

# ── 6. Register with Claude Code ──────────────────────────────────────────────

echo "→ Registering MCP server with Claude Code..."
claude mcp remove respond-help --scope user 2>/dev/null || true
claude mcp add respond-help --scope user uv -- --directory "$INSTALL_DIR" run python server.py
echo "   Registered."

# ── Done ──────────────────────────────────────────────────────────────────────

cat <<EOF

✅  All done!

   Help index:    $INSTALL_DIR/index.md
   To refresh:    cd "$INSTALL_DIR" && uv run python build_index.py
   To uninstall:  claude mcp remove respond-help && rm -rf "$INSTALL_DIR"

Restart Claude Code, then type /mcp to confirm respond-help is connected.
EOF
