function tests = test_plot_spectrumSummaryPanel
%TEST_PLOT_SPECTRUMSUMMARYPANEL Verify detailed one-shot PNG information.

tests = functiontests(localfunctions);
end


function testDisplaysPeakIntegralRangeAndSamples(testCase)
instrument = spectralab.drivers.MockInstrument(NoiseLevel=0);
session = spectralab.core.Session(instrument);
session = session.open();
session = session.calibrate();
session = session.withOperator("Test operator");
session = session.withProject("Test project");
spectrum = session.measure("Emission summary test");
archive = spectralab.archive.create(spectrum);
figureHandle = figure("Visible", "off");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
axesHandle = axes("Parent", figureHandle);
spectralab.plot.spectrum(spectrum, Parent=axesHandle, ShowSummary=false);

panel = spectralab.plot.spectrumSummaryPanel( ...
    axesHandle, spectrum, Archive=archive);
content = string(panel.String);

verifyTrue(testCase, any(contains(content, "Peak wavelength:"), "all"));
verifyTrue(testCase, any(contains(content, "Peak value:"), "all"));
verifyTrue(testCase, any(contains(content, "Integral:"), "all"));
verifyTrue(testCase, any(contains(content, "Range:"), "all"));
verifyTrue(testCase, any(contains(content, "Samples:"), "all"));
verifyTrue(testCase, any(contains(content, "Project: Test project"), "all"));
verifyTrue(testCase, any(contains(content, "Operator: Test operator"), "all"));
verifyTrue(testCase, any(contains(content, "Date:"), "all"));
verifyTrue(testCase, any(contains(content, "Instrument:"), "all"));
verifyTrue(testCase, any(contains(content, "Serial:"), "all"));
verifyEqual(testCase, string(panel.Tag), ...
    "SpectraLabDetailedSpectrumSummary");
verifyEqual(testCase, panel.Position(1:2), [0.02 0.98], "AbsTol", 1e-12);
verifyEqual(testCase, string(panel.HorizontalAlignment), "left");
end


function testReplacesExistingPanel(testCase)
instrument = spectralab.drivers.MockInstrument(NoiseLevel=0);
session = spectralab.core.Session(instrument);
session = session.open();
session = session.calibrate();
spectrum = session.measure("Emission summary replacement test");
figureHandle = figure("Visible", "off");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
axesHandle = axes("Parent", figureHandle);

spectralab.plot.spectrumSummaryPanel(axesHandle, spectrum);
spectralab.plot.spectrumSummaryPanel(axesHandle, spectrum);

panels = findall(axesHandle, "Type", "text", ...
    "Tag", "SpectraLabDetailedSpectrumSummary");
verifyNumElements(testCase, panels, 1);
end
