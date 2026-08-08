function dataset = colorimetry(inputData, options)
%COLORIMETRY Calculate one canonical colourimetry dataset from spectra.
%
%   DATASET = spectralab.analysis.colorimetry(SPECTRUM, Illuminant=SPD)
%   DATASET = spectralab.analysis.colorimetry(COLLECTION, Illuminant=SPD)
%   DATASET = spectralab.analysis.colorimetry(ARCHIVEFILE, Illuminant=SPD)
%
% The result is collection-based even for one spectrum. For canonical
% reflectance colorimetry, one common reference-white scale is derived
% from the supplied illuminant SPD. Exporters must serialize this result
% rather than recalculate XYZ or Lab. See docs/REFLECTANCE_COLORIMETRY.md.

arguments
    inputData
    options.Illuminant = []
    options.Observer (1,1) string ...
        {mustBeMember(options.Observer, "CIE1931_2")} = "CIE1931_2"
end

[spectra, sources] = normalizeInput(inputData);
illuminant = options.Illuminant;
if ~isempty(illuminant) && ~isa(illuminant, "spectralab.core.Spectrum")
    error("SpectraLab:Colorimetry:InvalidIlluminant", ...
        "Illuminant must be a spectralab.core.Spectrum.");
end

samples = repmat(emptySample(), numel(spectra), 1);
for index = 1:numel(spectra)
    spec = spectra{index};
    samples(index) = makeSample(spec, sources(index), illuminant, options.Observer);
end

dataset = struct();
dataset.Format = "spectralab.colorimetry.dataset.v1";
dataset.SchemaVersion = 1;
dataset.CalculationVersion = "COL-001";
dataset.CreatedBy = "SpectraLab " + spectralab.version();
dataset.CreatedAt = char(datetime("now", "TimeZone", "local"));
dataset.Observer = options.Observer;
dataset.SampleCount = numel(samples);
dataset.Samples = samples;
end

function sample = makeSample(spec, source, illuminant, observer)
sample = emptySample();
sample.SampleID = spec.Label;
sample.Source = source;
sample.Spectrum = struct( ...
    "WavelengthNm", spec.WavelengthNm(:).', ...
    "Value", spec.Power(:).', ...
    "Unit", spec.PowerUnit);

reported = instrumentReported(spec);
if isempty(illuminant)
    if ~reported.Available
        error("SpectraLab:Colorimetry:IlluminantRequired", ...
            "Reflectance colourimetry requires an illuminant SPD. " + ...
            "Supply Illuminant=... or retain spotread's reported values.");
    end
    if upper(reported.Illuminant) ~= "D50"
        sample.Colorimetry = reportedColorimetry(reported, observer);
        sample.InstrumentReported = reported;
        return
    end
    illuminant = spectralab.filters.cie.d50();
end

if ~contains(lower(spec.PowerUnit), "reflectance")
    error("SpectraLab:Colorimetry:UnsupportedQuantity", ...
        "Canonical colourimetry currently requires relative reflectance data.");
end

[wavelength, reflectance, illumination] = commonGrid(spec, illuminant);
sampleSpectrum = spectralab.core.Spectrum( ...
    wavelength, (reflectance ./ 100) .* illumination, spec.Label, ...
    struct(), struct(), struct(), "relative reflected spectral power");
whiteSpectrum = spectralab.core.Spectrum( ...
    wavelength, illumination, illuminant.Label, ...
    struct(), struct(), struct(), "relative illuminant spectral power");

sampleRaw = spectralab.analysis.xyz(sampleSpectrum, Normalization="none");
whiteRaw = spectralab.analysis.xyz(whiteSpectrum, Normalization="none");
scaleFactor = 100 / whiteRaw.Result.Y;
sampleXyz = referenceNormalizedXyz(sampleRaw, scaleFactor);
whiteXyz = referenceNormalizedXyz(whiteRaw, scaleFactor);
lab = spectralab.analysis.lab(sampleXyz, whiteXyz);
xyy = spectralab.analysis.xyY(sampleXyz);

