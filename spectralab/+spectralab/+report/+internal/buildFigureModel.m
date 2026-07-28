function figureModel = buildFigureModel(analysis, layout)
%BUILDFIGUREMODEL Build a deterministic report figure geometry model.
%
%   figureModel = spectralab.report.internal.buildFigureModel( ...
%       analysis, layout)
%
% The figure model contains geometry and identity only. It does not create
% or retain MATLAB graphics objects. The registered analysis definition
% must provide FigureDefinition when HasFigure is true.

arguments
    analysis (1,1) struct
    layout (1,1) struct
end

validateAnalysis(analysis);
validateLayout(layout);

definition = analysis.FigureDefinition;
aspectRatio = double(definition.AspectRatio);
widthFraction = double(definition.WidthFraction);
maxHeight = double(definition.MaxHeight);

desiredWidth = layout.ContentWidth * widthFraction;
desiredHeight = desiredWidth / aspectRatio;

if desiredHeight > maxHeight
    height = maxHeight;
    width = height * aspectRatio;
else
    width = desiredWidth;
    height = desiredHeight;
end

figureModel = struct( ...
    "Format", "SLAB-REPORT-FIGURE", ...
    "Version", "1.0", ...
    "Role", "primaryFigure", ...
    "AspectRatio", aspectRatio, ...
    "WidthFraction", widthFraction, ...
    "MaxHeight", maxHeight, ...
    "Width", width, ...
    "Height", height, ...
    "Units", string(layout.Units));
end

function validateAnalysis(analysis)
if ~isfield(analysis, "HasFigure") || ...
        ~isscalar(analysis.HasFigure) || ...
        ~islogical(analysis.HasFigure) || ...
        ~analysis.HasFigure
    error("SpectraLab:Report:InvalidFigureDefinition", ...
        "A report figure requires Analysis.HasFigure=true.");
end

if ~isfield(analysis, "FigureDefinition") || ...
        ~isstruct(analysis.FigureDefinition) || ...
        ~isscalar(analysis.FigureDefinition)
    error("SpectraLab:Report:InvalidFigureDefinition", ...
        "Analysis.FigureDefinition must be a scalar structure.");
end

required = ["AspectRatio", "WidthFraction", "MaxHeight"];
for k = 1:numel(required)
    fieldName = required(k);
    if ~isfield(analysis.FigureDefinition, fieldName)
        error("SpectraLab:Report:InvalidFigureDefinition", ...
            "FigureDefinition is missing required field '%s'.", ...
            fieldName);
    end
end

validatePositiveScalar(analysis.FigureDefinition.AspectRatio, ...
    "AspectRatio");
validatePositiveScalar(analysis.FigureDefinition.MaxHeight, ...
    "MaxHeight");

widthFraction = analysis.FigureDefinition.WidthFraction;
if ~isnumeric(widthFraction) || ~isscalar(widthFraction) || ...
        ~isfinite(widthFraction) || widthFraction <= 0 || widthFraction > 1
    error("SpectraLab:Report:InvalidFigureDefinition", ...
        "FigureDefinition.WidthFraction must be in the interval (0, 1].");
end
end

function validatePositiveScalar(value, fieldName)
if ~isnumeric(value) || ~isscalar(value) || ...
        ~isfinite(value) || value <= 0
    error("SpectraLab:Report:InvalidFigureDefinition", ...
        "FigureDefinition.%s must be a positive finite scalar.", ...
        fieldName);
end
end

function validateLayout(layout)
required = ["Units", "ContentWidth", "ContentHeight"];
for k = 1:numel(required)
    fieldName = required(k);
    if ~isfield(layout, fieldName)
        error("SpectraLab:Report:InvalidLayoutState", ...
            "Layout state is missing required field '%s'.", fieldName);
    end
end

if ~isnumeric(layout.ContentWidth) || ~isscalar(layout.ContentWidth) || ...
        ~isfinite(layout.ContentWidth) || layout.ContentWidth <= 0 || ...
        ~isnumeric(layout.ContentHeight) || ~isscalar(layout.ContentHeight) || ...
        ~isfinite(layout.ContentHeight) || layout.ContentHeight <= 0
    error("SpectraLab:Report:InvalidLayoutState", ...
        "Layout content dimensions must be positive finite scalars.");
end
end
