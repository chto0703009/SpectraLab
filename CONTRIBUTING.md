<!--
SpectraLab Documentation
Document: CONTRIBUTING.md
Version: v0.4.0
Status: FROZEN
-->

# Contributing to SpectraLab

Thank you for considering contributing to SpectraLab.

This document explains how to contribute successfully while preserving the engineering philosophy, software quality and long-term maintainability of the project.

---

## Before You Start

Before writing code, please read:

- `README.md`
- `docs/GETTING_STARTED.md`
- `docs/REPOSITORY_STRUCTURE.md`
- `docs/DEVELOPMENT_PHILOSOPHY.md`

Understanding SpectraLab is part of contributing to SpectraLab.

---

## Understanding SpectraLab

SpectraLab values careful engineering over rapid feature growth.

The project is designed around:

- stable public APIs,
- instrument-independent architecture,
- reproducible measurement workflows,
- clear diagnostics,
- regression testing,
- documentation as part of the product.

A good contribution should make SpectraLab clearer, more reliable or more useful without weakening these principles.

---

## Core Engineering Principles

When contributing, follow these principles:

- Preserve compatibility whenever practical.
- Keep the public API stable.
- Prefer simple solutions.
- Explain engineering decisions.
- Verify before merging.
- Update documentation when user-visible behaviour changes.

---

## Development Workflow

The preferred workflow is:

```text
Idea
  |
  v
Discussion
  |
  v
Implementation
  |
  v
Tests
  |
  v
Documentation
  |
  v
Review
  |
  v
Merge
```

The order is intentional.

Documentation is part of the contribution, not an afterthought.

---

## Coding Standards

SpectraLab code should be:

- readable,
- modular,
- consistent with existing style,
- named clearly,
- easy to test,
- easy to review.

Prefer comments that explain **why** something is done rather than comments that merely repeat **what** the code does.

Avoid unnecessary cleverness.

Reliable engineering software should be understandable.

---

## Testing Requirements

Code without appropriate tests is considered incomplete.

Functional changes should include regression tests where practical.

Bug fixes should include a test that would have detected the original problem whenever possible.

Before submitting a contribution, run:

```matlab
run_all_tests
```

Expected result:

```text
All SpectraLab tests passed.
```

Passing tests does not prove correctness. It demonstrates that no known regressions were detected by the current test suite.

---

## Documentation Requirements

Every user-visible change should update the documentation when appropriate.

This may include:

- `README.md`,
- `docs/GETTING_STARTED.md`,
- `docs/TROUBLESHOOTING.md`,
- examples,
- API documentation,
- release notes.

If a change affects how a user works, the documentation should change in the same contribution.

---

## Pull Requests

Before submitting a pull request, ask:

- Does this improve SpectraLab?
- Is it documented?
- Is it tested?
- Will another engineer understand it?
- Does it preserve the public API unless a change has been agreed?

A pull request should normally include:

- a clear description of the change,
- the engineering motivation,
- tests or verification evidence,
- documentation updates,
- notes about compatibility.

---

## Reviewing Contributions

Reviews should answer:

- Is the contribution technically correct?
- Is it understandable?
- Is it consistent with the project?
- Does it follow the engineering philosophy?
- Does it preserve or improve quality?

Reviews are intended to improve contributions, not to criticize contributors.

Review ideas, not people.

---

## Community Principles

SpectraLab development should be professional, constructive and engineering-oriented.

- Assume good intentions.
- Explain engineering decisions.
- Prefer evidence over opinion.
- Let the best solution win.
- Improve the project, not individual status.

Good engineering is collaborative.

Good collaboration is documented.

---

## Stable API Rule

The public API should remain stable whenever practical.

Breaking changes require discussion before implementation.

When a breaking change is necessary, it should be documented clearly and justified by engineering value.

---

## Thank You

Every contribution matters.

Code, documentation, tests, bug reports, examples and careful review all help SpectraLab become better.

Thank you for helping preserve the engineering quality of the project.
