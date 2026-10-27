# Scientific review - 2026-10-26

Scope: SpectraLab 1.3.0 working copy in the historically named `SpectraLab_v1.2.1-dev`. No original measurements, registered reports, prior release ZIPs or Camera-41 projects were rewritten. These corrections are included in release 1.3.1 (2026-10-27). Original measured archives and previously issued numerical reports remain unchanged.

## Findings and corrections

1. **Confirmed density weighting error.** Status A/M tabulations are complete documentary spectral products, not bare receiver responsivities. Their wrappers and ISO visual now form the measured transmission S/R before weighting. `CalculationVersion=DENS-002` and `IntegrationBasis=transmittance` identify revised outputs. Generic `weightedDensity` retains `source-weighted` as its compatibility default; the wrappers accept that explicit option for comparison. `whiteDensity` deliberately remains source-weighted with V(lambda), and is not ISO visual density. Original archives retain their measured values.
2. **Confirmed branch divergence.** The 1.3.0 copy lacked the fixed Camera-41 interval. Its single and series transmission artifacts, ColorChecker artifacts and qualitative wavelength colour bar now share the inclusive 400-730 nm contract from the other branch. Partial coverage is rejected; no extrapolation is introduced. This export/display interval does not crop archived measurements or globally restrict CIE colourimetry to 400-730 nm.
3. **Confirmed version/path confusion.** Actual VERSION contents were 1.3.0 and 1.2.2-dev, despite folder names. README and citation metadata now identify 1.3.0 (published 2026-10-21). Work/setup_spectralab selects by explicit VERSION or SPECTRALAB_PROGRAM_ROOT and prints the real root; it refuses to mix another package installation on MATLAB's path. Historic folder names remain to preserve existing paths. Both installations now have independent .git directories; original archive pointers were backed up. `git fsck` and identical before/after status checks passed.
4. **Negative samples require review.** The previous rejection is confirmed; automatic clipping is not adopted without a measured noise threshold. It would bias dense samples. Negatives outside the actual weighted interval are excluded and their wavelengths recorded, without clipping. Negatives inside active weights still require review. `C41Porta-18` has a negative sample at 380 nm: outside the Status A/M interval, but relevant to ISO visual. The combined audit therefore flags that input. Rejecting an analysis does not discard its original measured archive. A zero source over active weights is also rejected.
5. **Confirmed CRI reporting error.** Rounded Ra now equals round(mean(unrounded R1..R8)), rather than averaging already-rounded individual indices. Unrounded calculation was already correct. The report definition version is advanced.
6. **Confirmed unit handling error, plus artifact scale bug.** Colourimetry now accepts explicit fraction/percent units and rejects ambiguous labels. Percent and fraction inputs are tested to give identical XYZ. Derived ColorChecker artifacts now actually convert percentages to fractions when labelled Unit=1. Original-value JSON exports and archives remain unchanged.
7. **Numerical limitations confirmed.** Status A/M documentary log products are now evaluated at 1 nm in log space before conversion to linear weights. This fixes between-knot interpolation of that representation. It does NOT implement ISO 5-3:2009 Annex B weighting tables, ASTM E308 colourimetry weights, a certified densitometer geometry, or recover wavelengths absent from the measured spectrum. Results explicitly identify trapezoidal integration and incomplete weighting range. They are spectral approximations, not a claim of ISO conformity. No fabricated standard weights or extrapolated measurements were introduced.
8. **Emission-unit metadata confirmed.** Future explicit spotread -e/-p measurements use mW/(m^2 sr nm); -a uses mW/(m^2 nm). Unknown/relative modes retain an unknown scale. This records the documented mode units, not a new radiometric calibration; old archives are not relabelled.
9. **Historical files.** The txt files, back.log and old cleanup script are inactive historical material, not numerical runtime code. Historical measurement notes and old release ZIPs are retained. The release builder uses an allow-list rather than recursively packaging the releases directory.

## Recalculation of historical C-41 spectra

Separate results: Desktop/SpectraLab-scientific-review-20261026/C41-density-comparison.json and .csv. The original PDF explicitly pairs C41Porta-14 with C41_CSLWh-27; its old values were reproduced to the displayed precision. The other samples are a diagnostic cohort using the same fixed source, not independently verified historical reference pairings. 26/27 inputs were computable; one negative-signal input was flagged. Do not replace film-characterisation curves or accepted Camera-41 packages automatically. Re-evaluate downstream results as new reviewed revisions.

| C41Porta-14 quantity | Historical method | Formula only, same old tabulation | Revised formula and log interpolation |
|---|---:|---:|---:|
| Status M R | 2.064758 | 2.081211 | 2.090967 |
| Status M G | 2.825327 | 2.832150 | 2.811417 |
| Status M B | 3.207777 | 3.166451 | 3.160554 |
| ISO visual approximation | 1.948822 | 1.964346 | 1.964346 |

The source archive UUIDs/content hashes and source-file SHA-256 are recorded in the audit. No existing report was regenerated. The previous source-weighted formula remains reproducible separately.

## Verification and remaining qualification

Tests cover lamp-shape independence, explicit legacy/source weighting, zero/negative reference handling, fraction/percent equivalence, CRI rounding, fixed export coverage, immutable archive round trips, ColorChecker artifact fractions and spotread mode units. Integration/report tests are run in MATLAB R2025b using synthetic fixtures; no new physical instrument or printer qualification is claimed. Full test results are recorded separately after completion.

For a fully validated ISO result, obtain the appropriate authorized spectral weighting factors and implement the stated integration procedure, establish the applicable measurement geometry and validate against reference materials. Trapezoidal results must not be presented as ASTM E308 results.

## Primary references

- ISO 5-3:2009: https://www.iso.org/standard/52915.html
- Original ISO standard preview, sections 4.4-4.5: https://cdn.standards.iteh.ai/samples/52915/fed16a10b2884f89840a0daa8c480143/ISO-5-3-2009.pdf
- ArgyllCMS spotread mode and spectral-unit definitions: https://www.argyllcms.com/doc/spotread.html
- Dataset-specific DOI/SHA-256 remain in the existing CIE library; those source tables were not replaced.

Validation completed: 94/94 test files, 547 test cases, no failures. After the final negative-support refinement, 91 targeted tests passed. Package contents and the explicit Work version selector passed. Both standalone Git stores passed fsck. Physical instrument qualification and exact ISO numerical conformance remain outside this verification.

## Release follow-up - 2026-10-27

Release 1.3.1 preserves a numeric datetime reconstruction residual in new typed emission JSON. A full release regression exposed rare low-order timestamp rounding when rebuilding a datetime from date/time components. The original components and human-readable timestamp remain, older packets without the optional residual are still readable, and no binary/object deserialisation is introduced. New tests cover fractional seconds, timezone handling and old packet compatibility. Final release test totals are recorded in release-validation-v1.3.1.json.
