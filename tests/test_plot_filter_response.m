function tests = test_plot_filter_response
%TEST_PLOT_FILTER_RESPONSE Tests spectralab.plot.filterResponse.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)

    wavelength = (400:10:700).';

    result = struct();
    result.Type = "FilterResponse";
    result.Result = struct();
    result.Result.WavelengthNm = wavelength;
    result.Result.Value = exp(-0.5*((wavelength-550)/35).^2);

    testCase.TestData.Result = result;
end


function setup(~)
    close all force
end


function teardown(~)
    close all force
end


function testCreatesLine(testCase)

    h = spectralab.plot.filterResponse(testCase.TestData.Result);

    verifyClass(testCase, h, "matlab.graphics.chart.primitive.Line");
end


function testUsesCanonicalProperties(testCase)

    h = spectralab.plot.filterResponse( ...
        testCase.TestData.Result, ...
        Color="r", ...
        LineStyle="--", ...
        Marker="*", ...
        LineWidth=2, ...
        DisplayName="Filtered sample");

    verifyEqual(testCase, h.Color, [1 0 0], "AbsTol", 1e-12);
    verifyEqual(testCase, string(h.LineStyle), "--");
    verifyEqual(testCase, string(h.Marker), "*");
    verifyEqual(testCase, h.LineWidth, 2);
    verifyEqual(testCase, string(h.DisplayName), "Filtered sample");
end


function testUsesParent(testCase)

    fig = figure;
    ax = axes(fig);

    h = spectralab.plot.filterResponse( ...
        testCase.TestData.Result, ...
        Parent=ax);

    verifyEqual(testCase, h.Parent, ax);
end
