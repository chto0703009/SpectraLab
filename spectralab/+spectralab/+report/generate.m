function info = generate(archiveFiles, specificationOrAnalysisId, outputFolder, options)
%GENERATE Generate a SpectraLab report from one or two saved archives.
%
%   info = spectralab.report.generate( ...
%       archiveFile, analysisId, outputFolder)
%
%   info = spectralab.report.generate( ...
%       [referenceArchiveFile, sampleArchiveFile], ...
%       analysisId, outputFolder)
%
%   info = spectralab.report.generate( ...
%       archiveFiles, specification, outputFolder)
%
% RP-019 provides the public orchestration pipeline.
% RP-020 resolves canonical report specifications from AnalysisId values.
%
% A scalar specification structure remains supported as an internal and
% transitional contract.
%
% This initial RP-019 implementation supports analyses without figures.
% Figure-producing report orchestration is added in the next isolated step.

arguments
    archiveFiles
    specificationOrAnalysisId
    outputFolder {mustBeTextScalar}
    options.ShowFigure (1,1) logical = false
    options.OpenPDF (1,1) logical = false
    options.GenerationTime (1,1) datetime = datetime("now")
end

archiveFiles = normalizeArchiveFiles(archiveFiles);
outputFolder = string(outputFolder);

specification = resolveSpecification(specificationOrAnalysisId);
specification = normalizeInputRoles(specification);
validateSpecification(specification);
validateArchiveCount(archiveFiles, specification.InputRoles);

if specification.AnalysisDefinition.HasFigure && ...
        (~isfield(specification, "FigureRenderer") || ...
         ~isa(specification.FigureRenderer, "function_handle"))
    error("SpectraLab:Report:FigureSpecificationRequired", ...
        "A function-handle FigureRenderer is required when HasFigure=true.");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

archives = loadArchives(archiveFiles);
result = specification.AnalysisRunner(archives{:});

primaryArchiveFile = archiveFiles(end);
primaryArchive = archives{end};

context = spectralab.report.internal.buildContext( ...
    primaryArchiveFile, ...
    primaryArchive, ...
    specification.AnalysisDefinition, ...
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

if specification.AnalysisDefinition.HasFigure
    specification.FigureRenderer( ...
        renderContext.Graphics.Axes, archives{:}, result);

    pngFile = buildPngFilename( ...
        outputFolder, primaryArchiveFile, ...
        specification.AnalysisDefinition.AnalysisId);
end

[renderContext, renderResults] = ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, renderContext);

[renderContext, layoutPlan] = ...
    spectralab.report.internal.layoutRenderResults( ...
        renderContext, renderResults);

if specification.AnalysisDefinition.HasFigure
    pngInfo = spectralab.report.internal.exportPNG( ...
        pngFile, renderContext);
end

pdfFile = buildPdfFilename( ...
    outputFolder, primaryArchiveFile, ...
    specification.AnalysisDefinition.AnalysisId);

pdfInfo = spectralab.report.internal.exportPDF( ...
    pdfFile, layoutPlan, renderContext);

info = struct( ...
    "ArchiveFiles", archiveFiles, ...
    "InputRoles", specification.InputRoles, ...
    "PDFFile", pdfFile, ...
    "PNGFile", pngFile, ...
    "PDF", pdfInfo, ...
    "PNG", pngInfo, ...
    "Context", context, ...
    "Manifest", manifest, ...
    "Document", document, ...
    "LayoutPlan", layoutPlan);
end

function specification = resolveSpecification(value)
%RESOLVESPECIFICATION Resolve an explicit specification or AnalysisId.

if isstruct(value) && isscalar(value)
    specification = value;
    return
end

if ischar(value) || (isstring(value) && isscalar(value) && ~ismissing(value))
    entry = spectralab.report.internal.resolveAnalysisSpecification(value);

    specification = struct( ...
        "InputRoles", entry.InputRoles, ...
        "AnalysisDefinition", entry.DefinitionFactory(), ...
        "AnalysisRunner", entry.AnalysisRunner, ...
        "FigureRenderer", entry.FigureRenderer);
    return
end

error("SpectraLab:Report:InvalidSpecification", ...
    ["Second argument must be an AnalysisId text scalar or a scalar " ...
     "report specification structure."]);
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

function specification = normalizeInputRoles(specification)
%NORMALIZEINPUTROLES Preserve the transitional one-archive contract.

if ~isfield(specification, "InputRoles")
    specification.InputRoles = "Measurement";
end

roles = string(specification.InputRoles);

if isempty(roles) || ~isvector(roles) || any(ismissing(roles))
    error("SpectraLab:Report:InvalidSpecification", ...
        "InputRoles must be a non-empty string vector.");
end

specification.InputRoles = reshape(roles, 1, []);
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

function validateSpecification(specification)
%VALIDATESPECIFICATION Validate the explicit RP-019 specification.

required = ["InputRoles", "AnalysisDefinition", "AnalysisRunner"];

for fieldName = required
    if ~isfield(specification, fieldName)
        error("SpectraLab:Report:InvalidSpecification", ...
            "Report specification is missing required field '%s'.", ...
            fieldName);
    end
end

if ~isstruct(specification.AnalysisDefinition) || ...
        ~isscalar(specification.AnalysisDefinition)
    error("SpectraLab:Report:InvalidSpecification", ...
        "AnalysisDefinition must be a scalar structure.");
end

if ~isa(specification.AnalysisRunner, "function_handle")
    error("SpectraLab:Report:InvalidSpecification", ...
        "AnalysisRunner must be a function handle.");
end

requiredDefinition = [ ...
    "AnalysisId"
    "Name"
    "Method"
    "Standard"
    "DefinitionVersion"
    "HasFigure"
    "ResultFields"];

for fieldName = requiredDefinition.'
    if ~isfield(specification.AnalysisDefinition, fieldName)
        error("SpectraLab:Report:InvalidSpecification", ...
            "AnalysisDefinition is missing required field '%s'.", ...
            fieldName);
    end
end

if ~isscalar(specification.AnalysisDefinition.HasFigure) || ...
        ~islogical(specification.AnalysisDefinition.HasFigure)
    error("SpectraLab:Report:InvalidSpecification", ...
        "AnalysisDefinition.HasFigure must be a logical scalar.");
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
