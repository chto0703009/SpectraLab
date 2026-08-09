function info = generate(archiveFiles, analysisId, outputFolder, options)
%GENERATE Generate a SpectraLab report from saved archives.
%
%   info = spectralab.report.generate( ...
%       archiveFile, analysisId, outputFolder)
%
%   info = spectralab.report.generate( ...
%       [referenceArchiveFile, sampleArchiveFile], ...
%       analysisId, outputFolder)
%
%   Use FigureOutputFolder to save a figure directly outside the PDF
%   report folder. This keeps report and plot products separate even if
%   PDF generation subsequently fails.
%
% RP-019 provides the public orchestration pipeline.
% RP-020 requires every reportable analysis to be resolved from the
% canonical analysis registry. Ad-hoc specification structures are not
% accepted by this public API.

arguments
    archiveFiles
    analysisId {mustBeTextScalar}
    outputFolder {mustBeTextScalar}
    options.ShowFigure (1,1) logical = false
    options.OpenPDF (1,1) logical = false
    options.GenerationTime (1,1) datetime = datetime("now")
    options.Resample (1,1) logical = false
    options.RefinementFactor (1,1) double ...
        {mustBeInteger, mustBePositive} = 1
    options.InterpolationMethod (1,1) string = "pchip"
    options.OutputBaseName (1,1) string = ""
    options.DerivedArchiveFile (1,1) string = ""
    options.FigureOutputFolder (1,1) string = ""
    options.ExportPNG (1,1) logical = true
end

archiveFiles = normalizeArchiveFiles(archiveFiles);
analysisId = string(analysisId);
outputFolder = string(outputFolder);

entry = spectralab.report.internal.resolveAnalysisSpecification(analysisId);
definition = entry.AnalysisDefinition;
validateArchiveCount(archiveFiles, entry.InputRoles, definition.AnalysisId);
inputRoles = resolveInputRoles(entry.InputRoles, ...
    definition.AnalysisId, numel(archiveFiles));

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
figureOutputFolder = resolveFigureOutputFolder( ...
    outputFolder, options.FigureOutputFolder);

archives = loadArchives(archiveFiles);
if definition.AnalysisId == "ANL-009"
    result = entry.AnalysisRunner(archives, [], ...
        Resample=options.Resample, ...
        RefinementFactor=options.RefinementFactor, ...
        InterpolationMethod=options.InterpolationMethod, ...
        SourceFiles=archiveFiles);
elseif definition.AnalysisId == "ANL-010"
    result = entry.AnalysisRunner(archives{:}, ...
        Resample=options.Resample, ...
        RefinementFactor=options.RefinementFactor, ...
        InterpolationMethod=options.InterpolationMethod, ...
        SourceFiles=archiveFiles);
else
    result = entry.AnalysisRunner(archives{:});
end
result = addSourceFilenames(result, archiveFiles, ...
    definition.AnalysisId, options.DerivedArchiveFile);
validateAnalysisResult(result, definition);

primaryArchiveFile = archiveFiles(end);
primaryArchive = archives{end};

context = spectralab.report.internal.buildContext( ...
    primaryArchiveFile, ...
    primaryArchive, ...
    definition, ...
    result, ...
    outputFolder, ...
    ShowFigure=options.ShowFigure, ...
    OpenPDF=options.OpenPDF, ...
    GenerationTime=options.GenerationTime);

if numel(archives) == 2 || definition.AnalysisId == "ANL-009"
    context.SourceArchives = buildSourceArchives( ...
        archiveFiles, archives, inputRoles);
    if definition.AnalysisId == "ANL-009"
        pairTitle = definition.Name + ": " + numel(archives) + " sources";
    else
        pairTitle = definition.Name + ": " + ...
            string(archives{1}.Measurement.Name) + " / " + ...
            string(archives{2}.Measurement.Name);
    end
    context.Measurement.Name = pairTitle;
    context.MeasurementInformation.Name = pairTitle;
end

manifest = spectralab.report.internal.buildManifest(context);
document = spectralab.report.internal.buildDocumentModel(manifest);
renderContext = spectralab.report.internal.createRenderContext( ...
    context, manifest, ShowFigure=options.ShowFigure);

cleanup = onCleanup(@() ...
    spectralab.report.internal.releaseRenderContext(renderContext));

pngInfo = struct();
pngFile = "";

if definition.HasFigure
    if definition.AnalysisId == "ANL-009"
        entry.FigureRenderer( ...
            renderContext.Graphics.Axes, archives, [], result);
    else
        entry.FigureRenderer( ...
            renderContext.Graphics.Axes, archives{:}, result);
    end

    pngFile = buildPngFilename( ...
        figureOutputFolder, primaryArchiveFile, ...
        definition.AnalysisId, options.OutputBaseName);
