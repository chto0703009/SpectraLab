function tests = test_plot_spectrum
%TEST_PLOT_SPECTRUM Tests for spectralab.plot.spectrum.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)
% Create one valid Spectrum for all tests.

    inst = spectralab.drivers.MockInstrument();

    sess = spectralab.core.Session(inst);
    sess = sess.open();
    sess = sess.calibrate();

    testCase.TestData.Spec = sess.measure("Plot test spectrum");
end


function setup(~)
% Prevent figures from earlier tests affecting the current test.

    close all force
end


function teardown(~)

    close all force
end


function testCreatesLine(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        ShowSummary=false);

    verifyClass(testCase, h, "matlab.graphics.chart.primitive.Line");
    verifyTrue(testCase, isvalid(h));
end


function testPlotsSpectrumData(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        ShowSummary=false);

    verifyEqual(testCase, h.XData(:), spec.WavelengthNm(:));
    verifyEqual(testCase, h.YData(:), spec.Power(:));
end


function testUsesSuppliedParent(testCase)

    spec = testCase.TestData.Spec;

    fig = figure;
    ax = axes(fig);

    h = spectralab.plot.spectrum( ...
        spec, ...
        Parent=ax, ...
        ShowSummary=false);

    verifyEqual(testCase, h.Parent, ax);
    verifyEqual(testCase, numel(findobj(ax, "Type", "line")), 1);
end


function testAddsTwoSpectraToSameAxes(testCase)

    spec = testCase.TestData.Spec;

    fig = figure;
    ax = axes(fig);

    hold(ax, "on");

    h1 = spectralab.plot.spectrum( ...
        spec, ...
        Parent=ax, ...
        Color="r", ...
        LineStyle="-", ...
        DisplayName="First", ...
        ShowSummary=false);

    h2 = spectralab.plot.spectrum( ...
        spec, ...
        Parent=ax, ...
        Color="r", ...
        LineStyle="--", ...
        DisplayName="Second", ...
        ShowSummary=false);

    hold(ax, "off");

    verifyEqual(testCase, h1.Parent, ax);
    verifyEqual(testCase, h2.Parent, ax);
    verifyEqual(testCase, numel(findobj(ax, "Type", "line")), 2);
end


function testAppliesLineProperties(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        Color="r", ...
        LineStyle="--", ...
        Marker="*", ...
        LineWidth=2.5, ...
        DisplayName="Test spectrum", ...
        ShowSummary=false);

    verifyEqual(testCase, h.Color, [1 0 0], "AbsTol", 1e-12);
    verifyEqual(testCase, string(h.LineStyle), "--");
    verifyEqual(testCase, string(h.Marker), "*");
    verifyEqual(testCase, h.LineWidth, 2.5);
    verifyEqual(testCase, string(h.DisplayName), "Test spectrum");
end


function testAxisLabels(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        ShowSummary=false);

    ax = h.Parent;

    verifyEqual(testCase, string(ax.XLabel.String), "Wavelength (nm)");
    verifyEqual(testCase, string(ax.YLabel.String), "Spectral power");
end


function testCustomTitle(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        Title="Custom spectrum title", ...
        ShowSummary=false);

    verifyEqual( ...
        testCase, ...
        string(h.Parent.Title.String), ...
        "Custom spectrum title");
end


function testEmptyTitleWithParent(testCase)

    spec = testCase.TestData.Spec;

    fig = figure;
    ax = axes(fig);

    spectralab.plot.spectrum( ...
        spec, ...
        Parent=ax, ...
        Title="", ...
        ShowSummary=false);

    verifyEqual(testCase, string(ax.Title.String), "");
end


function testGridCanBeEnabled(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        ShowGrid=true, ...
        ShowSummary=false);

    ax = h.Parent;

    verifyEqual(testCase, string(ax.XGrid), "on");
    verifyEqual(testCase, string(ax.YGrid), "on");
end


function testGridCanBeDisabled(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        ShowGrid=false, ...
        ShowSummary=false);

    ax = h.Parent;

    verifyEqual(testCase, string(ax.XGrid), "off");
    verifyEqual(testCase, string(ax.YGrid), "off");
end


function testNormalizePlotsNormalizedPower(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        Normalize=true, ...
        ShowSummary=false);

    expected = spec.normalizedPower();

    verifyEqual(testCase, h.YData(:), expected(:));
    verifyEqual( ...
        testCase, ...
        string(h.Parent.YLabel.String), ...
        "Relative spectral power");
end


function testSummaryIsShownByDefault(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum(spec);

    summaryText = findSummaryText(h.Parent);

    verifyEqual(testCase, numel(summaryText), 1);
end


function testSummaryCanBeHidden(testCase)

    spec = testCase.TestData.Spec;

    h = spectralab.plot.spectrum( ...
        spec, ...
        ShowSummary=false);

    summaryText = findSummaryText(h.Parent);

    verifyEmpty(testCase, summaryText);
end


function testRejectsInvalidParent(testCase)

    spec = testCase.TestData.Spec;

    verifyError( ...
        testCase, ...
        @() spectralab.plot.spectrum( ...
            spec, ...
            Parent=42, ...
            ShowSummary=false), ...
        "spectralab:plot:spectrum:InvalidParent");
end


function testRejectsInvalidSpectrum(testCase)

    verifyError( ...
        testCase, ...
        @() spectralab.plot.spectrum(struct()), ...
        "MATLAB:validation:UnableToConvert");
end


function summaryText = findSummaryText(ax)
% Find the SpectraLab summary annotation, including hidden handles.

    allText = findall(ax, "Type", "text");

    if isempty(allText)
        summaryText = allText;
        return
    end

    isSummary = false(size(allText));

    for index = 1:numel(allText)
        textValue = string(allText(index).String);
        isSummary(index) = any(contains(textValue, "Peak:"), "all");
    end

    summaryText = allText(isSummary);
end


	function testPreservesHoldState(testCase)

	    spec = testCase.TestData.Spec;

	    fig = figure;
	    ax = axes(fig);

	    hold(ax, "on");
	    holdStateBefore = ishold(ax);

	    spectralab.plot.spectrum( ...
	        spec, ...
	        Parent=ax, ...
	        ShowSummary=false);

	    holdStateAfter = ishold(ax);

	    verifyEqual(testCase, holdStateAfter, holdStateBefore);
	end