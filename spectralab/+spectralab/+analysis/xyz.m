function result = xyz(inputData, options)
%XYZ Calculate CIE 1931 2 degree tristimulus values.
%
%   result = spectralab.analysis.xyz(inputData)
%
%   result = spectralab.analysis.xyz( ...
%       inputData, ...
%       Normalization="Y100")
%
%   inputData may be:
%
%       1. a scalar spectralab.core.Spectrum; or
%       2. a canonical SpectraLab spectral analysis result containing:
%
%              inputData.Result.WavelengthNm
%              inputData.Result.Value
%
%   The function follows the canonical SpectraLab weighting pipeline:
%
%       spectral input
%            ├─ xBar -> filterResponse -> integration -> X
%            ├─ yBar -> filterResponse -> integration -> Y
%            └─ zBar -> filterResponse -> integration -> Z
%
%   Normalization
%   -------------
%   "none"
%       Preserve the directly integrated relative tristimulus values.
%
%   "Y100"
%       Scale X, Y, and Z so that Y equals 100.
%
%   The wavelength-dependent X, Y, and Z responses are retained in the
%   returned result for plotting and scientific inspection.

    arguments
        inputData
        options.WavelengthRange (1,2) double = [NaN NaN]
        options.Normalization (1,1) string ...
            {mustBeMember(options.Normalization, ["none", "Y100"])} = "none"
    end

    xFilter = spectralab.filters.cie1931.xBar();
    yFilter = spectralab.filters.cie1931.yBar();
    zFilter = spectralab.filters.cie1931.zBar();

    xResponse = applyFilter( ...
        inputData, ...
        xFilter, ...
        options.WavelengthRange);

    yResponse = applyFilter( ...
        inputData, ...
        yFilter, ...
        options.WavelengthRange);

    zResponse = applyFilter( ...
        inputData, ...
        zFilter, ...
        options.WavelengthRange);

    validateCommonGrid(xResponse, yResponse, zResponse);

    rawX = integrateResponse(xResponse);
    rawY = integrateResponse(yResponse);
    rawZ = integrateResponse(zResponse);

    switch options.Normalization
        case "none"
            scaleFactor = 1;

        case "Y100"
            if ~isfinite(rawY) || rawY <= 0
                error( ...
                    "spectralab:analysis:xyz:InvalidYForNormalization", ...
                    "Y must be finite and positive for Y100 normalization.");
            end

            scaleFactor = 100 / rawY;
    end

    X = rawX * scaleFactor;
    Y = rawY * scaleFactor;
    Z = rawZ * scaleFactor;

    result = struct();
    result.Type = "CIE1931XYZ";

    result.Observer = struct();
    result.Observer.Name = "CIE 1931 2 degree standard observer";
    result.Observer.Source = ...
        "CIE 2019, DOI 10.25039/CIE.DS.xvudnb9b";

    result.XResponse = xResponse;
    result.YResponse = yResponse;
    result.ZResponse = zResponse;

    result.Range = struct();
    result.Range.EffectiveRangeNm = ...
        xResponse.Range.EffectiveRangeNm;
    result.Range.SampleCount = ...
        xResponse.Range.SampleCount;

    result.Processing = struct();
    result.Processing.Pipeline = ...
        "filterResponse -> trapezoidal integration";
    result.Processing.IntegrationMethod = "trapezoidal";
    result.Processing.Normalization = options.Normalization;
    result.Processing.ScaleFactor = scaleFactor;
    result.Processing.Observer = ...
        "CIE 1931 2 degree";

    result.Result = struct();
    result.Result.RawX = rawX;
    result.Result.RawY = rawY;
    result.Result.RawZ = rawZ;
    result.Result.X = X;
    result.Result.Y = Y;
    result.Result.Z = Z;
end


function response = applyFilter(inputData, filter, requestedRange)

    if all(isfinite(requestedRange))
        response = spectralab.analysis.filterResponse( ...
            inputData, ...
            filter, ...
            WavelengthRange=requestedRange);
        return
    end

    if any(isfinite(requestedRange))
        error( ...
            "spectralab:analysis:xyz:InvalidRange", ...
            "WavelengthRange must contain two finite values or be omitted.");
    end

    response = spectralab.analysis.filterResponse( ...
        inputData, ...
        filter);
end


function value = integrateResponse(response)

    wavelength = response.Result.WavelengthNm(:);
    weightedValue = response.Result.Value(:);

    value = trapz(wavelength, weightedValue);

    if ~isfinite(value)
        error( ...
            "spectralab:analysis:xyz:NonFiniteIntegral", ...
            "A tristimulus integral produced a non-finite value.");
    end
end


function validateCommonGrid(xResponse, yResponse, zResponse)

    xWavelength = xResponse.Result.WavelengthNm(:);
    yWavelength = yResponse.Result.WavelengthNm(:);
    zWavelength = zResponse.Result.WavelengthNm(:);

    if ~isequal(xWavelength, yWavelength, zWavelength)
        error( ...
            "spectralab:analysis:xyz:GridMismatch", ...
            "The xBar, yBar, and zBar responses must use one common wavelength grid.");
    end
end
