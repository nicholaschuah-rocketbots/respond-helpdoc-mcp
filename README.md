# Respond.io Help Docs — for Claude Desktop

## What is this?

This is a little add-on for **Claude Desktop** that gives Claude a live copy of every Respond.io help article.

Think of it like giving Claude a **bookshelf full of the official Respond.io manuals**. Once this is installed, when you ask Claude a question about Respond.io, it will go and look it up in the real help docs instead of guessing from memory. That means:

- ✅ Real answers from the real help center
- ✅ Claude can quote the article it used
- ❌ No more made-up features or outdated instructions

You only have to install it once. After that, it just works.

---

## How to install

> **Before you start:** Make sure you have **Claude Desktop** installed. If you don't, download it from [claude.ai/download](https://claude.ai/download).

**Step 1.** Open the Terminal app on your Mac. (Press `Cmd + Space`, type `Terminal`, press Enter.)

**Step 2.** Copy the line below, paste it into Terminal, and press Enter:

```sh
curl -LsSf https://raw.githubusercontent.com/nicholaschuah-rocketbots/respond-helpdoc-mcp/main/install.sh | sh
```

**Step 3.** Wait. You'll see a few progress lines. It takes about a minute — most of that is downloading ~200 help articles.

**Step 4.** When you see `✅ All done!`, you're finished. Quit Claude Desktop completely (`Cmd + Q`) and reopen it.

---

## How to check it's working

Inside Claude Desktop:

1. Open any chat.
2. Look at the small icons near the message box. You should see a **tool / plug icon** that says something like *"Search and tools"* when you hover.
3. Click it. In the list of connected tools you should see **respond-help**.

If it's there — you're good.

Still not sure? Just try asking Claude:

> *Using respond-help, what does Respond.io say about connecting WhatsApp?*

If Claude replies with a real answer that references a help article, it's working. If Claude says *"I don't have that tool"* — quit and reopen Claude Desktop, then try again.

---

## How to use it

You don't need to do anything special — just **talk to Claude like you normally would** and ask about Respond.io. Claude will decide to reach into the help docs whenever it makes sense.

Examples you can copy:

| Ask Claude this | What happens |
|---|---|
| *"What does respond.io help say about Lifecycle?"* | Claude looks up the relevant article and explains it to you |
| *"Walk me through connecting a WhatsApp Business channel."* | Claude fetches the article and walks you through the steps |
| *"What channels can I connect to respond.io?"* | Claude scans the index and lists the options |
| *"Compare AI Agent and Workflows in respond.io."* | Claude pulls both articles and summarises them |

**Tip:** If Claude ever gives you an answer that feels generic or made-up, reply with *"Please check the respond help docs first"*. That nudges it to use this add-on.

---

## Keeping the help docs fresh

Here's the thing: this add-on stores a **snapshot** of the help center on your computer. When Respond.io publishes new help articles or updates old ones, your snapshot won't know about it until you refresh.

### What "rebuild index" means

It's just a fancy way of saying *"go download the latest list of help articles."* The add-on re-reads Respond.io's help center, re-builds the local list, and saves it. Takes about 30 seconds.

### When should I do it?

- Once a month, to pick up new articles
- Anytime Respond.io announces a new feature
- Anytime Claude says it can't find an article you know exists

### How do I do it?

**The easy way — just ask Claude:**

> *"Please rebuild the respond help index."*

Claude will run the refresh for you and tell you how many articles it found. That's it.

**The manual way** (only if Claude Desktop is closed or you'd rather do it yourself):

Open Terminal and paste:

```sh
cd ~/.local/share/respond-helpdoc-mcp && uv run python build_index.py
```

---

## How to remove it

If you ever want to uninstall, open Terminal and run:

```sh
rm -rf ~/.local/share/respond-helpdoc-mcp
```

Then open this file in any text editor:

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

Find the section called `"respond-help"` and delete it (keep the rest of the file alone). Restart Claude Desktop.

---

## If something goes wrong

**Claude doesn't show `respond-help` in the tool list**
→ You probably didn't fully quit Claude Desktop. Press `Cmd + Q` (not just close the window), then reopen.

**"`uv: command not found`" after install**
→ Close Terminal and open a new Terminal window, then re-run the install command.

**"`git: command not found`" on macOS**
→ Run `xcode-select --install` in Terminal, wait for it to finish, then re-run the install command.

**"Some articles were skipped during build"**
→ Totally fine. A handful of help articles have odd formatting that the tool can't parse. The other ~195 are there.

**Where is the help index stored?**
→ `~/.local/share/respond-helpdoc-mcp/index.md`. Open it in TextEdit if you're curious — it's just a plain list of every article Claude can reach.