end

function folder = resolveFigureOutputFolder(reportFolder, requestedFolder)
%RESOLVEFIGUREOUTPUTFOLDER Return the explicit or default figure folder.

folder = strtrim(string(requestedFolder));
if strlength(folder) == 0
    folder = reportFolder;
end
if ~isfolder(folder)
    [created, message] = mkdir(folder);
    if ~created
        error("SpectraLab:Report:FigureOutputFolderCreateFailed", ...
            "Could not create figure output folder:\n%s\n\n%s", ...
            folder, message);
    end
end
end

[renderContext, renderResults] = ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, renderContext);

[renderContext, layoutPlan] = ...
    spectralab.report.internal.layoutRenderResults( ...
        renderContext, renderResults);

if definition.HasFigure && options.ExportPNG
    pngInfo = spectralab.report.internal.exportPNG( ...
        pngFile, renderContext);
elseif definition.HasFigure
    pngFile = "";
end

pdfFile = buildPdfFilename( ...
    outputFolder, primaryArchiveFile, ...
    definition.AnalysisId, options.OutputBaseName);

pdfInfo = spectralab.report.internal.exportPDF( ...
    pdfFile, layoutPlan, renderContext);

info = struct( ...
    "ArchiveFiles", archiveFiles, ...
    "AnalysisId", definition.AnalysisId, ...
    "InputRoles", inputRoles, ...
    "PDFFile", pdfFile, ...
    "PNGFile", pngFile, ...
    "PDF", pdfInfo, ...
    "PNG", pngInfo, ...
    "Context", context, ...
    "Manifest", manifest, ...
    "Document", document, ...
    "LayoutPlan", layoutPlan);

if options.OpenPDF
    openPdfFile(pdfFile);
end
end

function result = addSourceFilenames( ...
        result, archiveFiles, analysisId, derivedArchiveFile)
%ADDSOURCEFILENAMES Preserve the actual user-selected MAT filenames.

if analysisId == "ANL-009"
    displayFiles = strings(1, numel(archiveFiles));
    for index = 1:numel(archiveFiles)
        [~, name, extension] = fileparts(archiveFiles(index));
        displayFiles(index) = string(name) + string(extension);
    end
    result.SourceFiles = displayFiles;
    result.SourceFilesText = strjoin(displayFiles,newline);
    result.SourceCount = numel(displayFiles);
    result.SourceAFile = displayFiles(1);
    result.SourceBFile = displayFiles(2);
    if isfield(result, "Analysis") && isfield(result.Analysis, "Sources")
        for index = 1:numel(displayFiles)
            result.Analysis.Sources(index).Filename = displayFiles(index);
        end
    end
elseif numel(archiveFiles) ~= 2 || ...
        ~isfield(result, "SourceAFile") || ~isfield(result, "SourceBFile")
    return
else
    [~, firstName, firstExtension] = fileparts(archiveFiles(1));
    [~, secondName, secondExtension] = fileparts(archiveFiles(2));
    result.SourceAFile = string(firstName) + string(firstExtension);
    result.SourceBFile = string(secondName) + string(secondExtension);
end

if analysisId == "ANL-009" && isfield(result, "DerivedArchiveFile")
    if strlength(strtrim(derivedArchiveFile)) == 0
        result.DerivedArchiveFile = "Not saved by report generation";
    else
        [~, derivedName, derivedExtension] = fileparts(derivedArchiveFile);
        result.DerivedArchiveFile = ...
            string(derivedName) + string(derivedExtension);
    end
end

if analysisId ~= "ANL-009" && isfield(result, "Analysis") && isfield(result.Analysis, "Sources")
    result.Analysis.Sources(1).Filename = result.SourceAFile;
    result.Analysis.Sources(2).Filename = result.SourceBFile;
end
end

function sources = buildSourceArchives(archiveFiles, archives, inputRoles)
sources = repmat(struct( ...
    "Role", "", "Filename", "", "UUID", "", "ContentHash", "", ...
    "Format", "", "Version", "", "Measurement", struct(), ...
    "Metadata", struct(), "Instrument", struct()), 1, numel(archives));

for k = 1:numel(archives)
    [~, name, extension] = fileparts(archiveFiles(k));
    archive = archives{k};
    sources(k) = struct( ...
        "Role", inputRoles(k), ...
        "Filename", string(name) + string(extension), ...
        "UUID", string(archive.Identity.UUID), ...
        "ContentHash", string(archive.Identity.ContentHash), ...
        "Format", string(archive.Version.Format), ...
        "Version", string(archive.Version.Version), ...
        "Measurement", archive.Measurement, ...
        "Metadata", archive.Metadata, ...
        "Instrument", archive.Instrument);
