# ED-017 — ISO 5 Density Framework

**Status:** Approved design  
**Issue:** ANL-006  
**Applies to:** SpectraLab v0.8.0 and later
**Purpose:** Establish the architectural and standards framework for all photographic density analyses in SpectraLab.

## 1. Decision summary

SpectraLab shall not introduce a generic `ansiDensity` function.

The term *ANSI density* does not identify one unique spectral weighting or one complete measurement condition. SpectraLab shall instead organize density analysis according to the ISO 5 density framework and expose explicitly named density functions such as:

- `spectralab.analysis.whiteDensity`
- `spectralab.analysis.statusADensity`
- `spectralab.analysis.isoVisualDensity`
- `spectralab.analysis.statusMDensity`

All density functions shall use the common weighted-density engine. No analysis-specific implementation shall duplicate the density mathematics.

## 2. Scope

This engineering decision defines:

- the relationship between measured spectra, transmission, weighting and density;
- the separation between spectral computation and measurement geometry;
- the naming of public density-analysis functions;
- the provenance required in returned results;
- the limits of any standards-conformance claim;
- the extension pattern for future density types.

The numerical weighting data for ISO visual density and Status M density are
implemented as versioned standard-filter datasets. Their numerical integrity
is covered by the standard-filter regression tests.

## 3. Standards context

The ISO 5 family separates photographic density measurement into general definitions, geometric conditions and spectral conditions.

Relevant parts are:

- **ISO 5-1:2009** — general framework and notation;
- **ISO 5-2:2009** — geometric conditions for transmittance density;
- **ISO 5-3:2009** — spectral conditions and computational procedures;
- **ISO 5-4:2009** — geometric conditions for reflection density.

This separation is fundamental to the SpectraLab design.

A correct spectral computation alone does not demonstrate full conformance with a density standard. Conformance also depends on the measurement geometry, instrument characteristics, specimen arrangement and other conditions required by the applicable standard.

## 4. SpectraLab design principle

> SpectraLab computes spectral quantities. Compliance with an external standard requires both the correct computation and a measurement performed according to that standard. SpectraLab reports the computed quantity and records sufficient provenance for the user to assess compliance.

SpectraLab shall therefore distinguish between:

1. a calculated density quantity;
2. a density calculated using a named standard spectral weighting;
3. a complete standards-compliant measurement.

Only the first two are directly established by software computation.

## 5. Canonical calculation pipeline

All density analyses shall follow the same logical pipeline:

```text
Reference measurement
        +
Sample measurement
        |
        v
Canonical spectral transmission
        |
        v
Spectral weighting
        |
        v
Weighted transmittance
        |
        v
Density
```

The public density functions shall be thin wrappers around the common engine:

```text
spectralab.core.weightedDensity
        |
        +-- spectralab.analysis.whiteDensity
        +-- spectralab.analysis.statusADensity
        +-- spectralab.analysis.isoVisualDensity
        +-- spectralab.analysis.statusMDensity
```

The density calculation shall not be reimplemented separately in each public function.

## 6. Mathematical model

For a reference spectrum `R(λ)`, sample spectrum `S(λ)` and non-negative weighting function `W(λ)`, SpectraLab computes weighted transmittance using the canonical weighted-density engine.

Conceptually:

```text
weighted reference = integral R(λ) W(λ) dλ
weighted sample    = integral S(λ) W(λ) dλ

weighted transmittance = weighted sample / weighted reference

density = -log10(weighted transmittance)
```

The actual implementation may interpolate onto a common wavelength grid before integration. The interpolation and integration rules shall be recorded in the result provenance.

## 7. Public API taxonomy

### 7.1 White density

```matlab
result = spectralab.analysis.whiteDensity(reference, sample);
```

Purpose:

- broadband or photopically weighted density;
- already implemented;
- not automatically claimed as a complete ISO 5 measurement.

### 7.2 Status A density

```matlab
result = spectralab.analysis.statusADensity(reference, sample);
```

Purpose:

- Status A red, green and blue density channels;
- already implemented;
- uses the canonical weighted-density engine.

### 7.3 ISO visual density

```matlab
result = spectralab.analysis.isoVisualDensity(reference, sample);
```

Purpose:

- explicitly named ISO visual spectral density;
- implemented under ANL-007;
- uses the versioned ISO 5 spectral weighting dataset supplied with SpectraLab.

### 7.4 Status M density

```matlab
result = spectralab.analysis.statusMDensity(reference, sample);
```

Purpose:

- Status M spectral density channels;
- implemented under ANL-008;
- uses the versioned Status M spectral weighting data supplied with SpectraLab.

### 7.5 Generic user weighting

Future work may permit:

```matlab
result = spectralab.core.weightedDensity(reference, sample, filter);
```

