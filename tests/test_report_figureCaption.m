function tests = test_report_figureCaption
%TEST_REPORT_FIGURECAPTION Verify RP-016 figure-caption modelling and layout.

tests = functiontests(localfunctions);
end

function teardown(~)
close all force
end

function testBuildsCanonicalCaptionModel(testCase)
model = spectralab.report.internal.buildFigureCaption( ...
    "Measured spectral power distribution.");

verifyEqual(testCase, model.Format, "SLAB-REPORT-FIGURE-CAPTION");
verifyEqual(testCase, model.Version, "1.0");
verifyEqual(testCase, model.Role, "primaryFigureCaption");
verifyEqual(testCase, model.FigureRole, "primaryFigure");
verifyEqual(testCase, model.Text, ...
    "Measured spectral power distribution.");
end

function testManifestPlacesCaptionImmediatelyAfterFigure(testCase)
context = makeContext("Measured spectrum.");
manifest = spectralab.report.internal.buildManifest(context);
ids = [manifest.Sections.Id];
figureIndex = find(ids == "Figure", 1);

verifyEqual(testCase, ids(figureIndex+1), "FigureCaption");
verifyEqual(testCase, manifest.Sections(figureIndex+1).SourcePath, ...
    "Analysis.FigureDefinition.Caption");
end

function testManifestOmitsEmptyCaption(testCase)
context = makeContext("");
manifest = spectralab.report.internal.buildManifest(context);

verifyFalse(testCase, any([manifest.Sections.Id] == "FigureCaption"));
end

function testCaptionRendererReturnsFiniteHeightAndModel(testCase)
context = makeContext("Measured spectral power distribution.");
element = makeCaptionElement();
document = makeDocument(element);
[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyTrue(testCase, isfinite(result.HeightUsed));
verifyGreaterThan(testCase, result.HeightUsed, 0);
record = renderContext.State.RenderedElements(1);
verifyEqual(testCase, record.Type, "caption");
verifyEqual(testCase, record.Content.Text, ...
    "Measured spectral power distribution.");
verifyEqual(testCase, record.Content.FigureRole, "primaryFigure");
end

function testFigureAndCaptionMoveTogether(testCase)
layout = spectralab.report.internal.createLayoutState();
start = layout.ContentHeight - 250;
rc = makeRenderContext();
rc.State.Layout = layout;
rc.State.Layout.CursorY = start;
rc.State.Layout.CurrentPage = 1;
results = [ ...
    spectralab.report.internal.createRenderResult( ...
        "Figure", "figure", 230, false, strings(0,1))
    spectralab.report.internal.createRenderResult( ...
        "FigureCaption", "caption", 30, false, strings(0,1))];

[~, plan] = spectralab.report.internal.layoutRenderResults(rc, results);

verifyEqual(testCase, [plan.Page], [2 2]);
verifyEqual(testCase, plan(1).Y, 0);
verifyEqual(testCase, plan(2).Y, 230);
verifyTrue(testCase, plan(1).AutomaticPageBreak);
verifyFalse(testCase, plan(2).AutomaticPageBreak);
end

function testCaptionCanFollowFigureOnCurrentPage(testCase)
rc = makeRenderContext();
results = [ ...
    spectralab.report.internal.createRenderResult( ...
        "Figure", "figure", 180, false, strings(0,1))
    spectralab.report.internal.createRenderResult( ...
        "FigureCaption", "caption", 24, false, strings(0,1))];

[~, plan] = spectralab.report.internal.layoutRenderResults(rc, results);

verifyEqual(testCase, [plan.Page], [1 1]);
verifyEqual(testCase, [plan.Y], [0 180]);
end

function testPDFBackendAcceptsCaption(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() removeFolder(folder)); %#ok<NASGU>
pdfFile = fullfile(folder, "caption.pdf");
model = spectralab.report.internal.buildFigureCaption("Measured spectrum.");
records = [ ...
    struct("Id", "Figure", "Type", "figure", ...
        "Role", "primaryFigure", "Content", figureModel())
    struct("Id", "FigureCaption", "Type", "caption", ...
        "Role", "primaryFigureCaption", "Content", model)];
plan = [ ...
    placement("Figure", "figure", 1, 0, 180)
    placement("FigureCaption", "caption", 1, 180, 24)];
rc = makeRenderContext();
sourceFigure = figure("Visible", "off");
sourceAxes = axes(sourceFigure);
plot(sourceAxes, [380 555 730], [0 1 0.2]);
rc.Graphics = struct("Figure", sourceFigure, "Axes", sourceAxes);
rc.State.RenderedElements = records;

info = spectralab.report.internal.exportPDF(pdfFile, plan, rc);

verifyTrue(testCase, isfile(pdfFile));
verifyEqual(testCase, info.PageCount, 1);
end

function testRejectsEmptyCaption(testCase)
verifyError(testCase, @() ...
    spectralab.report.internal.buildFigureCaption("   "), ...
    "SpectraLab:Report:InvalidFigureCaption");
end

function item = placement(id, type, page, y, height)
item = struct( ...
    "ElementId", string(id), ...
    "ElementType", string(type), ...
    "Page", double(page), ...
    "Y", double(y), ...
    "Height", double(height), ...
    "Measured", true, ...
    "ExplicitPageBreak", false, ...
    "AutomaticPageBreak", false);
end

function model = figureModel()
model = struct("Format", "SLAB-REPORT-FIGURE", "Version", "1.0", ...
    "Role", "primaryFigure", "Units", "points", ...
    "AspectRatio", 3/2, "WidthFraction", 0.8, ...
    "MaxHeight", 260, "Width", 360, "Height", 240);
end

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end

function context = makeContext(caption)
context = struct();
context.Archive = struct("UUID", "uuid", "ContentHash", "hash");
context.Measurement = struct("Name", "Reference");
context.Analysis = struct( ...
    "AnalysisId", "ANL-CRI", ...
    "Name", "Color Rendering Index", ...
    "HasFigure", true, ...
    "FigureDefinition", struct( ...
        "AspectRatio", 3/2, ...
        "WidthFraction", 0.8, ...
        "MaxHeight", 260, ...
        "Caption", string(caption)));
context.Result = struct("Ra", 95.4);
context.Report = struct("ReportId", "RPT-001", ...
    "Warnings", strings(0,1));
end

function element = makeCaptionElement()
element = struct( ...
    "Id", "FigureCaption", ...
    "Type", "caption", ...
    "Role", "primaryFigureCaption", ...
    "SourcePath", "Analysis.FigureDefinition.Caption", ...
    "Required", true);
end

function document = makeDocument(element)
document = struct("Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", "Elements", element);
end

function renderContext = makeRenderContext()
renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", gobjects(0), "Axes", gobjects(0)), ...
    "PageFrame", struct( ...
        "Format", "SLAB-REPORT-PAGE-FRAME", ...
        "Version", "1.0", ...
        "HeaderLeft", "SpectraLab", ...
        "HeaderRight", "Color Rendering Index", ...
        "FooterLeft", "Report ID RPT-001", ...
        "FooterCenter", "SpectraLab 0.8.0-test"), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct("CurrentPage", 0, "CursorY", NaN));
end
