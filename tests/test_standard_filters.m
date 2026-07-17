function tests = test_standard_filters
%TEST_STANDARD_FILTERS Tests the built-in SpectraLab filter library.

    tests = functiontests(localfunctions);
end


function testFlatFilter(testCase)

    filter = spectralab.filters.flat([400 700]);
    value = filter.evaluate([400 500 700]);

    verifyClass(testCase, filter, "spectralab.core.SpectralFilter");
    verifyEqual(testCase, value, [1 1 1]);
    verifyEqual(testCase, filter.RangeNm, [400 700]);
end


function testCie1931Filters(testCase)

    xBar = spectralab.filters.cie1931.xBar();
    yBar = spectralab.filters.cie1931.yBar();
    zBar = spectralab.filters.cie1931.zBar();

    verifyClass(testCase, xBar, "spectralab.core.SpectralFilter");
    verifyClass(testCase, yBar, "spectralab.core.SpectralFilter");
    verifyClass(testCase, zBar, "spectralab.core.SpectralFilter");

    verifyEqual(testCase, xBar.RangeNm, [360 830]);
    verifyEqual(testCase, yBar.RangeNm, [360 830]);
    verifyEqual(testCase, zBar.RangeNm, [360 830]);

    verifyEqual(testCase, numel(xBar.WavelengthNm), 471);
    verifyEqual(testCase, numel(yBar.WavelengthNm), 471);
    verifyEqual(testCase, numel(zBar.WavelengthNm), 471);
end


function testPhotopicMatchesYBar(testCase)

    photopic = spectralab.filters.photopic();
    yBar = spectralab.filters.cie1931.yBar();

    wavelength = (360:830).';

    verifyEqual( ...
        testCase, ...
        photopic.evaluate(wavelength), ...
        yBar.evaluate(wavelength), ...
        "AbsTol", 1e-14);
end


function testStatusAPeaks(testCase)

    blue = spectralab.filters.statusA.blue();
    green = spectralab.filters.statusA.green();
    red = spectralab.filters.statusA.red();

    verifyPeak(testCase, blue, 440);
    verifyPeak(testCase, green, 530);
    verifyPeak(testCase, red, 620);
end


function testStatusAIsNormalized(testCase)

    filters = { ...
        spectralab.filters.statusA.blue(), ...
        spectralab.filters.statusA.green(), ...
        spectralab.filters.statusA.red()};

    for index = 1:numel(filters)
        verifyEqual(testCase, max(filters{index}.Value), 1, ...
            "AbsTol", 1e-14);
        verifyGreaterThanOrEqual(testCase, min(filters{index}.Value), 0);
    end
end


function testStatusAMetadata(testCase)

    red = spectralab.filters.statusA.red();

    verifyEqual(testCase, red.Unit, "relative spectral product");
    verifyTrue(testCase, contains(red.Source, "ISO 5-3"));
end


function verifyPeak(testCase, filter, expectedWavelength)

    [~, index] = max(filter.Value);

    verifyEqual( ...
        testCase, ...
        filter.WavelengthNm(index), ...
        expectedWavelength);
end


function testStatusMPeaks(testCase)

    blue = spectralab.filters.statusM.blue();
    green = spectralab.filters.statusM.green();
    red = spectralab.filters.statusM.red();

    verifyPeak(testCase, blue, 450);
    verifyPeak(testCase, green, 540);
    verifyPeak(testCase, red, 640);
end


function testStatusMIsNormalized(testCase)

    filters = { ...
        spectralab.filters.statusM.blue(), ...
        spectralab.filters.statusM.green(), ...
        spectralab.filters.statusM.red()};

    for index = 1:numel(filters)
        verifyEqual(testCase, max(filters{index}.Value), 1, ...
            "AbsTol", 1e-14);

        verifyGreaterThanOrEqual( ...
            testCase, ...
            min(filters{index}.Value), ...
            0);
    end
end


function testStatusMMetadata(testCase)

    red = spectralab.filters.statusM.red();

    verifyEqual( ...
        testCase, ...
        red.Unit, ...
        "relative spectral product");

    verifyTrue( ...
        testCase, ...
        contains(red.Source, "ISO 5-3"));

    verifyTrue( ...
        testCase, ...
        contains(red.Name, "Status M"));
end
