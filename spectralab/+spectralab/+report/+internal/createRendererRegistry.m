function registry = createRendererRegistry()
%CREATERENDERERREGISTRY Create the canonical report renderer registry.
%
%   registry = spectralab.report.internal.createRendererRegistry()
%
% The registry maps canonical manifest component identifiers to one
% renderer function each. Render Engine uses this registry for dispatch and
% contains no component-specific switch or if logic.

registry = [ ...
    makeEntry("title",       @spectralab.report.internal.renderers.renderTitle)
    makeEntry("measurement", @spectralab.report.internal.renderers.renderMeasurement)
    makeEntry("analysis",    @spectralab.report.internal.renderers.renderAnalysis)
    makeEntry("results",     @spectralab.report.internal.renderers.renderResults)
    makeEntry("figure",      @spectralab.report.internal.renderers.renderFigure)
    makeEntry("warnings",    @spectralab.report.internal.renderers.renderWarnings)
    makeEntry("provenance",  @spectralab.report.internal.renderers.renderProvenance)
    makeEntry("footer",      @spectralab.report.internal.renderers.renderFooter)];
end

function entry = makeEntry(component, renderer)
%MAKEENTRY Create one immutable renderer registration entry.

entry = struct( ...
    "Component", string(component), ...
    "Renderer", renderer);
end
