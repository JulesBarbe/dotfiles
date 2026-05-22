# /dump — Log to Obsidian Vault

Summarize recent conversation context and append it to the project's running log in the Obsidian vault.

## Arguments

$ARGUMENTS is optional guidance for what to log. If empty, summarize the most significant decisions and context from the conversation.

## Steps

1. Get the project name (worktree-safe — use git-common-dir to find the real repo root).
   Run these as **separate Bash calls** (no subshells or chaining):
   - `git rev-parse --path-format=absolute --git-common-dir` → returns a path like `/Users/jules/code/myrepo/.git`
   - From that output, strip the trailing `/.git` and take the last path component as the project name. Use `dirname` and `basename` as separate calls on the result.
   - Fallback if not in a git repo: use `pwd` and take the last path component.

2. Get the context label (worktree directory name for the log heading).
   Run as a **separate Bash call**:
   - `git rev-parse --show-toplevel` → returns the working tree root
   - Take the last path component as the context label via a separate `basename` call.
   - Fallback: same as project name.
   Escape the brackets in the heading as `\[...\]` so Obsidian doesn't parse them as wikilinks.

3. Get the current timestamp via `date '+%Y-%m-%d %H:%M'`

4. Summarize the conversation using $ARGUMENTS as focus. Structure around whichever apply:
   - **Decisions** and their rationale
   - **Architecture** changes or patterns chosen
   - **Trade-offs** and drawbacks acknowledged
   - **Context** that would be lost without documentation
   - **Open questions** or next steps

5. Try reading `Projects/{project-name}/log.md` via `mcp__obsidian__read_note`. If it exists, check the last entry to avoid repeating information that was already logged.

6. If the file doesn't exist, create it with `mcp__obsidian__write_note` (mode: `overwrite`):
   ```markdown
   ---
   project: {project-name}
   type: log
   ---

   # {Project Name} — Log
   ```
   Then append the entry separately.

7. Append the entry via `mcp__obsidian__write_note` (mode: `append`):
   ```markdown

   ---

   ## \[{context-label}\] {YYYY-MM-DD HH:MM} — {brief descriptive title}

   {structured summary using the categories above}
   ```

8. Confirm what was logged in one sentence.

## Rules

- Entries must be self-contained — a reader should understand without conversation access
- Use Obsidian markdown with [[wikilinks]] for cross-references where relevant
- Always include date and time in the heading
- Prioritize conciseness, but let the content dictate the length — a complex architectural discussion warrants more detail than a quick config change
- Don't include code blocks unless essential to understanding a decision
- The MCP server is named `obsidian` — tools are `mcp__obsidian__*`
