function handle = spectrumSummaryPanel(ax, spec, options)
%SPECTRUMSUMMARYPANEL Add detailed measured-spectrum values to an axes.

% This presentation helper does not recalculate or alter the spectrum. It
% displays values from Spectrum.summaryStruct for traceable PNG output.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    spec (1,1) spectralab.core.Spectrum
    options.Archive (1,1) struct = struct()
end

summary = spec.summaryStruct();
unit = string(spec.PowerUnit);
if strlength(unit) == 0, unit = "spectral units"; end
textValue = join([ ...
    "Measurement: " + archiveValue(options.Archive, ...
        ["Measurement.Name", "MeasurementName"], spec.Label)
    compose("Peak wavelength: %.2f nm", summary.peak_wavelength_nm)
    compose("Peak value: %.6g %s", summary.peak_power, unit)
    compose("Integral: %.6g %s*nm", summary.integrated_power, unit)
    compose("Range: %.1f–%.1f nm", summary.range_nm(1), summary.range_nm(2))
    compose("Samples: %d", summary.samples)
    "Project: " + archiveValue(options.Archive, ...
        "Metadata.Project", "—")
    "Operator: " + archiveValue(options.Archive, ...
        ["Measurement.Operator", "Metadata.Operator"], "—")
    "Date: " + archiveValue(options.Archive, ...
        ["Measurement.Timestamp", "Measurement.Date", "Metadata.Date"], "—")
    "Instrument: " + archiveValue(options.Archive, ...
        ["Instrument.Name", "Instrument.Model", "Instrument.Instrument"], "—")
    "Serial: " + archiveValue(options.Archive, ...
        "Instrument.SerialNumber", "—")], newline);

existing = findall(ax, "Type", "text", ...
    "Tag", "SpectraLabDetailedSpectrumSummary");
delete(existing);
handle = text(ax, 0.02, 0.98, textValue, ...
    "Units", "normalized", ...
    "HorizontalAlignment", "left", ...
    "VerticalAlignment", "top", ...
    "BackgroundColor", "white", ...
    "EdgeColor", [0.75 0.75 0.75], ...
    "Margin", 7, "FontSize", 9, ...
    "Interpreter", "none", ...
    "HandleVisibility", "off", ...
    "Tag", "SpectraLabDetailedSpectrumSummary");
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
