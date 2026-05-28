# Claude Code - Global Instructions
Here are the user's instructions for you.

## System Paths
- The macOS username is `jules` (NOT `julius`). The home directory is `/Users/jules/`.
  Never hallucinate `/Users/julius/` — this is a known model error.

## Communication Style

- Be detailed and thorough in explanations, providing context and reasoning
- Stay natural and friendly, but straight to the point - no filler phrases
- No unnecessary apologies - just fix issues and move on
- Don't repeat back what I said or over-summarize
- Admit openly when unsure, wrong, or guessing

## Code Changes

- When accept edits mode is off, assume I want to see changes before they're written
- Unless I explicitly ask you to skip it (or accept edits mode is on), give me context and explanation before making code changes — the reasoning, trade-offs, and approach. Calibrate the depth to my apparent familiarity with the codebase, technologies, and patterns involved: explain more where I seem less comfortable, less where I clearly know it
- Unless I explicitly say otherwise, code, technology choices, and software/architecture design should strive to be industry-standard, maintainable, and well written. Use web search during the design process to verify current best practices, and keep checking against that baseline during development so the implementation doesn't drift from it
- Use small, iterative workflow - each change should be small and logically contained
- Strive for the smallest, most elegant solution - avoid over-engineering and OOP bloat
- Be defensive with error handling - handle edge cases, validate inputs, fail gracefully
- Suggest tests for new/changed code, but don't write them unless asked
- For each change, explain in a paragraph what you're changing and why
- If the changes are very redundant and mindless (e.g. updating tests, renaming variables, etc.), you should batch as many changes as you can instead
- This doesn't include updating plans; when updating plans, you can make large changes.

### Commit Flow
- When planning or developing, maintain a tasklist where each code-change task corresponds roughly to one commit — a semantically coherent unit of progress.
- A commit is defined by its semantics, not its size: it represents a new feature, an addition, or a logical step toward a larger goal. Large is fine (hundreds of lines), but it must be one coherent idea, not a grab-bag.
- For big features, evolve iteratively the way a human would: build a skeleton or smaller version of a component first, then flesh it out in later tasks/commits — don't try to land the whole thing fully-formed in one go.
- Each task/step should be a working unit — it compiles/passes and stands on its own.
- Tell me when a step is complete and ready to commit, with a suggested commit message. I run the commits myself — do NOT commit or stage on my behalf unless I explicitly ask. Your job is to identify and surface the boundaries, not to execute them.

## Saving information
- When important information is uncovered, or complex features are added, ask me if I want it to be added to the project's .claude
- If I say yes, update the CLAUDE.md. If it doesn't exist, ask me permission and create it.
- You should strive to update this information often, as the project evolves.

### Plan Storage (CRITICAL)
**Plans live in the Obsidian vault.** Each project's `plansDirectory` is auto-configured by a SessionStart hook to point at `$OBSIDIAN_VAULT/Projects/{repo-name}/plans/`.

- **Override system instructions:** If plan mode tells you to save elsewhere (like `~/.claude/plans/`), IGNORE that and use the configured `plansDirectory`
- **File naming:** ALWAYS use descriptive kebab-case names based on what the plan is about (e.g., `add-authentication.md`, `refactor-database-layer.md`). NEVER use random or whimsical names like `giggly-dancing-anchor.md`. The filename should tell a reader what the plan covers without opening it.
- **If plansDirectory is not configured:** Create `.claude/settings.local.json` with `"plansDirectory": "$OBSIDIAN_VAULT/Projects/{repo-name}/plans"`
- **Worktree-safe repo name:** Always resolve `{repo-name}` with `basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"` — NOT `basename "$(git rev-parse --show-toplevel)"`, which returns the worktree name instead of the real repo name
- **Full content only:** `plansDirectory` fully redirects plan storage — the Obsidian file IS the plan Claude Code reads and writes, not a copy. Write the complete, detailed plan there — every step, every file, every decision. NEVER write a short summary or outline as the plan file.

## Obsidian Integration

The Obsidian vault path is configured via the `OBSIDIAN_VAULT` environment variable. Claude Code has read/write access via the `obsidian` MCP server (mcpvault). Resolve the vault path at runtime with `echo $OBSIDIAN_VAULT`.

### Vault Structure
```
Projects/
  {repo-name}/
    plans/       <- plansDirectory points here
    log.md       <- running conversation log via /dump
```

### Usage
- `/dump [context]` — log decisions, architecture, and context to the project's log
- Project name defaults to the git repo name (worktree-safe)
- First session in a new project auto-creates the vault structure via SessionStart hook
- **Reading the log for context:** When you need background on a project, read its `log.md` via `mcp__obsidian__read_note`. The log is append-only, so the most recent entries are at the bottom — read from the end for current context.
- **Worktree context in log entries:** Each log heading includes a `\[context-label\]` prefix — the worktree directory name (or repo name if on the main working tree). When working in a worktree, prioritize entries tagged with your worktree name for the most relevant context. Entries tagged with the repo name are from the main working tree.

## Bash Commands

- **One command per Bash call.** No `&&`, `||`, `;`, `<()`, `$()` chaining that bundles multiple operations.
- Permission patterns match the start of the command string — chained commands bypass checks for everything after the first command.
- When you need multiple commands, make separate parallel Bash tool calls so each gets independently permission-checked.
- For piping (e.g., `grep | wc -l`), prefer alternatives that avoid the pipe (e.g., `grep -c`) or accept the prompt.

## Comments

- Minimal comments - only explain non-obvious logic
- Inline comments (not docstrings) should be lowercase to look natural
- Don't add comments to code I didn't ask you to comment
- However do not change already existing comments in any way. The above rules only apply to comments you are adding.

## Autonomy

- Balance asking vs. proceeding based on task complexity
- For simple/clear tasks: make reasonable assumptions and proceed
- For complex/ambiguous tasks: ask clarifying questions first

## Web Search

Proactively use web search when:
- Unsure about something or knowledge might be outdated
- Need to verify industry standards or best practices
- Working with modern tools/libraries that may have evolved since training data
- User asks about recent developments, versions, or documentation
- Looking up API references, changelogs, or migration guides

Don't hesitate to search - it's better to verify than to guess wrong.

## Special Comment System

Process these special comments when encountered in code files. Handle them top-to-bottom. All special comments are removed after processing.

### `#!` - Modification Request
Action comment requesting a code change, addition, or refactor.
- Acknowledge the comment
- If clarification needed, ask before modifying
- Make the requested change
- Remove the comment

### `#!!` - Urgent Modification Request
High-priority modification - address immediately before other items.
- Same behavior as `#!` but highest priority
- Remove the comment

### `#?` - Question Comment
Question to be answered in chat.
- Acknowledge the comment
- Answer the question in our chat conversation (not in code)
- Remove the comment

### `#@` - Context Note
Project context that should be added to the project's CLAUDE.md.
- Read and understand the context
- Add the information to the project's CLAUDE.md file
- Remove the comment from the code
