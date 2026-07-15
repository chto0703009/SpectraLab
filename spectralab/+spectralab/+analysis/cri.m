function result = cri(inputData, options)
%CRI Calculate CIE 13.3-1995 colour rendering indices.
%
%   result = spectralab.analysis.cri(inputData)
%
%   The input may be:
%
%       1. a scalar spectralab.core.Spectrum; or
%       2. a canonical SpectraLab spectral result containing:
%
%              inputData.Result.WavelengthNm
%              inputData.Result.Value
%
%   The implementation returns:
%
%       result.Result.Ra
%       result.Result.R      % 1-by-14, R1 ... R14
%       result.Result.CCT
%       result.Result.Duv
%
%   CIE 13.3 reference illuminant:
%
%       CCT < 5000 K   Planckian radiator
%       CCT >= 5000 K  CIE daylight illuminant
%
%   IMPORTANT
%   ---------
%   CIE 13.3 recommends spectral intervals of at most 5 nm. SpectraLab
%   interpolates the measured input onto a 5 nm calculation grid.
%
%   The method is intended for approximately white light sources. A warning
%   is emitted if the test/reference chromaticity difference exceeds the
%   CIE practical tolerance of 5.4e-3 in the CIE 1960 UCS diagram.

    arguments
        inputData
        options.WavelengthRange (1,2) double = [380 780]
        options.RoundIndices (1,1) logical = false
    end

    [inputWavelength, inputValue, inputName] = resolveInput(inputData);
    validateInput(inputWavelength, inputValue);

    requestedRange = options.WavelengthRange;

    if any(~isfinite(requestedRange)) || requestedRange(1) >= requestedRange(2)
        error( ...
            "spectralab:analysis:cri:InvalidRange", ...
            "WavelengthRange must be a finite [minimum maximum] interval.");
    end

    lowerNm = max([requestedRange(1), min(inputWavelength), 380]);
    upperNm = min([requestedRange(2), max(inputWavelength), 780]);

    calculationWavelength = (ceil(lowerNm/5)*5 : 5 : floor(upperNm/5)*5).';

    if numel(calculationWavelength) < 2
        error( ...
            "spectralab:analysis:cri:TooFewSamples", ...
            "The common CRI wavelength interval must contain at least two samples.");
    end

    testSpd = interp1( ...
        inputWavelength, ...
        inputValue, ...
        calculationWavelength, ...
        "linear");

    if any(~isfinite(testSpd)) || all(testSpd <= 0)
        error( ...
            "spectralab:analysis:cri:InvalidSpectrum", ...
            "The interpolated test spectrum must be finite and contain positive values.");
    end

    [xBar, yBar, zBar] = colourMatchingFunctions(calculationWavelength);

    testSpd = normalizeIlluminantY100( ...
        calculationWavelength, testSpd, yBar);

    testWhiteXyz = integrateXyz( ...
        calculationWavelength, testSpd, xBar, yBar, zBar);

    [testU, testV] = xyzToUv(testWhiteXyz);

    cct = estimateCctPlanckian( ...
        testU, testV, calculationWavelength, xBar, yBar, zBar);

    if cct < 5000
        referenceKind = "Planckian radiator";
        referenceSpd = planckianSpd(calculationWavelength, cct);
    else
        referenceKind = "CIE daylight";
        referenceSpd = daylightSpd(calculationWavelength, cct);
    end

    referenceSpd = normalizeIlluminantY100( ...
        calculationWavelength, referenceSpd, yBar);

    referenceWhiteXyz = integrateXyz( ...
        calculationWavelength, referenceSpd, xBar, yBar, zBar);

    [referenceU, referenceV] = xyzToUv(referenceWhiteXyz);

    duvSigned = signedUvDistanceToPlanckian( ...
        testU, testV, cct, calculationWavelength, xBar, yBar, zBar);

    chromaticityDifference = hypot( ...
        testU - referenceU, ...
        testV - referenceV);

    if chromaticityDifference > 5.4e-3

    warningMessage = sprintf( ...
        ['Test/reference chromaticity difference %.6g exceeds ' ...
         'the CIE practical tolerance 5.4e-3. ' ...
         'CRI may be less accurate.'], ...
        chromaticityDifference);

    warning( ...
        'spectralab:analysis:cri:ReferenceChromaticityDifference', ...
        '%s', ...
        warningMessage);
