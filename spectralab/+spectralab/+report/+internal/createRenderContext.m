function renderContext = createRenderContext(context, manifest, options)
%CREATERENDERCONTEXT Create temporary resources for report rendering.
%
%   renderContext = spectralab.report.internal.createRenderContext( ...
%       context, manifest)
%
% RenderContext contains temporary MATLAB resources and mutable rendering
% state only. It does not copy ReportContext or ReportManifest data.
%
% A private figure and axes are created only when the manifest contains a
% Figure section. The figure is hidden by default.

arguments
    context (1,1) struct
    manifest (1,1) struct
    options.ShowFigure (1,1) logical = false
end

validateInputs(context, manifest);

renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct( ...
        "Figure", gobjects(0), ...
        "Axes", gobjects(0)), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct( ...
        "CurrentPage", 1, ...
        "CursorY", 0, ...
        "Layout", spectralab.report.internal.createLayoutState()));

if hasFigureSection(manifest)
    visibility = "off";
    if options.ShowFigure
        visibility = "on";
    end

    figureHandle = figure( ...
        "Visible", visibility, ...
        "HandleVisibility", "callback", ...
        "NumberTitle", "off", ...
        "Name", "SpectraLab Report Figure");

    axesHandle = axes("Parent", figureHandle);

    renderContext.Graphics.Figure = figureHandle;
    renderContext.Graphics.Axes = axesHandle;
end
end

function tf = hasFigureSection(manifest)
%HASFIGURESECTION True when the manifest contains one Figure section.

tf = any([manifest.Sections.Id] == "Figure");
end

function validateInputs(context, manifest)
%VALIDATEINPUTS Validate the initial RenderContext contract.

if ~isfield(context, "Report")
    error("SpectraLab:Report:InvalidContext", ...
        "ReportContext is missing required field 'Report'.");
end

requiredManifest = ["Format", "Version", "Sections"];
for fieldName = requiredManifest
    if ~isfield(manifest, fieldName)
        error("SpectraLab:Report:InvalidManifest", ...
            "ReportManifest is missing required field '%s'.", fieldName);
    end
end

if ~isstruct(manifest.Sections) || ...
        (~isempty(manifest.Sections) && ~isfield(manifest.Sections, "Id"))
    error("SpectraLab:Report:InvalidManifest", ...
        "ReportManifest.Sections must contain section identifiers.");
end
end
