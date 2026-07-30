function context = buildContext( ...
        archiveFile, archive, analysisDefinition, result, ...
        outputFolder, options)
%BUILDCONTEXT Build the data-only context for a SpectraLab report.
%
%   context = spectralab.report.internal.buildContext( ...
%       archiveFile, archive, analysisDefinition, result, outputFolder)
%
% This internal function only assembles trusted information. It does not
% load an archive, run an analysis, create graphics, or write files.
%
% ReportContext contains reproducible report information only. Temporary
% graphics resources and export state belong to a separate RenderContext.

arguments
    archiveFile {mustBeTextScalar}
    archive (1,1) struct
    analysisDefinition (1,1) struct
    result
    outputFolder {mustBeTextScalar}
    options.ShowFigure (1,1) logical = false
    options.OpenPDF (1,1) logical = false
    options.GenerationTime (1,1) datetime = datetime("now")
end

archiveFile = string(archiveFile);
outputFolder = string(outputFolder);

validateArchiveFields(archive);
validateAnalysisDefinition(analysisDefinition);

[~, archiveName, archiveExtension] = fileparts(archiveFile);
archiveFilename = string(archiveName) + string(archiveExtension);

context = struct();

context.Request = struct( ...
    "ArchiveFile", archiveFile, ...
    "AnalysisId", string(analysisDefinition.AnalysisId), ...
    "OutputFolder", outputFolder, ...
    "ShowFigure", options.ShowFigure, ...
    "OpenPDF", options.OpenPDF);

context.Archive = struct( ...
    "UUID", string(archive.Identity.UUID), ...
    "ContentHash", string(archive.Identity.ContentHash), ...
    "Format", string(archive.Version.Format), ...
    "Version", string(archive.Version.Version), ...
    "Filename", archiveFilename);

context.Measurement = archive.Measurement;
context.MeasurementInformation = buildMeasurementInformation(archive);
context.Instrument = archive.Instrument;
context.Quality = archive.Quality;
context.Analysis = analysisDefinition;
context.Result = result;

context.Report = struct( ...
    "Format", "SLAB-REPORT", ...
    "Version", "1.0", ...
    "SpectraLabVersion", spectralab.version(), ...
    "GenerationTime", options.GenerationTime, ...
    "ReportId", "", ...
    "Warnings", strings(0,1));
end

function information = buildMeasurementInformation(archive)
%BUILDMEASUREMENTINFORMATION Assemble trusted measurement information.
%
% MeasurementInformation is a report-specific presentation structure.
% Its values are derived automatically from the archive's canonical
% Measurement and Metadata sections.

information = struct( ...
    "Name", firstArchiveValue(archive, [ ...
        "Measurement.Name"]), ...
    "Project", firstArchiveValue(archive, [ ...
        "Measurement.Project"
        "Metadata.Project"]), ...
    "Sample", firstArchiveValue(archive, [ ...
        "Measurement.Sample"
        "Metadata.Sample"
        "Metadata.SampleID"]), ...
    "Operator", firstArchiveValue(archive, [ ...
        "Measurement.Operator"
        "Metadata.Operator"]), ...
    "Date", firstArchiveValue(archive, [ ...
        "Measurement.Date"
        "Measurement.MeasurementDate"
        "Measurement.Timestamp"
        "Metadata.Date"]), ...
    "Comment", firstArchiveValue(archive, [ ...
        "Measurement.Comment"
        "Metadata.Comment"]));
end

function value = firstArchiveValue(archive, paths)
%FIRSTARCHIVEVALUE Return the preferred existing archive value.
%
% The first non-empty value has priority. If all existing candidates are
% empty, preserve the first existing value so its original data type is
% retained, for example string empty rather than numeric empty.

value = [];
hasFallback = false;
fallback = [];

for path = paths.'
    parts = split(path, ".");
    candidate = archive;
    found = true;

    for part = parts.'
        if ~isstruct(candidate) || ...
                ~isscalar(candidate) || ...
                ~isfield(candidate, part)
            found = false;
            break
        end

        candidate = candidate.(part);
    end

    if found && ~hasFallback
        fallback = candidate;
        hasFallback = true;
    end

    if found && ~isEmptyReportValue(candidate)
        value = candidate;
        return
    end
end

if hasFallback
    value = fallback;
end
end

function tf = isEmptyReportValue(value)
%ISEMPTYREPORTVALUE Identify absent descriptive values.

if isempty(value)
    tf = true;
elseif isstring(value) && isscalar(value)
    tf = strlength(strip(value)) == 0;
elseif ischar(value) && (isrow(value) || isempty(value))
    tf = strlength(strip(string(value))) == 0;
else
    tf = false;
end
end

function validateArchiveFields(archive)
%VALIDATEARCHIVEFIELDS Validate fields required by ReportContext.

requiredTopLevel = [ ...
    "Identity"
    "Version"
    "Measurement"
    "Metadata"
    "Instrument"
    "Quality"];

for fieldName = requiredTopLevel.'
    if ~isfield(archive, fieldName)
        error("SpectraLab:Report:InvalidArchive", ...
            "Archive is missing required field '%s'.", fieldName);
    end
end

requiredIdentity = ["UUID", "ContentHash"];
for fieldName = requiredIdentity
    if ~isfield(archive.Identity, fieldName)
        error("SpectraLab:Report:InvalidArchive", ...
            "Archive identity is missing required field '%s'.", ...
            fieldName);
    end
end

requiredVersion = ["Format", "Version"];
for fieldName = requiredVersion
    if ~isfield(archive.Version, fieldName)
        error("SpectraLab:Report:InvalidArchive", ...
            "Archive version is missing required field '%s'.", ...
            fieldName);
    end
end
end

function validateAnalysisDefinition(definition)
%VALIDATEANALYSISDEFINITION Validate the initial reporting contract.

required = [ ...
    "AnalysisId"
    "Name"
    "Method"
    "Standard"
    "DefinitionVersion"
    "HasFigure"];

for fieldName = required.'
    if ~isfield(definition, fieldName)
        error("SpectraLab:Report:InvalidAnalysisDefinition", ...
            "Analysis definition is missing required field '%s'.", ...
            fieldName);
    end
end

if ~isscalar(definition.HasFigure) || ~islogical(definition.HasFigure)
    error("SpectraLab:Report:InvalidAnalysisDefinition", ...
        "Analysis definition field 'HasFigure' must be a logical scalar.");
end
end
