function panel = reflectanceColorimetryPanel(ax, archive, options)
%REFLECTANCECOLORIMETRYPANEL Add reflectance XYZ and Lab beside a plot.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    archive (1,1) struct
    options.AdditionalLines (:,1) string = strings(0,1)
    options.ShowColorimetryText (1,1) logical = true
    options.ShowColorSwatch (1,1) logical = true
end

evaluated = struct();
try
    evaluated = spectralab.plot.evaluateReflectanceColor(archive);
catch
end
sourceText = "";
xyz = [];
lab = [];
if isfield(archive, "Measurement") && ...
        isfield(archive.Measurement, "Context") && ...
        isstruct(archive.Measurement.Context) && ...
        isfield(archive.Measurement.Context, "InstrumentReportedColorimetry")
    reported = archive.Measurement.Context.InstrumentReportedColorimetry;
    if isstruct(reported) && isfield(reported, "available") && ...
            logical(reported.available) && isfield(reported, "xyz") && ...
            isfield(reported, "lab")
        xyz = double(reported.xyz(:));
        lab = double(reported.lab(:));
        sourceText = "Instrument-reported control values";
    end
end
if isempty(xyz) && isReflectanceArchive(archive)
    if isfield(evaluated, "XYZ")
        xyz = evaluated.XYZ;
        lab = evaluated.Lab;
        sourceText = "SpectraLab calculated (D50, CIE 1931 2 degree)";
    end
end
hasColorimetry = numel(xyz) == 3 && numel(lab) == 3 && ...
    all(isfinite([xyz; lab]));
hasSwatch = options.ShowColorSwatch && isfield(evaluated, "DisplayRGB");
if (~hasColorimetry || ~options.ShowColorimetryText) && ...
        isempty(options.AdditionalLines) && ~hasSwatch
    panel = gobjects(0);
    return
end

profile = spectralab.report.internal.figureLayoutProfile();
fig = ancestor(ax, "figure");
ax.Units = "normalized";
ax.Position = profile.AxesWithSidebar;
panelTag = "SpectraLabFigureInformationPanel";
if isempty(options.AdditionalLines) && ~options.ShowColorimetryText
    panelTag = "SpectraLabFigureColorSwatchPanel";
end
panel = axes("Parent", fig, "Units", "normalized", ...
    "Position", profile.SidePanel, "Visible", "off", ...
    "XLim", [0 1], "YLim", [0 1], ...
    "XLimMode", "manual", "YLimMode", "manual", ...
    "Tag", panelTag, ...
    "HandleVisibility", "off");
lines = options.AdditionalLines;
if hasColorimetry && options.ShowColorimetryText
    lines(end+1:end+3,1) = [sourceText; ...
        sprintf("XYZ: %.2f, %.2f, %.2f", xyz(1), xyz(2), xyz(3)); ...
        sprintf("Lab: %.2f, %.2f, %.2f", lab(1), lab(2), lab(3))];
end
if ~isempty(lines)
    text(panel, 0, 1, join(lines, newline), ...
        "Units", "normalized", "HorizontalAlignment", "left", ...
        "VerticalAlignment", "top", "BackgroundColor", "white", ...
        "EdgeColor", [0.8 0.8 0.8], "Margin", 6, "FontSize", 9, ...
        "Interpreter", "none", "Tag", "SpectraLabReflectanceColorimetry");
end
if hasSwatch
    rectangle(panel, "Position", [0 0.02 0.18 0.18], ...
        "FaceColor", evaluated.DisplayRGB, ...
        "EdgeColor", [0.35 0.35 0.35], "LineWidth", 0.8, ...
        "Tag", "SpectraLabEvaluatedColorSwatch");
    text(panel, 0, 0.23, "Approximate sRGB preview", ...
        "Units", "normalized", "HorizontalAlignment", "left", ...
        "VerticalAlignment", "bottom", "FontSize", 8, ...
        "Color", [0.3 0.3 0.3], "Interpreter", "none", ...
        "Tag", "SpectraLabEvaluatedColorSwatchLabel");
end
end

function value = isReflectanceArchive(archive)
value = false;
if ~isfield(archive, "Measurement"), return, end
if isfield(archive.Measurement, "Unit") && ...
        contains(lower(string(archive.Measurement.Unit)), "reflectance")
    value = true;
    return
end
if isfield(archive.Measurement, "Context") && ...
        isstruct(archive.Measurement.Context) && ...
        isfield(archive.Measurement.Context, "Kind")
    value = lower(string(archive.Measurement.Context.Kind)) == "reflectance";
end
end
