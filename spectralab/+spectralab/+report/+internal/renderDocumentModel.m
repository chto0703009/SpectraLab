function [renderContext, results] = renderDocumentModel( ...
        document, context, renderContext, registry)
%RENDERDOCUMENTMODEL Resolve and dispatch document elements in order.
%
%   [renderContext, results] = ...
%       spectralab.report.internal.renderDocumentModel( ...
%           document, context, renderContext)
%
% Each renderer receives one resolved element, the read-only ReportContext,
% and the mutable short-lived RenderContext. It returns an updated
% RenderContext and one canonical RenderResult.

arguments
    document (1,1) struct
    context (1,1) struct
    renderContext (1,1) struct
    registry (:,1) struct = ...
        spectralab.report.internal.createElementRendererRegistry()
end

validateInputs(document, context, renderContext, registry);

results = repmat(emptyResult(), 0, 1);

for element = reshape(document.Elements, 1, [])
    resolved = spectralab.report.internal.resolveDocumentElement( ...
        element, context);
    renderer = lookupRenderer(registry, resolved.Type);

    [renderContext, result] = renderer( ...
        resolved, context, renderContext);

    validateRenderResult(result, resolved);
    results(end+1,1) = result; %#ok<AGROW>
end
end

function renderer = lookupRenderer(registry, elementType)
elementType = string(elementType);
matches = [registry.ElementType] == elementType;

if ~any(matches)
    error("SpectraLab:Report:UnknownElementRenderer", ...
        "No renderer is registered for document element type '%s'.", ...
        elementType);
end

if nnz(matches) > 1
    error("SpectraLab:Report:DuplicateElementRenderer", ...
        "Multiple renderers are registered for document element type '%s'.", ...
        elementType);
end

renderer = registry(matches).Renderer;
end

function validateRenderResult(result, element)
required = [ ...
    "ElementId"
    "ElementType"
    "HeightUsed"
    "PageBreakRequested"
    "Warnings"];

if ~isstruct(result) || ~isscalar(result)
    error("SpectraLab:Report:InvalidRenderResult", ...
        "An element renderer must return one scalar RenderResult structure.");
end

for k = 1:numel(required)
    fieldName = required(k);
    if ~isfield(result, fieldName)
        error("SpectraLab:Report:InvalidRenderResult", ...
            "RenderResult is missing required field '%s'.", fieldName);
    end
end

if string(result.ElementId) ~= string(element.Id) || ...
        string(result.ElementType) ~= string(element.Type)
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult identity does not match the rendered document element.");
end

if ~isscalar(result.HeightUsed) || ~isnumeric(result.HeightUsed) || ...
        ~(isnan(result.HeightUsed) || ...
        (isfinite(result.HeightUsed) && result.HeightUsed >= 0))
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult HeightUsed must be NaN or a finite non-negative scalar.");
end

if ~isscalar(result.PageBreakRequested) || ...
        ~islogical(result.PageBreakRequested)
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult PageBreakRequested must be a logical scalar.");
end

if ~isstring(result.Warnings) || ~iscolumn(result.Warnings)
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult Warnings must be a string column vector.");
end
end

function validateInputs(document, context, renderContext, registry)
if ~isfield(document, "Elements") || ~isstruct(document.Elements)
    error("SpectraLab:Report:InvalidDocumentModel", ...
        "DocumentModel.Elements must be a structure array.");
end

if ~isfield(context, "Report")
    error("SpectraLab:Report:InvalidContext", ...
        "ReportContext is missing required field 'Report'.");
end

if ~isfield(renderContext, "State")
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext is missing required field 'State'.");
end

if ~isstruct(registry) || ...
        (~isempty(registry) && ...
        (~isfield(registry, "ElementType") || ...
        ~isfield(registry, "Renderer")))
    error("SpectraLab:Report:InvalidElementRendererRegistry", ...
        "Element renderer registry must contain ElementType and Renderer fields.");
end

for k = 1:numel(registry)
    if ~isa(registry(k).Renderer, "function_handle")
        error("SpectraLab:Report:InvalidElementRendererRegistry", ...
            "Renderer for element type '%s' must be a function handle.", ...
            string(registry(k).ElementType));
    end
end
end

function result = emptyResult()
result = struct( ...
    "ElementId", "", ...
    "ElementType", "", ...
    "HeightUsed", NaN, ...
    "PageBreakRequested", false, ...
    "Warnings", strings(0,1));
end
