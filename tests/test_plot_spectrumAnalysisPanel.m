function tests = test_plot_spectrumAnalysisPanel
tests = functiontests(localfunctions);
end

function testShowsAnalysisWithoutMeasurementMetadata(testCase)
fig = figure(Visible="off");
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
ax = axes(Parent=fig);
result = struct("PeakWavelength", 450, ...
    "PeakValueText", "0.557111 arbitrary", ...
    "IntegratedPowerText", "85.8694 arbitrary*nm", ...
    "WavelengthMinimum", 370, "WavelengthMaximum", 730, ...
    "SampleCount", 109);

spectralab.plot.spectrumAnalysisPanel(ax, result);
textHandle = findall(fig, Type="text", ...
    Tag="SpectraLabReflectanceColorimetry");
content = string(textHandle.String);

for expected = ["Peak wavelength: 450.00 nm", ...
        "Peak value: 0.557111 arbitrary", ...
        "Spectral integral: 85.8694 arbitrary*nm", ...
        "Range: 370.0–730.0 nm", "Spectral samples: 109"]
    verifyTrue(testCase, any(contains(content, expected), "all"));
end
for excluded = ["Operator:", "Instrument:", "Serial:"]
    verifyFalse(testCase, any(contains(content, excluded), "all"));
end
end
