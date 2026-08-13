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

### Referring to items by name, not by number
- When you surface a task, decision, option, finding, or open question to me, name it. I have no lookup table in my head: "#9", "T3", "D1", "option 2", "the third one" mean nothing to me out of the blue.
- Lead with a short identifying phrase, and put any ID after it if it's still useful: "the settings merge step (task 4)" — never "task 4" alone.
- Internal use is fine. Track items by whatever IDs you like in tasklists, plans, and your own reasoning. The rule applies at the boundary where you mention one to me.
- This also covers back-references. "As decided earlier" and "per the second finding" are equally unresolvable: restate the thing in three or four words.

## Prose Style

Governs all written English you produce as an artifact: PR descriptions, commit messages, plan files, docs, READMEs, log entries, review comments. Comments and docstrings follow this plus the extra rules under `## Comments`.

- Write like reference documentation, not like a person reporting on their work. Dead, flat, declarative prose. State what the thing is and what it does. The reader wants the mechanism, not the journey.
- Terse by default. Cut every word that carries no information. Shorter and drier is almost always better.
- Describe the code, not the act of writing it. No "I refactored", "we then added", "this change introduces", "as requested", "now handles". Say what the code does in the present tense: "Retries on 429 with exponential backoff."
- No selling and no ceremony. Cut "robust", "seamless", "powerful", "comprehensive", "significantly improves", "cleanly handles", "it's worth noting", "importantly", "in order to". Cut praise of the design entirely.
- No hedging. "Should generally work", "might possibly", "tends to" either state a real condition or get deleted. If behavior is conditional, name the condition.
- No rhetorical scaffolding. No "Let's", no questions you then answer, no numbered walkthroughs of your own thought process, no closing summary that repeats the opening.
- Prefer concrete nouns and verbs over abstractions. "Parses the manifest" beats "handles manifest processing logic".
- Bad: "This PR significantly improves the sync flow by introducing a new, more robust merge helper that we then use to cleanly combine the public and private settings files." Good: "Merges public and private settings via `jq`; private keys win on conflict."

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
- At commit boundaries, do NOT offer to run tests, launch the app, or otherwise verify locally — I do all pre-commit verification myself. Instead, hand me a runnable summary: (1) what the task accomplished and what's now possible, (2) the exact commands to run, in order, to test it, (3) what to look out for / signs it's working, then ask if I'm ready to move on. Assume I'm doing the verification and the commit.
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

`## Prose Style` applies here too; the rules below add to it and win where they conflict.

- Comments are a last resort, not a default. Most code should carry none. Only add one when the code genuinely can't speak for itself: a non-obvious constraint, a subtle invariant, a "why it must be this way" that isn't visible from the code.
- Comments may (and should) express INTENTION: what this is for, why it must hold. But only intention that stands on its own in the current state of the codebase. A future reader with zero knowledge of our conversation must find it useful and correct.
- NEVER tie a comment to the act of changing the code or to context that isn't in the file. No narrating the diff, the session, or a decision: no "added per request", "changed to fix...", "new helper for...", "renamed from...", "as discussed", "now handles...", "switched to...". If a comment only makes sense to someone who watched me write it, it must not exist.
- No LLM-speak, anywhere. No hedging ("this should generally"), no self-narration ("here we...", "we now..."), no ceremonial framing ("it's worth noting", "importantly,"), no restating the code in prose. Technical and direct.
- NEVER use em dashes in comments or docstrings. Use commas, colons, parens, or two short clauses instead.
- Inline comments: terse and telegraphic. Drop filler connectives ("we", "this", "because", "the"), lean on commas/colons, keep the load-bearing nouns and the *why*. "list not tuple: caller mutates in place", not "this needs to be a list because the caller mutates it". Shortened, not cryptic: real words, just no filler. All lowercase (inline only; docstrings keep normal capitalization).
- Docstrings and block comments: fuller sentences, but still lean, telegraphic, and technical. State what it does, the non-obvious contract, and any invariant. Don't restate the signature or pad with framing.
- Don't add comments to code I didn't ask you to comment.
- Do NOT change comments that already exist in the file. These rules govern only comments I add.

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