end

    samples = spectralab.filters.cri.all();

    R = zeros(1,14);
    deltaE = zeros(1,14);
    testSampleXyz = zeros(14,3);
    referenceSampleXyz = zeros(14,3);

    for index = 1:14
        sampleFactor = samples{index}.evaluate(calculationWavelength);
        sampleFactor = sampleFactor(:);

        testSampleSpd = testSpd .* sampleFactor;
        referenceSampleSpd = referenceSpd .* sampleFactor;

        xyzTest = integrateXyz( ...
            calculationWavelength, testSampleSpd, xBar, yBar, zBar);

        xyzReference = integrateXyz( ...
            calculationWavelength, referenceSampleSpd, xBar, yBar, zBar);

        testSampleXyz(index,:) = xyzTest;
        referenceSampleXyz(index,:) = xyzReference;

        [uTestSample, vTestSample] = xyzToUv(xyzTest);
        [uReferenceSample, vReferenceSample] = xyzToUv(xyzReference);

        [uAdapted, vAdapted] = adaptCriUv( ...
            uTestSample, ...
            vTestSample, ...
            testU, ...
            testV, ...
            referenceU, ...
            referenceV);

        [Utest, Vtest, Wtest] = uvYToUvw( ...
            uAdapted, ...
            vAdapted, ...
            xyzTest(2), ...
            referenceU, ...
            referenceV);

        [Uref, Vref, Wref] = uvYToUvw( ...
            uReferenceSample, ...
            vReferenceSample, ...
            xyzReference(2), ...
            referenceU, ...
            referenceV);

        deltaE(index) = sqrt( ...
            (Uref-Utest)^2 + ...
            (Vref-Vtest)^2 + ...
            (Wref-Wtest)^2);

        R(index) = 100 - 4.6 * deltaE(index);
    end

    Ra = mean(R(1:8));

    if options.RoundIndices
        Rreported = round(R);
        Rareported = round(mean(Rreported(1:8)));
    else
        Rreported = R;
        Rareported = Ra;
    end

    result = struct();
    result.Type = "CIE13_3_CRI";

    result.Source = struct();
    result.Source.InputName = inputName;
    result.Source.Standard = "CIE 13.3-1995";
    result.Source.TestSamples = ...
        "CIE 1995, DOI 10.25039/CIE.DS.wuiuu9cz";
    result.Source.DaylightComponents = ...
        "CIE 2018, DOI 10.25039/CIE.DS.w7zunnny";

    result.ReferenceIlluminant = struct();
    result.ReferenceIlluminant.Kind = referenceKind;
    result.ReferenceIlluminant.CCT = cct;
    result.ReferenceIlluminant.WavelengthNm = calculationWavelength;
    result.ReferenceIlluminant.Value = referenceSpd;
    result.ReferenceIlluminant.XYZ = referenceWhiteXyz;
    result.ReferenceIlluminant.u = referenceU;
    result.ReferenceIlluminant.v = referenceV;

    result.TestIlluminant = struct();
    result.TestIlluminant.WavelengthNm = calculationWavelength;
    result.TestIlluminant.Value = testSpd;
    result.TestIlluminant.XYZ = testWhiteXyz;
    result.TestIlluminant.u = testU;
    result.TestIlluminant.v = testV;

    result.Processing = struct();
    result.Processing.CalculationIntervalNm = 5;
    result.Processing.InterpolationMethod = "linear";
    result.Processing.Observer = "CIE 1931 2 degree";
    result.Processing.ColourSpace = "CIE 1964 Uniform Space";
    result.Processing.ChromaticAdaptation = ...
        "CIE 13.3 adaptive colour shift";
    result.Processing.RoundIndices = options.RoundIndices;

    result.TestSamples = struct();
    result.TestSamples.DeltaE = deltaE;
    result.TestSamples.TestXYZ = testSampleXyz;
    result.TestSamples.ReferenceXYZ = referenceSampleXyz;

    result.Result = struct();
    result.Result.Ra = Rareported;
    result.Result.R = Rreported;
    result.Result.R1 = Rreported(1);
    result.Result.R2 = Rreported(2);
    result.Result.R3 = Rreported(3);
    result.Result.R4 = Rreported(4);
    result.Result.R5 = Rreported(5);
    result.Result.R6 = Rreported(6);
    result.Result.R7 = Rreported(7);
    result.Result.R8 = Rreported(8);
    result.Result.R9 = Rreported(9);
    result.Result.R10 = Rreported(10);
    result.Result.R11 = Rreported(11);
    result.Result.R12 = Rreported(12);
    result.Result.R13 = Rreported(13);
    result.Result.R14 = Rreported(14);
    result.Result.CCT = cct;
    result.Result.Duv = duvSigned;
    result.Result.ChromaticityDifference = chromaticityDifference;
