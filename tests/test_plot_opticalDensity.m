function tests = test_plot_opticalDensity
%TEST_PLOT_OPTICALDENSITY Tests for spectralab.plot.opticalDensity.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)

    wavelength = (380:10:730).';
    density = linspace(0, 2, numel(wavelength)).';

    testCase.TestData.WavelengthNm = wavelength;
    testCase.TestData.Density = density;
end


function setup(~)

    close all force
end


function teardown(~)

    close all force
end


function testCreatesLine(testCase)

    h = spectralab.plot.opticalDensity( ...
        testCase.TestData.WavelengthNm, ...
        testCase.TestData.Density);

    verifyClass(testCase, h, "matlab.graphics.chart.primitive.Line");
    verifyTrue(testCase, isvalid(h));
end


function testPlotsInputData(testCase)

    wavelength = testCase.TestData.WavelengthNm;
    density = testCase.TestData.Density;

    h = spectralab.plot.opticalDensity(wavelength, density);

    verifyEqual(testCase, h.XData(:), wavelength);
    verifyEqual(testCase, h.YData(:), density);
end


function testUsesSuppliedParent(testCase)

    fig = figure;
    ax = axes(fig);

    h = spectralab.plot.opticalDensity( ...
        testCase.TestData.WavelengthNm, ...
        testCase.TestData.Density, ...
        Parent=ax);

    verifyEqual(testCase, h.Parent, ax);
end


function testAppliesCommonLineProperties(testCase)

    h = spectralab.plot.opticalDensity( ...
        testCase.TestData.WavelengthNm, ...
        testCase.TestData.Density, ...
        Color="r", ...
        LineStyle="--", ...
        Marker="*", ...
        LineWidth=2.5, ...
        DisplayName="Test density");

    verifyEqual(testCase, h.Color, [1 0 0], "AbsTol", 1e-12);
    verifyEqual(testCase, string(h.LineStyle), "--");
    verifyEqual(testCase, string(h.Marker), "*");
    verifyEqual(testCase, h.LineWidth, 2.5);
    verifyEqual(testCase, string(h.DisplayName), "Test density");
end


function testAxisLabels(testCase)

    h = spectralab.plot.opticalDensity( ...
        testCase.TestData.WavelengthNm, ...
        testCase.TestData.Density);

    verifyEqual(testCase, string(h.Parent.XLabel.String), "Wavelength (nm)");
    verifyEqual(testCase, string(h.Parent.YLabel.String), "Optical density");
end


function testAllowsPositiveInfinity(testCase)

    density = testCase.TestData.Density;
    density(3) = Inf;

    h = spectralab.plot.opticalDensity( ...
        testCase.TestData.WavelengthNm, density);

    verifyEqual(testCase, h.YData(3), Inf);
end


function testRejectsNaN(testCase)

    density = testCase.TestData.Density;
    density(3) = NaN;

    verifyError(testCase, ...
        @() spectralab.plot.opticalDensity( ...
            testCase.TestData.WavelengthNm, density), ...
        "spectralab:plot:opticalDensity:NaNY");
end


function testRejectsSizeMismatch(testCase)

    verifyError(testCase, ...
        @() spectralab.plot.opticalDensity( ...
            testCase.TestData.WavelengthNm, ...
            testCase.TestData.Density(1:end-1)), ...
        "spectralab:plot:opticalDensity:SizeMismatch");
end
		
		function testAddsTwoDensityCurvesToSameAxes(testCase)

		    wavelength = testCase.TestData.WavelengthNm;
		    density1 = testCase.TestData.Density;
		    density2 = 0.8 .* density1;

		    fig = figure;
		    ax = axes(fig);

		    hold(ax, "on");

		    h1 = spectralab.plot.opticalDensity( ...
		        wavelength, ...
		        density1, ...
		        Parent=ax, ...
		        DisplayName="First");

		    h2 = spectralab.plot.opticalDensity( ...
		        wavelength, ...
		        density2, ...
		        Parent=ax, ...
		        LineStyle="--", ...
		        DisplayName="Second");

		    hold(ax, "off");

		    verifyEqual(testCase, h1.Parent, ax);
		    verifyEqual(testCase, h2.Parent, ax);
		    verifyEqual(testCase, numel(findobj(ax, "Type", "line")), 2);
		end


		function testPreservesHoldState(testCase)

		    wavelength = testCase.TestData.WavelengthNm;
		    density = testCase.TestData.Density;

		    fig = figure;
		    ax = axes(fig);

		    hold(ax, "on");
		    holdStateBefore = ishold(ax);

		    spectralab.plot.opticalDensity( ...
		        wavelength, ...
		        density, ...
		        Parent=ax);

		    holdStateAfter = ishold(ax);

		    verifyEqual(testCase, holdStateAfter, holdStateBefore);
		end		
