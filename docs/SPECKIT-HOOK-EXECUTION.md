# Spec Kit Hook Execution Guide

This document defines the **canonical invocation patterns** for Spec Kit extension hooks in the `uranos` repository. All `.github/agents/speckit.*.agent.md` templates reference this file.

## Hook Source

Hooks are declared in `.specify/extensions.yml` under keys like `hooks.before_analyze`, `hooks.after_tasks`, etc. Each hook has:

| Field         | Required | Description                                      |
|---------------|----------|--------------------------------------------------|
| `extension`   | yes      | Extension name / identifier                      |
| `command`     | yes      | The hook command id (e.g. `speckit-analyze-lint`)|
| `description` | no       | Human-readable description                       |
| `prompt`      | no       | Prompt text for optional hooks                   |
| `optional`    | no       | `true` = user must opt-in; `false` = auto-run    |
| `enabled`     | no       | `false` skips the hook; default `true`           |
| `condition`   | no       | Runtime condition (left to HookExecutor)         |

## Invocation Patterns

The `{command}` placeholder in agent templates maps to a concrete invocation depending on the agent runtime environment:

### 1. VS Code Copilot Chat (skills-mode)

```
/skill:{command}
```

Example: `{command}` = `speckit-analyze-lint` → invoke `/skill:speckit-analyze-lint`

### 2. OpenAI Codex

```
${command}
```

Example: `{command}` = `speckit-analyze-lint` → invoke `$speckit-analyze-lint`

### 3. Claude Code

```
/{command}
```

Example: `{command}` = `speckit-analyze-lint` → invoke `/speckit-analyze-lint`

### 4. Generic CLI / Shell

If the hook maps to a shell script or CLI tool:

```bash
npx {command}
```

Or if a local script exists at `.specify/hooks/{command}.sh`:

```bash
bash .specify/hooks/{command}.sh
```

### 5. Qodo IDE Plugin (workflow)

```
/{command}
```

Example: `{command}` = `speckit-analyze-lint` → invoke `/speckit-analyze-lint` in Qodo chat

## Execution Rules

1. **Mandatory hooks** (`optional: false`): Execute immediately after emitting the hook block. Wait for completion before proceeding.
2. **Optional hooks** (`optional: true`): Present to the user. Execute only if the user confirms.
3. **Disabled hooks** (`enabled: false`): Skip silently.
4. **Conditional hooks** (non-empty `condition`): Skip — leave condition evaluation to the HookExecutor implementation.
5. **Failed hooks**: If a mandatory hook fails, halt the agent workflow and report the error. Optional hook failures are non-blocking.
6. **Emitting ≠ executing**: Writing the hook block to output does NOT execute the hook. You MUST separately invoke the command using the patterns above.

## Detection Logic

To determine the current runtime environment:

| Signal                              | Environment              |
|-------------------------------------|--------------------------|
| `COPILOT_CHAT_SESSION` env var      | VS Code Copilot Chat     |
| `CODEX_SESSION` env var             | OpenAI Codex             |
| `CLAUDE_CODE_SESSION` env var       | Claude Code              |
| `.specify/hooks/{command}.sh` exists| Generic CLI / Shell      |
| Qodo IDE Plugin active              | Qodo IDE Plugin          |

If the environment cannot be detected, fall back to the generic CLI pattern (`npx {command}`).
