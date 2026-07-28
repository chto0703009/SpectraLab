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
cleanupTemporary = onCleanup(@() deleteIfExists(temporaryFile)); %#ok<NASGU>

exportFigure = createExportFigure(model);
cleanupFigure = onCleanup(@() closeIfValid(exportFigure)); %#ok<NASGU>

exportAxes = copyobj(sourceAxes, exportFigure);
set(exportAxes, ...
    "Units", "normalized", ...
    "OuterPosition", [0 0 1 1], ...
    "PositionConstraint", "outerposition");

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
