function tests = test_plot_spectrumPNGInformationPanel
%TEST_PLOT_SPECTRUMPNGINFORMATIONPANEL Verify standalone PNG information.

tests = functiontests(localfunctions);
end


function testDisplaysAnalysisAndProvenance(testCase)
instrument = spectralab.drivers.MockInstrument(NoiseLevel=0);
session = spectralab.core.Session(instrument);
session = session.open();
session = session.calibrate();
session = session.withOperator("Test operator");
session = session.withProject("Test project");
spectrum = session.measure("Emission PNG test");
archive = spectralab.archive.create(spectrum);
figureHandle = figure("Visible", "off");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
axesHandle = axes("Parent", figureHandle);

panel = spectralab.plot.spectrumPNGInformationPanel( ...
    axesHandle, spectrum, archive);
content = string(panel.String);

for expected = ["Measurement:", "Peak wavelength:", "Peak value:", ...
        "Integral:", "Range:", "Samples:", "Project: Test project", ...
        "Operator: Test operator", "Date:", "Instrument:", "Serial:"]
    verifyTrue(testCase, any(contains(content, expected), "all"));
end
verifyEqual(testCase, string(panel.Tag), ...
    "SpectraLabSpectrumPNGInformation");
verifyEqual(testCase, panel.Position(1:2), [0.02 0.98], "AbsTol", 1e-12);
end


function testReplacesExistingPanel(testCase)
instrument = spectralab.drivers.MockInstrument(NoiseLevel=0);
session = spectralab.core.Session(instrument);
session = session.open();
session = session.calibrate();
spectrum = session.measure("Emission PNG replacement test");
archive = spectralab.archive.create(spectrum);
figureHandle = figure("Visible", "off");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
axesHandle = axes("Parent", figureHandle);

spectralab.plot.spectrumPNGInformationPanel(axesHandle, spectrum, archive);
spectralab.plot.spectrumPNGInformationPanel(axesHandle, spectrum, archive);

panels = findall(axesHandle, "Type", "text", ...
    "Tag", "SpectraLabSpectrumPNGInformation");
verifyNumElements(testCase, panels, 1);
end
