function handle = spectrumPNGInformationPanel(ax, spec, archive)
%SPECTRUMPNGINFORMATIONPANEL Add analysis and provenance to standalone PNG.
%
% This overlay is used only during explicit standalone PNG export. The PDF
% figure remains a clean curve with legend; PDF analysis values are rendered
% separately in the report Results section.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    spec (1,1) spectralab.core.Spectrum
    archive (1,1) struct
end

summary = spec.summaryStruct();
unit = string(spec.PowerUnit);
if strlength(unit) == 0, unit = "spectral units"; end
textValue = join([ ...
    "Measurement: " + archiveValue(archive, ...
        ["Measurement.Name", "MeasurementName"], spec.Label)
    compose("Peak wavelength: %.2f nm", summary.peak_wavelength_nm)
    compose("Peak value: %.6g %s", summary.peak_power, unit)
    compose("Integral: %.6g %s*nm", summary.integrated_power, unit)
    compose("Range: %.1f–%.1f nm", ...
        summary.range_nm(1), summary.range_nm(2))
    compose("Samples: %d", summary.samples)
    "Project: " + archiveValue(archive, "Metadata.Project", "—")
    "Operator: " + archiveValue(archive, ...
        ["Measurement.Operator", "Metadata.Operator"], "—")
    "Date: " + archiveValue(archive, ...
        ["Measurement.Timestamp", "Measurement.Date", "Metadata.Date"], "—")
    "Instrument: " + archiveValue(archive, ...
        ["Instrument.Name", "Instrument.Model", "Instrument.Instrument"], "—")
    "Serial: " + archiveValue(archive, ...
        "Instrument.SerialNumber", "—")], newline);

fig = ancestor(ax, "figure");
existing = findall(fig, "Type", "axes", ...
    "Tag", "SpectraLabFigureInformationPanel");
delete(existing);
profile = spectralab.report.internal.figureLayoutProfile();
ax.Units = "normalized";
ax.Position = profile.AxesWithSidebar;
panel = axes("Parent", fig, "Units", "normalized", ...
    "Position", profile.SidePanel, "Visible", "off", ...
    "XLim", [0 1], "YLim", [0 1], ...
    "XLimMode", "manual", "YLimMode", "manual", ...
    "Tag", "SpectraLabFigureInformationPanel", ...
    "HandleVisibility", "off");
handle = text(panel, 0, 1, textValue, ...
    "Units", "normalized", ...
    "HorizontalAlignment", "left", ...
    "VerticalAlignment", "top", ...
    "BackgroundColor", "white", ...
    "EdgeColor", [0.75 0.75 0.75], ...
    "Margin", 7, "FontSize", profile.SidePanelFontSize, ...
    "Interpreter", "none", ...
    "HandleVisibility", "off", ...
    "Tag", "SpectraLabSpectrumPNGInformation");
end


function value = archiveValue(archive, paths, fallback)
value = string(fallback);
for path = string(paths)
    parts = split(path, ".");
    current = archive;
    found = true;
    for part = parts.'
        field = char(part);
        if ~isstruct(current) || ~isfield(current, field)
            found = false;
            break
        end
        current = current.(field);
    end
    if found
        candidate = string(current);
        if isscalar(candidate) && ~ismissing(candidate) && ...
                strlength(strtrim(candidate)) > 0
            value = candidate;
            return
        end
    end
end
end
