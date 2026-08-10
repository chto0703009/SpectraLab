function tests = test_plot_transmission
%TEST_PLOT_TRANSMISSION Tests for spectralab.plot.transmission.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)
% Create one valid transmission result structure for all tests.

    wavelength = (380:10:730).';
    transmission = linspace(0.15, 0.85, numel(wavelength)).';

    result = struct();
    result.Result = struct();
    result.Result.WavelengthNm = wavelength;
    result.Result.Value = transmission;

    testCase.TestData.Result = result;
end


function setup(~)

    close all force
end


function teardown(~)

    close all force
end


function testCreatesLine(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission(result);

    verifyClass(testCase, h, "matlab.graphics.chart.primitive.Line");
    verifyTrue(testCase, isvalid(h));
end


function testPlotsResultData(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission(result);

    verifyEqual( ...
        testCase, ...
        h.XData(:), ...
        result.Result.WavelengthNm(:));

    verifyEqual( ...
        testCase, ...
        h.YData(:), ...
        100 .* result.Result.Value(:));
end


function testUsesSuppliedParent(testCase)

    result = testCase.TestData.Result;

    fig = figure;
    ax = axes(fig);

    h = spectralab.plot.transmission( ...
        result, ...
        Parent=ax);

    verifyEqual(testCase, h.Parent, ax);
    verifyEqual(testCase, numel(findobj(ax, "Type", "line")), 1);
end


function testAddsTwoResultsToSameAxes(testCase)

    result = testCase.TestData.Result;

    secondResult = result;
    secondResult.Result.Value = ...
        0.9 .* secondResult.Result.Value;

    fig = figure;
    ax = axes(fig);

    hold(ax, "on");

    h1 = spectralab.plot.transmission( ...
        result, ...
        Parent=ax, ...
        DisplayName="First");

    h2 = spectralab.plot.transmission( ...
        secondResult, ...
        Parent=ax, ...
        LineStyle="--", ...
        DisplayName="Second");

    hold(ax, "off");

    verifyEqual(testCase, h1.Parent, ax);
    verifyEqual(testCase, h2.Parent, ax);
    verifyEqual(testCase, numel(findobj(ax, "Type", "line")), 2);
end


function testAppliesLineProperties(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission( ...
        result, ...
        Color="r", ...
        LineStyle="--", ...
        Marker="*", ...
        LineWidth=2.5, ...
        DisplayName="Test transmission");

    verifyEqual(testCase, h.Color, [1 0 0], "AbsTol", 1e-12);
    verifyEqual(testCase, string(h.LineStyle), "--");
    verifyEqual(testCase, string(h.Marker), "*");
    verifyEqual(testCase, h.LineWidth, 2.5);
    verifyEqual( ...
        testCase, ...
        string(h.DisplayName), ...
        "Test transmission");
end


function testAxisLabels(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission(result);
    ax = h.Parent;

    verifyEqual( ...
        testCase, ...
        string(ax.XLabel.String), ...
        "Wavelength (nm)");

    verifyEqual( ...
        testCase, ...
        string(ax.YLabel.String), ...
        "Transmission (%)");
end


function testYAxisStartsAtZero(testCase)

    result = testCase.TestData.Result;
    h = spectralab.plot.transmission(result);

    verifyEqual(testCase, h.Parent.YLim, [0 100], "AbsTol", 1e-12);
end

function testShowsSpectralColorBarByDefault(testCase)
h = spectralab.plot.transmission(testCase.TestData.Result);
verifyEqual(testCase, numel(findall(h.Parent, ...
    "Tag", "SpectraLabSpectralColorBar")), 1);
end

function testCanHideSpectralColorBar(testCase)
h = spectralab.plot.transmission( ...
    testCase.TestData.Result, ShowSpectralColorBar=false);
verifyEmpty(testCase, findall(h.Parent, ...
    "Tag", "SpectraLabSpectralColorBar"));
end


function testCustomTitle(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission( ...
        result, ...
        Title="Custom transmission title");

    verifyEqual( ...
        testCase, ...
        string(h.Parent.Title.String), ...
        "Custom transmission title");
end


function testEmptyTitle(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission( ...
        result, ...
        Title="");

    verifyEqual( ...
        testCase, ...
        string(h.Parent.Title.String), ...
        "");
end


function testGridCanBeEnabled(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission( ...
        result, ...
        ShowGrid=true);

    verifyEqual(testCase, string(h.Parent.XGrid), "on");
    verifyEqual(testCase, string(h.Parent.YGrid), "on");
end


function testGridCanBeDisabled(testCase)

    result = testCase.TestData.Result;

    h = spectralab.plot.transmission( ...
        result, ...
        ShowGrid=false);

    verifyEqual(testCase, string(h.Parent.XGrid), "off");
    verifyEqual(testCase, string(h.Parent.YGrid), "off");
end


function testRejectsInvalidParent(testCase)

    result = testCase.TestData.Result;

    verifyError( ...
        testCase, ...
        @() spectralab.plot.transmission( ...
            result, ...
            Parent=42), ...
        "spectralab:plot:transmission:InvalidParent");
end


function testRejectsMissingResultSection(testCase)

    verifyError( ...
        testCase, ...
        @() spectralab.plot.transmission(struct()), ...
        "spectralab:plot:transmission:MissingResult");
end


function testRejectsMissingWavelength(testCase)

    result = testCase.TestData.Result;
    result.Result = rmfield(result.Result, "WavelengthNm");

    verifyError( ...
        testCase, ...
        @() spectralab.plot.transmission(result), ...
        "spectralab:plot:transmission:MissingField");
end


function testRejectsMissingValue(testCase)

    result = testCase.TestData.Result;
    result.Result = rmfield(result.Result, "Value");

    verifyError( ...
        testCase, ...
        @() spectralab.plot.transmission(result), ...
        "spectralab:plot:transmission:MissingField");
end


function testRejectsSizeMismatch(testCase)

    result = testCase.TestData.Result;
    result.Result.Value = result.Result.Value(1:end-1);

    verifyError( ...
        testCase, ...
        @() spectralab.plot.transmission(result), ...
        "spectralab:plot:transmission:SizeMismatch");
end
		

		function testPreservesHoldState(testCase)

		    result = testCase.TestData.Result;

		    fig = figure;
		    ax = axes(fig);

		    hold(ax, "on");
		    holdStateBefore = ishold(ax);

		    spectralab.plot.transmission( ...
		        result, ...
		        Parent=ax);

		    holdStateAfter = ishold(ax);

		    verifyEqual(testCase, holdStateAfter, holdStateBefore);
		end
