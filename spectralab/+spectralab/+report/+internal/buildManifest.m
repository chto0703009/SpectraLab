function manifest = buildManifest(context)
%BUILDMANIFEST Build the document structure for a SpectraLab report.
%
%   manifest = spectralab.report.internal.buildManifest(context)
%
% The manifest describes report structure only. It does not duplicate
% scientific or technical data from ReportContext. Each section identifies
% the canonical context path consumed by its presentation component.

arguments
    context (1,1) struct
end

validateContext(context);

sections = [ ...
    makeSection("Title",       "title",       "Measurement", true)
    makeSection("InformationBox", "informationBox", "Report", true)
    makeSection("Measurement", "measurement", "Measurement", true)
    makeSection("Analysis",    "analysis",    "Analysis",    true)
    makeSection("Results",     "results",     "Result",      true)];

if context.Analysis.HasFigure
    sections(end+1,1) = makeSection( ...
        "Figure", "figure", "Analysis", true); %#ok<AGROW>

    if hasFigureCaption(context.Analysis)
        sections(end+1,1) = makeSection( ...
            "FigureCaption", "figureCaption", ...
            "Analysis.FigureDefinition.Caption", true); %#ok<AGROW>
    end
end

if hasWarnings(context)
    sections(end+1,1) = makeSection( ...
        "Warnings", "warnings", "Report.Warnings", false); %#ok<AGROW>
end

sections(end+1,1) = makeSection( ...
    "Provenance", "provenance", "Archive", true);
sections(end+1,1) = makeSection( ...
    "Footer", "footer", "Report", true);

manifest = struct( ...
    "Format", "SLAB-REPORT-MANIFEST", ...
    "Version", "1.0", ...
    "Sections", sections);
end

function section = makeSection(id, component, sourcePath, required)
%MAKESECTION Create one declarative manifest section.

section = struct( ...
    "Id", string(id), ...
    "Component", string(component), ...
    "SourcePath", string(sourcePath), ...
    "Required", logical(required));
end

function tf = hasFigureCaption(analysis)
%HASFIGURECAPTION True when the figure definition declares caption text.

tf = isfield(analysis, "FigureDefinition") && ...
    isstruct(analysis.FigureDefinition) && ...
    isscalar(analysis.FigureDefinition) && ...
    isfield(analysis.FigureDefinition, "Caption") && ...
    isTextScalar(analysis.FigureDefinition.Caption) && ...
    strlength(strtrim(string(analysis.FigureDefinition.Caption))) > 0;
end

function tf = isTextScalar(value)
%ISTEXTSCALAR True for one character vector or one string scalar.

tf = ischar(value) || (isstring(value) && isscalar(value) && ~ismissing(value));
end

function tf = hasWarnings(context)
%HASWARNINGS True when ReportContext contains one or more warnings.

warnings = context.Report.Warnings;
tf = ~isempty(warnings) && any(strlength(string(warnings)) > 0);
end

function validateContext(context)
%VALIDATECONTEXT Validate the initial ReportManifest contract.

requiredTopLevel = [ ...
    "Archive"
    "Measurement"
    "Analysis"
    "Result"
    "Report"];

for fieldName = requiredTopLevel.'
    if ~isfield(context, fieldName)
        error("SpectraLab:Report:InvalidContext", ...
            "ReportContext is missing required field '%s'.", fieldName);
    end
end

if ~isfield(context.Analysis, "HasFigure") || ...
        ~isscalar(context.Analysis.HasFigure) || ...
        ~islogical(context.Analysis.HasFigure)
    error("SpectraLab:Report:InvalidContext", ...
        "ReportContext.Analysis.HasFigure must be a logical scalar.");
end

if ~isfield(context.Report, "Warnings")
    error("SpectraLab:Report:InvalidContext", ...
        "ReportContext.Report is missing required field 'Warnings'.");
end
end
