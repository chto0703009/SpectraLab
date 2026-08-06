<!--
SpectraLab Documentation
Document: RELEASE_CHECKLIST.md
Version: v0.8.2
Status: RELEASE CANDIDATE
-->

# SpectraLab Release Checklist

> **v0.8.2 release-candidate note:** Checkmarks below are inherited from
> the v0.8.1 checklist and are not release approval for v0.8.2. Final
> approval requires the v0.8.2 regression and visual-review evidence to be
> recorded in the Release Record.

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
| Version | v0.8.2 |
| Release type | Presentation Standard and Reliable Report Exports Release |
| Release date | 2026-08-06 |
| Release manager | Project owner |

---

## 1. Engineering Readiness

Confirm before release verification begins:

- [x] Intended release scope has been achieved.
- [x] No known release-blocking defects remain.
- [x] Public API is stable.
- [x] Architecture remains consistent.
- [x] Engineering objectives for the release have been met.
- [x] No feature additions remain pending for this release.

The checklist evaluates engineering readiness, not development activity.

---

## 2. Software Verification

Confirm that:

- [x] Regression tests pass.
- [x] Interactive workflow has been verified.
- [x] Calibration workflow has been verified.
- [x] Measurement workflow has been verified.
- [x] Example programs execute correctly.
- [x] Every registered report analysis has been verified.
- [x] Every intended report figure appears in both PDF and PNG output.
- [x] Every report figure has labelled axes and follows its registered
  y-axis contract: zero-origin for magnitude plots or symmetric zero-centred
  limits for signed difference plots.
- [x] Supported environments have been verified.
- [x] Version information is consistent.
- [x] No obsolete release candidate or build version strings remain in user-facing files.

Verification shall be based on objective evidence.

---

## 3. Documentation Verification

Confirm that each release document has been reviewed and approved.

- [x] `README.md`
- [x] `docs/GETTING_STARTED.md`
- [x] `docs/TROUBLESHOOTING.md`
- [x] `docs/REPOSITORY_STRUCTURE.md`
- [x] `docs/DEVELOPMENT_PHILOSOPHY.md`
- [x] `CONTRIBUTING.md`
- [x] `DISCLAIMER.md`
- [x] `CHANGELOG.md`
- [x] `ROADMAP.md`
- [x] `MANIFEST.md`
- [x] `RELEASE_CHECKLIST.md`

The Documentation Pack is considered part of the release itself.

---

## 4. Release Package Verification

Confirm that the release package contains:

- [x] Source code
- [x] Documentation
- [x] Examples
- [x] Regression tests
- [x] License
- [x] Manifest
- [x] Release Checklist
- [x] Release notes, if applicable

An incomplete package is not an official release.

---

## 5. Final Engineering Review

Before publication, confirm that the release:

- [x] improves or preserves engineering quality,
- [x] preserves compatibility where intended,
- [x] remains consistent with the Engineering Philosophy,
- [x] is understandable and maintainable,
- [x] satisfies the objectives defined for the release.

A release should never be approved only because development has stopped.

A release should be approved because verification has been completed.

---

## 6. Release Approval

Approval should be recorded by the appropriate roles.

| Role | Approval |
|------|----------|
| Technical Author | Release candidate prepared 2026-08-06 |
| Engineering Reviewer | Pending final regression and visual review |
| Release Manager | Pending |
| Project Owner | Pending |

Approval represents acceptance of the engineering evidence supporting release.

---

## 7. Release Record

| Item | Value |
|------|-------|
| Version | v0.8.2 |
| Release date | Pending approval |
| Git tag | Pending publication as `v0.8.2` |
| Release package | `releases/SpectraLab_v0.8.2.zip` built and contents verified |
| Test result | Pending final regression evidence |
| Real measurement verified | Existing v0.8.1 acquisition evidence retained; no acquisition changes in this release |
| Comments | Release candidate includes GP-001, updated examples and report-export verification. |

---

## Closing Principles

Engineering decisions shall be supported by objective evidence whenever practical.

A release is complete only when every required item has been verified.

A SpectraLab release is published only after engineering evidence demonstrates that it is ready.
