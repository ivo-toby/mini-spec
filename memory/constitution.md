# [PROJECT_NAME] Constitution
<!-- Example: PhotoAlbum Constitution, TaskFlow Constitution, etc. -->

## Core Principles

### [PRINCIPLE_1_NAME]
<!-- Example: I. Code Quality -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Example: All code must be readable, maintainable, and follow established patterns; No magic numbers; Meaningful names; Single responsibility -->

### [PRINCIPLE_2_NAME]
<!-- Example: II. Testing Standards -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Example: Unit tests for business logic; Integration tests for APIs; E2E tests for critical paths; Minimum 80% coverage on new code -->

### [PRINCIPLE_3_NAME]
<!-- Example: III. Documentation -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Example: Public APIs must be documented; Complex logic requires inline comments; Architecture decisions recorded -->

### [PRINCIPLE_4_NAME]
<!-- Example: IV. Security -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Example: No secrets in code; Input validation on all boundaries; Principle of least privilege -->

### [PRINCIPLE_5_NAME]
<!-- Example: V. Performance, VI. Accessibility, VII. Error Handling -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Example: Lazy loading for large datasets; Core Web Vitals targets; Graceful degradation -->

## [SECTION_2_NAME]
<!-- Example: Technology Stack, Constraints, Standards -->

[SECTION_2_CONTENT]
<!-- Example: React 18+, TypeScript strict mode, PostgreSQL, deployed on AWS -->

## [SECTION_3_NAME]
<!-- Example: Development Workflow, Review Process -->

[SECTION_3_CONTENT]
<!-- Example: Feature branches, PR reviews required, CI must pass -->

---

## Project Constraints

<!--
This section defines soft rules that the AI agent enforces during development.
These are configurable per-project and shape AI behavior through prompts.
For hard safety hooks (git push approval, secrets scanning), see .minispec/hooks/
-->

### Commit Standards

[COMMIT_STANDARDS]
<!--
Options (can enable multiple):
- conventional-commits: Enforce conventional commit format (feat:, fix:, docs:, chore:, etc.)
- ticket-reference: Require issue/ticket reference in commit messages (e.g., #123, JIRA-456)
- flag-todos: Flag TODO/FIXME comments and ask if they should be documented as issues
- none: No specific commit format enforced
-->

### Code Quality Rules

[CODE_QUALITY_RULES]
<!--
Options (can enable multiple):
- require-tests: New functionality must include corresponding tests
- coverage-threshold: Minimum coverage for new code (specify percentage, e.g., 80%)
- linter-before-commit: Run linter/formatter before commits (specify tool, e.g., ruff, eslint, prettier)
- import-conventions: Validate imports follow project patterns (describe pattern)
- none: No automated code quality rules
-->

### Chunk Size Limits

[CHUNK_SIZE_LIMITS]
<!--
Options:
- warn-soft: Warn if changes exceed preferred chunk size (continues anyway)
- warn-hard: Warn and pause for confirmation if changes exceed limit
- no-limit: No warnings about chunk size
- threshold: Line count that triggers warning (default: 80)
-->

### Documentation Requirements

[DOCUMENTATION_REQUIREMENTS]
<!--
Options (can enable multiple):
- adr-for-architecture: Prompt for ADR when touching core/architectural code
- changelog-for-features: Require changelog entry for user-facing changes
- update-module-docs: Flag when public APIs change without doc updates
- pattern-documentation: Suggest documenting patterns when similar code appears 3+ times
- none: No documentation requirements
-->

### Knowledge Base Maintenance

[KNOWLEDGE_MAINTENANCE]
<!--
Options (can enable multiple):
- conventions-prompts: Prompt to update conventions.md when new patterns are introduced
- architecture-staleness: Flag when architecture.md might be stale after structural changes
- decision-logging: Auto-prompt to log significant decisions to decisions/
- capture-rationale: Prompt to capture "why" explanations during implementation
- none: No knowledge base maintenance prompts
-->

---

## MiniSpec Preferences

<!--
This section configures how MiniSpec's pair programming workflow operates.
These preferences shape the collaboration between engineer and AI.
-->

### Review Chunk Size

[CHUNK_SIZE_PREFERENCE]
<!--
Options:
- small: 20-40 lines per chunk (maximum engagement, best for learning new codebases)
- medium: 40-80 lines per chunk (balanced pace, recommended default)
- large: 80-150 lines per chunk (for experienced engineers comfortable with larger reviews)
- adaptive: AI assesses complexity and suggests appropriate size per task
-->

### Documentation Review Policy

[DOC_REVIEW_POLICY]
<!--
Options:
- review-all: Engineer reviews all documentation changes before commit
- review-decisions: Engineer reviews decisions/ only, AI trusted for patterns/modules
- trust-ai: AI handles all documentation autonomously (recommended for velocity)
-->

### Autonomy Level

[AUTONOMY_LEVEL]
<!--
Options:
- always-confirm: AI always pauses for engineer approval before proceeding
- tests-passing: AI proceeds automatically if tests pass, pauses on failure
- familiar-areas: AI proceeds in code areas already reviewed this session
- explicit-batch: AI only batches when engineer explicitly says "next N"
-->

### Design Evolution Handling

[DESIGN_EVOLUTION_POLICY]
<!--
Options:
- always-discuss: AI stops implementation to discuss any design deviation
- flag-and-continue: AI flags issues, proposes spec updates, continues if minor
- auto-update: AI updates specs automatically, notifies engineer after (experienced teams)
-->

### Walkthrough Depth

[WALKTHROUGH_DEPTH]
<!--
Options:
- quick: High-level architecture overview (5-10 min)
- standard: Architecture + key patterns + conventions (15-20 min)
- deep: Full codebase tour with all modules explained (30+ min)
-->

---

## Governance

[GOVERNANCE_RULES]
<!-- Example: Constitution supersedes all other practices; Amendments require team discussion; MiniSpec preferences can be adjusted per-feature if needed -->

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
<!-- Example: Version: 1.0.0 | Ratified: 2025-02-01 | Last Amended: 2025-02-01 -->