This remains a calculation using a user-supplied weighting function. It shall not be labelled as an ISO density unless the weighting data and measurement conditions justify that claim.

## 8. Naming rules

Public function names shall identify the actual spectral density type.

Approved pattern:

```text
whiteDensity
statusADensity
isoVisualDensity
statusMDensity
```

Disallowed ambiguous names:

```text
ansiDensity
standardDensity
photographicDensity
```

A public name shall not imply broader standards compliance than the implementation and measurement provenance support.

## 9. Geometry and provenance

A density result shall be able to record, where known:

- transmission or reflection measurement;
- illumination geometry;
- collection geometry;
- diffuse or projection condition;
- instrument identity;
- measurement aperture;
- specimen backing, where applicable;
- polarization condition, where applicable;
- standard reference and edition;
- spectral weighting identifier;
- weighting dataset version;
- wavelength range;
- wavelength interval or calculation grid;
- interpolation method;
- integration method;
- warnings and validity notes.

Absence of geometric metadata shall not prevent SpectraLab from returning a calculated spectral density. It shall prevent the software from claiming verified full compliance.

## 10. Result structure

Density analyses should follow a consistent result structure. The exact field names may evolve, but the result should conceptually include:

```matlab
result.Result.Density
result.Result.Transmittance
result.Result.Weighting
result.Method
result.Standard
result.Provenance
result.Warnings
```

For multi-channel density types:

```matlab
result.Result.R
result.Result.G
result.Result.B
```

Each channel result should expose the same core fields wherever practical.

## 11. Standards-conformance language

SpectraLab documentation shall use precise wording.

Preferred:

- “Calculated using the ISO visual spectral weighting.”
- “Spectral density calculated according to the computational model used by SpectraLab.”
- “Measurement geometry was not verified.”
- “Full ISO 5 conformance is not claimed.”

Avoid:

- “ANSI-compliant density” without identifying the exact standard and conditions;
- “ISO density” when only a weighting curve was applied;
- “certified” or “compliant” unless all relevant conditions are known and verified.

## 12. Validation requirements

Every new density type shall include tests for:

- identical reference and sample producing zero density;
- 50% transmission producing approximately `log10(2)`;
- 10% transmission producing density 1;
- differing input wavelength grids;
- no common wavelength range;
- invalid or negative weighting values;
- zero weighted reference;
- sample values above reference;
- metadata and method provenance;
- expected warning behavior.

Where a standards dataset is used, tests shall also verify:

- wavelength values;
- monotonic wavelength ordering;
- expected wavelength range;
- non-negative weights;
- dataset identity;
- selected reference values or checksums.

## 13. Future extension

The framework may later be extended to:

- reflection density;
- additional ISO 5 spectral types;
- custom laboratory weighting functions;
- instrument-geometry profiles;
- conformance-assessment reports;
- uncertainty estimates.

Such extensions shall preserve the separation between:

```text
measurement geometry
spectral weighting
numerical computation
standards claim
```

## 14. Consequences

### Positive

- avoids an ambiguous `ansiDensity` API;
- aligns the roadmap with the ISO 5 standards family;
- keeps all density mathematics in one engine;
- makes provenance and limitations explicit;
- provides a stable extension pattern.

### Trade-offs

- full standards compliance cannot be inferred from spectral data alone;
- additional metadata may be needed for future conformance assessment;
- standard weighting datasets must be sourced and versioned carefully.

## 15. Roadmap impact

The approved analysis roadmap becomes:

```text
ANL-001 Spectral transmission             Complete
ANL-002 Spectral optical density          Complete
ANL-003 Common weighted-density engine    Complete
ANL-004 White density                     Complete
ANL-005 Status A RGB density              Complete
ANL-006 ISO 5 density framework           Complete with ED-017
ANL-007 ISO visual density                Complete
ANL-008 Status M density                  Complete
```

## 16. References

- ISO 5-1:2009, *Photography and graphic technology — Density measurements — Part 1: Geometry and functional notation*.
- ISO 5-2:2009, *Photography and graphic technology — Density measurements — Part 2: Geometric conditions for transmittance density*.
- ISO 5-3:2009, *Photography and graphic technology — Density measurements — Part 3: Spectral conditions*.
- ISO 5-4:2009, *Photography and graphic technology — Density measurements — Part 4: Geometric conditions for reflection density*.

## 17. Decision

Approved:

1. Do not implement a generic `ansiDensity` function.
2. Use ISO 5 terminology and explicitly named density types.
3. Keep all density calculations based on the common weighted-density engine.
4. Separate spectral calculation from measurement-geometry compliance.
5. Record enough provenance for later assessment.
6. ANL-007 and ANL-008 are implemented and verified in v0.8.0.
