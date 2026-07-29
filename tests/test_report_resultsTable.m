function tests = test_report_resultsTable
%TEST_REPORT_RESULTSTABLE Verify RP-010 analysis-results tables.

tests = functiontests(localfunctions);
end

function testBuildsCanonicalTwoColumnTable(testCase)
context = makeContext();
tableModel = spectralab.report.internal.buildResultsTable( ...
    context.Result, context.Analysis);

verifyEqual(testCase, tableModel.Format, "SLAB-REPORT-TABLE");
verifyEqual(testCase, tableModel.Version, "1.0");
verifyEqual(testCase, tableModel.Title, "Results");
verifyEqual(testCase, tableModel.Columns, ["Label", "Value"]);
verifyEqual(testCase, [tableModel.Rows.Field], ["CCT", "Duv", "Ra"]);
verifyEqual(testCase, [tableModel.Rows.Label], ["CCT", "Duv", "Ra"]);
end

function testFormatsValuesAndUnitsWithoutChangingPrecision(testCase)
context = makeContext();
tableModel = spectralab.report.internal.buildResultsTable( ...
    context.Result, context.Analysis);

verifyEqual(testCase, tableModel.Rows(1).DisplayText, "5045 K");
verifyEqual(testCase, tableModel.Rows(2).DisplayText, "+0.00482");
verifyEqual(testCase, tableModel.Rows(3).DisplayText, "95.4");
verifyEqual(testCase, tableModel.Rows(1).Value, 5045.123456789);
verifyEqual(testCase, tableModel.Rows(2).Value, 0.004821987654);
verifyEqual(testCase, tableModel.Rows(3).Value, 95.4321987654);
end

function testResultFieldOrderFollowsAnalysisDefinition(testCase)
context = makeContext();
context.Analysis.ResultFields = context.Analysis.ResultFields([3 1]);

tableModel = spectralab.report.internal.buildResultsTable( ...
    context.Result, context.Analysis);

verifyEqual(testCase, [tableModel.Rows.Field], ["Ra", "CCT"]);
end

function testResultsRendererReturnsFiniteHeight(testCase)
context = makeContext();
document = makeDocument(makeElement("Results", "table", "analysisResults", "Result"));

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

tableModel = renderContext.State.RenderedElements(1).Content;
expectedHeight = ...
    spectralab.report.internal.estimateResultsTableHeight(tableModel);

verifyEqual(testCase, result.HeightUsed, expectedHeight);
verifyTrue(testCase, isfinite(result.HeightUsed));
verifyEqual(testCase, tableModel.Rows(2).DisplayText, "+0.00482");
end

function testOtherCanonicalTableRolesReturnFiniteHeight(testCase)
context = makeContext();
document = makeDocument(makeElement( ...
    "Measurement", "table", "measurementInformation", "Measurement"));

[renderContext, result] = spectralab.report.internal.renderDocumentModel( ...
    document, context, makeRenderContext());

tableModel = renderContext.State.RenderedElements(1).Content;
expectedHeight = ...
    spectralab.report.internal.estimateResultsTableHeight(tableModel);

verifyEqual(testCase, result.HeightUsed, expectedHeight);
verifyTrue(testCase, isfinite(result.HeightUsed));
end

function testRejectsMissingDeclaredResult(testCase)
context = makeContext();
context.Result = rmfield(context.Result, "Duv");

verifyError(testCase, @() ...
    spectralab.report.internal.buildResultsTable( ...
        context.Result, context.Analysis), ...
    "SpectraLab:Report:MissingResultField");
end

function testRejectsDuplicateResultDefinitions(testCase)
context = makeContext();
context.Analysis.ResultFields(3) = context.Analysis.ResultFields(1);

verifyError(testCase, @() ...
    spectralab.report.internal.buildResultsTable( ...
        context.Result, context.Analysis), ...
    "SpectraLab:Report:DuplicateResultField");
end

function testDoesNotModifyResultOrDefinition(testCase)
context = makeContext();
resultBefore = context.Result;
definitionBefore = context.Analysis;

spectralab.report.internal.buildResultsTable( ...
    context.Result, context.Analysis);

verifyEqual(testCase, context.Result, resultBefore);
verifyEqual(testCase, context.Analysis, definitionBefore);
end

function context = makeContext()
context = struct();
context.Report = struct("ReportId", "RPT-001", "Warnings", strings(0,1));
context.Measurement = struct("Name", "Lamp");
context.Result = struct( ...
    "CCT", 5045.123456789, ...
    "Duv", 0.004821987654, ...
    "Ra", 95.4321987654);
context.Analysis = struct( ...
    "Name", "Color Rendering Index", ...
    "ResultFields", [ ...
        makeResultField("CCT", "CCT", "K", "%.0f")
        makeResultField("Duv", "Duv", "", "%+.5f")
        makeResultField("Ra", "Ra", "", "%.1f")]);
end

function field = makeResultField(name, label, unit, format)
field = struct( ...
    "Field", string(name), ...
    "Label", string(label), ...
    "Unit", string(unit), ...
    "Format", string(format));
end

function document = makeDocument(elements)
document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", elements);
end

function element = makeElement(id, type, role, sourcePath)
element = struct( ...
    "Id", string(id), ...
    "Type", string(type), ...
    "Role", string(role), ...
    "SourcePath", string(sourcePath), ...
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
