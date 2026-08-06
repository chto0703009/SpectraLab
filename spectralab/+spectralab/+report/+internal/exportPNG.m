function info = exportPNG(pngFile, renderContext, options)
%EXPORTPNG Export the report's primary figure as a full-resolution PNG.
%
%   info = spectralab.report.internal.exportPNG(pngFile, renderContext)
%   info = spectralab.report.internal.exportPNG( ...
%       pngFile, renderContext, Resolution=300)
%
% The exporter reads the completed figure model and the report-owned axes
% from RenderContext. It creates a separate hidden export figure so that
% the source figure, axes, and interactive MATLAB state remain unchanged.
% Existing files are never overwritten.

arguments
    pngFile (1,1) string
    renderContext (1,1) struct
    options.Resolution (1,1) double {mustBeFinite, mustBePositive} = 300
end

pngFile = validateTarget(pngFile);
[model, sourceAxes] = validateRenderContext(renderContext);
resolution = double(options.Resolution);

folder = string(fileparts(pngFile));
if folder == ""
    folder = string(pwd);
end

temporaryFile = string(tempname(folder)) + ".png";
cleanupTemporary = onCleanup(@() deleteIfExists(temporaryFile));

exportFigure = createExportFigure(model);
cleanupFigure = onCleanup(@() closeIfValid(exportFigure));

sourceLegend = findall(ancestor(sourceAxes, "figure"), "Type", "legend");
if isempty(sourceLegend)
    exportAxes = copyobj(sourceAxes, exportFigure);
    exportLegend = gobjects(0);
elseif isscalar(sourceLegend)
    exportAxes = copyobj(sourceAxes, exportFigure);
    exportLegend = createLegend(exportAxes, sourceLegend);
else
    error("SpectraLab:Report:InvalidFigureLegend", ...
        "A report figure may contain at most one legend.");
end
informationPanel = copyInformationPanel(sourceAxes, exportFigure);
positionLegend(exportLegend, ~isempty(informationPanel));
if ~isempty(informationPanel)
    set(exportAxes, ...
        "Units", "normalized", ...
        "Position", [0.06 0.12 0.48 0.80], ...
        "PositionConstraint", "innerposition");
else
    set(exportAxes, ...
        "Units", "normalized", ...
        "OuterPosition", [0.02 0.08 0.96 0.84], ...
        "PositionConstraint", "outerposition");
    if ~isempty(exportLegend)
        set(exportAxes, ...
            "Position", [0.06 0.12 0.60 0.80], ...
            "PositionConstraint", "innerposition");
    end
end

print(exportFigure, char(temporaryFile), ...
    "-dpng", sprintf("-r%.15g", resolution));

[ok, message] = movefile(temporaryFile, pngFile);
if ~ok
    error("SpectraLab:Report:PNGExportFailed", ...
        "Unable to finalize PNG figure '%s': %s", pngFile, message);
end

pixelWidth = round(model.Width / 72 * resolution);
pixelHeight = round(model.Height / 72 * resolution);

info = struct( ...
    "PNGFile", pngFile, ...
    "Format", "PNG", ...
    "Resolution", resolution, ...
    "WidthPoints", double(model.Width), ...
    "HeightPoints", double(model.Height), ...
    "ExpectedPixelWidth", double(pixelWidth), ...
    "ExpectedPixelHeight", double(pixelHeight));
end

function panel = copyInformationPanel(sourceAxes, exportFigure)
%COPYINFORMATIONPANEL Preserve a renderer-owned side panel in PNG output.

sourceFigure = ancestor(sourceAxes, "figure");
panel = findall(sourceFigure, "Type", "axes", ...
    "Tag", "SpectraLabFigureInformationPanel");
if isempty(panel)
    return
end
if numel(panel) ~= 1
    error("SpectraLab:Report:InvalidFigureInformationPanel", ...
        "A report figure may contain at most one information panel.");
end
panel = copyobj(panel, exportFigure);
set(panel, ...
    "Units", "normalized", ...
    "Position", [0.78 0.22 0.20 0.56], ...
    "HandleVisibility", "off");
end

function legendHandle = createLegend(targetAxes, sourceLegend)
%CREATELEGEND Recreate a source legend without changing its source axes.

legendHandle = legend(targetAxes, string(sourceLegend.String), ...
    "Location", "none", "Interpreter", sourceLegend.Interpreter);
legendHandle.FontSize = sourceLegend.FontSize;
end