sample.Colorimetry = struct( ...
    "Status", "canonical", ...
    "Method", "R(lambda) * illuminant SPD -> CIE 1931 XYZ -> CIELAB", ...
    "Observer", observer, ...
    "Illuminant", struct("Label", illuminant.Label, ...
        "Unit", illuminant.PowerUnit, ...
        "WavelengthRangeNm", [wavelength(1) wavelength(end)]), ...
    "XYZ", xyzValues(sampleXyz), ...
    "xyY", struct("x", xyy.Result.x, "y", xyy.Result.y, "Y", xyy.Result.Y), ...
    "Lab", struct("L", lab.Result.L, "a", lab.Result.a, "b", lab.Result.b), ...
    "ReferenceWhiteXYZ", struct("X", whiteXyz.Result.X, ...
        "Y", whiteXyz.Result.Y, "Z", whiteXyz.Result.Z));
sample.InstrumentReported = instrumentReported(spec);
sample.Verification = compareInstrumentReported( ...
    sample.Colorimetry, sample.InstrumentReported);
end

function verification = compareInstrumentReported(calculated, reported)
%COMPAREINSTRUMENTREPORTED Informatively compare spotread and SpectraLab.

verification = struct("Status", "not_available", "Method", "", ...
    "DeltaXYZ", struct(), "DeltaLab", struct());
if ~reported.Available || ~contains(upper(calculated.Illuminant.Label), "D50")
    return
end
verification.Status = "informational";
verification.Method = "SpectraLab CIE D50 / CIE 1931 2 degree versus spotread reported values";
verification.DeltaXYZ = struct( ...
    "X", calculated.XYZ.X - reported.XYZ.X, ...
    "Y", calculated.XYZ.Y - reported.XYZ.Y, ...
    "Z", calculated.XYZ.Z - reported.XYZ.Z);
verification.DeltaLab = struct( ...
    "L", calculated.Lab.L - reported.Lab.L, ...
    "a", calculated.Lab.a - reported.Lab.a, ...
    "b", calculated.Lab.b - reported.Lab.b);
end

function result = referenceNormalizedXyz(rawResult, scaleFactor)
%REFERENCENORMALIZEDXYZ Apply the illuminant-white scale to one XYZ result.

if ~isfinite(scaleFactor) || scaleFactor <= 0
    error("SpectraLab:Colorimetry:InvalidReferenceWhite", ...
        "The illuminant reference white must have positive Y.");
end
result = rawResult;
result.Result.X = rawResult.Result.X * scaleFactor;
result.Result.Y = rawResult.Result.Y * scaleFactor;
result.Result.Z = rawResult.Result.Z * scaleFactor;
result.Processing.Normalization = "ReferenceY100";
result.Processing.ScaleFactor = scaleFactor;
result.Processing.ReferenceWhite = "Illuminant SPD";
end

function values = xyzValues(xyz)
values = struct("X", xyz.Result.X, "Y", xyz.Result.Y, "Z", xyz.Result.Z);
end

function value = reportedColorimetry(reported, observer)
xyz = reported.XYZ;
sumXYZ = xyz.X + xyz.Y + xyz.Z;
value = struct( ...
    "Status", "instrument_reported_only", ...
    "Method", "spotread reported XYZ and Lab; no SpectraLab illuminant SPD supplied", ...
    "Observer", observer, ...
    "Illuminant", struct("Label", reported.Illuminant, "Unit", ""), ...
    "XYZ", xyz, ...
    "xyY", struct("x", xyz.X / sumXYZ, "y", xyz.Y / sumXYZ, "Y", xyz.Y), ...
    "Lab", reported.Lab, ...
    "ReferenceWhiteXYZ", struct());
end

function reported = instrumentReported(spec)
reported = struct("Available", false, "XYZ", struct(), "Lab", struct(), ...
    "Illuminant", "", "Observer", "", "Source", "");
