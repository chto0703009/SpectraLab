function resolvedDocument = resolveDocumentModel(document, context)
%RESOLVEDOCUMENTMODEL Resolve actual content for all document elements.
%
%   resolvedDocument = spectralab.report.internal.resolveDocumentModel( ...
%       document, context)
%
% This function creates a short-lived resolved view for rendering. It does
% not modify ReportContext or the declarative DocumentModel.

arguments
    document (1,1) struct
    context (1,1) struct
end

validateDocument(document);

resolvedElements = repmat(emptyResolvedElement(), 0, 1);
for element = reshape(document.Elements, 1, [])
    resolvedElements(end+1,1) = ... %#ok<AGROW>
        spectralab.report.internal.resolveDocumentElement( ...
            element, context);
end

resolvedDocument = struct( ...
    "Format", "SLAB-REPORT-RESOLVED-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", resolvedElements);
end

function element = emptyResolvedElement()
%EMPTYRESOLVEDELEMENT Return a schema-compatible empty resolved element.

element = struct( ...
    "Id", "", ...
    "Type", "", ...
    "Role", "", ...
    "SourcePath", "", ...
    "Required", false, ...
    "Content", []);
end

function validateDocument(document)
%VALIDATEDOCUMENT Validate the declarative document-model contract.

if ~isfield(document, "Elements") || ~isstruct(document.Elements)
    error("SpectraLab:Report:InvalidDocumentModel", ...
        "DocumentModel.Elements must be a structure array.");
end
end
