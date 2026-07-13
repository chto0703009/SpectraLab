function tests = test_plot_optical_density
%TEST_PLOT_OPTICAL_DENSITY Tests for optical-density plotting.

    tests = functiontests(localfunctions);
end


function testCreatesLine(testCase)
    figureHandle = figure("Visible", "off");
    cleanup = onCleanup(@() close(figureHandle));

    axesHandle = axes("Parent", figureHandle);

    wavelengthNm = [400, 500, 600];
    density = [0, 1, 2];

    lineHandle = spectralab.plot.opticalDensity( ...
        wavelengthNm, ...
        density, ...
        Parent=axesHandle);

    verifyClass(testCase, lineHandle, "matlab.graphics.chart.primitive.Line");
    verifyEqual(testCase, lineHandle.XData, wavelengthNm);
    verifyEqual(testCase, lineHandle.YData, density);

    clear cleanup
end


function testAxisLabels(testCase)
    figureHandle = figure("Visible", "off");
    cleanup = onCleanup(@() close(figureHandle));

    axesHandle = axes("Parent", figureHandle);

    spectralab.plot.opticalDensity( ...
        [400, 500, 600], ...
        [0, 1, 2], ...
        Parent=axesHandle);

	verifyEqual(testCase, string(axesHandle.XLabel.String), "Wavelength (nm)");
	verifyEqual(testCase, string(axesHandle.YLabel.String), "Optical density");

    clear cleanup
end


function testCustomTitle(testCase)
    figureHandle = figure("Visible", "off");
    cleanup = onCleanup(@() close(figureHandle));

    axesHandle = axes("Parent", figureHandle);

    spectralab.plot.opticalDensity( ...
        [400, 500], ...
        [0, 1], ...
        Parent=axesHandle, ...
        Title="Film density");

    verifyEqual(testCase, string(axesHandle.Title.String), "Film density");

    clear cleanup
end


function testPreservesParentAxes(testCase)
    figureHandle = figure("Visible", "off");
    cleanup = onCleanup(@() close(figureHandle));

    axesHandle = axes("Parent", figureHandle);

    lineHandle = spectralab.plot.opticalDensity( ...
        [400, 500], ...
        [0, 1], ...
        Parent=axesHandle);

    verifyEqual(testCase, lineHandle.Parent, axesHandle);

    clear cleanup
end


function testRejectsSizeMismatch(testCase)
    testFunction = @() spectralab.plot.opticalDensity( ...
        [400, 500, 600], ...
        [0, 1]);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:plot:opticalDensity:SizeMismatch");
end


function testRejectsEmptyWavelength(testCase)
    testFunction = @() spectralab.plot.opticalDensity([], []);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:plot:opticalDensity:EmptyWavelength");
end


function testRejectsNonFiniteDensity(testCase)
    testFunction = @() spectralab.plot.opticalDensity( ...
        [400, 500], ...
        [0, NaN]);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:plot:opticalDensity:NonFiniteDensity");
end