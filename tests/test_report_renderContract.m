function tests = test_report_renderContract
%TEST_REPORT_RENDERCONTRACT Verify the RP-006 element renderer contract.

tests = functiontests(localfunctions);
end

function testCanonicalRegistryHasUniqueElementTypes(testCase)
registry = spectralab.report.internal.createElementRendererRegistry();

verifyEqual(testCase, [registry.ElementType], [ ...
    "heading", "paragraph", "table", "figure", ...
    "caption", "list", "spacer", "pageBreak"]);
verifyEqual(testCase, numel(unique([registry.ElementType])), ...
    numel(registry));
verifyTrue(testCase, all(arrayfun(@(x) ...
    isa(x.Renderer, "function_handle"), registry)));
end

function testRendersResolvedContentInDocumentOrder(testCase)
context = makeContext();
document = makeDocument([ ...
    makeElement("Title", "heading", "Analysis")
    makeElement("Results", "table", "Result", "analysisResults")]);
renderContext = makeRenderContext();

[renderContext, results] = ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, renderContext);

verifyEqual(testCase, [results.ElementId], ["Title", "Results"]);
verifyEqual(testCase, [renderContext.State.RenderedElements.Id], ...
    ["Title", "Results"]);
verifyEqual(testCase, ...
    renderContext.State.RenderedElements(1).Content, context.Analysis.Name);
tableModel = renderContext.State.RenderedElements(2).Content;
verifyEqual(testCase, tableModel.Format, "SLAB-REPORT-TABLE");
verifyEqual(testCase, [tableModel.Rows.Field], ["CCT", "Ra"]);
verifyEqual(testCase, [tableModel.Rows.DisplayText], ["5045 K", "95.4"]);
end

function testReturnsCanonicalRenderResult(testCase)
context = makeContext();
document = makeDocument(makeElement("Title", "heading", "Analysis"));

[~, results] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyEqual(testCase, fieldnames(results), { ...
    'ElementId'; 'ElementType'; 'HeightUsed'; ...
    'PageBreakRequested'; 'Warnings'});
verifyEqual(testCase, results.ElementId, "Title");
verifyEqual(testCase, results.ElementType, "heading");
verifyTrue(testCase, isfinite(results.HeightUsed));
verifyGreaterThan(testCase, results.HeightUsed, 0);
verifyFalse(testCase, results.PageBreakRequested);
verifyEqual(testCase, results.Warnings, strings(0,1));
end

function testPageBreakRequestsPageBreak(testCase)
context = makeContext();
document = makeDocument( ...
    makeElement("Break", "pageBreak", "Report"));

[~, results] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyTrue(testCase, results.PageBreakRequested);
end

function testUsesInjectedRendererRegistry(testCase)
context = makeContext();
document = makeDocument(makeElement("Title", "heading", "Analysis"));
registry = struct( ...
    "ElementType", "heading", ...
    "Renderer", @injectedRenderer);

[renderContext, results] = ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, makeRenderContext(), registry);

verifyTrue(testCase, renderContext.State.InjectedRendererUsed);
verifyEqual(testCase, results.HeightUsed, 2.5);
end

function testRejectsUnknownElementRenderer(testCase)
context = makeContext();
document = makeDocument(makeElement("Title", "heading", "Analysis"));
registry = struct( ...
    "ElementType", "table", ...
    "Renderer", @injectedRenderer);

verifyError(testCase, @() ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, makeRenderContext(), registry), ...
    "SpectraLab:Report:UnknownElementRenderer");
end

function testRejectsInvalidRenderResult(testCase)
context = makeContext();
document = makeDocument(makeElement("Title", "heading", "Analysis"));
registry = struct( ...
    "ElementType", "heading", ...
    "Renderer", @invalidRenderer);

verifyError(testCase, @() ...
    spectralab.report.internal.renderDocumentModel( ...
        document, context, makeRenderContext(), registry), ...
    "SpectraLab:Report:InvalidRenderResult");
end

function testDoesNotModifyContextOrDocument(testCase)
context = makeContext();
document = makeDocument(makeElement("Results", "table", "Result"));
contextBefore = context;
documentBefore = document;

spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

verifyEqual(testCase, context, contextBefore);
verifyEqual(testCase, document, documentBefore);
end

function [renderContext, result] = injectedRenderer(element, ~, renderContext)
renderContext.State.InjectedRendererUsed = true;
result = spectralab.report.internal.createRenderResult( ...
    element.Id, element.Type, 2.5, false, strings(0,1));
end

function [renderContext, result] = invalidRenderer(~, ~, renderContext)
result = struct("HeightUsed", 1); %#ok<NASGU>
end

function document = makeDocument(elements)
document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", elements);
end

function element = makeElement(id, type, sourcePath, role)
if nargin < 4
    role = "testRole";
end
element = struct( ...
    "Id", string(id), ...
    "Type", string(type), ...
    "Role", string(role), ...
    "SourcePath", string(sourcePath), ...
    "Required", true);
end

function context = makeContext()
context = struct();
context.Analysis = struct( ...
    "Name", "Color Rendering Index", ...
    "ResultFields", [ ...
        makeResultField("CCT", "CCT", "K", "%.0f")
        makeResultField("Ra", "Ra", "", "%.1f")]);
context.Result = struct("CCT", 5045.123456789, "Ra", 95.4321987654);
context.Report = struct("ReportId", "RPT-001", "Warnings", strings(0,1));
end

function field = makeResultField(name, label, unit, format)
field = struct( ...
    "Field", string(name), ...
    "Label", string(label), ...
    "Unit", string(unit), ...
    "Format", string(format));
end

function renderContext = makeRenderContext()
renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", gobjects(0), "Axes", gobjects(0)), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct("CurrentPage", 0, "CursorY", NaN));
end
