# ED-022 — Colorimetry and Measurement Export Architecture

**Status:** Approved for v0.8.3-dev implementation
**Scope:** One reflectance point in v0.8.3-dev; patch sets in a later release.

## Decision

SpectraLab shall calculate colour data exactly once in a canonical,
versioned colourimetry result. JSON, CGATS, CSV and text exports shall
only serialize that result. They shall not implement their own XYZ, Lab,
or spectral conversion.

The canonical public calculation accepts a collection of samples. A
one-point measurement is represented as a collection containing one sample.
This freezes the data contract for later ColorChecker and other multi-patch
work without creating a separate one-point code path.

## Data flow

```text
immutable measurement archive(s)
        -> canonical colourimetry calculation
        -> versioned colourimetry dataset
        -> JSON | CGATS | CSV | XYZ/Lab text exports
```

Each dataset shall contain:

- a schema and calculation version;
- one or more sample records, each with identifier, spectral data and
  calculated XYZ, xyY and Lab;
- the observer, illuminant, illuminant SPD identity, normalization and
  computation method;
- source archive UUID, scientific content hash and filename;
- separately labelled instrument-reported colourimetry, when available.

## Reflectance rule

For reflectance, `R(lambda)` is the primary measurement. SpectraLab's
canonical XYZ and Lab shall be calculated from `R(lambda)`, a declared
illuminant SPD and a declared standard observer. Values reported directly
by spotread are retained only as instrument-reported control data; they are
not substituted for the canonical result.

## Provenance and correction policy

The original archive is immutable. A colourimetry result records its source
archive identities and calculation version. A later correction to the
central calculation creates a new derived result; it does not silently
rewrite an older export or archive.

## v0.8.3-dev delivery

The first delivery creates a one-sample dataset and exports JSON, CGATS,
CSV and concise XYZ/Lab representations. The API and serialized structure
remain collection-based from the first release. Plotting is optional and is
not a requirement for a dataset export.
