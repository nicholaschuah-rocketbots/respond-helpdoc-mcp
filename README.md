# Respond.io Help Docs — MCP for Claude Code

This gives Claude Code a live index of every Respond.io help article. Once installed, Claude can answer questions like *"How does Lifecycle work?"* or *"What channels can I connect?"* by reading the official help docs — no hallucinating, no guessing.

---

## Install

> **Before you start:** Make sure you have [Claude Code](https://claude.ai/claude-code) installed and can open a Terminal (on Mac: press `Cmd + Space`, type `Terminal`, press Enter).

Paste this one command into Terminal and press Enter:

```sh
curl -LsSf https://raw.githubusercontent.com/nicholaschuah-rocketbots/respond-help-mcp/main/install.sh | sh
```

The script will:
1. Install `uv` (a Python tool) if you don't have it — takes about 10 seconds
2. Download this project to `~/.local/share/respond-help-mcp`
3. Fetch all ~200 Respond.io help articles and build a local index — takes about 30 seconds
4. Register itself with Claude Code

When it finishes you'll see `✅ All done!`

---

## Verify it works

1. **Quit and reopen Claude Code** — the MCP only loads on startup
2. Type `/mcp` in the Claude Code prompt
3. You should see `respond-help` with a green connected indicator

Then try asking:

> *What does Respond.io help say about connecting WhatsApp?*

Claude should cite a help article by name and walk you through it.

---

## Where things live

| What | Where |
|---|---|
| Install folder | `~/.local/share/respond-help-mcp` |
| Help index (what Claude reads) | `~/.local/share/respond-help-mcp/index.md` |
| MCP registration | `~/.claude.json` (managed automatically) |

**To open the install folder in Finder:** Press `Cmd + Shift + G` in Finder, paste `~/.local/share/respond-help-mcp`, and press Enter.

---

## Refresh the help index

The help index is a snapshot — it won't update itself automatically. Re-run this command in Terminal whenever you want the latest articles (once a month is usually enough):

```sh
cd ~/.local/share/respond-help-mcp && uv run python build_index.py
```

---

## Uninstall

Two commands in Terminal:

```sh
claude mcp remove respond-help
rm -rf ~/.local/share/respond-help-mcp
```

Restart Claude Code and the MCP is gone.

---

## Troubleshooting

**Claude Code doesn't see the MCP after install**
→ Quit Claude Code completely and reopen it. Type `/mcp` to check the status.

**`uv: command not found` error after install**
→ Open a new Terminal tab (the PATH update from the installer only applies to the current session). Then retry.

**`claude: command not found` during install**
→ Claude Code CLI isn't installed. Download it from [claude.ai/claude-code](https://claude.ai/claude-code), install it, open a new Terminal, then re-run the install command.

**`git: command not found` on macOS**
→ Run `xcode-select --install` in Terminal, wait for it to finish, then re-run the install command.

**Some articles are skipped during index build**
→ That's expected. A small number of help articles have formatting quirks that can't be parsed — they're skipped with a warning. The rest of the index is complete.

**How do I see exactly what Claude is reading?**
→ Open `~/.local/share/respond-help-mcp/index.md` in any text editor (TextEdit works). Each line is one help article with its description.
