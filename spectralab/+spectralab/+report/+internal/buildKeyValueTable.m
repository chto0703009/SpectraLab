function model = buildKeyValueTable(role, context)
%BUILDKEYVALUETABLE Build canonical report metadata tables.

arguments
    role (1,1) string
    context (1,1) struct
end

switch role
    case "measurementInformation"
        titleText = "Measurement";
        rows = [ ...
            row("Measurement", valueAt(context, "Measurement.Name"))
            row("Project", valueAt(context, "Measurement.Project"))
            row("Sample", valueAt(context, "Measurement.Sample"))
            row("Operator", valueAt(context, "Measurement.Operator"))
            row("Date", valueAt(context, "Measurement.Date"))];
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
        rows = [ ...
            row("Archive", valueAt(context, "Archive.Filename"))
            row("Archive UUID", ...
                displayArchiveUUID(valueAt(context, "Archive.UUID")), 2)
            row("Content hash", ...
                displayContentHash(valueAt(context, "Archive.ContentHash")), 2)
            row("Archive format", joinValues(valueAt(context,"Archive.Format"), valueAt(context,"Archive.Version")))
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

function r = row(label, value, lineCount)

if nargin < 3
    lineCount = 1;
end

r = struct( ...
    "Label", string(label), ...
    "DisplayText", displayValue(value), ...
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
