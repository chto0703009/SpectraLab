function model = buildKeyValueTable(role, context)
%BUILDKEYVALUETABLE Build canonical report metadata tables.

arguments
    role (1,1) string
    context (1,1) struct
end

switch role
    case "measurementInformation"
        rows = [ ...
            row("Measurement", valueAt(context, "Measurement.Name"))
            row("Project", valueAt(context, "Measurement.Project"))
            row("Sample", valueAt(context, "Measurement.Sample"))
            row("Operator", valueAt(context, "Measurement.Operator"))
            row("Date", valueAt(context, "Measurement.Date"))];
    case "analysisInformation"
        rows = [ ...
            row("Analysis ID", valueAt(context, "Analysis.AnalysisId"))
            row("Analysis", valueAt(context, "Analysis.Name"))
            row("Method", valueAt(context, "Analysis.Method"))
            row("Standard", valueAt(context, "Analysis.Standard"))
            row("Definition", valueAt(context, "Analysis.DefinitionVersion"))];
    case "provenance"
        rows = [ ...
            row("Archive", valueAt(context, "Archive.Filename"))
            row("Archive UUID", valueAt(context, "Archive.UUID"))
            row("Content hash", valueAt(context, "Archive.ContentHash"))
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
    "Version","1.0","Role",role,"Columns",["Label","Value"], ...
    "Rows",rows);
end

function r = row(label, value)
r = struct("Label",string(label),"DisplayText",displayValue(value));
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
