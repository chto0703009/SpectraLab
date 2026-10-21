# SpectraLab v1.3.0 release verification

Release date: 2026-10-21. Scope: all tracked development changes and new spectral exchange source/tests/examples in this worktree.

- [x] VERSION, spectralab.version and README identify 1.3.0.
- [x] Release notes and changelog describe the final scope.
- [x] Complete automated regression: 92 test files, 539 test cases, zero failures in MATLAB R2025b on 2026-10-21.
- [x] Versioned package built with tools/package_release.m; ZIP CRC, required exchange files, version, and exclusion of local measurement output/cache verified.
Publication step: create the release commit, annotated v1.3.0 tag and GitHub release after the package checks below. Publication is verified through GitHub, not assumed from this checklist.

## Evidence boundaries

Physical measurement acquisition and every instrument/OS combination have not been newly requalified for this release. Historical v1.2.0 field approvals must not be relabelled as v1.3.0 measurements. The release notes state this limitation. Local measurement output is excluded from public release packaging.

The package uses an explicit source allow-list and excludes examples/output. Check that ZIP contents contain no local captures, private instrument data, Python cache or Finder metadata. Base-MATLAB dependency policy is exercised by automated regression.