end


function [wavelength, value, name] = resolveInput(inputData)

    if isa(inputData, "spectralab.core.Spectrum")
        wavelength = inputData.WavelengthNm(:);
        value = inputData.Power(:);
        name = string(inputData.Label);
        return
    end

    if isstruct(inputData) && ...
            isfield(inputData, "Result") && ...
            isstruct(inputData.Result) && ...
            isfield(inputData.Result, "WavelengthNm") && ...
            isfield(inputData.Result, "Value")

        wavelength = inputData.Result.WavelengthNm(:);
        value = inputData.Result.Value(:);

        if isfield(inputData, "Type")
            name = string(inputData.Type);
        else
            name = "Unnamed spectral result";
        end
        return
    end

    error( ...
        "spectralab:analysis:cri:InvalidInput", ...
        "Input must be a Spectrum or a canonical spectral result containing Result.WavelengthNm and Result.Value.");
end


function validateInput(wavelength, value)

    if isempty(wavelength) || isempty(value)
        error( ...
            "spectralab:analysis:cri:EmptyInput", ...
            "The spectral input must not be empty.");
    end

    if numel(wavelength) ~= numel(value)
        error( ...
            "spectralab:analysis:cri:SizeMismatch", ...
            "Wavelength and spectral-value vectors must have equal length.");
    end

    if any(~isfinite(wavelength)) || any(~isfinite(value))
        error( ...
            "spectralab:analysis:cri:NonFiniteInput", ...
            "Wavelength and spectral values must be finite.");
    end

    if any(diff(wavelength) <= 0)
        error( ...
            "spectralab:analysis:cri:WavelengthNotIncreasing", ...
            "Wavelength values must be strictly increasing.");
    end
end


function [xBar, yBar, zBar] = colourMatchingFunctions(wavelength)

    xFilter = spectralab.filters.cie1931.xBar();
    yFilter = spectralab.filters.cie1931.yBar();
    zFilter = spectralab.filters.cie1931.zBar();

    xBar = xFilter.evaluate(wavelength);
    yBar = yFilter.evaluate(wavelength);
    zBar = zFilter.evaluate(wavelength);

    xBar = xBar(:);
    yBar = yBar(:);
    zBar = zBar(:);
end


function spd = normalizeIlluminantY100(wavelength, spd, yBar)

    denominator = trapz(wavelength, spd .* yBar);

    if ~isfinite(denominator) || denominator <= 0
        error( ...
            "spectralab:analysis:cri:InvalidIlluminantY", ...
            "The illuminant Y integral must be finite and positive.");
    end

    spd = spd .* (100 / denominator);
end


function xyz = integrateXyz(wavelength, spd, xBar, yBar, zBar)

    xyz = [ ...
        trapz(wavelength, spd .* xBar), ...
        trapz(wavelength, spd .* yBar), ...
        trapz(wavelength, spd .* zBar)];
end


function [u, v] = xyzToUv(xyz)

    denominator = xyz(1) + 15*xyz(2) + 3*xyz(3);

    if ~isfinite(denominator) || denominator <= 0
        error( ...
            "spectralab:analysis:cri:InvalidXyz", ...
            "XYZ values cannot be converted to CIE 1960 UCS coordinates.");
    end

    u = 4*xyz(1) / denominator;
    v = 6*xyz(2) / denominator;
end


function cct = estimateCctPlanckian( ...
        targetU, targetV, wavelength, xBar, yBar, zBar)

    objective = @(temperature) planckianDistanceSquared( ...
        temperature, targetU, targetV, wavelength, xBar, yBar, zBar);

    cct = fminbnd(objective, 1000, 25000);
end


function distance = planckianDistanceSquared( ...
        temperature, targetU, targetV, wavelength, xBar, yBar, zBar)

    spd = planckianSpd(wavelength, temperature);
    xyz = integrateXyz(wavelength, spd, xBar, yBar, zBar);
    [u, v] = xyzToUv(xyz);

    distance = (u-targetU)^2 + (v-targetV)^2;
end


function spd = planckianSpd(wavelengthNm, temperature)

    c2 = 1.438776877e-2;
    wavelengthM = wavelengthNm(:) * 1e-9;

    exponent = c2 ./ (wavelengthM * temperature);

    spd = 1 ./ ( ...
        wavelengthM.^5 .* ...
        expm1(exponent));

    spd = spd ./ max(spd);
end


