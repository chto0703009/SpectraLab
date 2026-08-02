function element = createDocumentElement( ...
        id, type, role, sourcePath, required)
%CREATEDOCUMENTELEMENT Create one declarative report document element.
%
%   element = spectralab.report.internal.createDocumentElement( ...
%       id, type, role, sourcePath, required)
%
% A document element describes presentation structure only. It references
% ReportContext through SourcePath and does not copy report data.

arguments
    id {mustBeTextScalar}
    type {mustBeTextScalar}
    role {mustBeTextScalar}
    sourcePath {mustBeTextScalar}
    required (1,1) logical
end

id = string(id);
type = string(type);
role = string(role);
sourcePath = string(sourcePath);

validateElementText(id, "Id");
validateElementType(type);
validateElementText(role, "Role");
validateElementText(sourcePath, "SourcePath");

element = struct( ...
    "Id", id, ...
    "Type", type, ...
    "Role", role, ...
    "SourcePath", sourcePath, ...
    "Required", required);
end

function validateElementType(type)
%VALIDATEELEMENTTYPE Validate the canonical minimal document vocabulary.

canonicalTypes = [ ...
    "heading"
    "paragraph"
    "table"
    "figure"
    "caption"
    "list"
    "spacer"
    "pageBreak"];

if ~any(type == canonicalTypes)
    error("SpectraLab:Report:UnknownDocumentElement", ...
        "Unknown document element type '%s'.", type);
end
end

function validateElementText(value, fieldName)
%VALIDATEELEMENTTEXT Require a non-empty scalar text value.

if strlength(strtrim(value)) == 0
    error("SpectraLab:Report:InvalidDocumentElement", ...
        "Document element field '%s' must not be empty.", fieldName);
end
end
