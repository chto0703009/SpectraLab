function tests = test_report_layoutEngine
%TEST_REPORT_LAYOUTENGINE Verify RP-008 separation and placement.

tests = functiontests(localfunctions);
end

function testRenderersDoNotAdvanceLayout(testCase)
context = makeContext();
document = makeDocument([ ...
    makeElement("Title", "heading", "TitleText")
    makeElement("Body", "paragraph", "BodyText")]);
renderContext = makeRenderContext();

[renderContext, results] = spectralab.report.internal.renderDocumentModel( ...
    document, context, renderContext);

verifyEqual(testCase, [results.HeightUsed], [28, 20]);
verifyEqual(testCase, renderContext.State.Layout.CurrentPage, 1);
verifyEqual(testCase, renderContext.State.Layout.CursorY, 0);
end

function testLayoutEnginePlacesMeasuredElements(testCase)
results = [ ...
    makeResult("A", "heading", 28, false)
    makeResult("B", "paragraph", 20, false)
    makeResult("C", "spacer", 12.5, false)];

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, [plan.Page], [1, 1, 1]);
verifyEqual(testCase, [plan.Y], [0, 28, 48]);
verifyEqual(testCase, [plan.Height], [28, 20, 12.5]);
verifyTrue(testCase, all([plan.Measured]));
verifyEqual(testCase, renderContext.State.Layout.CursorY, 60.5);
verifyEqual(testCase, renderContext.State.CursorY, 60.5);
end

function testExplicitPageBreakStartsNewPage(testCase)
results = [ ...
    makeResult("A", "heading", 28, false)
    makeResult("Break", "pageBreak", NaN, true)
    makeResult("B", "paragraph", 20, false)];

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, [plan.Page], [1, 2, 2]);
verifyEqual(testCase, [plan.Y], [0, 0, 0]);
verifyFalse(testCase, plan(1).ExplicitPageBreak);
verifyTrue(testCase, plan(2).ExplicitPageBreak);
verifyEqual(testCase, renderContext.State.Layout.CurrentPage, 2);
verifyEqual(testCase, renderContext.State.Layout.CursorY, 20);
end

function testUnmeasuredElementDoesNotMoveCursor(testCase)
results = [ ...
    makeResult("A", "heading", 28, false)
    makeResult("Table", "table", NaN, false)
    makeResult("B", "paragraph", 20, false)];

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, [plan.Y], [0, 28, 28]);
verifyFalse(testCase, plan(2).Measured);
verifyTrue(testCase, isnan(plan(2).Height));
verifyEqual(testCase, renderContext.State.Layout.CursorY, 48);
end

function testAutomaticallyStartsNewPageWhenElementDoesNotFit(testCase)
layout = spectralab.report.internal.createLayoutState();
firstHeight = layout.ContentHeight - 10;
results = [ ...
    makeResult("A", "paragraph", firstHeight, false)
    makeResult("B", "heading", 28, false)];

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, [plan.Page], [1, 2]);
verifyEqual(testCase, [plan.Y], [0, 0]);
verifyFalse(testCase, plan(1).AutomaticPageBreak);
verifyTrue(testCase, plan(2).AutomaticPageBreak);
verifyEqual(testCase, renderContext.State.Layout.CurrentPage, 2);
verifyEqual(testCase, renderContext.State.Layout.CursorY, 28);
end

function testElementThatExactlyFitsRemainsOnPage(testCase)
layout = spectralab.report.internal.createLayoutState();
results = [ ...
    makeResult("A", "paragraph", 100, false)
    makeResult("B", "paragraph", layout.ContentHeight - 100, false)];

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, [plan.Page], [1, 1]);
verifyFalse(testCase, any([plan.AutomaticPageBreak]));
verifyEqual(testCase, renderContext.State.Layout.CursorY, ...
    layout.ContentHeight, "AbsTol", 1e-12);
end

function testElementTooTallIsRejected(testCase)
layout = spectralab.report.internal.createLayoutState();
result = makeResult("Tall", "paragraph", layout.ContentHeight + 0.001, false);

verifyError(testCase, @() ...
    spectralab.report.internal.layoutRenderResults( ...
        makeRenderContext(), result), ...
    "SpectraLab:Report:ElementTooTall");
end

function testAutomaticBreakAfterExplicitBreakUsesCurrentPage(testCase)
layout = spectralab.report.internal.createLayoutState();
results = [ ...
    makeResult("Break", "pageBreak", NaN, true)
    makeResult("A", "paragraph", layout.ContentHeight - 5, false)
    makeResult("B", "heading", 28, false)];

[renderContext, plan] = spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, [plan.Page], [2, 2, 3]);
verifyTrue(testCase, plan(1).ExplicitPageBreak);
verifyTrue(testCase, plan(3).AutomaticPageBreak);
verifyEqual(testCase, renderContext.State.Layout.CurrentPage, 3);
end

function testLayoutDoesNotModifyRenderResults(testCase)
results = [ ...
    makeResult("A", "heading", 28, false)
    makeResult("B", "paragraph", 20, false)];
before = results;

spectralab.report.internal.layoutRenderResults( ...
    makeRenderContext(), results);

verifyEqual(testCase, results, before);
end

function testRejectsIncompleteRenderResult(testCase)
bad = struct("ElementType", "heading");

verifyError(testCase, @() ...
    spectralab.report.internal.layoutRenderResults( ...
        makeRenderContext(), bad), ...
    "SpectraLab:Report:InvalidRenderResult");
end

function result = makeResult(id, type, height, pageBreak)
result = spectralab.report.internal.createRenderResult( ...
    id, type, height, pageBreak, strings(0,1));
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
context.BodyText = "Short paragraph.";
context.Report = struct("ReportId", "RPT-001", "Warnings", strings(0,1));
end

function renderContext = makeRenderContext()
renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", gobjects(0), "Axes", gobjects(0)), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct( ...
        "CurrentPage", 1, ...
        "CursorY", NaN, ...
        "Layout", spectralab.report.internal.createLayoutState()));
end
