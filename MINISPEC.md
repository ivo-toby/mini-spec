# MiniSpec: Pair Programming with AI

## The Problem

Spec-Driven Development with full AI implementation has two critical issues:

1. **Review Fatigue**: Engineers face massive PRs (500+ lines) after AI completes implementation. Reviewing code you didn't write is cognitively exhausting and error-prone.

2. **Lost Mental Models**: Engineers become "code tourists" in their own codebase. Without writing the code, they don't build the mental models needed to trust, maintain, and debug it.

The current SpecKit workflow:

```
AI works alone → dumps artifacts → Engineer reads/reviews alone
```

This creates a disconnect between implementation and understanding.

## The Solution

MiniSpec reimagines the workflow as **pair programming** where:

- **Engineer = Navigator**: Makes decisions, directs, reviews in small chunks
- **AI = Driver**: Executes, implements, documents

The new workflow:

```
AI + Engineer collaborate in real-time → decisions are shared → understanding is built
```

## Core Principles

### 1. Interactive Over Generative

Instead of AI generating large documents for engineers to read, every phase is a conversation where engineers make decisions with AI guidance.

### 2. Small Chunks, Continuous Review

Implementation happens in reviewable increments (20-80 lines). Engineers never face overwhelming PRs.

### 3. Document by Default

Documentation is a natural byproduct of the pairing process, not a separate task. Decisions made during conversations are automatically captured.

### 4. Living Documentation

A structured knowledge base serves as shared memory for both human and AI. It's queryable, version-controlled, and kept fresh.

### 5. Configurable Autonomy

Engineers can tune how much AI asks for confirmation vs. proceeds independently, based on their comfort level and familiarity with the code.

---

## Commands

| Command                   | Purpose                                            | When to Use                                    |
| ------------------------- | -------------------------------------------------- | ---------------------------------------------- |
| `/minispec.constitution`  | Set up project principles + MiniSpec preferences   | Project setup                                  |
| `/minispec.walkthrough`   | Guided tour of codebase for context-building       | Before starting work, onboarding new engineers |
| `/minispec.design`        | Interactive design conversation                    | Starting a new feature                         |
| `/minispec.tasks`         | Break design into reviewable chunks (interactive)  | After design is complete                       |
| `/minispec.analyze`       | Validate design ↔ tasks coherence                 | Before starting implementation                 |
| `/minispec.next`          | Implement next chunk in pair programming style     | During implementation (loop)                   |
| `/minispec.validate-docs` | Check documentation freshness against code         | Ongoing maintenance                            |
| `/minispec.status`        | Show current progress, what's next, what's changed | Anytime                                        |

---

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                        PROJECT SETUP                            │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.constitution                                         │
│  Set up project principles and MiniSpec preferences             │
│  (review chunk size, doc review policy, autonomy triggers)      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CONTEXT BUILDING                            │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.walkthrough                                          │
│  Understand existing codebase, architecture, patterns           │
│  (Skip for greenfield projects)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DESIGN                                  │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.design "feature description"                         │
│  Interactive conversation:                                      │
│  - AI asks clarifying questions                                 │
│  - Presents options with trade-offs                             │
│  - Engineer makes decisions                                     │
│  - Decisions auto-documented to knowledge/decisions/            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TASK BREAKDOWN                             │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.tasks                                                │
│  Interactive breakdown:                                         │
│  - AI proposes task groupings based on chunk size preference    │
│  - Engineer adjusts groupings, priorities, dependencies         │
│  - Tasks sized for comfortable review                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       VALIDATION                                │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.analyze                                              │
│  Pre-implementation checks:                                     │
│  - All design decisions have corresponding tasks                │
│  - Task dependencies are satisfiable                            │
│  - No gaps between design and implementation plan               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    IMPLEMENTATION                               │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.next  (repeat until done)                            │
│                                                                 │
│  For each chunk:                                                │
│  1. AI explains what will be implemented and why                │
│  2. AI implements (20-80 lines)                                 │
│  3. Engineer reviews, asks questions                            │
│  4. Engineer approves → commit                                  │
│  5. Documentation updated automatically                         │
│                                                                 │
│  Engineer can:                                                  │
│  - Ask questions before approving                               │
│  - Request modifications                                        │
│  - Batch multiple chunks ("next 3") when comfortable            │
│  - Update specs if design needs to evolve                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MAINTENANCE                                │
├─────────────────────────────────────────────────────────────────┤
│  /minispec.validate-docs                                        │
│  Ongoing freshness checks:                                      │
│  - Cross-reference docs with code                               │
│  - Flag stale or contradictory documentation                    │
│  - Propose updates or mark as superseded                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Documentation Structure

MiniSpec maintains a living knowledge base that serves both humans and AI:

