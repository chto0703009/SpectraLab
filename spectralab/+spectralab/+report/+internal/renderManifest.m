function renderContext = renderManifest( ...
        context, manifest, renderContext, registry)
%RENDERMANIFEST Dispatch manifest sections through registered renderers.
%
%   renderContext = spectralab.report.internal.renderManifest( ...
%       context, manifest, renderContext)
%
% Render Engine processes sections in manifest order. It selects each
% renderer through the central registry and returns only updated temporary
% rendering state. ReportContext and ReportManifest are read-only inputs.

arguments
    context (1,1) struct
    manifest (1,1) struct
    renderContext (1,1) struct
    registry (:,1) struct = ...
        spectralab.report.internal.createRendererRegistry()
end

validateInputs(context, manifest, renderContext, registry);

for section = reshape(manifest.Sections, 1, [])
    renderer = lookupRenderer(registry, section.Component);
    renderContext = renderer(context, section, renderContext);
end
end

function renderer = lookupRenderer(registry, component)
%LOOKUPRENDERER Return the unique renderer for a component identifier.

component = string(component);
matches = [registry.Component] == component;

if ~any(matches)
    error("SpectraLab:Report:UnknownRenderer", ...
        "No renderer is registered for component '%s'.", component);
end

if nnz(matches) > 1
    error("SpectraLab:Report:DuplicateRenderer", ...
        "Multiple renderers are registered for component '%s'.", ...
        component);
end

renderer = registry(matches).Renderer;
end

function validateInputs(context, manifest, renderContext, registry)
%VALIDATEINPUTS Validate Render Engine contracts before dispatch.

if ~isfield(context, "Report")
    error("SpectraLab:Report:InvalidContext", ...
        "ReportContext is missing required field 'Report'.");
end

if ~isfield(manifest, "Sections") || ~isstruct(manifest.Sections)
    error("SpectraLab:Report:InvalidManifest", ...
        "ReportManifest.Sections must be a structure array.");
end

requiredSectionFields = ["Id", "Component", "SourcePath", "Required"];
for fieldName = requiredSectionFields
    if ~isempty(manifest.Sections) && ~isfield(manifest.Sections, fieldName)
        error("SpectraLab:Report:InvalidManifest", ...
            "ReportManifest.Sections is missing required field '%s'.", ...
            fieldName);
    end
end

if ~isfield(renderContext, "State")
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext is missing required field 'State'.");
end

if ~isstruct(registry) || ...
        (~isempty(registry) && ...
        (~isfield(registry, "Component") || ~isfield(registry, "Renderer")))
    error("SpectraLab:Report:InvalidRendererRegistry", ...
        "Renderer registry must contain Component and Renderer fields.");
end

for k = 1:numel(registry)
    if ~isa(registry(k).Renderer, "function_handle")
        error("SpectraLab:Report:InvalidRendererRegistry", ...
            "Renderer for component '%s' must be a function handle.", ...
            string(registry(k).Component));
    end
end
end
