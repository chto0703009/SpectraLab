function tests = test_cri_test_samples
%TEST_CRI_TEST_SAMPLES Tests the official CIE CRI sample library.

    tests = functiontests(localfunctions);
end


function testLoadsAllSamples(testCase)

    filters = spectralab.filters.cri.all();

    verifySize(testCase, filters, [1 14]);

    for index = 1:14
        verifyClass( ...
            testCase, ...
            filters{index}, ...
            "spectralab.core.SpectralFilter");
    end
end


function testSampleRangeAndGrid(testCase)

    filter = spectralab.filters.cri.tcs01();

    verifyEqual(testCase, filter.RangeNm, [360 830]);
    verifyEqual(testCase, numel(filter.WavelengthNm), 95);
    verifyEqual(testCase, diff(filter.WavelengthNm), 5*ones(94,1));
end


function testPublishedSampleRow(testCase)
% Official metadata gives wavelength 475 nm as a validation row.

    expected = [ ...
        0.214
        0.143
        0.094
        0.254
        0.410
        0.531
        0.429
        0.366
        0.031
        0.125
        0.167
        0.328
        0.389
        0.052
    ];

    filters = spectralab.filters.cri.all();

    actual = zeros(14,1);

    for index = 1:14
        actual(index) = filters{index}.evaluate(475);
    end

    verifyEqual(testCase, actual, expected, "AbsTol", 1e-14);
end


function testMetadata(testCase)

    filter = spectralab.filters.cri.tcs09();

    verifyTrue(testCase, contains(filter.Name, "TCS09"));
    verifyEqual(testCase, filter.Unit, "spectral radiance factor");
    verifyTrue(testCase, contains(filter.Source, "10.25039/CIE.DS.wuiuu9cz"));
end


function testDatasetSha256(testCase)

    filtersFolder = fileparts(which("spectralab.filters.photopic"));

    filename = fullfile( ...
        filtersFolder, ...
        "data", ...
        "CIE_srf_cri.csv");

    actual = sha256File(filename);

    expected = ...
        "f461decedb5c18800c61a6923240c71f6cf91fd23ac94865133cbfdb7e05c0ad";

    verifyEqual(testCase, actual, expected);
end


function value = sha256File(filename)

    fileId = fopen(filename, "rb");

    if fileId < 0
        error( ...
            "spectralab:test:CannotOpenFile", ...
            "Could not open file: %s", ...
            filename);
    end

    cleanup = onCleanup(@() fclose(fileId));

    bytes = fread(fileId, Inf, "*uint8");

    digest = java.security.MessageDigest.getInstance("SHA-256");
    digest.update(bytes);

    hashBytes = typecast(digest.digest(), "uint8");
    value = lower(string(reshape(dec2hex(hashBytes, 2).', 1, [])));
end
