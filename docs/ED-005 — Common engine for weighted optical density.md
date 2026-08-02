ED-005 — Common engine for weighted optical density

Status: Accepted
Date: 2026-07-15

Decision

All weighted optical-density measurements shall use the common numerical implementation:

spectralab.core.weightedDensity

Public analysis functions shall act as thin wrappers that select the appropriate spectral weighting function and present the result in a form suitable for the user.

Current public wrappers are:

spectralab.analysis.whiteDensity
spectralab.analysis.statusADensity

Rationale

White density, Status A red density, Status A green density, Status A blue density, and future weighted-density measurements are the same type of physical calculation.

Only the spectral weighting function differs.

The common calculation sequence is:

Reference and sample spectra
        ↓
Determine common wavelength range
        ↓
Interpolate onto a common wavelength grid
        ↓
Apply spectral weighting
        ↓
Integrate weighted reference and sample signals
        ↓
Calculate weighted transmittance
        ↓
Calculate density

The weighted transmittance is:

[
T_w =
\frac{\int S_{\mathrm{sample}}(\lambda)W(\lambda),d\lambda}
{\int S_{\mathrm{reference}}(\lambda)W(\lambda),d\lambda}
]

The weighted density is:

[
D_w=-\log_{10}(T_w)
]

Consequences

* White and Status A density use identical interpolation, integration, validation, and numerical logic.
* New density systems can be added by supplying another weighting function.
* Public analysis functions remain easy for engineers to understand.
* Numerical behavior is tested once in the shared core.
* Wrapper tests verify the meaning and structure of each public result.
* Duplicate density implementations are not permitted.

Public API

White density:

white = spectralab.analysis.whiteDensity(reference, sample);
density = white.Density;
transmittance = white.Transmittance;

Status A RGB density:

statusA = spectralab.analysis.statusADensity(reference, sample);
redDensity   = statusA.Red.Density;
greenDensity = statusA.Green.Density;
blueDensity  = statusA.Blue.Density;
densityRGB = statusA.DensityRGB;

The order of DensityRGB and TransmittanceRGB is:

[Red, Green, Blue]

Verification

The implementation is verified by:

tests/test_core_weightedDensity.m
tests/test_analysis_whiteDensity.m
tests/test_analysis_statusADensity.m

At acceptance, all 27 tests pass.