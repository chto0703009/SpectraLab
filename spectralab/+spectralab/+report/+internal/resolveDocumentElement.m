function resolved = resolveDocumentElement(element, context)
%RESOLVEDOCUMENTELEMENT Resolve one document element's actual content.
%
%   resolved = spectralab.report.internal.resolveDocumentElement( ...
%       element, context)
%
% The returned object is a short-lived rendering input. The declarative
% DocumentModel remains unchanged and continues to contain only SourcePath
% references. Scientific and technical data are read from ReportContext at
% the point where a renderer needs them.

arguments
    element (1,1) struct
    context (1,1) struct
end

validateElement(element);

content = spectralab.report.internal.resolveContextPath( ...
    context, element.SourcePath);

resolved = element;
resolved.Content = content;
end

function validateElement(element)
%VALIDATEELEMENT Validate the document-element resolution contract.

required = ["Id", "Type", "Role", "SourcePath", "Required"];
for fieldName = required
    if ~isfield(element, fieldName)
        error("SpectraLab:Report:InvalidDocumentElement", ...
            "Document element is missing required field '%s'.", ...
            fieldName);
    end
end

if ~isscalar(element.Required) || ~islogical(element.Required)
    error("SpectraLab:Report:InvalidDocumentElement", ...
        "Document element field 'Required' must be a logical scalar.");
end
end
