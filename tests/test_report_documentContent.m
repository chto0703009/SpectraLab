function tests = test_report_documentContent
%TEST_REPORT_DOCUMENTCONTENT Verify ReportContext content resolution.

tests = functiontests(localfunctions);
end

function testResolvesTopLevelContent(testCase)
context = makeContext();
element = makeElement("Measurement", "table", "Measurement");

resolved = spectralab.report.internal.resolveDocumentElement( ...
    element, context);

verifyEqual(testCase, resolved.Content, context.Measurement);
verifyEqual(testCase, resolved.SourcePath, "Measurement");
end

function testResolvesNestedContent(testCase)
context = makeContext();
element = makeElement("Warnings", "list", "Report.Warnings");

resolved = spectralab.report.internal.resolveDocumentElement( ...
    element, context);

verifyEqual(testCase, resolved.Content, context.Report.Warnings);
end

function testResolvesCompleteDocumentInOrder(testCase)
context = makeContext();
document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", [ ...
        makeElement("Measurement", "table", "Measurement")
        makeElement("Results", "table", "Result")
        makeElement("Warnings", "list", "Report.Warnings")]);

resolved = spectralab.report.internal.resolveDocumentModel( ...
    document, context);

verifyEqual(testCase, [resolved.Elements.Id], ...
    ["Measurement", "Results", "Warnings"]);
verifyEqual(testCase, resolved.Elements(1).Content, context.Measurement);
verifyEqual(testCase, resolved.Elements(2).Content, context.Result);
verifyEqual(testCase, resolved.Elements(3).Content, context.Report.Warnings);
end

function testDoesNotModifyContextOrDocument(testCase)
context = makeContext();
document = struct( ...
    "Format", "SLAB-REPORT-DOCUMENT", ...
    "Version", "1.0", ...
    "Elements", makeElement("Results", "table", "Result"));

contextBefore = context;
documentBefore = document;

spectralab.report.internal.resolveDocumentModel(document, context);

verifyEqual(testCase, context, contextBefore);
verifyEqual(testCase, document, documentBefore);
end

function testRejectsMissingContextSource(testCase)
context = makeContext();
element = makeElement("Missing", "table", "Result.NotThere");

verifyError(testCase, @() ...
    spectralab.report.internal.resolveDocumentElement(element, context), ...
    "SpectraLab:Report:MissingContextSource");
end

function testRejectsUnsafeSourcePath(testCase)
context = makeContext();
element = makeElement("Unsafe", "table", "Result(1)");

verifyError(testCase, @() ...
    spectralab.report.internal.resolveDocumentElement(element, context), ...
    "SpectraLab:Report:InvalidSourcePath");
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
context.Measurement = struct( ...
    "Name", "LED panel", ...
    "Operator", "Christer Törnkvist");
context.Result = struct( ...
    "CCT", 5045.123456789, ...
    "Duv", 0.0048223456789, ...
    "Ra", 95.4321987654);
context.Report = struct( ...
    "Warnings", ["Archive name differs"; "Limited coverage"]);
end
