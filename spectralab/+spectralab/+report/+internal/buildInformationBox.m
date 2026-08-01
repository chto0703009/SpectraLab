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

pairAnalysis = isPairArchiveAnalysis(context.Analysis);
hasSourcePair = isfield(context, "SourceArchives") && ...
    isstruct(context.SourceArchives) && numel(context.SourceArchives) == 2;
if hasSourcePair
    metadataRows = pairInformationRows(context);
elseif pairAnalysis
    metadataRows = [ ...
        makeRow("Analysis", firstValue(context, "Analysis.Name"))
        makeRow("Method", firstValue(context, "Analysis.Method"))];
else
    metadataRows = [ ...
        makeRow("Measurement", firstValue(context, ...
            "MeasurementInformation.Name"))
        makeRow("Project", firstValue(context, ...
            "MeasurementInformation.Project"))
        makeRow("Sample", firstValue(context, ...
            "MeasurementInformation.Sample"))
        makeRow("Operator", firstValue(context, ...
            "MeasurementInformation.Operator"))
        makeRow("Date", firstValue(context, ...
            "MeasurementInformation.Date"))
        makeRow("Comment", firstValue(context, ...
            "MeasurementInformation.Comment"))
        makeRow("Instrument", firstValue(context, ...
            ["Instrument.Name","Instrument.Model","Instrument.Instrument"]))
        makeRow("Analysis", firstValue(context, "Analysis.Name"))
        makeRow("Method", firstValue(context, "Analysis.Method"))];
    metadataRows(end+1) = ...
        makeArchiveRow("Archive", firstValue(context, "Archive.Filename"));
end

model = struct( ...
    "Format", "SLAB-REPORT-INFORMATION-BOX", ...
    "Version", "1.0", ...
    "Role", "informationBox", ...
    "Title", "Information", ...
    "MeasurementInformationRows", metadataRows, ...
    "ResultRows", emptyResultRows());
end

function rows = emptyResultRows()
rows = struct("Field", {}, "Label", {}, "Value", {}, "Unit", {}, ...
    "Format", {}, "DisplayValue", {}, "DisplayText", {});
end

function tf = isPairArchiveAnalysis(analysis)
tf = isfield(analysis, "AnalysisId") && ...
    any(string(analysis.AnalysisId) == ["ANL-009", "ANL-010"]);
end

function rows = pairInformationRows(context)
first = context.SourceArchives(1);
second = context.SourceArchives(2);
rows = [ ...
    makeRow("Analysis", firstValue(context, "Analysis.Name"))
    makeRow("Method", firstValue(context, "Analysis.Method"))
    makeArchiveRow(first.Role + " archive", first.Filename)
    makeRow(first.Role + " measurement", first.Measurement.Name)
    makeRow(sampleIdLabel(first.Role), sourceSample(first))
    makeRow(first.Role + " comment", sourceComment(first))
    makeArchiveRow(second.Role + " archive", second.Filename)
    makeRow(second.Role + " measurement", second.Measurement.Name)
    makeRow(sampleIdLabel(second.Role), sourceSample(second))
    makeRow(second.Role + " comment", sourceComment(second))];
end

function label = sampleIdLabel(role)
if string(role) == "Sample"
    label = "Sample ID";
else
    label = string(role) + " sample ID";
end
end

function value = sourceSample(source)
value = "—";
if isfield(source.Metadata, "SampleID") && ...
        strlength(string(source.Metadata.SampleID)) > 0
    value = string(source.Metadata.SampleID);
end
end

function value = sourceComment(source)
value = "—";
if isfield(source.Metadata, "Comment") && ...
        strlength(string(source.Metadata.Comment)) > 0
    value = string(source.Metadata.Comment);
end
end

function result = makeArchiveRow(label, value)
[text, lineCount] = spectralab.report.internal.wrapFilename(value);
result = makeRow(label, text, lineCount);
end

function row = makeRow(label, value, lineCount)
if nargin < 3
    lineCount = 1;
end
row = struct("Label", string(label), ...
    "DisplayText", string(value), "LineCount", lineCount);
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
