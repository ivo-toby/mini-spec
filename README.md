# MiniSpec

**Pair programming with AI that actually works.**

## The Problem

Spec-driven AI development has a fundamental flaw: AI generates hundreds of lines of code, then dumps it on engineers to review. This creates two issues:

1. **Review fatigue** - You're staring at a 500-line PR for code you didn't write. Your eyes glaze over. Things slip through.

2. **Lost mental models** - You become a tourist in your own codebase. You didn't write it, so you don't really understand it. Debugging becomes archaeology.

The current approach:
```
AI works alone → dumps massive PR → Engineer reviews (or pretends to)
```

## The Solution

MiniSpec flips the model. Instead of AI working alone and engineers reviewing after, it's pair programming:

- **Engineer = Navigator** - You make decisions, ask questions, approve small chunks
- **AI = Driver** - Implements, documents, explains

```
AI + Engineer work together → small chunks reviewed continuously → understanding built
```

## Quick Start

### Install

```bash
uv tool install minispec-cli --from git+https://github.com/ivo-toby/mini-spec.git
```

Or run directly:
```bash
uvx --from git+https://github.com/ivo-toby/mini-spec.git minispec init my-project
```

### Initialize a Project

```bash
minispec init my-project --ai claude
cd my-project
claude
```

### The Workflow

1. **`/minispec.constitution`** - Set up project principles and preferences (chunk size, autonomy level)

2. **`/minispec.walkthrough`** - Get oriented in an existing codebase (skip for greenfield)

3. **`/minispec.design "feature description"`** - Interactive design conversation. AI asks questions, presents options with trade-offs, you make decisions.

4. **`/minispec.tasks`** - Break design into reviewable chunks. You adjust groupings and priorities.

5. **`/minispec.analyze`** - Validate design-to-task alignment before implementing.

6. **`/minispec.next`** - Implement one chunk at a time. AI explains, implements 20-80 lines, you review and approve. Repeat.

7. **`/minispec.status`** - See where you are, what's next.

## Commands

| Command | Purpose |
|---------|---------|
| `/minispec.constitution` | Set up project principles + preferences |
| `/minispec.walkthrough` | Guided codebase tour |
| `/minispec.design` | Interactive design conversation |
| `/minispec.tasks` | Break design into reviewable chunks |
| `/minispec.analyze` | Validate design ↔ tasks alignment |
| `/minispec.next` | Implement next chunk (pair programming loop) |
| `/minispec.checklist` | Generate quality checklists for requirements |
| `/minispec.validate-docs` | Check documentation freshness |
| `/minispec.status` | Show progress dashboard |

## How It's Different

| | Traditional Spec-Driven | MiniSpec |
|---|---|---|
| **Planning** | AI generates document | Interactive conversation |
| **Implementation** | All at once, massive PR | Small chunks, continuous review |
| **Engineer role** | Reviewer (post-hoc) | Navigator (real-time) |
| **Documentation** | Manual | Automatic byproduct |
| **Mental model** | Hope you read carefully | Built through dialogue |

## Example Session

```
> /minispec.design "add user authentication"

AI: "Let's design authentication. First: what's your expected user scale?"

> Around 5000 users

AI: "For ~5000 users, both session-based and JWT work.
    Given your Kubernetes setup, JWT is simpler operationally.
    Trade-offs are [...]
    Preference?"

> JWT makes sense

AI: "Documenting this in decisions/001-jwt-auth.md.
    Next question: client-side token storage..."

[conversation continues through all decisions]

> /minispec.tasks

AI: "Based on your 'medium chunk' preference (40-80 lines),
    I propose 8 tasks:
    1. User model + migration (45 lines)
    2. Password hashing utilities (35 lines)
    [...]
    Adjust any groupings?"

> Looks good

> /minispec.next

AI: "Task 1/8: User model + migration

    Creating:
    - src/models/user.ts
    - src/migrations/001-create-users.ts

    [implements ~45 lines]

    Review above. Questions, changes, or ready to commit?"

> Why nullable for lastLoginAt?

AI: "It's null until first login - distinguishes 'never logged in'
    from 'logged in recently'. Want it to default to createdAt instead?"

> Nullable is fine. Commit.

AI: "Committed. 7 tasks remaining. /minispec.next when ready."
```

## Configurable Preferences

Set these during `/minispec.constitution`:

**Review Chunk Size**
- Small (20-40 lines) - Maximum engagement
- Medium (40-80 lines) - Balanced (recommended)
- Large (80-150 lines) - Move faster
- Adaptive - AI asks based on complexity

**Autonomy Level**
- Always confirm - Pause after every chunk
- Tests passing - Auto-proceed if tests pass
- Familiar areas - Auto-proceed in reviewed code
- Explicit batch - Only when you say "next 3"

**Documentation Review**
- Review all changes
- Only review decisions
- Trust AI (recommended)

## Project Structure

```
.minispec/
├── memory/
│   └── constitution.md          # Project principles + preferences
├── specs/
│   └── [feature-name]/
│       ├── design.md            # Feature design
│       ├── tasks.md             # Implementation tasks
│       └── checklists/          # Quality checklists
└── knowledge/
    ├── architecture.md          # System overview
    ├── conventions.md           # Code patterns
    ├── decisions/               # ADRs (auto-created)
    ├── patterns/                # Code patterns (auto-created)
    └── modules/                 # Module docs (auto-created)
```

## Prerequisites

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) for package management
- An AI coding agent (Claude Code, Cursor, etc.)

## Supported AI Agents

MiniSpec works with any AI agent that supports slash commands:

- Claude Code
- Cursor
- GitHub Copilot
- Gemini CLI
- Qwen Code
- And [many more](./docs/agents.md)

## Why "MiniSpec"?

Mini = small chunks, incremental review, manageable PRs.
Spec = still spec-driven, just collaborative instead of batch.

## Acknowledgements

MiniSpec is a fork of [SpecKit](https://github.com/github/spec-kit) by Den Delimarsky and John Lam. It builds on their foundation while reimagining the workflow as pair programming.

## License

MIT
