function tests = test_report_layoutMetrics
%TEST_REPORT_LAYOUTMETRICS Verify deterministic RP-007 layout measures.

tests = functiontests(localfunctions);
end

function testCreatesA4PortraitLayout(testCase)
layout = spectralab.report.internal.createLayoutState();

verifyEqual(testCase, layout.Units, "points");
verifyGreaterThan(testCase, layout.PageHeight, layout.PageWidth);
verifyEqual(testCase, layout.CurrentPage, 1);
verifyEqual(testCase, layout.CursorY, 0);
verifyGreaterThan(testCase, layout.ContentWidth, 0);
verifyGreaterThan(testCase, layout.ContentHeight, 0);
end

function testHeadingReturnsFiniteHeight(testCase)
context = makeContext();
document = makeDocument(makeElement("Title", "heading", "TitleText"));

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyEqual(testCase, result.HeightUsed, 28);
verifyEqual(testCase, renderContext.State.Layout.CursorY, 0);
verifyEqual(testCase, renderContext.State.CursorY, NaN);
end

function testLongParagraphUsesMoreHeightThanShortParagraph(testCase)
context = makeContext();
shortDocument = makeDocument(makeElement("Short", "paragraph", "ShortText"));
longDocument = makeDocument(makeElement("Long", "paragraph", "LongText"));

[~, shortResult] = spectralab.report.internal.renderDocumentModel( ...
    shortDocument, context, makeRenderContext());
[~, longResult] = spectralab.report.internal.renderDocumentModel( ...
    longDocument, context, makeRenderContext());

verifyGreaterThan(testCase, longResult.HeightUsed, shortResult.HeightUsed);
verifyEqual(testCase, shortResult.HeightUsed, 20);
end

function testSpacerUsesExactPointHeight(testCase)
context = makeContext();
document = makeDocument(makeElement("Gap", "spacer", "SpacerHeight"));

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyEqual(testCase, result.HeightUsed, 12.5);
verifyFalse(testCase, isfield(renderContext.State, "Layout"));
end

function testCursorAccumulatesMeasuredElements(testCase)
context = makeContext();
document = makeDocument([ ...
    makeElement("Title", "heading", "TitleText")
    makeElement("Body", "paragraph", "ShortText")
    makeElement("Gap", "spacer", "SpacerHeight")]);

[renderContext, results] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyEqual(testCase, [results.HeightUsed], [28, 20, 12.5]);
verifyEqual(testCase, renderContext.State.Layout.CursorY, 0);

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    renderContext, results);
verifyEqual(testCase, [plan.Y], [0, 28, 48]);
verifyEqual(testCase, renderContext.State.Layout.CursorY, 60.5);
end

function testUnmeasuredElementStillReturnsNaN(testCase)
context = makeContext();
document = makeDocument(makeElement("Results", "table", "Result"));

[~, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyTrue(testCase, isnan(result.HeightUsed));
end

function testStringVectorIsJoinedAsParagraph(testCase)
context = makeContext();
context.TextParts = ["First sentence." "Second sentence."];
document = makeDocument(makeElement("Body", "paragraph", "TextParts"));

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyTrue(testCase, isfinite(result.HeightUsed));
verifyEqual(testCase, renderContext.State.RenderedElements(1).Content, ...
    "First sentence. Second sentence.");
end

function testCellTextIsJoinedAsParagraph(testCase)
context = makeContext();
context.TextParts = {"First sentence.", "Second sentence."};
document = makeDocument(makeElement("Body", "paragraph", "TextParts"));

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyTrue(testCase, isfinite(result.HeightUsed));
verifyEqual(testCase, renderContext.State.RenderedElements(1).Content, ...
    "First sentence. Second sentence.");
end

function testRejectsInvalidTextContent(testCase)
context = makeContext();
context.InvalidText = struct("Value", 5);
document = makeDocument(makeElement("Body", "paragraph", "InvalidText"));

verifyError(testCase, @() ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, makeRenderContext()), ...
    "SpectraLab:Report:InvalidTextContent");
end

function testRejectsInvalidSpacerContent(testCase)
context = makeContext();
context.BadSpacer = -1;
document = makeDocument(makeElement("Gap", "spacer", "BadSpacer"));

verifyError(testCase, @() ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, makeRenderContext()), ...
    "SpectraLab:Report:InvalidSpacerContent");
end

function document = makeDocument(elements)
document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", elements);
end

function element = makeElement(id, type, sourcePath)
element = struct( ...
    "Id", string(id), ...
    "Type", string(type), ...
    "Role", "testRole", ...
    "SourcePath", string(sourcePath), ...
    "Required", true);
end

function context = makeContext()
context = struct();
context.TitleText = "Color Rendering Index";
context.ShortText = "Short paragraph.";
context.LongText = repmat("This paragraph is intentionally long so deterministic wrapping uses several lines. ", 1, 8);
context.SpacerHeight = 12.5;
context.Result = struct("CCT", 5045.123456789, "Ra", 95.4321987654);
context.Report = struct("ReportId", "RPT-001", "Warnings", strings(0,1));
end

function renderContext = makeRenderContext()
renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", gobjects(0), "Axes", gobjects(0)), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct("CurrentPage", 0, "CursorY", NaN));
end
