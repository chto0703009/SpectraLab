function result = xyY(xyzResult)
%XYY Convert a SpectraLab XYZ result to CIE xyY coordinates.
%
%   result = spectralab.analysis.xyY(xyzResult)
%
%   The input must be a canonical SpectraLab XYZ result containing:
%
%       xyzResult.Result.X
%       xyzResult.Result.Y
%       xyzResult.Result.Z
%
%   The conversion is:
%
%       x = X / (X + Y + Z)
%       y = Y / (X + Y + Z)
%       Y = Y
%
%   The luminance-like Y value is preserved exactly from the input XYZ
%   result. If the XYZ result used Y100 normalization, the returned Y is 100.
%
%   xyY is undefined when X + Y + Z is zero or non-finite.

    arguments
        xyzResult
    end

    validateXyzResult(xyzResult);

    X = xyzResult.Result.X;
    Y = xyzResult.Result.Y;
    Z = xyzResult.Result.Z;

    denominator = X + Y + Z;

    if ~isfinite(denominator) || denominator <= 0
        error( ...
            "spectralab:analysis:xyY:InvalidTristimulusSum", ...
            "X + Y + Z must be finite and positive to calculate xyY.");
    end

    x = X / denominator;
    y = Y / denominator;

    result = struct();
    result.Type = "CIExyY";

    result.Source = struct();
    result.Source.Type = "CIE1931XYZ";

    if isfield(xyzResult, "Observer")
        result.Observer = xyzResult.Observer;
    end

    result.Processing = struct();
    result.Processing.Conversion = ...
        "x=X/(X+Y+Z), y=Y/(X+Y+Z), Y preserved";
    result.Processing.SourceNormalization = sourceNormalization(xyzResult);

    result.Result = struct();
    result.Result.x = x;
    result.Result.y = y;
    result.Result.Y = Y;

    result.Result.X = X;
    result.Result.Z = Z;
    result.Result.TristimulusSum = denominator;
end


function validateXyzResult(xyzResult)

    if ~isstruct(xyzResult)
        error( ...
            "spectralab:analysis:xyY:InvalidInput", ...
            "Input must be a SpectraLab XYZ result structure.");
    end

    if ~isfield(xyzResult, "Result") || ...
            ~isstruct(xyzResult.Result)
        error( ...
            "spectralab:analysis:xyY:MissingResult", ...
            "The XYZ input is missing its Result section.");
    end

    requiredFields = ["X", "Y", "Z"];

    for fieldName = requiredFields
        if ~isfield(xyzResult.Result, fieldName)
            error( ...
                "spectralab:analysis:xyY:MissingField", ...
                "XYZ Result.%s is required.", ...
                fieldName);
        end

        value = xyzResult.Result.(fieldName);

        if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
            error( ...
                "spectralab:analysis:xyY:InvalidField", ...
                "XYZ Result.%s must be a finite numeric scalar.", ...
                fieldName);
        end
    end

    if isfield(xyzResult, "Type") && ...
            string(xyzResult.Type) ~= "CIE1931XYZ"
        error( ...
            "spectralab:analysis:xyY:UnexpectedType", ...
            "Input Type must be CIE1931XYZ.");
    end
end


function normalization = sourceNormalization(xyzResult)

    normalization = "unknown";

    if isfield(xyzResult, "Processing") && ...
            isstruct(xyzResult.Processing) && ...
            isfield(xyzResult.Processing, "Normalization")
        normalization = string(xyzResult.Processing.Normalization);
    end
end