function positionLegend(legendHandle, hasInformationPanel)
%POSITIONLEGEND Place an exported legend outside the plot axes.

if isempty(legendHandle)
    return
end
legendHandle.Units = "normalized";
if hasInformationPanel
    legendHandle.Position = [0.56 0.68 0.20 0.18];
else
    legendHandle.Position = [0.70 0.68 0.27 0.18];
end
legendHandle.Location = "none";
legendHandle.AutoUpdate = "off";
legendHandle.HandleVisibility = "off";
end

function pngFile = validateTarget(pngFile)
pngFile = string(pngFile);
if ~endsWith(lower(pngFile), ".png")
    error("SpectraLab:Report:InvalidPNGFile", ...
        "PNG output filename must use the .png extension.");
end

folder = string(fileparts(pngFile));
if folder ~= "" && ~isfolder(folder)
    error("SpectraLab:Report:OutputFolderNotFound", ...
        "PNG output folder does not exist: %s", folder);
end

if isfile(pngFile)
    error("SpectraLab:Report:ReportFileAlreadyExists", ...
        "Report file already exists: %s", pngFile);
end
end

function [model, sourceAxes] = validateRenderContext(renderContext)
if ~isfield(renderContext, "Graphics") || ...
        ~isfield(renderContext.Graphics, "Axes")
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext must contain Graphics.Axes.");
end

sourceAxes = renderContext.Graphics.Axes;
if ~isscalar(sourceAxes) || ~isgraphics(sourceAxes, "axes")
    error("SpectraLab:Report:MissingReportFigure", ...
        "PNG export requires exactly one valid report-owned axes object.");
end

if ~isfield(renderContext, "State") || ...
        ~isfield(renderContext.State, "RenderedElements") || ...
        ~isstruct(renderContext.State.RenderedElements)
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext must contain State.RenderedElements.");
end

records = renderContext.State.RenderedElements;
if isempty(records) || ~all(isfield(records, ["Type", "Role", "Content"]))
    error("SpectraLab:Report:MissingReportFigure", ...
        "RenderContext does not contain a valid rendered primary figure.");
end

matches = string({records.Type}) == "figure" & ...
    string({records.Role}) == "primaryFigure";
if nnz(matches) ~= 1
    error("SpectraLab:Report:MissingReportFigure", ...
        "PNG export requires exactly one rendered primary figure.");
end

model = records(matches).Content;
validateFigureModel(model);
end

function validateFigureModel(model)
required = ["Format", "Version", "Role", "Units", ...
    "Width", "Height", "AspectRatio"];
if ~isstruct(model) || ~isscalar(model)
    error("SpectraLab:Report:InvalidFigureModel", ...
        "The rendered primary figure must contain a scalar figure model.");
end
for k = 1:numel(required)
    if ~isfield(model, required(k))
        error("SpectraLab:Report:InvalidFigureModel", ...
            "Figure model is missing required field '%s'.", required(k));
    end
end
if string(model.Format) ~= "SLAB-REPORT-FIGURE" || ...
        string(model.Role) ~= "primaryFigure" || ...
        string(model.Units) ~= "points" || ...
        ~isscalar(model.Width) || ~isfinite(model.Width) || model.Width <= 0 || ...
        ~isscalar(model.Height) || ~isfinite(model.Height) || model.Height <= 0 || ...
        ~isscalar(model.AspectRatio) || ~isfinite(model.AspectRatio) || ...
        model.AspectRatio <= 0 || ...
        abs(model.Width / model.Height - model.AspectRatio) > 1e-10
    error("SpectraLab:Report:InvalidFigureModel", ...
        "The rendered primary figure has an invalid figure model.");
end
end

function fig = createExportFigure(model)
fig = figure( ...
    "Visible", "off", ...
    "Color", "white", ...
    "Units", "points", ...
    "Position", [100 100 double(model.Width) double(model.Height)], ...
    "PaperUnits", "points", ...
    "PaperSize", [double(model.Width) double(model.Height)], ...
    "PaperPosition", [0 0 double(model.Width) double(model.Height)], ...
    "PaperPositionMode", "manual", ...
    "InvertHardcopy", "off", ...
    "MenuBar", "none", ...
    "ToolBar", "none", ...
    "HandleVisibility", "off");
end

function deleteIfExists(file)
if isfile(file)
    delete(file);
end
end

function closeIfValid(fig)
if isgraphics(fig, "figure")
    close(fig);
end
end
