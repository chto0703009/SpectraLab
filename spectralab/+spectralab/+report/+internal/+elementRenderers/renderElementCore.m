function [renderContext, result] = renderElementCore( ...
        element, context, renderContext, expectedType)
%RENDERELEMENTCORE Apply the common RP-006 renderer contract.
%
% This function records the resolved element in temporary rendering state.
% It never changes page or cursor state. Placement is owned exclusively by
% the Layout Engine.

arguments
    element (1,1) struct
    context (1,1) struct %#ok<INUSA>
    renderContext (1,1) struct
    expectedType {mustBeTextScalar}
end

validateElement(element, string(expectedType));

if ~isfield(renderContext, "State")
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext is missing required field 'State'.");
end

if ~isfield(renderContext.State, "RenderedElements")
    renderContext.State.RenderedElements = repmat(emptyRecord(), 0, 1);
end

record = struct( ...
    "Id", string(element.Id), ...
    "Type", string(element.Type), ...
    "Role", string(element.Role), ...
    "Content", element.Content);

renderContext.State.RenderedElements(end+1,1) = record;

pageBreakRequested = string(element.Type) == "pageBreak";
result = spectralab.report.internal.createRenderResult( ...
    element.Id, element.Type, NaN, pageBreakRequested, strings(0,1));
end

function validateElement(element, expectedType)
required = ["Id", "Type", "Role", "SourcePath", "Required", "Content"];
for fieldName = required
    if ~isfield(element, fieldName)
        error("SpectraLab:Report:InvalidResolvedElement", ...
            "Resolved document element is missing required field '%s'.", ...
            fieldName);
    end
end

if string(element.Type) ~= expectedType
    error("SpectraLab:Report:WrongElementRenderer", ...
        "Renderer for '%s' cannot render document element type '%s'.", ...
        expectedType, string(element.Type));
end
end

function record = emptyRecord()
record = struct( ...
    "Id", "", ...
    "Type", "", ...
    "Role", "", ...
    "Content", []);
end
