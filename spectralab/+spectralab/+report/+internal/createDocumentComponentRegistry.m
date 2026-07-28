function registry = createDocumentComponentRegistry()
%CREATEDOCUMENTCOMPONENTREGISTRY Map report components to document elements.
%
%   registry = spectralab.report.internal.createDocumentComponentRegistry()
%
% The registry defines the initial generic document representation for each
% canonical manifest component. It contains no scientific report data.

registry = [ ...
    makeEntry("title",       "heading",   "reportTitle")
    makeEntry("informationBox", "table", "informationBox")
    makeEntry("measurement", "table",     "measurementInformation")
    makeEntry("analysis",    "table",     "analysisInformation")
    makeEntry("results",     "table",     "analysisResults")
    makeEntry("figure",      "figure",    "primaryFigure")
    makeEntry("figureCaption", "caption", "primaryFigureCaption")
    makeEntry("warnings",    "list",      "reportWarnings")
    makeEntry("provenance",  "table",     "provenance")
    makeEntry("footer",      "paragraph", "reportFooter")];
end

function entry = makeEntry(component, elementType, role)
%MAKEENTRY Create one document component registration entry.

entry = struct( ...
    "Component", string(component), ...
    "ElementType", string(elementType), ...
    "Role", string(role));
end
