%% CIELAB from measured LED reference and LED-through-sample spectra
%
% The reference and sample are first converted to raw XYZ values.
% One common scale factor, derived from the reference Y value, is then
% applied to both XYZ results. This preserves the sample/reference
% luminance relationship while setting the measured reference white to
% Yn = 100.

startup

[referenceFile, referenceFolder] = uigetfile( ...
    "*.mat", ...
    "Select the LED reference archive");

if isequal(referenceFile, 0)
    error("No reference archive was selected.");
end

[sampleFile, sampleFolder] = uigetfile( ...
    "*.mat", ...
    "Select the LED-through-sample archive");

if isequal(sampleFile, 0)
    error("No sample archive was selected.");
end

referencePath = fullfile(referenceFolder, referenceFile);
samplePath = fullfile(sampleFolder, sampleFile);

referenceArchive = spectralab.archive.load(referencePath);
sampleArchive = spectralab.archive.load(samplePath);

referenceSpec = spectralab.archive.restore(referenceArchive);
sampleSpec = spectralab.archive.restore(sampleArchive);

assert( ...
    isa(referenceSpec, "spectralab.core.Spectrum"), ...
    "Reference archive did not restore to a Spectrum.");

assert( ...
    isa(sampleSpec, "spectralab.core.Spectrum"), ...
    "Sample archive did not restore to a Spectrum.");

%% Calculate raw XYZ values on the measured scale

referenceRaw = spectralab.analysis.xyz( ...
    referenceSpec, ...
    Normalization="none");

sampleRaw = spectralab.analysis.xyz( ...
    sampleSpec, ...
    Normalization="none");

if ~isfinite(referenceRaw.Result.Y) || referenceRaw.Result.Y <= 0
    error( ...
        "validation:InvalidReferenceY", ...
        "The measured reference Y value must be finite and positive.");
end

%% Apply one common scale factor derived from the reference

scaleFactor = 100 / referenceRaw.Result.Y;

referenceXyz = referenceRaw;
sampleXyz = sampleRaw;

referenceXyz.Result.X = referenceRaw.Result.X * scaleFactor;
referenceXyz.Result.Y = referenceRaw.Result.Y * scaleFactor;
referenceXyz.Result.Z = referenceRaw.Result.Z * scaleFactor;

sampleXyz.Result.X = sampleRaw.Result.X * scaleFactor;
sampleXyz.Result.Y = sampleRaw.Result.Y * scaleFactor;
sampleXyz.Result.Z = sampleRaw.Result.Z * scaleFactor;

referenceXyz.Processing.Normalization = "ReferenceY100";
referenceXyz.Processing.ScaleFactor = scaleFactor;

sampleXyz.Processing.Normalization = "ReferenceY100";
sampleXyz.Processing.ScaleFactor = scaleFactor;

%% Convert sample XYZ to CIELAB relative to measured reference white

labResult = spectralab.analysis.lab( ...
    sampleXyz, ...
    referenceXyz);

fprintf("\nReference-scaled XYZ\n");

fprintf( ...
    "Reference: Xn = %.6f, Yn = %.6f, Zn = %.6f\n", ...
    referenceXyz.Result.X, ...
    referenceXyz.Result.Y, ...
    referenceXyz.Result.Z);

fprintf( ...
    "Sample:    X  = %.6f, Y  = %.6f, Z  = %.6f\n", ...
    sampleXyz.Result.X, ...
    sampleXyz.Result.Y, ...
    sampleXyz.Result.Z);

fprintf("\nCommon scale factor\n");
fprintf("Scale factor = %.9f\n", scaleFactor);

fprintf("\nCIELAB relative to measured LED reference\n");
fprintf("L* = %.6f\n", labResult.Result.L);
fprintf("a* = %.6f\n", labResult.Result.a);
fprintf("b* = %.6f\n", labResult.Result.b);
