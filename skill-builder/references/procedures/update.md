## Update Command Procedure

<!-- Relocated verbatim from SKILL.md (2026-07-01 optimize): the update command's inline procedure moved here; the SKILL.md command table links to this file. -->

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `update` Command

Re-run the installer to update skill-builder to the latest version.

The installer issues many file writes and bash calls in sequence. Without auto-accept, the user will be prompted to approve each one. Claude Code does NOT expose a way for a skill to flip the session into "accept edits on" mode programmatically, nor to detect the current permission mode at runtime — mode changes require the user to press Shift+Tab. The procedure below therefore prompts the user to enable auto-accept before the installer runs.

**CHECKPOINT — fires when `/skill-builder update` is invoked:**

1. **BEFORE running the installer**, output this notice to the user verbatim and STOP for their acknowledgement:

   > **Before I run the installer, please enable "accept edits on" mode so you don't get prompted for every file write and bash call.**
   >
   > Press **Shift+Tab** until the prompt indicator shows **"accept edits on"** (it cycles: default → accept edits on → plan mode).
   >
   > I cannot detect or set this mode from inside the session — it has to be you. Reply with anything (e.g., "go") once it's enabled and I'll run the installer.

2. After the user acknowledges, select the installer by platform. Read the `Platform:` line from the session environment context (a concrete read, no judgment, no agent):
   - IF platform is `linux` or `darwin` (macOS) → run via the shell tool: `bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"`
   - IF platform is `windows`/`win32` → run via the shell tool: `powershell -NoProfile -Command "irm https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install.ps1 | iex"` (this works whether the session's shell tool is Git Bash or PowerShell, so no shell detection is needed)
   - IF the platform line is absent or unrecognized → ask the user which OS they are on before running anything.
   Both installers consume the same shared `manifest.txt`, so they ship identical content.
3. Tell the user: **"Restart Claude Code to load the updated skill."** The current session still has the old skill loaded in memory, so start a new conversation. Once you're back, run `/skill-builder audit` — updates often add new recommendations that apply to your existing skills.
<!-- /origin -->
