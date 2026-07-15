function result = lab(sampleXyz, referenceXyz)
%LAB Convert sample XYZ to CIELAB using a reference-white XYZ result.
%
%   result = spectralab.analysis.lab(sampleXyz, referenceXyz)
%
%   Both inputs must be canonical SpectraLab CIE1931XYZ result structures.
%   The reference XYZ represents the reference white.
%
%   For measured transmission work:
%
%       reference spectrum -> XYZ -> reference white
%       sample spectrum    -> XYZ -> sample colour
%
%   The conversion follows the CIE 1976 L*a*b* equations.
%
%   IMPORTANT:
%   sampleXyz and referenceXyz must use the same XYZ normalization.

    arguments
        sampleXyz
        referenceXyz
    end

    validateXyz(sampleXyz, "sample");
    validateXyz(referenceXyz, "reference");

    sampleNormalization = getNormalization(sampleXyz);
    referenceNormalization = getNormalization(referenceXyz);

    if sampleNormalization ~= referenceNormalization
        error( ...
            "spectralab:analysis:lab:NormalizationMismatch", ...
            "Sample and reference XYZ results must use the same normalization.");
    end

    X = sampleXyz.Result.X;
    Y = sampleXyz.Result.Y;
    Z = sampleXyz.Result.Z;

    Xn = referenceXyz.Result.X;
    Yn = referenceXyz.Result.Y;
    Zn = referenceXyz.Result.Z;

    if any([Xn Yn Zn] <= 0)
        error( ...
            "spectralab:analysis:lab:InvalidReferenceWhite", ...
            "Reference-white X, Y, and Z values must be positive.");
    end

    fx = cieF(X / Xn);
    fy = cieF(Y / Yn);
    fz = cieF(Z / Zn);

    L = 116 * fy - 16;
    a = 500 * (fx - fy);
    b = 200 * (fy - fz);

    result = struct();
    result.Type = "CIELAB";

    result.ReferenceWhite = struct();
    result.ReferenceWhite.X = Xn;
    result.ReferenceWhite.Y = Yn;
    result.ReferenceWhite.Z = Zn;
    result.ReferenceWhite.Normalization = referenceNormalization;

    result.Source = struct();
    result.Source.SampleType = string(sampleXyz.Type);
    result.Source.ReferenceType = string(referenceXyz.Type);

    result.Processing = struct();
    result.Processing.Standard = "CIE 1976 L*a*b*";
    result.Processing.Normalization = sampleNormalization;
    result.Processing.ReferenceWhite = "Measured reference XYZ";

    result.Result = struct();
    result.Result.L = L;
    result.Result.a = a;
    result.Result.b = b;

    result.Result.SampleX = X;
    result.Result.SampleY = Y;
    result.Result.SampleZ = Z;
end


function value = cieF(t)

    delta = 6 / 29;
    threshold = delta^3;

    value = zeros(size(t));

    above = t > threshold;
    below = ~above;

    value(above) = t(above).^(1/3);
    value(below) = t(below) / (3 * delta^2) + 4 / 29;
end


function validateXyz(xyzResult, role)

    if ~isstruct(xyzResult)
        error( ...
            "spectralab:analysis:lab:InvalidInput", ...
            "The %s XYZ input must be a structure.", ...
            role);
    end

    if ~isfield(xyzResult, "Type") || ...
            string(xyzResult.Type) ~= "CIE1931XYZ"
        error( ...
            "spectralab:analysis:lab:UnexpectedType", ...
            "The %s input must have Type CIE1931XYZ.", ...
            role);
    end

    if ~isfield(xyzResult, "Result") || ...
            ~isstruct(xyzResult.Result)
        error( ...
            "spectralab:analysis:lab:MissingResult", ...
            "The %s XYZ input is missing its Result section.", ...
            role);
    end

    requiredFields = ["X", "Y", "Z"];

    for fieldName = requiredFields
        if ~isfield(xyzResult.Result, fieldName)
            error( ...
                "spectralab:analysis:lab:MissingField", ...
                "The %s XYZ Result.%s field is required.", ...
                role, ...
                fieldName);
        end

        fieldValue = xyzResult.Result.(fieldName);

        if ~isnumeric(fieldValue) || ...
                ~isscalar(fieldValue) || ...
                ~isfinite(fieldValue)
            error( ...
                "spectralab:analysis:lab:InvalidField", ...
                "The %s XYZ Result.%s field must be a finite numeric scalar.", ...
                role, ...
                fieldName);
        end
    end
end


function normalization = getNormalization(xyzResult)

    normalization = "unknown";

    if isfield(xyzResult, "Processing") && ...
            isstruct(xyzResult.Processing) && ...
            isfield(xyzResult.Processing, "Normalization")
        normalization = string(xyzResult.Processing.Normalization);
    end
end
