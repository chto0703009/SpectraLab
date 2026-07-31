<!--
SpectraLab Documentation
Document: ROADMAP.md
Version: v0.8.0
Status: CURRENT
-->

# Roadmap

The roadmap communicates the long-term engineering direction of SpectraLab.

It describes where the project is heading. It does not promise exactly how or when future work will be implemented.

The objective of the roadmap is to communicate direction, not to predict the future.

---

## Guiding Engineering Principles

The roadmap is governed by long-term engineering principles.

- Preserve a stable public API whenever practical.
- Extend functionality through modular design.
- Prefer reliability over rapid feature growth.
- Improve documentation together with software.
- Verify before releasing.
- Preserve compatibility whenever possible.

These principles should remain stable even as the software evolves.

---

## Strategic Development Priorities

The roadmap describes engineering priorities rather than detailed feature lists.

---

### Completed in v0.8.0

Version 0.8.0 established the scientific analysis and reporting foundation:

- spectral transmission and optical density;
- white, Status A, ISO visual and Status M density;
- CIE XYZ, xyY, CIELAB and colour rendering analyses;
- a single authoritative registry for every reportable analysis;
- deterministic PDF reporting and full-resolution PNG figure export.

Future analysis and report development shall extend the authoritative registry
rather than introduce separate report-specific definitions.

---

### Instrument Support

SpectraLab will continue extending support for additional spectrometers while preserving a consistent user experience and stable engineering framework.

Future work will prioritize instruments that can be integrated through well-established interfaces such as ArgyllCMS `spotread`. This naturally includes compatible instruments such as the X-Rite i1Pro, alongside the currently supported X-Rite i1Pro2, where the underlying measurement workflow and driver architecture can be reused.

The objective is to broaden instrument support while maintaining a single, consistent user experience rather than introducing instrument-specific workflows.

New instrument support should require minimal changes to user applications by preserving the public API and measurement workflow whenever practical.

---

### Data Exchange and Interoperability

SpectraLab will continue improving the exchange of measurement data with external software, scientific workflows and long-term archives.

Export formats are vehicles that enable spectral measurements to move safely between tools without losing essential information.

Future development may include additional exchange formats capable of preserving:

- spectral data,
- metadata,
- calibration information,
- quality-related information,
- traceability information,
- information required for reproducible scientific and engineering work.

The objective is not simply to support more file formats.

The objective is to ensure that measurement data remain useful throughout their entire lifetime.

Software should never imprison data.

---

### Data Integrity and Traceability

SpectraLab should preserve the scientific context of measured data throughout acquisition, storage, processing and export.

Data should not lose meaning when transferred between tools.

---

### Visualization and Analysis

SpectraLab will continue improving visualisation and analysis tools while maintaining simplicity and usability.

New analysis functionality should support understanding without making the core workflow harder to use.

---

### Documentation

Documentation will continue to evolve together with the software.

Documentation is part of the engineering process, not an afterthought.

---

### Software Quality

SpectraLab will continue expanding automated verification, regression testing and release verification wherever these improvements increase reliability.

Quality improvements are considered engineering progress even when they do not add visible features.

---

## Long-Term Vision

SpectraLab aims to become a reliable engineering platform for spectral measurements.

The project should support multiple instruments, preserve a stable engineering philosophy and enable reproducible scientific and engineering workflows.

Growth should be driven by engineering value rather than by the number of implemented features.

---

## Evolution of the Roadmap

The roadmap is reviewed at every public release.

It evolves through engineering experience rather than short-term opportunities.

Changes should remain consistent with the engineering philosophy described in `docs/DEVELOPMENT_PHILOSOPHY.md`.

The roadmap communicates direction, not commitments.

It is aspirational rather than contractual.

---

## Closing Statement

Reliable engineering requires reliable measurements.

Reliable measurements require data that remain understandable, reproducible and transferable.

SpectraLab will continue to evolve through careful engineering rather than rapid expansion.

The roadmap is a compass, not a schedule.
