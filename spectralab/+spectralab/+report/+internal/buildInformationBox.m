function model = buildInformationBox(context)
%BUILDINFORMATIONBOX Build the reusable SpectraLab information-box model.
%
% The model contains selected trusted metadata and the analysis-defined
% public result fields. Missing metadata is displayed explicitly as an
% em dash. No scientific values are inferred or recalculated.

arguments
    context (1,1) struct
end

required = ["Archive","Measurement","MeasurementInformation", ...
    "Instrument","Analysis","Result","Report"];
for k = 1:numel(required)
    if ~isfield(context, required(k))
        error("SpectraLab:Report:InvalidInformationBoxContext", ...
            "InformationBox context is missing required field '%s'.", required(k));
    end
end

metadataRows = [ ...
    makeRow("Measurement", firstValue(context, ...
        ["MeasurementInformation.Name"]))
    makeRow("Project", firstValue(context, ...
        ["MeasurementInformation.Project"]))
    makeRow("Sample", firstValue(context, ...
        ["MeasurementInformation.Sample"]))
    makeRow("Operator", firstValue(context, ...
        ["MeasurementInformation.Operator"]))
    makeRow("Date", firstValue(context, ...
        ["MeasurementInformation.Date"]))
    makeRow("Instrument", firstValue(context, ...
        ["Instrument.Name","Instrument.Model","Instrument.Instrument"]))
    makeRow("Analysis", firstValue(context, ["Analysis.Name"]))
    makeRow("Method", firstValue(context, ["Analysis.Method"]))
    makeRow("Archive", firstValue(context, ["Archive.Filename"]))];

results = spectralab.report.internal.buildResultsTable( ...
    context.Result, context.Analysis);

model = struct( ...
    "Format", "SLAB-REPORT-INFORMATION-BOX", ...
    "Version", "1.0", ...
    "Role", "informationBox", ...
    "Title", "Information", ...
    "MeasurementInformationRows", metadataRows, ...
    "ResultRows", results.Rows);
end

function row = makeRow(label, value)
row = struct("Label", string(label), "DisplayText", string(value));
end

function value = firstValue(context, paths)
value = "—";
for k = 1:numel(paths)
    [found, candidate] = tryPath(context, paths(k));
    if found
        candidate = formatValue(candidate);
        if strlength(candidate) > 0
            value = candidate;
            return
        end
    end
end
end

function [found, value] = tryPath(value, path)
parts = split(string(path), ".");
found = true;
for k = 1:numel(parts)
    if ~isstruct(value) || ~isscalar(value) || ~isfield(value, parts(k))
        found = false;
        value = [];
        return
    end
    value = value.(parts(k));
end
end

function text = formatValue(value)
if isdatetime(value) && isscalar(value)
    text = string(value, "yyyy-MM-dd HH:mm:ss");
elseif isstring(value) && isscalar(value)
    text = value;
elseif ischar(value) && (isrow(value) || isempty(value))
    text = string(value);
elseif isnumeric(value) && isscalar(value) && isfinite(value)
    text = string(value);
else
    text = "";
end
text = strip(text);
end
