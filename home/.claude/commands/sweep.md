# /sweep — Process Special Comments

Scan the project for special comments (`#!`, `#!!`, `#?`, `#@`) and process them according to their type. These are inline action items embedded in source code.

## Arguments

$ARGUMENTS optionally restricts the scan to specific files or directories (e.g., `src/` or `config.py`). If empty, scan the entire project.

## Comment Types (in priority order)

1. **`#!!`** — Urgent modification request. Process these FIRST, before anything else.
2. **`#!`** — Modification request. Make the requested code change.
3. **`#?`** — Question. Answer in chat (not in code).
4. **`#@`** — Context note. Add the information to the project's CLAUDE.md.

## Steps

1. **Discover** — Search for special comments across the project. Use `grep -rn` with appropriate patterns to find all four types. Respect .gitignore (use `git ls-files` or `rg` if available). Exclude binary files and common non-source directories (node_modules, .git, __pycache__, etc.).

   Search scope: $ARGUMENTS if provided, otherwise the project root.

   Run separate searches for each comment type so they can be triaged independently:
   - `rg -n '#!!'` (urgent mods — must not match `#!` without the second `!`)
   - `rg -n '#!'` (mods — filter out `#!!` matches, `#!:` shebang lines, and CSS hex colors)
   - `rg -n '#\?'` (questions)
   - `rg -n '#@'` (context notes)

   Skip results from files that **document** the comment system (e.g., CLAUDE.md files describing the `#!` syntax, or this skill file itself). Only match lines where the marker is an actionable inline comment, not documentation about the system.

2. **Report** — Present a summary of all found comments, grouped by type, showing file paths, line numbers, and the comment text. Ask the user to confirm before proceeding, unless there are 3 or fewer comments total.

3. **Triage** — Process in strict priority order:
   - All `#!!` comments first (urgent)
   - Then process remaining comments file-by-file, top-to-bottom within each file

4. **Process each comment** according to its type:

   **`#!!` and `#!` (Modification Requests):**
   - Read the surrounding code for context
   - Make the requested change
   - Remove the comment
   - Briefly explain what you changed

   **`#?` (Questions):**
   - Read the surrounding code for context
   - Answer the question in chat
   - Remove the comment

   **`#@` (Context Notes):**
   - Read the context note
   - Add the information to the project's CLAUDE.md (create if it doesn't exist — ask first)
   - Remove the comment
   - Confirm what was added

5. **Summary** — After processing all comments, give a brief summary: how many of each type were processed, and any that were skipped or need follow-up.

## Rules

- Always remove the special comment after processing it — that's the contract.
- For `#!`/`#!!`: if the request is ambiguous or would be a large change, ask for clarification before modifying. Don't guess on big changes.
- For `#?`: answer in the conversation, never modify code beyond removing the comment.
- For `#@`: only add to CLAUDE.md — don't modify other code beyond removing the comment.
- Process one comment at a time. Don't batch modifications that could conflict.
- If a file has multiple special comments, process them top-to-bottom (after all `#!!` globally).
- Shebangs (`#!/...`) are NOT special comments — ignore them.
- CSS/hex patterns like `#fff` are NOT special comments — ignore them.
- Comments must start with the marker at the beginning of the comment portion (e.g., `// #!` or `# #!` or `/* #! */`), not embedded in other text.
