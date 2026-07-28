function registry = createElementRendererRegistry()
%CREATEELEMENTRENDERERREGISTRY Create the canonical element renderer registry.
%
% The registry maps each canonical document element type to exactly one
% renderer implementing the common RP-006 rendering contract.

registry = [ ...
    makeEntry("heading",   @spectralab.report.internal.elementRenderers.renderHeading)
    makeEntry("paragraph", @spectralab.report.internal.elementRenderers.renderParagraph)
    makeEntry("table",     @spectralab.report.internal.elementRenderers.renderTable)
    makeEntry("figure",    @spectralab.report.internal.elementRenderers.renderFigure)
    makeEntry("caption",   @spectralab.report.internal.elementRenderers.renderCaption)
    makeEntry("list",      @spectralab.report.internal.elementRenderers.renderList)
    makeEntry("spacer",    @spectralab.report.internal.elementRenderers.renderSpacer)
    makeEntry("pageBreak", @spectralab.report.internal.elementRenderers.renderPageBreak)];
end

function entry = makeEntry(elementType, renderer)
entry = struct( ...
    "ElementType", string(elementType), ...
    "Renderer", renderer);
end
