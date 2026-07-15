function tests = test_standard_filter_data_integrity
%TEST_STANDARD_FILTER_DATA_INTEGRITY Verify bundled standard datasets.
%
%   These tests protect the authoritative CIE CSV files from accidental
%   editing, truncation, line-ending conversion, or replacement.

    tests = functiontests(localfunctions);
end


function testCie1931DatasetSha256(testCase)

    filename = filterDataFile("CIE_xyz_1931_2deg.csv");

    actual = sha256File(filename);
    expected = ...
        "fa663e3535a7e0763a745993a1f0a192eb0275ac46ad2d1befd7626841e713c1";

    verifyEqual(testCase, actual, expected);
end


function testPhotopicDatasetSha256(testCase)

    filename = filterDataFile("CIE_sle_photopic.csv");

    actual = sha256File(filename);
    expected = ...
        "ee5d5d17922ae645d4af52cacf6a50bdb9385749f9d2181ca312eb2b08febac2";

    verifyEqual(testCase, actual, expected);
end


function testCie1931DatasetShape(testCase)

    data = readmatrix(filterDataFile("CIE_xyz_1931_2deg.csv"));

    verifySize(testCase, data, [471 4]);
    verifyEqual(testCase, data(1,1), 360);
    verifyEqual(testCase, data(end,1), 830);
end


function testPhotopicDatasetShape(testCase)

    data = readmatrix(filterDataFile("CIE_sle_photopic.csv"));

    verifySize(testCase, data, [471 2]);
    verifyEqual(testCase, data(1,1), 360);
    verifyEqual(testCase, data(end,1), 830);
end


function testStatusADocumentaryValues(testCase)
% Protect selected published Status A values after linear conversion.

    blue = spectralab.filters.statusA.blue();
    green = spectralab.filters.statusA.green();
    red = spectralab.filters.statusA.red();

    verifyEqual(testCase, blue.evaluate(440), 1, "AbsTol", 1e-14);
    verifyEqual(testCase, green.evaluate(530), 1, "AbsTol", 1e-14);
    verifyEqual(testCase, red.evaluate(620), 1, "AbsTol", 1e-14);

    verifyEqual( ...
        testCase, ...
        blue.evaluate(420), ...
        10^(3.602 - 5), ...
        "AbsTol", 1e-14);

    verifyEqual( ...
        testCase, ...
        green.evaluate(500), ...
        10^(1.650 - 5), ...
        "AbsTol", 1e-14);

    verifyEqual( ...
        testCase, ...
        red.evaluate(600), ...
        10^(2.568 - 5), ...
        "AbsTol", 1e-14);
end


function filename = filterDataFile(name)

    filtersPackage = fileparts(which("spectralab.filters.photopic"));

    filename = fullfile(filtersPackage, "data", name);

    if ~isfile(filename)
        error( ...
            "spectralab:test:MissingFilterDataset", ...
            "Filter dataset was not found: %s", ...
            filename);
    end
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
