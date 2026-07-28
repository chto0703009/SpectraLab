function tests = test_report_figureElement
%TEST_REPORT_FIGUREELEMENT Verify RP-011 deterministic figure geometry.

tests = functiontests(localfunctions);
end

function testBuildsCanonicalFigureModel(testCase)
analysis = makeAnalysis(4/3, 1.0, 400);
layout = spectralab.report.internal.createLayoutState();

model = spectralab.report.internal.buildFigureModel(analysis, layout);

verifyEqual(testCase, model.Format, "SLAB-REPORT-FIGURE");
verifyEqual(testCase, model.Version, "1.0");
verifyEqual(testCase, model.Role, "primaryFigure");
verifyEqual(testCase, model.Units, "points");
verifyEqual(testCase, model.AspectRatio, 4/3);
end

function testUsesAvailableContentWidthAndPreservesAspectRatio(testCase)
analysis = makeAnalysis(4/3, 0.75, 1000);
layout = spectralab.report.internal.createLayoutState();

model = spectralab.report.internal.buildFigureModel(analysis, layout);

verifyEqual(testCase, model.Width, layout.ContentWidth * 0.75, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, model.Width / model.Height, 4/3, ...
    "AbsTol", 1e-12);
end

function testMaxHeightCapsFigureWithoutDistortion(testCase)
analysis = makeAnalysis(16/9, 1.0, 180);
layout = spectralab.report.internal.createLayoutState();

model = spectralab.report.internal.buildFigureModel(analysis, layout);

verifyEqual(testCase, model.Height, 180, "AbsTol", 1e-12);
verifyEqual(testCase, model.Width, 180 * 16/9, "AbsTol", 1e-12);
verifyLessThanOrEqual(testCase, model.Width, layout.ContentWidth);
end

function testFigureRendererReturnsFiniteHeight(testCase)
context = makeContext();
document = makeDocument(makeElement());

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyTrue(testCase, isfinite(result.HeightUsed));
verifyGreaterThan(testCase, result.HeightUsed, 0);
model = renderContext.State.RenderedElements(1).Content;
verifyEqual(testCase, result.HeightUsed, model.Height);
verifyEqual(testCase, model.Width / model.Height, 3/2, "AbsTol", 1e-12);
end

function testFigureCanBePlacedByLayoutEngine(testCase)
context = makeContext();
document = makeDocument(makeElement());

[~, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());
[layoutContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), result);

verifyEqual(testCase, plan.Page, 1);
verifyEqual(testCase, plan.Y, 0);
verifyEqual(testCase, plan.Height, result.HeightUsed);
verifyEqual(testCase, layoutContext.State.Layout.CursorY, result.HeightUsed);
end

function testRejectsMissingFigureDefinition(testCase)
analysis = struct("HasFigure", true);
layout = spectralab.report.internal.createLayoutState();

verifyError(testCase, @() ...
    spectralab.report.internal.buildFigureModel(analysis, layout), ...
    "SpectraLab:Report:InvalidFigureDefinition");
end

function testRejectsInvalidWidthFraction(testCase)
analysis = makeAnalysis(4/3, 1.2, 300);
layout = spectralab.report.internal.createLayoutState();

verifyError(testCase, @() ...
    spectralab.report.internal.buildFigureModel(analysis, layout), ...
    "SpectraLab:Report:InvalidFigureDefinition");
end

function testDoesNotCreateGraphicsOrModifyDefinition(testCase)
analysis = makeAnalysis(4/3, 1.0, 300);
analysisBefore = analysis;
layout = spectralab.report.internal.createLayoutState();

model = spectralab.report.internal.buildFigureModel(analysis, layout);

verifyEqual(testCase, analysis, analysisBefore);
verifyFalse(testCase, any(contains(string(fieldnames(model)), ...
    ["Handle", "Axes", "FigureHandle"]), "all"));
end

function analysis = makeAnalysis(aspectRatio, widthFraction, maxHeight)
analysis = struct( ...
    "Name", "Spectrum", ...
    "HasFigure", true, ...
    "FigureDefinition", struct( ...
        "AspectRatio", aspectRatio, ...
        "WidthFraction", widthFraction, ...
        "MaxHeight", maxHeight));
end

function context = makeContext()
context = struct();
context.Analysis = makeAnalysis(3/2, 0.8, 260);
context.Result = struct();
context.Report = struct("ReportId", "RPT-001", "Warnings", strings(0,1));
end

function document = makeDocument(element)
document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", element);
end

function element = makeElement()
element = struct( ...
    "Id", "Figure", ...
    "Type", "figure", ...
    "Role", "primaryFigure", ...
    "SourcePath", "Analysis", ...
    "Required", true);
end

function renderContext = makeRenderContext()
renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", gobjects(0), "Axes", gobjects(0)), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct("CurrentPage", 0, "CursorY", NaN));
end
