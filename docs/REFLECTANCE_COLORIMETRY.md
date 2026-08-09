# Reflectance Measurement and Colourimetry

**Status:** Normative SpectraLab implementation profile for v0.9.0-beta.2
**Related:** ED-022, `spectralab.analysis.colorimetry`

## Scope and terminology

SpectraLab stores the measured quantity as spectral reflectance factor
`R(lambda)` in percent. It is the primary scientific measurement. XYZ,
xyY and CIELAB are derived values and always retain their source archive,
observer, illuminant and calculation version.

The current one-shot workflow uses ArgyllCMS `spotread -s` in reflective
mode. The instrument is white-reference calibrated in that same session;
the archive records that it is a reflective measurement and preserves
spotread's reported colour values as control data.

This profile does **not** claim ISO 13655 M0, M1 or M2 conformance. The
measurement condition, geometry, fluorescence treatment and physical
reference standard must be explicitly qualified before such a claim is
made. They are therefore not inferred from a spotread result.

## Instrument-reported control values

Spotread may report `XYZ` and `Lab` tagged, for example, `D50 Lab`. These
values are preserved as `instrument_reported_only`. They are useful for
checking the instrument chain, but are not SpectraLab's canonical
colourimetry result because the complete illuminant SPD and calculation
parameters have not been supplied to SpectraLab.

## Canonical calculation

Canonical reflectance colourimetry requires all of the following:

1. archived `R(lambda)`;
2. an explicit illuminant SPD `S(lambda)` on an overlapping wavelength
   range;
3. a declared observer, currently CIE 1931 2 degree;
4. one common numerical wavelength grid.

Reflectance is converted from percent to factor before weighting:

```text
r(lambda) = R(lambda) / 100
```

SpectraLab integrates the reflected SPD `r(lambda) S(lambda)` with the
CIE colour-matching functions. With `xbar`, `ybar` and `zbar`, the raw
sample values are:

```text
Xraw = sum r(lambda) S(lambda) xbar(lambda) DeltaLambda
Yraw = sum r(lambda) S(lambda) ybar(lambda) DeltaLambda
Zraw = sum r(lambda) S(lambda) zbar(lambda) DeltaLambda
```

The reference white is calculated from the *same* illuminant spectrum:

```text
Xn_raw = sum S(lambda) xbar(lambda) DeltaLambda
Yn_raw = sum S(lambda) ybar(lambda) DeltaLambda
Zn_raw = sum S(lambda) zbar(lambda) DeltaLambda
k = 100 / Yn_raw
```

The same `k` is applied to both sample and white. This sets the reference
white to `Yn = 100` while preserving the patch luminance:

```text
XYZsample = k [Xraw, Yraw, Zraw]
XYZwhite  = k [Xn_raw, Yn_raw, Zn_raw]
```

CIELAB is then calculated with `XYZwhite` as reference white, using the
CIE 1976 L*a*b* equations. A patch is never independently normalized to
`Y = 100`; doing that would incorrectly force its lightness to `L* = 100`.

## Standards and data sources

- CIE 015:2018, *Colorimetry, 4th Edition*, defines the colorimetric
  framework, standard observers, illuminants, tristimulus and colour-space
  calculations. DOI: `10.25039/TR.015.2018`.
- CIE 1931 2 degree colour-matching functions supplied by SpectraLab are
  the CIE 2019 dataset, DOI: `10.25039/CIE.DS.xvudnb9b`.
- CIELAB follows CIE 1976 L*a*b* as implemented by
  `spectralab.analysis.lab`.

## Reproducibility rules

- `R(lambda)` and the illuminant SPD are retained, rather than only XYZ or
  Lab.
- JSON stores wavelength and spectral values as numeric IEEE-754 binary64
  (`double`) values. SpectraLab's JSON round-trip test requires the
  exported `R(lambda)` and wavelength arrays to be recovered exactly as
  the same MATLAB `double` values.
- The archive identity and content hash are carried into every derived
  colourimetry dataset.
- A correction to the calculation creates a new calculation version and
  derived export; it never rewrites the original measurement.
- JSON, CGATS, CSV, XYZ and Lab exporters serialize one canonical dataset;
  they do not recalculate colour values.

## ColorChecker sessions

ColorChecker patch archives are stricter than general one-shot archives:
they preserve `R(lambda)` and acquisition provenance but deliberately omit
instrument-reported XYZ and Lab. The original `colorchecker_session.json`
is immutable measurement documentation.

`spectralab.colorchecker.calculateColorimetry` reads a complete session and
its patch archives, calculates XYZ and CIELAB for an explicit illuminant and
observer, and writes a separate suffixed JSON copy. The source session JSON
and every MAT archive remain unchanged. D50 and CIE 1931 2 degree are the
documented defaults; another illuminant SPD may be supplied explicitly.