function spd = daylightSpd(wavelengthNm, temperature)

    if temperature < 4000 || temperature > 25000
        error( ...
            "spectralab:analysis:cri:DaylightCctOutsideRange", ...
            "CIE daylight construction requires CCT from 4000 to 25000 K.");
    end

    if temperature <= 7000
        xD = ...
            -4.6070e9 / temperature^3 + ...
             2.9678e6 / temperature^2 + ...
             0.09911e3 / temperature + ...
             0.244063;
    else
        xD = ...
            -2.0064e9 / temperature^3 + ...
             1.9018e6 / temperature^2 + ...
             0.24748e3 / temperature + ...
             0.237040;
    end

    yD = -3*xD^2 + 2.87*xD - 0.275;

    denominator = 0.0241 + 0.2562*xD - 0.7341*yD;

    M1 = (-1.3515 - 1.7703*xD + 5.9114*yD) / denominator;
    M2 = ( 0.0300 -31.4424*xD +30.0717*yD) / denominator;

    data = loadDaylightComponents();

    S0 = interp1(data(:,1), data(:,2), wavelengthNm, "linear");
    S1 = interp1(data(:,1), data(:,3), wavelengthNm, "linear");
    S2 = interp1(data(:,1), data(:,4), wavelengthNm, "linear");

    spd = S0 + M1*S1 + M2*S2;

    if any(~isfinite(spd)) || any(spd < 0)
        error( ...
            "spectralab:analysis:cri:InvalidDaylightSpectrum", ...
            "The calculated CIE daylight spectrum is invalid.");
    end
end


function data = loadDaylightComponents()

    filtersFolder = fileparts(which("spectralab.filters.photopic"));

    filename = fullfile( ...
        filtersFolder, ...
        "data", ...
        "CIE_illum_Dxx_comp.csv");

    if ~isfile(filename)
        error( ...
            "spectralab:analysis:cri:MissingDaylightData", ...
            "CIE daylight-component dataset was not found: %s", ...
            filename);
    end

    data = readmatrix(filename);

    if size(data,2) ~= 4 || size(data,1) < 2
        error( ...
            "spectralab:analysis:cri:InvalidDaylightData", ...
            "The daylight dataset must contain wavelength, S0, S1, and S2.");
    end
end


function [uAdapted, vAdapted] = adaptCriUv( ...
        uSample, vSample, uTest, vTest, uRef, vRef)

    [cSample, dSample] = criCd(uSample, vSample);
    [cTest, dTest] = criCd(uTest, vTest);
    [cRef, dRef] = criCd(uRef, vRef);

    denominator = ...
        16.518 + ...
        1.481*(cRef/cTest)*cSample - ...
        (dRef/dTest)*dSample;

    uAdapted = ( ...
        10.872 + ...
        0.404*(cRef/cTest)*cSample - ...
        4*(dRef/dTest)*dSample) / denominator;

    vAdapted = 5.520 / denominator;
end


function [c, d] = criCd(u, v)

    if ~isfinite(v) || v == 0
        error( ...
            "spectralab:analysis:cri:InvalidUv", ...
            "CIE 1960 v must be finite and non-zero.");
    end

    c = (4 - u - 10*v) / v;
    d = (1.708*v + 0.404 - 1.481*u) / v;
end


function [U, V, W] = uvYToUvw(u, v, Y, whiteU, whiteV)

    if Y < 0 || ~isfinite(Y)
        error( ...
            "spectralab:analysis:cri:InvalidSampleY", ...
            "Sample Y must be finite and non-negative.");
    end

    W = 25*nthroot(Y,3) - 17;
    U = 13*W*(u-whiteU);
    V = 13*W*(v-whiteV);
end


function duv = signedUvDistanceToPlanckian( ...
        u, v, cct, wavelength, xBar, yBar, zBar)

    deltaT = max(1, cct*1e-4);

    uvLow = planckianUv(cct-deltaT, wavelength, xBar, yBar, zBar);
    uvHigh = planckianUv(cct+deltaT, wavelength, xBar, yBar, zBar);
    uvCentre = planckianUv(cct, wavelength, xBar, yBar, zBar);

    tangent = uvHigh - uvLow;
    normal = [-tangent(2), tangent(1)];
    normal = normal / norm(normal);

    duv = dot([u v] - uvCentre, normal);
end


function uv = planckianUv(temperature, wavelength, xBar, yBar, zBar)

    temperature = max(1000, min(25000, temperature));

    spd = planckianSpd(wavelength, temperature);
    xyz = integrateXyz(wavelength, spd, xBar, yBar, zBar);
    [u, v] = xyzToUv(xyz);

    uv = [u v];
end
