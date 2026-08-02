<!--
SpectraLab Documentation
Document: DEVELOPMENT_PHILOSOPHY.md
Version: v0.8.1
Status: CURRENT
-->

# SpectraLab Engineering Philosophy

SpectraLab is built around a simple idea:

> Reliable measurements require reliable software.

This document explains why SpectraLab is engineered the way it is.

It is written for current and future developers, contributors and maintainers.

---

## Core Engineering Principles

SpectraLab follows five core engineering principles.

### Stability before expansion

A stable core is more valuable than a large feature set that cannot be trusted.

### Simplicity before complexity

Simple workflows are easier to understand, verify and maintain.

### Verification before assumption

Confidence comes from verification, not from assumption.

### Reproducibility before convenience

Measurement data should remain understandable and reusable after the measurement session has ended.

### Engineering judgement before automation

Automation assists engineering work. It does not replace engineering judgement.

---

## Software Architecture

SpectraLab is organised in layers.

```text
Application
    |
    v
Public API
    |
    v
Core Library
    |
    v
Instrument Driver
    |
    v
External Software
    |
    v
Instrument
```

Each layer has one responsibility.

Applications express measurement intent through the public API. Drivers implement the instrument-specific details. External software such as ArgyllCMS `spotread` remains behind the driver boundary.

Engineering decisions should be understandable before they are accepted.

---

## Public API Philosophy

The public API is a contract between SpectraLab and its users.

Applications should depend on public interfaces, not internal implementation details.

Internal implementation may evolve. Public behaviour should remain stable whenever practical.

This allows SpectraLab to improve without breaking user applications unnecessarily.

---

## Interactive Workflow

Measurements are physical operations involving both software and an operator.

The interactive workflow reflects this reality.

For the current Spotread driver, the user must position the instrument before calibration and measurement. SpectraLab therefore guides the user through the process with clear prompts.

Interactivity belongs to the instrument driver, not to the application.

Applications describe **what** should happen.

Instrument drivers determine **how** it is performed.

---

## Quality and Verification

Verification is continuous throughout development, not only before release.

SpectraLab uses:

- regression tests,
- real instrument testing,
- quality gates,
- documentation review,
- release checklists.

Passing all tests demonstrates that no known regressions have been introduced. It does not prove that the software is free from defects.

Quality gates exist to discover problems, not to prove perfection.

The goal of SpectraLab is not to eliminate all mistakes.

The goal is to discover them before they matter.

---

## Documentation Philosophy

Documentation is engineered with the same care as the software itself.

SpectraLab documentation follows these principles:

- Documentation is part of the product.
- Every document has one primary purpose.
- Every document serves one primary reader at one particular moment.
- Documentation follows the user's workflow.
- Examples are documentation.
- Troubleshooting is recovery-oriented.

Good documentation does not show everything the author knows.

Good documentation gives the reader what is needed at the right moment.

---

## Contribution Philosophy

Good contributions preserve the character of the project.

A contribution should:

- improve clarity,
- preserve compatibility whenever practical,
- include tests where appropriate,
- update documentation when user-visible behaviour changes,
- follow the engineering philosophy.

Review exists to improve ideas, not to defend ownership of ideas.

The objective of collaboration is the quality of the final result.

---

## Long-Term Vision

SpectraLab is intended to evolve through careful engineering rather than rapid feature growth.

The long-term goal is a reliable platform for spectral measurements that can support multiple instruments while preserving a consistent user experience and stable public API.

Growth should be driven by engineering value.

---

## Final Principles

Reliable software supports reliable measurements.

Reliable measurements require verification.

Verification supports engineering judgement.

Documentation is engineered with the same care as the software itself.

Engineers remain responsible for engineering decisions.

Measure once.
Save forever.
Verify always.
