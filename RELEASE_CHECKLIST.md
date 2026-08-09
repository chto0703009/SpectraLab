<!--
SpectraLab Documentation
Document: RELEASE_CHECKLIST.md
Version: v0.9.0-beta.1
Status: FIELD-VALIDATION PRERELEASE
-->

# SpectraLab Release Checklist

> **v0.9.0-beta.1 prerelease note:** Automated regression and report-layout
> verification are complete. Physical ColorChecker field validation is the
> purpose of this beta and remains open before v1.0.0.

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
| Version | v0.9.0-beta.1 |
| Release type | ColorChecker Field Validation Prerelease |
| Release date | 2026-08-09 |
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
- [ ] Full IRL ColorChecker workflow has been field verified.
- [ ] Calibration and resume behaviour have been field verified across a complete chart.
- [ ] D50, D65 and selected-MAT conversion have been field verified.
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
| Technical Author | Beta prepared 2026-08-09 |
| Engineering Reviewer | Automated regression and visual report review complete |
| Release Manager | Prerelease publication approved |
| Project Owner | Beta field-validation use approved |

Approval represents acceptance of the engineering evidence supporting release.

---

## 7. Release Record

| Item | Value |
|------|-------|
| Version | v0.9.0-beta.1 |
| Release date | 2026-08-09 |
| Git tag | `v0.9.0-beta.1` |
| Release package | `releases/SpectraLab_v0.9.0-beta.1.zip` |
| Test result | Complete automated MATLAB regression suite passed 2026-08-09 |
| Real measurement verified | Pending controlled IRL ColorChecker field validation |
| Comments | Prerelease only; current stable release remains v0.8.2. |

---

## Closing Principles

Engineering decisions shall be supported by objective evidence whenever practical.

A release is complete only when every required item has been verified.

A SpectraLab release is published only after engineering evidence demonstrates that it is ready.
