# SpectraLab 1.3.1: measurement, analysis and provenance

Release documentation | 2026-10-27 | Christer Törnkvist

## Scope and reading order

SpectraLab acquires spectra through an external instrument adapter, preserves immutable source archives, computes explicitly identified analyses and exports traceable reports and spectral artifacts. Standard/base MATLAB is the runtime policy. External Python and ArgyllCMS tools remain separate dependencies with their own licences.

This document describes release 1.3.1. The current sections take precedence over the retained historical technical foundation in the appendix. The appendix describes the older v1.0.1 architecture and is marked HISTORICAL on every page. Earlier version labels and numerical-method descriptions there must not be read as the current release contract.

Release 1.3.1 corrects density weighting, CRI rounding, reflectance units and Camera-41 export coverage. It includes portable Python preparation from the intervening development work. These corrections do not modify original measured archives, accepted Camera-41 projects or previously issued reports. Recalculation produces a separate reviewed revision.

## Acquisition and immutable records

The verified acquisition family uses X-Rite i1Pro2 and GretagMacbeth Eye-One Pro through ArgyllCMS spotread. Preserve instrument identity, mode, calibration evidence, operator comments, wavelength grid, values, units, timestamps and archive provenance. Incomplete or calibration-only output must not become a completed measurement.

A durable archive preserves the actual measured data and its scientific content identity. A derived spectrum or analysis is a new record. A file checksum verifies bytes; a scientific content hash binds canonical scientific content. Neither alone establishes correct physical measurement geometry or instrument accuracy. New typed emission JSON also records a numeric datetime reconstruction residual, preserving low-order timestamp precision without executable object bytes; older packets remain readable.

## Runtime and preparation

Each installation uses its own isolated Python 3.13.6 environment with pinned package versions. Prepare can obtain a private interpreter on macOS using a checksum-verified preparation tool; system Python is unchanged. Identify/check remain read-only. ARM is preferred on physical Apple Silicon. A complete installation and first-time internet access are required. See PYTHON_ENVIRONMENT.md.

---

# Density calculations in 1.3.1

## Separate transmission from source weighting

Let S(lambda) be the measured sample signal and R(lambda) the corresponding measured source/reference signal. ISO visual and Status A/M wrappers first form T(lambda) = S(lambda) / R(lambda) on a shared wavelength grid. Their documented spectral product Pi(lambda) already includes the required spectral weighting components.

The revised basis is D = -log10(integral(T * Pi) / integral(Pi)). This prevents the measured source spectrum from being applied twice. Revised outputs identify CalculationVersion=DENS-002 and IntegrationBasis=transmittance.

The generic weightedDensity function retains source-weighted calculation as its compatibility default: D = -log10(integral(S * W) / integral(R * W)). The wrappers accept an explicit source-weighted basis for diagnostic comparison. whiteDensity intentionally retains source-weighted V(lambda) weighting and is not ISO visual density. The two quantities must not be conflated.

## Weight tables, integration and missing support

Documentary Status A/M log products are interpolated in log space on a 1 nm weighting grid before conversion to linear weights. Integration is trapezoidal; this is not ISO 5-3 Annex B weighting or ASTM E308 colourimetry. The implementation records incomplete weighting support and does not extrapolate missing measured wavelengths. Spectral calculation alone does not establish certified densitometer geometry or ISO conformity.

## Dense samples and negative values

No automatic clipping threshold is invented. Negative signals outside the active weighted interval are excluded and their wavelengths recorded. Negative signals inside active weights require review and remain an error for the analysis. A zero reference under active weights is rejected. Rejection leaves the original measured archive intact.

A comparison of historical C-41 spectra is documented in SCIENTIFIC_REVIEW_20261026.md. The numerical changes are calculation revisions, not evidence that earlier physical measurements were changed or that downstream film profiles should be replaced automatically.

---

# Colourimetry, spectral units and exchange

## XYZ, Lab and reflectance units

Colourimetry combines measured reflectance and the chosen illuminant on common supported wavelengths, normalises the reference white to Y=100 and applies CIE 1976 Lab. Integration remains trapezoidal on supported spectral data; ASTM E308 weights are not implemented.

Reflectance units are explicit: percent values are converted to fractions once; fractional inputs are used directly. Ambiguous labels are rejected. A derived ColorChecker artifact labelled Unit=1 stores fractional values. Original-value archives and JSON exports remain their own records. XYZ and Lab are derived results, not replacements for measured patch spectra.

## CRI rounding and emission metadata

Reported Ra is the rounded mean of the unrounded R1-R8 values. Individual reported indices may be rounded separately for display but are not averaged after rounding.

Future explicit spotread -e/-p spectral modes record mW/(m^2 sr nm); -a records mW/(m^2 nm). Unknown or relative modes retain an unknown scale. This is mode metadata and does not create a radiometric calibration or relabel historical measurements.

## Camera-41 hand-off

Single/series transmission artifacts, ColorChecker artifacts and the qualitative wavelength colour bar use the same inclusive 400-730 nm contract. Partial coverage is rejected and no extrapolation is allowed. This exchange interval does not crop immutable source archives or globally limit CIE colourimetry to that interval.

Standalone JSON retains measured spectral content and available archive/provenance identities. Camera-41 owns camera calibration, RAW sampling, physical camera identity and the subsequent film-characterisation workflow. Each application verifies incoming content without rewriting the other's source measurements.

---

# Verification, limitations and retained foundation

## Release evidence

The scientific regression suite covers source-shape independence of transmission-weighted density, explicit compatibility weighting, zero/negative references, fraction/percent equivalence, CRI rounding, fixed export coverage, archive round trips, ColorChecker fractional artifacts and spotread mode units. The full release test result and package verification are recorded in releases/RELEASE_NOTES_v1.3.1.md and docs/release-validation-v1.3.1.json.

Automated tests use MATLAB R2025b and synthetic fixtures. No new physical instrument, printer, densitometer geometry or operating-system combination is qualified merely by these tests. Obtain authorized reference weights and validate measurement geometry and reference materials before claiming full standards conformance.

## Historical appendix

The following retained technical foundation was issued for v1.0.1 on 2026-08-31. Its architecture discussion is useful background. Its release labels, formulas and numerical claims describe that historical implementation. The current 1.3.1 sections above define the corrected calculation and export behaviour.

The archived foundation is retained separately as docs/scientific-reports/foundation-v1.0.1-historical.pdf. Its original bytes are preserved. The combined current report adds a historical margin label to displayed appendix pages only.

## Further reading

README.md provides installation and release links. USER_GUIDE.md and GETTING_STARTED.md describe the operator workflow. SCIENTIFIC_REVIEW_20261026.md records findings, a historical comparison and qualification limits. ED-017 describes the density framework and SPECTRAL_ARTIFACT.md describes artifact structure. Their historical decisions are read together with the 1.3.1 scientific review, not as new physical certification.
