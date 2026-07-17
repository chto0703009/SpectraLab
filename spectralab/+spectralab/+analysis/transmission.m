function analysis = transmission(referenceArchive, sampleArchive, options)
%TRANSMISSION Calculate spectral transmission from two SpectraLab archives.
%
%   analysis = spectralab.analysis.transmission( ...
%       referenceArchive, sampleArchive)
%
%   analysis = spectralab.analysis.transmission( ...
%       referenceArchive, sampleArchive, ...
%       Resample=true, ...
%       RefinementFactor=4, ...
%       InterpolationMethod="pchip", ...
%       WarnAboveOne=true)
%
% The spectral transmission is calculated as
%
%       T(lambda) = sample(lambda) / reference(lambda)
%
% Resampling behaviour
% --------------------
%
%   Resample=false
%
%       The measured wavelength values are used directly.
%       Reference and sample wavelength grids must be identical.
%
%   Resample=true
%
%       Reference and sample spectra are always interpolated onto a
%       refined common wavelength grid, even when their original
%       wavelength grids are identical.
%
% Options
% -------
%
%   Resample
%       Logical scalar. Default: false.
%
%   RefinementFactor
%       Positive integer controlling the refinement of the common
%       wavelength grid. Default: 1.
%
%       A factor of 1 preserves the original common spacing while still
%       passing both spectra through the interpolation operation.
%
%   InterpolationMethod
%       MATLAB interpolation method used by the resampling routine.
%       Default: "pchip".
%
%   WarnAboveOne
%       Emit a warning if calculated transmission exceeds 1.
%       Default: true.
%
% Result
% ------
%
%   analysis.Result.WavelengthNm
%   analysis.Result.Value
%
%   analysis.Definition.Type
%   analysis.Definition.Method
%
%   analysis.Parameters.Alignment
%   analysis.Parameters.Resampled
%   analysis.Parameters.RefinementFactor
%   analysis.Parameters.InterpolationMethod
%   analysis.Parameters.EffectiveWavelengthRangeNm
%
%   analysis.Source.Reference
%   analysis.Source.Sample
%
%   analysis.Identity.ContentHash

    arguments
        referenceArchive (1,1) struct
        sampleArchive    (1,1) struct

        options.Resample (1,1) logical = false

        options.RefinementFactor (1,1) double ...
            {mustBeInteger, mustBePositive} = 1

        options.InterpolationMethod (1,1) string = "pchip"

        options.WarnAboveOne (1,1) logical = true
    end


    %% Validate archives

    referenceValidation = ...
        spectralab.archive.validate(referenceArchive);

    if ~referenceValidation.IsValid
        error( ...
            "SpectraLab:Analysis:InvalidReference", ...
            "Reference archive is invalid:\n%s", ...
            join(referenceValidation.Errors, newline));
    end


    sampleValidation = ...
        spectralab.archive.validate(sampleArchive);

    if ~sampleValidation.IsValid
        error( ...
            "SpectraLab:Analysis:InvalidSample", ...
            "Sample archive is invalid:\n%s", ...
            join(sampleValidation.Errors, newline));
    end


    %% Read measured spectra

    referenceWavelength = ...
        double(referenceArchive.Measurement.Wavelength(:));

    referenceValue = ...
        double(referenceArchive.Measurement.Value(:));

    sampleWavelength = ...
        double(sampleArchive.Measurement.Wavelength(:));

    sampleValue = ...
        double(sampleArchive.Measurement.Value(:));


    %% Check reference signal

    if any(~isfinite(referenceValue)) || ...
            any(referenceValue <= 0)
			error( ...
			    "SpectraLab:Analysis:InvalidReferenceSignal", ...
			    "Reference spectrum must contain finite values greater " + ...
			    "than zero.");
    end


    %% Determine wavelength alignment

    gridsAreIdentical = ...
        isequal(referenceWavelength, sampleWavelength);


    if ~options.Resample

        if ~gridsAreIdentical
			error( ...
			    "SpectraLab:Analysis:WavelengthMismatch", ...
			    "Reference and sample wavelength grids differ. " + ...
			    "Set Resample=true to interpolate both spectra onto " + ...
			    "a common wavelength grid.");
        end

        wavelength = referenceWavelength;
        alignedReferenceValue = referenceValue;
        alignedSampleValue = sampleValue;

        alignment = "Exact";


		else

		    referenceSpec = spectralab.core.Spectrum( ...
		        referenceWavelength, ...
		        referenceValue);

		    sampleSpec = spectralab.core.Spectrum( ...
		        sampleWavelength, ...
		        sampleValue);

		    [referenceFine, sampleFine] = ...
		        spectralab.core.resampleSpectrumPair( ...
		            referenceSpec, ...
		            sampleSpec, ...
		            RefinementFactor=options.RefinementFactor, ...
		            Method=options.InterpolationMethod);

		    overlapMinimum = max( ...
		        referenceFine.WavelengthNm(1), ...
		        sampleFine.WavelengthNm(1));

		    overlapMaximum = min( ...
		        referenceFine.WavelengthNm(end), ...
		        sampleFine.WavelengthNm(end));

		    if overlapMinimum >= overlapMaximum
		        error( ...
		            "SpectraLab:Analysis:NoCommonWavelengthRange", ...
		            "Reference and sample spectra have no common wavelength range.");
		    end

		    referenceGrid = referenceFine.WavelengthNm(:);
		    sampleGrid = sampleFine.WavelengthNm(:);

		    commonGrid = unique([ ...
		        referenceGrid( ...
		            referenceGrid >= overlapMinimum & ...
		            referenceGrid <= overlapMaximum); ...
		        sampleGrid( ...
		            sampleGrid >= overlapMinimum & ...
		            sampleGrid <= overlapMaximum) ...
		    ]);

		    wavelength = commonGrid;

		    alignedReferenceValue = interp1( ...
		        referenceFine.WavelengthNm, ...
		        referenceFine.Power, ...
		        wavelength, ...
		        options.InterpolationMethod);

		    alignedSampleValue = interp1( ...
		        sampleFine.WavelengthNm, ...
		        sampleFine.Power, ...
		        wavelength, ...
		        options.InterpolationMethod);

		    alignment = "Interpolated";
		end


    %% Validate aligned reference signal

    if any(~isfinite(alignedReferenceValue)) || ...
            any(alignedReferenceValue <= 0)

        error( ...
            "SpectraLab:Analysis:InvalidReferenceSignal", ...
            [ ...
            "The aligned reference spectrum contains non-finite " ...
            "values or values less than or equal to zero." ...
            ]);
    end


    if any(~isfinite(alignedSampleValue))
        error( ...
            "SpectraLab:Analysis:InvalidSampleSignal", ...
            "The aligned sample spectrum contains non-finite values.");
    end


    %% Calculate transmission

    transmissionValue = ...
        alignedSampleValue ./ alignedReferenceValue;


    %% Warn when transmission exceeds unity

    if options.WarnAboveOne && any(transmissionValue > 1)
		warning( ...
		    "SpectraLab:Analysis:TransmittanceAboveOne", ...
		    "Calculated spectral transmission exceeds 1 at one or " + ...
		    "more wavelengths. Check reference and sample measurements.");    end


    %% Construct result

    analysis = struct();


    analysis.Identity = struct();

    analysis.Identity.UUID = ...
        string(java.util.UUID.randomUUID);

    analysis.Identity.Created = ...
        datetime("now", "TimeZone", "UTC");

    analysis.Identity.CreatedBy = ...
        "spectralab.analysis.transmission";


    analysis.Definition = struct();

    analysis.Definition.Type = ...
        "TransmissionSpectrum";

    analysis.Definition.Method = ...
        "SampleReferenceRatio";

    analysis.Definition.Expression = ...
        "T(lambda) = Sample(lambda) / Reference(lambda)";


    analysis.Parameters = struct();

    analysis.Parameters.Alignment = ...
        alignment;

    analysis.Parameters.Resampled = ...
        logical(options.Resample);

    analysis.Parameters.RefinementFactor = ...
        options.RefinementFactor;

    analysis.Parameters.InterpolationMethod = ...
        options.InterpolationMethod;

    analysis.Parameters.EffectiveWavelengthRangeNm = ...
        [wavelength(1), wavelength(end)];

    analysis.Parameters.WarnAboveOne = ...
        options.WarnAboveOne;


    analysis.Result = struct();

    analysis.Result.WavelengthNm = ...
        wavelength(:);

    analysis.Result.Value = ...
        transmissionValue(:);

    analysis.Result.Unit = ...
        "1";


    analysis.Source = struct();

    analysis.Source.Reference = ...
        makeSourceSummary(referenceArchive);

    analysis.Source.Sample = ...
        makeSourceSummary(sampleArchive);


    %% Deterministic analysis hash

    hashPayload = struct();

    hashPayload.Definition = ...
        analysis.Definition;

    hashPayload.Parameters = ...
        analysis.Parameters;

    hashPayload.Result = ...
        analysis.Result;

    hashPayload.Source = ...
        analysis.Source;

    analysis.Identity.ContentHash = ...
        spectralab.archive.contentHash(hashPayload);
end


function source = makeSourceSummary(archive)
%MAKESOURCESUMMARY Create concise provenance for an input archive.

    source = struct();

    source.UUID = ...
        readText(archive.Identity, "UUID");

    source.ContentHash = ...
        readText(archive.Identity, "ContentHash");

    source.MeasurementName = ...
        readText(archive.Measurement, "Name");

    source.Timestamp = ...
        readValue(archive.Measurement, "Timestamp");
end


function value = readText(source, fieldName)
%READTEXT Read a field and return it as a scalar string.

    value = "";

    if ~isstruct(source) || ...
            isempty(source) || ...
            ~isfield(source, fieldName)

        return
    end

    raw = source.(fieldName);

    if isempty(raw)
        return
    end

    try
        converted = string(raw);
    catch
        return
    end

    if ~isempty(converted)
        value = converted(1);
    end
end


function value = readValue(source, fieldName)
%READVALUE Read an optional field without changing its type.

    value = [];

    if ~isstruct(source) || ...
            isempty(source) || ...
            ~isfield(source, fieldName)

        return
    end

    value = source.(fieldName);
end