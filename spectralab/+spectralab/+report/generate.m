function info = generate(archiveFiles, analysisId, outputFolder, options)
%GENERATE Generate a SpectraLab report from one or two saved archives.
%
%   info = spectralab.report.generate( ...
%       archiveFile, analysisId, outputFolder)
%
%   info = spectralab.report.generate( ...
%       [referenceArchiveFile, sampleArchiveFile], ...
%       analysisId, outputFolder)
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
end

archiveFiles = normalizeArchiveFiles(archiveFiles);
analysisId = string(analysisId);
outputFolder = string(outputFolder);

entry = spectralab.report.internal.resolveAnalysisSpecification(analysisId);
definition = entry.AnalysisDefinition;
validateArchiveCount(archiveFiles, entry.InputRoles);

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

archives = loadArchives(archiveFiles);
result = entry.AnalysisRunner(archives{:});
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

manifest = spectralab.report.internal.buildManifest(context);
document = spectralab.report.internal.buildDocumentModel(manifest);
renderContext = spectralab.report.internal.createRenderContext( ...
    context, manifest, ShowFigure=options.ShowFigure);

cleanup = onCleanup(@() ...
    spectralab.report.internal.releaseRenderContext(renderContext)); %#ok<NASGU>

pngInfo = struct();
pngFile = "";

if definition.HasFigure
    entry.FigureRenderer( ...
        renderContext.Graphics.Axes, archives{:}, result);

    pngFile = buildPngFilename( ...
        outputFolder, primaryArchiveFile, ...
        definition.AnalysisId);
end

[renderContext, renderResults] = ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, renderContext);

[renderContext, layoutPlan] = ...
    spectralab.report.internal.layoutRenderResults( ...
        renderContext, renderResults);

if definition.HasFigure
    pngInfo = spectralab.report.internal.exportPNG( ...
        pngFile, renderContext);
end

pdfFile = buildPdfFilename( ...
    outputFolder, primaryArchiveFile, ...
    definition.AnalysisId);

pdfInfo = spectralab.report.internal.exportPDF( ...
    pdfFile, layoutPlan, renderContext);

info = struct( ...
    "ArchiveFiles", archiveFiles, ...
    "AnalysisId", definition.AnalysisId, ...
    "InputRoles", entry.InputRoles, ...
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
%NORMALIZEARCHIVEFILES Validate and normalize one or two archive paths.

if ischar(value)
    value = string(value);
end

if ~isstring(value) || isempty(value) || ...
        ~isvector(value) || any(ismissing(value))
    error("SpectraLab:Report:InvalidArchiveFiles", ...
        "Archive input must be one or two file paths.");
end

archiveFiles = reshape(value, 1, []);

if numel(archiveFiles) < 1 || numel(archiveFiles) > 2 || ...
        any(strlength(strtrim(archiveFiles)) == 0)
    error("SpectraLab:Report:InvalidArchiveFiles", ...
        "Archive input must contain one or two non-empty file paths.");
end
end

function validateArchiveCount(archiveFiles, inputRoles)
%VALIDATEARCHIVECOUNT Require one archive for each declared input role.

if numel(archiveFiles) ~= numel(inputRoles)
    error("SpectraLab:Report:ArchiveCountMismatch", ...
        "Analysis requires %d archive input(s) with roles: %s.", ...
        numel(inputRoles), strjoin(inputRoles, ", "));
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

function pngFile = buildPngFilename(outputFolder, archiveFile, analysisId)
%BUILDPNGFILENAME Build the deterministic public figure filename.

[~, archiveName] = fileparts(archiveFile);

safeAnalysisId = regexprep( ...
    string(analysisId), "[^A-Za-z0-9_-]", "_");

pngFile = fullfile( ...
    outputFolder, ...
    string(archiveName) + "_" + safeAnalysisId + "_figure.png");
end

function pdfFile = buildPdfFilename(outputFolder, archiveFile, analysisId)
%BUILDPDFFILENAME Build the deterministic public report filename.

[~, archiveName] = fileparts(archiveFile);

safeAnalysisId = regexprep( ...
    string(analysisId), "[^A-Za-z0-9_-]", "_");

pdfFile = fullfile( ...
    outputFolder, ...
    string(archiveName) + "_" + safeAnalysisId + "_report.pdf");
end