end
end

function openPdfFile(pdfFile)
%OPENPDFFILE Ask MATLAB to open the completed report in the system viewer.

try
    open(char(pdfFile));
catch exception
    warning("SpectraLab:Report:PDFOpenFailed", ...
        "The PDF report was created but could not be opened automatically.\n" + ...
        "File: %s\nReason: %s", ...
        pdfFile, exception.message);
end
end

function archiveFiles = normalizeArchiveFiles(value)
%NORMALIZEARCHIVEFILES Validate and normalize archive paths.

if ischar(value)
    value = string(value);
end

if ~isstring(value) || isempty(value) || ...
        ~isvector(value) || any(ismissing(value))
    error("SpectraLab:Report:InvalidArchiveFiles", ...
        "Archive input must be one or more file paths.");
end

archiveFiles = reshape(value, 1, []);

if numel(archiveFiles) < 1 || ...
        any(strlength(strtrim(archiveFiles)) == 0)
    error("SpectraLab:Report:InvalidArchiveFiles", ...
        "Archive input must contain non-empty file paths.");
end
end

function validateArchiveCount(archiveFiles, inputRoles, analysisId)
%VALIDATEARCHIVECOUNT Require one archive for each declared input role.

if analysisId == "ANL-009"
    if numel(archiveFiles) < 2
        error("SpectraLab:Report:ArchiveCountMismatch", ...
            "Spectral Mean requires at least two archive inputs.");
    end
    return
end
if numel(archiveFiles) ~= numel(inputRoles)
    error("SpectraLab:Report:ArchiveCountMismatch", ...
        "Analysis requires %d archive input(s) with roles: %s.", ...
        numel(inputRoles), strjoin(inputRoles, ", "));
end
end

function roles = resolveInputRoles(registeredRoles, analysisId, count)
if analysisId == "ANL-009"
    roles = "Source " + string(1:count);
    if count == 2
        roles = registeredRoles;
    end
else
    roles = registeredRoles;
end
end

function archives = loadArchives(archiveFiles)
%LOADARCHIVES Load and validate all requested archives.

archives = cell(1, numel(archiveFiles));

for k = 1:numel(archiveFiles)
    archives{k} = spectralab.archive.load( ...
        archiveFiles(k), Quiet=true, Validation="error");
end
end

function validateAnalysisResult(result, definition)
%VALIDATEANALYSISRESULT Enforce the registered result-field contract.

if ~isstruct(result) || ~isscalar(result)
    error("SpectraLab:Report:InvalidAnalysisResult", ...
        "Registered analysis '%s' must return a scalar structure.", ...
        definition.AnalysisId);
end

for fieldName = [definition.ResultFields.Field]
    if ~isfield(result, fieldName)
        error("SpectraLab:Report:InvalidAnalysisResult", ...
            "Registered analysis '%s' did not return result field '%s'.", ...
            definition.AnalysisId, fieldName);
    end
end
end

function pngFile = buildPngFilename( ...
        outputFolder, archiveFile, analysisId, outputBaseName)
%BUILDPNGFILENAME Build the deterministic public figure filename.

archiveName = resolveOutputBaseName(archiveFile, outputBaseName);

safeAnalysisId = regexprep( ...
    string(analysisId), "[^A-Za-z0-9_-]", "_");

pngFile = fullfile( ...
    outputFolder, ...
    string(archiveName) + "_" + safeAnalysisId + "_figure.png");
end

function pdfFile = buildPdfFilename( ...
        outputFolder, archiveFile, analysisId, outputBaseName)
%BUILDPDFFILENAME Build the deterministic public report filename.

archiveName = resolveOutputBaseName(archiveFile, outputBaseName);

safeAnalysisId = regexprep( ...
    string(analysisId), "[^A-Za-z0-9_-]", "_");

pdfFile = fullfile( ...
    outputFolder, ...
    string(archiveName) + "_" + safeAnalysisId + "_report.pdf");
end

function archiveName = resolveOutputBaseName(archiveFile, requestedName)
if strlength(strtrim(requestedName)) == 0
    [~, archiveName] = fileparts(archiveFile);
    archiveName = string(archiveName);
    return
end

archiveName = strtrim(requestedName);
if ~isempty(regexp(char(archiveName), '[\\/:]', 'once'))
    error("SpectraLab:Report:InvalidOutputBaseName", ...
        "OutputBaseName must contain no path separators.");
end
end