if ~isfield(spec.Metadata, "spotread_colorimetry")
    return
end
raw = spec.Metadata.spotread_colorimetry;
if ~isstruct(raw) || ~isfield(raw, "available") || ~logical(raw.available) || ...
        ~isfield(raw, "xyz") || ~isfield(raw, "lab")
    return
end
xyz = double(raw.xyz(:));
lab = double(raw.lab(:));
if numel(xyz) ~= 3 || numel(lab) ~= 3 || ...
        any(~isfinite([xyz; lab])) || sum(xyz) <= 0
    return
end
reported.Available = true;
reported.XYZ = struct("X", xyz(1), "Y", xyz(2), "Z", xyz(3));
reported.Lab = struct("L", lab(1), "a", lab(2), "b", lab(3));
reported.Illuminant = string(raw.illuminant);
if isfield(raw, "observer")
    reported.Observer = string(raw.observer);
end
if isfield(raw, "source")
    reported.Source = string(raw.source);
end
end

function [wavelength, reflectance, illumination] = commonGrid(spec, illuminant)
lowerLimit = max(spec.WavelengthNm(1), illuminant.WavelengthNm(1));
upperLimit = min(spec.WavelengthNm(end), illuminant.WavelengthNm(end));
mask = spec.WavelengthNm >= lowerLimit & spec.WavelengthNm <= upperLimit;
wavelength = spec.WavelengthNm(mask);
if numel(wavelength) < 2
    error("SpectraLab:Colorimetry:NoCommonWavelengthRange", ...
        "Reflectance and illuminant must share at least two wavelengths.");
end
reflectance = spec.Power(mask);
illumination = interp1(illuminant.WavelengthNm, illuminant.Power, ...
    wavelength, "pchip");
if any(~isfinite(illumination)) || any(illumination < 0)
    error("SpectraLab:Colorimetry:InvalidIlluminant", ...
        "Illuminant values on the common wavelength grid must be finite and non-negative.");
end
end

function [spectra, sources] = normalizeInput(inputData)
spectra = {};
sources = struct.empty;
if isa(inputData, "spectralab.core.Spectrum")
    spectra = {inputData};
    sources = sourceRecord(struct(), "");
elseif isa(inputData, "spectralab.core.SpectrumCollection")
    for index = 1:inputData.count()
        spectra{end+1} = inputData.get(index); %#ok<AGROW>
        sources(end+1) = sourceRecord(struct(), ""); %#ok<AGROW>
    end
elseif isstruct(inputData) && isfield(inputData, "Measurement")
    spectra = {spectralab.archive.restore(inputData)};
    sources = sourceRecord(inputData, "");
elseif ischar(inputData) || (isstring(inputData) && isscalar(inputData))
    filename = string(inputData);
    archive = spectralab.archive.load(filename, Quiet=true);
    spectra = {spectralab.archive.restore(archive)};
    sources = sourceRecord(archive, filename);
else
    error("SpectraLab:Colorimetry:InvalidInput", ...
        "Input must be a Spectrum, SpectrumCollection, archive, or archive filename.");
end
if isempty(spectra)
    error("SpectraLab:Colorimetry:EmptyCollection", ...
        "Colourimetry requires at least one spectrum.");
end
end

function source = sourceRecord(archive, filename)
source = struct("ArchiveUUID", "", "ContentHash", "", "Filename", string(filename));
if isstruct(archive) && isfield(archive, "Identity")
    if isfield(archive.Identity, "UUID"), source.ArchiveUUID = string(archive.Identity.UUID); end
    if isfield(archive.Identity, "ContentHash"), source.ContentHash = string(archive.Identity.ContentHash); end
end
end

function sample = emptySample()
sample = struct("SampleID", "", "Source", struct(), "Spectrum", struct(), ...
    "Colorimetry", struct(), "InstrumentReported", struct(), ...
    "Verification", struct());
end
