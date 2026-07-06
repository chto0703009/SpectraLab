<!--
SpectraLab Documentation
Document: RELEASE_CHECKLIST.md
Version: v0.4.0
Status: FROZEN
-->

# SpectraLab Release Checklist

The Release Checklist defines the verification process required before any SpectraLab version is published.

It exists to answer one question:

> **Does the available engineering evidence justify releasing this version?**

It is not a task list.

It is an engineering verification document.

---

## Release Identification

| Item | Value |
|------|-------|
| Project | SpectraLab |
| Version | v0.4.0 |
| Release type | Foundation Release |
| Release date | To be completed at publication |
| Release manager | To be completed at publication |

---

## 1. Engineering Readiness

Confirm before release verification begins:

- [ ] Intended release scope has been achieved.
- [ ] No known release-blocking defects remain.
- [ ] Public API is stable.
- [ ] Architecture remains consistent.
- [ ] Engineering objectives for the release have been met.
- [ ] No feature additions remain pending for this release.

The checklist evaluates engineering readiness, not development activity.

---

## 2. Software Verification

Confirm that:

- [ ] Regression tests pass.
- [ ] Interactive workflow has been verified.
- [ ] Calibration workflow has been verified.
- [ ] Measurement workflow has been verified.
- [ ] Example programs execute correctly.
- [ ] Supported environments have been verified.
- [ ] Version information is consistent.
- [ ] No obsolete release candidate or build version strings remain in user-facing files.

Verification shall be based on objective evidence.

---

## 3. Documentation Verification

Confirm that each release document has been reviewed and approved.

- [ ] `README.md`
- [ ] `docs/GETTING_STARTED.md`
- [ ] `docs/TROUBLESHOOTING.md`
- [ ] `docs/REPOSITORY_STRUCTURE.md`
- [ ] `docs/DEVELOPMENT_PHILOSOPHY.md`
- [ ] `CONTRIBUTING.md`
- [ ] `DISCLAIMER.md`
- [ ] `CHANGELOG.md`
- [ ] `ROADMAP.md`
- [ ] `MANIFEST.md`
- [ ] `RELEASE_CHECKLIST.md`

The Documentation Pack is considered part of the release itself.

---

## 4. Release Package Verification

Confirm that the release package contains:

- [ ] Source code
- [ ] Documentation
- [ ] Examples
- [ ] Regression tests
- [ ] License
- [ ] Manifest
- [ ] Release Checklist
- [ ] Release notes, if applicable

An incomplete package is not an official release.

---

## 5. Final Engineering Review

Before publication, confirm that the release:

- [ ] improves or preserves engineering quality,
- [ ] preserves compatibility where intended,
- [ ] remains consistent with the Engineering Philosophy,
- [ ] is understandable and maintainable,
- [ ] satisfies the objectives defined for the release.

A release should never be approved only because development has stopped.

A release should be approved because verification has been completed.

---

## 6. Release Approval

Approval should be recorded by the appropriate roles.

| Role | Approval |
|------|----------|
| Technical Author |  |
| Engineering Reviewer |  |
| Release Manager |  |
| Project Owner |  |

Approval represents acceptance of the engineering evidence supporting release.

---

## 7. Release Record

| Item | Value |
|------|-------|
| Version |  |
| Release date |  |
| Git tag |  |
| Release package |  |
| Test result |  |
| Real measurement verified |  |
| Comments |  |

---

## Closing Principles

Engineering decisions shall be supported by objective evidence whenever practical.

A release is complete only when every required item has been verified.

A SpectraLab release is published only after engineering evidence demonstrates that it is ready.
