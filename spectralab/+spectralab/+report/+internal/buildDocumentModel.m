function document = buildDocumentModel(manifest, registry)
%BUILDDOCUMENTMODEL Build the generic document model from a report manifest.
%
%   document = spectralab.report.internal.buildDocumentModel(manifest)
%
% The document model preserves manifest order and references ReportContext
% through SourcePath. It does not copy scientific, technical, or metadata
% values from ReportContext.

arguments
    manifest (1,1) struct
    registry (:,1) struct = ...
        spectralab.report.internal.createDocumentComponentRegistry()
end

validateInputs(manifest, registry);

elements = repmat(emptyElement(), 0, 1);

for section = reshape(manifest.Sections, 1, [])
    definition = lookupDefinition(registry, section.Component);
    elements(end+1,1) = ... %#ok<AGROW>
        spectralab.report.internal.createDocumentElement( ...
            section.Id, ...
            definition.ElementType, ...
            definition.Role, ...
            section.SourcePath, ...
            section.Required);
end

document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", elements);
end

function element = emptyElement()
%EMPTYELEMENT Return a schema-compatible empty document element.

element = struct( ...
    "Id", "", ...
    "Type", "", ...
    "Role", "", ...
    "SourcePath", "", ...
    "Required", false);
end

function definition = lookupDefinition(registry, component)
%LOOKUPDEFINITION Return the unique definition for a manifest component.

component = string(component);
matches = [registry.Component] == component;

if ~any(matches)
    error("SpectraLab:Report:UnknownDocumentComponent", ...
        "No document definition is registered for component '%s'.", ...
        component);
end

if nnz(matches) > 1
    error("SpectraLab:Report:DuplicateDocumentComponent", ...
        "Multiple document definitions are registered for component '%s'.", ...
        component);
end

definition = registry(matches);
end

function validateInputs(manifest, registry)
%VALIDATEINPUTS Validate document-model construction contracts.

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

if ~isstruct(registry) || ...
        (~isempty(registry) && ...
        (~isfield(registry, "Component") || ...
        ~isfield(registry, "ElementType") || ...
        ~isfield(registry, "Role")))
    error("SpectraLab:Report:InvalidDocumentRegistry", ...
        ["Document component registry must contain Component, " ...
         "ElementType, and Role fields."]);
end
end