```
.minispec/
├── knowledge/
│   ├── architecture.md          # System overview (auto-updated)
│   ├── conventions.md           # Code patterns, naming, style
│   ├── glossary.md              # Domain terms and definitions
│   │
│   ├── patterns/                # Reusable patterns in this codebase
│   │   ├── error-handling.md
│   │   ├── api-response.md
│   │   └── auth-flow.md
│   │
│   ├── decisions/               # ADR-style decision records
│   │   ├── 001-jwt-over-sessions.md
│   │   ├── 002-postgres-over-mongo.md
│   │   └── ...
│   │
│   └── modules/                 # Per-module deep dives
│       ├── auth.md
│       ├── payments.md
│       └── ...
```

### Document Format

Each document uses YAML frontmatter (machine-parseable) + Markdown body (human-readable):

```markdown
---
type: decision
id: jwt-over-sessions
date: 2024-01-15
status: active
supersedes: null
impacts:
  - src/auth/*
  - src/middleware/auth.ts
tags: [authentication, security, stateless]
---

# JWT Over Session-Based Auth

## Context

Our deployment runs on Kubernetes with horizontal scaling.
Session-based auth would require sticky sessions or a shared
session store, adding operational complexity.

## Decision

We use JWT tokens with:

- Access token: 15 min expiry, stored in memory
- Refresh token: 7 days, httpOnly cookie

## Consequences

- ✅ Stateless services, easy horizontal scaling
- ✅ No shared session store needed
- ⚠️ Token revocation requires a blocklist check
- ⚠️ Slightly larger request payload

## Code References

- Token generation: `src/auth/tokens.ts:generateTokenPair()`
- Validation middleware: `src/middleware/auth.ts`
- Refresh endpoint: `src/routes/auth.ts:/refresh`
```

### When Documentation Is Created

| Command                   | Documentation Created                         |
| ------------------------- | --------------------------------------------- |
| `/minispec.design`        | `decisions/` files as choices are made        |
| `/minispec.next`          | `patterns/` and `modules/` as code is written |
| `/minispec.validate-docs` | Updates or marks docs as superseded           |
| `/minispec.walkthrough`   | Reads from `knowledge/` to explain codebase   |

### Documentation Principles

1. **If it was discussed, document it** - Any trade-off conversation or questioned decision gets recorded
2. **Trust AI by default** - AI writes docs without asking (configurable in constitution)
3. **Staleness is a bug** - Regular validation ensures docs match code

---

## Constitution Additions

The constitution setup (`/minispec.constitution`) should capture these MiniSpec-specific preferences:

```markdown
## MiniSpec Preferences

### Review Chunk Size

How much code can you comfortably review in one sitting?

- [ ] Small (20-40 lines) - Maximum engagement, best for learning
- [ ] Medium (40-80 lines) - Balanced pace (recommended)
- [ ] Large (80-150 lines) - Comfortable with larger chunks
- [ ] Adaptive - AI asks based on complexity of each task

### Documentation Review

Should AI ask you to review documentation changes?

- [ ] Yes, review all doc changes
- [ ] Only for decisions/, trust AI on patterns/modules
- [ ] No, trust AI for all documentation (recommended)

### Autonomy Triggers

When can AI proceed to next chunk without explicit confirmation?

- [ ] Never - always pause for review
- [ ] Tests passing - if tests pass, auto-proceed
- [ ] Familiar areas - proceed in areas already reviewed in this session
- [ ] Explicit batch - only when I say "next N"

### Design Evolution

When implementation reveals design issues, AI should:

- [ ] Always stop and discuss
- [ ] Flag it, propose spec update, continue if minor
- [ ] Update specs automatically, notify after (recommended for experienced teams)
```

---

## Comparison with SpecKit

| Aspect             | SpecKit                       | MiniSpec                                   |
| ------------------ | ----------------------------- | ------------------------------------------ |
| **Planning**       | AI generates plan document    | Interactive conversation, engineer decides |
| **Task creation**  | Batch generation              | Interactive breakdown with engineer input  |
| **Implementation** | All at once, then review      | Small chunks, continuous review            |
| **Documentation**  | Manual/optional               | Automatic byproduct of pairing             |
| **Engineer role**  | Reviewer (post-hoc)           | Navigator (real-time decision maker)       |
| **AI role**        | Solo implementer              | Pair programming driver                    |
| **Mental model**   | Hope engineer reads carefully | Built through dialogue and decisions       |
| **Review burden**  | Large PRs (100s of lines)     | Small chunks (20-80 lines)                 |
| **Spec evolution** | Specs often become stale      | AI proactively proposes spec updates       |

---

## Example Session

