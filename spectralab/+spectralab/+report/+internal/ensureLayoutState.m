function renderContext = ensureLayoutState(renderContext)
%ENSURELAYOUTSTATE Add canonical layout state when it is not present.

if ~isfield(renderContext, "State") || ~isstruct(renderContext.State)
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext is missing required structure State.");
end

if ~isfield(renderContext.State, "Layout")
    renderContext.State.Layout = ...
        spectralab.report.internal.createLayoutState();
end

layout = renderContext.State.Layout;
required = ["ContentWidth", "ContentHeight", "CurrentPage", "CursorY"];
for k = 1:numel(required)
    if ~isfield(layout, required(k))
        error("SpectraLab:Report:InvalidRenderContext", ...
            "RenderContext layout is missing required field '%s'.", required(k));
    end
end
end
