function renderContext = recordSection(renderContext, sectionId)
%RECORDSECTION Record one successfully dispatched manifest section.
%
% This is the initial renderer implementation boundary. Concrete document
% drawing is added later without changing Render Engine dispatch.

if ~isfield(renderContext.State, "RenderedSections")
    renderContext.State.RenderedSections = strings(0,1);
end

renderContext.State.RenderedSections(end+1,1) = string(sectionId);
end