```
Engineer: /minispec.design "add user authentication"

AI: "Let's design authentication together. First question:
    What's your expected user scale? This affects our session strategy."

Engineer: "Around 5000 users"

AI: "For ~5000 users, both session-based and JWT work well.

    Session-based:
    + Simpler revocation (delete session)
    + Smaller tokens
    - Requires session store (Redis) for multi-instance

    JWT:
    + Stateless, scales easily
    + No shared store needed
    - Revocation needs blocklist

    Given you're on Kubernetes (from your infra notes), JWT might
    be simpler operationally. What's your preference?"

Engineer: "JWT makes sense for our setup"

AI: "Good choice. I'm documenting this in decisions/001-jwt-auth.md

    Next: Token storage on client side. Options are..."

[conversation continues through all design decisions]

AI: "Design complete. I've documented 4 decisions:
    - decisions/001-jwt-auth.md
    - decisions/002-token-storage.md
    - decisions/003-password-hashing.md
    - decisions/004-refresh-strategy.md

    Ready to break this into tasks?"

Engineer: "/minispec.tasks"

AI: "Based on your 'medium chunk' preference (40-80 lines),
    I propose 8 tasks:

    1. User model + migration (45 lines)
    2. Password hashing utilities (35 lines)
    [...]

    Want to adjust any groupings?"

Engineer: "Looks good"

AI: "Tasks saved. Run /minispec.analyze to validate before implementing."

Engineer: /minispec.analyze

AI: "Analyzing design ↔ tasks alignment...

    ✅ All decisions have corresponding tasks
    ✅ Dependencies are valid
    ⚠️ decisions/004-refresh-strategy.md mentions rate limiting,
       but no task covers it. Add task or mark out-of-scope?"

Engineer: "Add a task"

AI: "Added Task 9: Rate limiting middleware.

    ✅ All checks pass. Ready to implement.
    Run /minispec.next to start."

Engineer: /minispec.next

AI: "Task 1/9: User model + migration

    I'll create:
    - src/models/user.ts (User entity)
    - src/migrations/001-create-users.ts

    The User model will have: id, email (unique), passwordHash,
    status (active/suspended), createdAt, updatedAt.

    Proceed?"

Engineer: "Add a 'lastLoginAt' field too"

AI: "Good addition - useful for security auditing. Adding lastLoginAt.

    [implements ~45 lines]

    Here's the implementation. Review above.
    Questions, changes, or ready to commit?"

Engineer: "Why nullable for lastLoginAt?"

AI: "It's nullable because when a user first registers, they haven't
    logged in yet. After first login, it's always populated.
    Alternative: default to createdAt. Preference?"

Engineer: "Nullable is fine, makes the distinction clear. Commit."

AI: "Committed: 'Add User model and migration'

    Updated modules/auth.md with User model documentation.

    8 tasks remaining. /minispec.next when ready."
```

---

## Implementation Notes

### Reusing SpecKit Infrastructure

MiniSpec builds on SpecKit's foundation:

- Similar project structure (`.minispec/` instead of SpecKit's `.specify/`)
- Same script infrastructure (bash/powershell)
- Same template system for commands
- Constitution concept extended with MiniSpec preferences

### Template Files (Source)

These templates in the MiniSpec repo get copied to target projects:

```
memory/
└── constitution.md              # Constitution template with MiniSpec preferences

templates/
├── commands/
│   └── constitution.md          # Interactive constitution command
│
└── knowledge/                   # Knowledge base document templates
    ├── decision-template.md     # ADR format for architectural decisions
    ├── pattern-template.md      # Template for documenting code patterns
    └── module-template.md       # Template for module documentation
```

### Target Project Structure

When a project is initialized, it gets:

```
.minispec/
├── memory/
│   └── constitution.md          # Filled-in constitution
│
└── knowledge/
    ├── architecture.md          # System overview (grows over time)
    ├── conventions.md           # Code conventions (grows over time)
    ├── glossary.md              # Domain terms (grows over time)
    ├── decisions/               # ADRs created during /minispec.design
    ├── patterns/                # Patterns documented during /minispec.next
    └── modules/                 # Module docs created as features complete
```

### Still Needed

1. **State tracking** - Track current task, progress, chunk history for `/minispec.next`
2. **Conversation context** - Design decisions need to flow into task creation and implementation
3. **Remaining commands** - `/minispec.design`, `/minispec.tasks`, `/minispec.next`, etc.

### Migration Path from SpecKit

Projects can adopt MiniSpec incrementally:

- Start with `/minispec.walkthrough` on existing SpecKit projects
- Use `/minispec.next` for implementation instead of `/speckit.implement`
- Gradually add documentation structure

---

## Future Considerations

1. **Team collaboration** - Multiple engineers working on same feature
2. **Async handoffs** - Engineer A designs, Engineer B implements
3. **Learning mode** - More Socratic for junior engineers, more autonomous for seniors
4. **Metrics** - Track chunk sizes, review times, doc coverage
5. **IDE integration** - Tighter integration with editor workflows
