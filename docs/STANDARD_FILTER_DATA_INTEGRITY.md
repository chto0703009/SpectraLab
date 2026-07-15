# Standard Filter Data Integrity

The standard filter library records both scientific provenance and file
integrity.

## CIE datasets

The manifest records the official CIE dataset DOI and SHA-256 digest for each
bundled CSV file. Automated tests verify the digest and expected table shape.

This detects accidental:

- editing;
- truncation;
- replacement;
- line-ending conversion;
- corruption.

## Status A

The Status A implementation records its source as ANSI/ISO 5-3:1995,
Table 3. Because the documentary values are embedded in MATLAB source rather
than a separate CSV file, tests verify selected published logarithmic values
after conversion to normalized linear spectral products.

The conversion is:

```text
value = 10^(logProduct - 5)
```

Git history provides file-level integrity for the complete implementation,
while the tests protect representative scientific values and peak locations.
