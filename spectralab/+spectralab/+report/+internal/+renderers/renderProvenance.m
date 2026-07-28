function renderContext = renderProvenance(context, section, renderContext)
%RENDERPROVENANCE Render the provenance report component.
%
% This first implementation establishes the component boundary and records
% successful dispatch. Concrete document elements are introduced later.

arguments
    context (1,1) struct %#ok<INUSA>
    section (1,1) struct
    renderContext (1,1) struct
end

renderContext = spectralab.report.internal.renderers.recordSection( ...
    renderContext, section.Id);
end
