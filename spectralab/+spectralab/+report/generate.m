function info = generate(archiveFile, specificationOrAnalysisId, outputFolder, options)
%GENERATE Generate a SpectraLab report from a saved archive.
%
%   info = spectralab.report.generate( ...
%       archiveFile, analysisId, outputFolder)
%
%   info = spectralab.report.generate( ...
%       archiveFile, specification, outputFolder)
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
    archiveFile {mustBeTextScalar}
    specificationOrAnalysisId
    outputFolder {mustBeTextScalar}
    options.ShowFigure (1,1) logical = false
    options.OpenPDF (1,1) logical = false
    options.GenerationTime (1,1) datetime = datetime("now")
end

archiveFile = string(archiveFile);
outputFolder = string(outputFolder);

specification = resolveSpecification(specificationOrAnalysisId);
validateSpecification(specification);

if specification.AnalysisDefinition.HasFigure && ...
        (~isfield(specification, "FigureRenderer") || ...
         ~isa(specification.FigureRenderer, "function_handle"))
    error("SpectraLab:Report:FigureSpecificationRequired", ...
        "A function-handle FigureRenderer is required when HasFigure=true.");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

archive = spectralab.archive.load( ...
    archiveFile, Quiet=true, Validation="error");

result = specification.AnalysisRunner(archive);

context = spectralab.report.internal.buildContext( ...
    archiveFile, ...
    archive, ...
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
        renderContext.Graphics.Axes, archive, result);

    pngFile = buildPngFilename( ...
        outputFolder, archiveFile, ...
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
    outputFolder, archiveFile, specification.AnalysisDefinition.AnalysisId);

pdfInfo = spectralab.report.internal.exportPDF( ...
    pdfFile, layoutPlan, renderContext);

info = struct( ...
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
        "AnalysisDefinition", entry.DefinitionFactory(), ...
        "AnalysisRunner", entry.AnalysisRunner, ...
        "FigureRenderer", entry.FigureRenderer);
    return
end

error("SpectraLab:Report:InvalidSpecification", ...
    ["Second argument must be an AnalysisId text scalar or a scalar " ...
     "report specification structure."]);
end

function validateSpecification(specification)
%VALIDATESPECIFICATION Validate the explicit RP-019 specification.

required = ["AnalysisDefinition", "AnalysisRunner"];

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
