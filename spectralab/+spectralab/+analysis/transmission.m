function analysis = transmission(referenceArchive, sampleArchive, options)
%TRANSMISSION Create a transmission-spectrum analysis.
%
%   analysis = spectralab.analysis.transmission( ...
%       referenceArchive, sampleArchive)
%
%   calculates spectral transmittance as:
%
%       T(lambda) = sample(lambda) / reference(lambda)
%
%   The reference and sample wavelength grids must be identical.
%
%   Name-value options
%   ------------------
%   WarnAboveOne
%       Emit a warning when transmittance exceeds 1 at one or more
%       wavelengths. Default: true.
%
%   This option allows higher-level analysis functions to suppress the
%   wavelength-level warning and report only anomalies relevant to their
%   final result.
%
%   Example:
%
%       result = spectralab.analysis.transmission( ...
%           referenceArchive, ...
%           sampleArchive, ...
%           WarnAboveOne=false);

    arguments
        referenceArchive (1,1) struct
        sampleArchive (1,1) struct

        options.WarnAboveOne (1,1) logical = true
    end

    referenceValidation = ...
        spectralab.archive.validate(referenceArchive);

    sampleValidation = ...
        spectralab.archive.validate(sampleArchive);

    if ~referenceValidation.IsValid
        error( ...
            "SpectraLab:Analysis:InvalidReference", ...
            "Reference archive is invalid:\n%s", ...
            strjoin(referenceValidation.Errors, newline));
    end

    if ~sampleValidation.IsValid
        error( ...
            "SpectraLab:Analysis:InvalidSample", ...
            "Sample archive is invalid:\n%s", ...
            strjoin(sampleValidation.Errors, newline));
    end

    referenceWavelength = ...
        referenceArchive.Measurement.Wavelength(:);

    sampleWavelength = ...
        sampleArchive.Measurement.Wavelength(:);

    referenceValue = ...
        referenceArchive.Measurement.Value(:);

    sampleValue = ...
        sampleArchive.Measurement.Value(:);

    if numel(referenceWavelength) ~= numel(sampleWavelength) || ...
            ~isequal(referenceWavelength, sampleWavelength)

        error( ...
            "SpectraLab:Analysis:WavelengthMismatch", ...
            "Reference and sample wavelength grids are not identical. " + ...
            "Explicit spectral alignment is required.");
    end

    if numel(referenceValue) ~= numel(sampleValue)
        error( ...
            "SpectraLab:Analysis:ValueLengthMismatch", ...
            "Reference and sample value vectors have different lengths.");
    end

    if any(~isfinite(referenceValue)) || ...
            any(~isfinite(sampleValue))

        error( ...
            "SpectraLab:Analysis:NonFiniteInput", ...
            "Reference and sample values must be finite.");
    end

    if any(referenceValue <= 0)
        error( ...
            "SpectraLab:Analysis:InvalidReferenceSignal", ...
            "Reference values must be greater than zero.");
    end

    transmittance = sampleValue ./ referenceValue;

    analysis.Identity.UUID = ...
        string(java.util.UUID.randomUUID);

    analysis.Identity.Created = ...
        datetime("now");

    analysis.Identity.CreatedBy = ...
        "SpectraLab";

    analysis.Identity.HashAlgorithm = ...
        "SHA-256";

    analysis.Version.Format = ...
        "SLAB-ANALYSIS-MAT";

    analysis.Version.Version = ...
        "0.1";

    analysis.Version.Software = ...
        spectralab.version();

    analysis.Definition.Type = ...
        "TransmissionSpectrum";

    analysis.Definition.Method = ...
        "SampleReferenceRatio";

    analysis.Result.Kind = ...
        "Spectral";

    analysis.Result.Quantity = ...
        "Transmittance";

    analysis.Result.WavelengthNm = ...
        referenceWavelength;

    analysis.Result.Value = ...
        transmittance;

    analysis.Result.Unit = ...
        "1";

    analysis.Result.DisplayUnit = ...
        "%";

    analysis.Result.DisplayScale = ...
        100;

    analysis.Sources = [
        makeSource(referenceArchive, "Reference")
        makeSource(sampleArchive, "Sample")
    ];

    analysis.Parameters.Alignment = ...
        "Exact";

    analysis.Parameters.WarnAboveOne = ...
        options.WarnAboveOne;

    analysis.Metadata = ...
        struct();

    analysis.History = ...
        struct.empty;

    payload.Definition = ...
        analysis.Definition;

    payload.Result = ...
        analysis.Result;

    payload.Sources = ...
        analysis.Sources;

    payload.Parameters = ...
        analysis.Parameters;

    analysis.Identity.ContentHash = ...
        spectralab.archive.contentHash(payload);

    if options.WarnAboveOne && any(transmittance > 1)
        warning( ...
            "SpectraLab:Analysis:TransmittanceAboveOne", ...
            "Calculated transmittance exceeds 1 at one or more wavelengths.");
    end
end


function source = makeSource(archive, role)

    source.Kind = ...
        "Measurement";

    source.Role = ...
        string(role);

    source.Format = ...
        string(archive.Version.Format);

    source.UUID = ...
        string(archive.Identity.UUID);

    source.ContentHash = ...
        string(archive.Identity.ContentHash);

    source.Quantity = ...
        "MeasuredSpectrum";

    source.MeasurementMode = ...
        "Unspecified";

    if isfield(archive.Measurement, "Mode") && ...
            ~isempty(archive.Measurement.Mode)

        source.MeasurementMode = ...
            string(archive.Measurement.Mode);
    end

    source.MeasurementName = ...
        string(archive.Measurement.Name);

    source.Timestamp = ...
        archive.Measurement.Timestamp;
end