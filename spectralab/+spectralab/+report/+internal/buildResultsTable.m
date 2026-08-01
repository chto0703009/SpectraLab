function tableModel = buildResultsTable(result, analysisDefinition)
%BUILDRESULTSTABLE Build a canonical two-column analysis-results table.
%
%   tableModel = spectralab.report.internal.buildResultsTable( ...
%       result, analysisDefinition)
%
% The analysis definition declares which result fields are public and how
% they are presented. Numerical values retain full precision in Value;
% formatting is applied only to DisplayValue.

arguments
    result (1,1) struct
    analysisDefinition (1,1) struct
end

if ~isfield(analysisDefinition, "ResultFields") || ...
        ~isstruct(analysisDefinition.ResultFields) || ...
        isempty(analysisDefinition.ResultFields)
    error("SpectraLab:Report:InvalidResultDefinition", ...
        "Analysis definition must contain a non-empty ResultFields structure array.");
end

fields = analysisDefinition.ResultFields(:);
validateDefinitions(fields, result);

rows = repmat(emptyRow(), numel(fields), 1);
for k = 1:numel(fields)
    definition = fields(k);
    fieldName = string(definition.Field);
    value = result.(fieldName);
    displayValue = formatValue(value, string(definition.Format));
    unit = string(definition.Unit);

    if strlength(unit) > 0
        displayText = displayValue + " " + unit;
    else
        displayText = displayValue;
    end

    rows(k) = struct( ...
        "Field", fieldName, ...
        "Label", string(definition.Label), ...
        "Value", value, ...
        "Unit", unit, ...
        "Format", string(definition.Format), ...
        "DisplayValue", displayValue, ...
        "DisplayText", displayText);
end

tableModel = struct( ...
    "Format", "SLAB-REPORT-TABLE", ...
    "Version", "1.0", ...
    "Title", "Results", ...
    "Columns", ["Label", "Value"], ...
    "Rows", rows);
end

function validateDefinitions(definitions, result)
required = ["Field", "Label", "Unit", "Format"];
for k = 1:numel(definitions)
    definition = definitions(k);
    for j = 1:numel(required)
        fieldName = required(j);
        if ~isfield(definition, fieldName)
            error("SpectraLab:Report:InvalidResultDefinition", ...
                "ResultFields entry %d is missing required field '%s'.", ...
                k, fieldName);
        end
    end

    publicField = string(definition.Field);
    if ~isscalar(publicField) || strlength(strtrim(publicField)) == 0 || ...
            ~isvarname(char(publicField))
        error("SpectraLab:Report:InvalidResultDefinition", ...
            "Result field names must be non-empty valid MATLAB field names.");
    end

    if ~isfield(result, publicField)
        error("SpectraLab:Report:MissingResultField", ...
            "Analysis result is missing declared field '%s'.", publicField);
    end

    label = string(definition.Label);
    unit = string(definition.Unit);
    format = string(definition.Format);
    if ~isscalar(label) || strlength(strtrim(label)) == 0 || ...
            ~isscalar(unit) || ~isscalar(format) || ...
            strlength(format) == 0
        error("SpectraLab:Report:InvalidResultDefinition", ...
            "Result label, unit, and format must be scalar text values.");
    end
end

names = string({definitions.Field});
if numel(unique(names)) ~= numel(names)
    error("SpectraLab:Report:DuplicateResultField", ...
        "Analysis ResultFields contains duplicate field declarations.");
end
end

function displayValue = formatValue(value, format)
if (isstring(value) && isscalar(value)) || ...
        (ischar(value) && (isrow(value) || isempty(value)))
    if format ~= "%s"
        error("SpectraLab:Report:InvalidResultFormat", ...
            "Text analysis results require the format '%%s'.");
    end
    displayValue = string(value);
    return
end

if ~(isnumeric(value) || islogical(value)) || ~isscalar(value)
    error("SpectraLab:Report:UnsupportedResultValue", ...
        "Result-table values must be numeric, logical, or text scalars.");
end

try
    displayValue = string(sprintf(char(format), value));
catch exception
    error("SpectraLab:Report:InvalidResultFormat", ...
        "Unable to format analysis result using '%s': %s", ...
        format, exception.message);
end

if ~isscalar(displayValue)
    error("SpectraLab:Report:InvalidResultFormat", ...
        "Result format must produce one scalar text value.");
end
end

function row = emptyRow()
row = struct( ...
    "Field", "", ...
    "Label", "", ...
    "Value", [], ...
    "Unit", "", ...
    "Format", "", ...
    "DisplayValue", "", ...
    "DisplayText", "");
end
