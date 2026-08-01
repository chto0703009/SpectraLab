function model = buildKeyValueTable(role, context)
%BUILDKEYVALUETABLE Build canonical report metadata tables.

arguments
    role (1,1) string
    context (1,1) struct
end

switch role
    case "measurementInformation"
        titleText = "Measurement";
        if hasTwoSources(context)
            rows = pairMeasurementRows(context.SourceArchives);
        else
            rows = [ ...
                row("Measurement", valueAt(context, ...
                    "MeasurementInformation.Name"))
                row("Project", valueAt(context, ...
                    "MeasurementInformation.Project"))
                row("Sample", valueAt(context, ...
                    "MeasurementInformation.Sample"))
                row("Operator", valueAt(context, ...
                    "MeasurementInformation.Operator"))
                row("Date", valueAt(context, ...
                    "MeasurementInformation.Date"))
                row("Comment", valueAt(context, ...
                    "MeasurementInformation.Comment"))];
        end
    case "analysisInformation"
        titleText = "Analysis";
        rows = [ ...
            row("Analysis ID", valueAt(context, "Analysis.AnalysisId"))
            row("Analysis", valueAt(context, "Analysis.Name"))
            row("Method", valueAt(context, "Analysis.Method"))
            row("Standard", valueAt(context, "Analysis.Standard"))
            row("Definition", valueAt(context, "Analysis.DefinitionVersion"))];
    case "provenance"
        titleText = "Provenance";
        if hasTwoSources(context)
            sourceRows = pairProvenanceRows(context.SourceArchives);
        else
            sourceRows = [ ...
                archiveRow("Archive", valueAt(context, "Archive.Filename"))
                row("Archive UUID", ...
                    displayArchiveUUID(valueAt(context, "Archive.UUID")), 2)
                row("Content hash", ...
                    displayContentHash(valueAt(context, "Archive.ContentHash")), 2)
                row("Archive format", joinValues( ...
                    valueAt(context,"Archive.Format"), ...
                    valueAt(context,"Archive.Version")))
                row("Instrument serial number", ...
                    valueAt(context, "Instrument.SerialNumber"))];
        end
        rows = [ ...
            sourceRows
            row("Report format", joinValues(valueAt(context,"Report.Format"), valueAt(context,"Report.Version")))
            row("SpectraLab", valueAt(context, "Report.SpectraLabVersion"))
            row("Report ID", valueAt(context, "Report.ReportId"))
            row("Generated", valueAt(context, "Report.GenerationTime"))];
    otherwise
        error("SpectraLab:Report:UnknownKeyValueTableRole", ...
            "Unknown key-value table role '%s'.", role);
end

model = struct("Format","SLAB-REPORT-KEY-VALUE-TABLE", ...
    "Version","1.0","Role",role,"Title",titleText, ...
    "Columns",["Label","Value"],"Rows",rows);
end

function tf = hasTwoSources(context)
tf = isfield(context, "SourceArchives") && ...
    isstruct(context.SourceArchives) && numel(context.SourceArchives) == 2;
end

function rows = pairMeasurementRows(sources)
rows = repmat(row("", ""), 12, 1);
index = 1;
for source = sources
    role = source.Role;
    rows(index) = row(role + " measurement", ...
        valueAt(source, "Measurement.Name")); index = index + 1;
    rows(index) = row(role + " project", ...
        valueAt(source, "Metadata.Project")); index = index + 1;
    rows(index) = row(sampleIdLabel(role), ...
        valueAt(source, "Metadata.SampleID")); index = index + 1;
    rows(index) = row(role + " operator", ...
        valueAt(source, "Measurement.Operator")); index = index + 1;
    rows(index) = row(role + " date", ...
        valueAt(source, "Measurement.Timestamp")); index = index + 1;
    rows(index) = row(role + " comment", ...
        valueAt(source, "Metadata.Comment")); index = index + 1;
end
end

function label = sampleIdLabel(role)
if string(role) == "Sample"
    label = "Sample ID";
else
    label = string(role) + " sample ID";
end
end

function rows = pairProvenanceRows(sources)
rows = repmat(row("", ""), 10, 1);
index = 1;
for source = sources
    role = source.Role;
    rows(index) = archiveRow(role + " archive", source.Filename); index = index + 1;
    rows(index) = row(role + " UUID", ...
        displayArchiveUUID(source.UUID), 2); index = index + 1;
    rows(index) = row(role + " content hash", ...
        displayContentHash(source.ContentHash), 2); index = index + 1;
    rows(index) = row(role + " format", ...
        joinValues(source.Format, source.Version)); index = index + 1;
    rows(index) = row(role + " instrument serial number", ...
        valueAt(source, "Instrument.SerialNumber")); index = index + 1;
end
end

function r = archiveRow(label, value)
[displayText, lineCount] = ...
    spectralab.report.internal.wrapFilename(value);
r = row(label, displayText, lineCount);
end

function r = row(label, value, lineCount)

if nargin < 3
    [displayText, lineCount] = ...
        spectralab.report.internal.wrapValue(displayValue(value), 36);
else
    displayText = displayValue(value);
end

r = struct( ...
    "Label", string(label), ...
    "DisplayText", displayText, ...
    "LineCount", lineCount);
end

function value = valueAt(context, path)
try
    value = spectralab.report.internal.resolveContextPath(context, path);
catch ME
    if ME.identifier == "SpectraLab:Report:MissingContextSource"
        value = "—";
    else
        rethrow(ME)
    end
end
end

function text = displayValue(value)
if isempty(value)
    text = "—";
elseif isdatetime(value) && isscalar(value)
    text = string(value, "yyyy-MM-dd HH:mm:ss");
elseif isstring(value) && isscalar(value)
    text = value;
elseif ischar(value)
    text = string(value);
elseif isnumeric(value) && isscalar(value)
    text = string(value);
else
    text = "—";
end
if ismissing(text) || strlength(strtrim(text)) == 0
    text = "—";
end
end

function text = displayArchiveUUID(value)

text = displayValue(value);

if text == "—"
    return
end

characters = char(text);

if numel(characters) == 36
    text = string(sprintf("%s\n%s", ...
        characters(1:18), ...
        characters(19:36)));
end
end


function text = displayContentHash(value)

text = displayValue(value);

if text == "—"
    return
end

characters = char(text);

if numel(characters) == 64
    text = string(sprintf("%s\n%s", ...
        characters(1:32), ...
        characters(33:64)));
end
end


function text = joinValues(a,b)
a = displayValue(a); b = displayValue(b);
if a == "—" && b == "—"
    text = "—";
elseif b == "—"
    text = a;
elseif a == "—"
    text = b;
else
    text = a + " " + b;
end
end
