function panel = spectrumAnalysisPanel(ax, result)
%SPECTRUMANALYSISPANEL Add spectral results to a standalone report PNG.
%
% The panel intentionally excludes measurement provenance. Operator,
% instrument and similar metadata belong to the PDF report information box.
arguments
    ax (1,1) matlab.graphics.axis.Axes
    result (1,1) struct
end

required = ["PeakWavelength", "PeakValueText", ...
    "IntegratedPowerText", "WavelengthMinimum", ...
    "WavelengthMaximum", "SampleCount"];
if ~all(isfield(result, required))
    error("SpectraLab:Plot:IncompleteSpectrumAnalysis", ...
        "Spectrum analysis results are incomplete for PNG presentation.");
end
lines = [ ...
    compose("Peak wavelength: %.2f nm", result.PeakWavelength)
    "Peak value: " + string(result.PeakValueText)
    "Spectral integral: " + string(result.IntegratedPowerText)
    compose("Range: %.1f–%.1f nm", ...
        result.WavelengthMinimum, result.WavelengthMaximum)
    compose("Spectral samples: %d", result.SampleCount)];
panel = spectralab.plot.reflectanceColorimetryPanel(ax, struct(), ...
    AdditionalLines=lines, ShowColorimetryText=false, ...
    ShowColorSwatch=false);
end
