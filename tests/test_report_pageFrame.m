function tests = test_report_pageFrame
%TEST_REPORT_PAGEFRAME Verify the fixed PDF page-frame model.

tests = functiontests(localfunctions);

end


function testBuildsTrustedPageFrame(testCase)

context = makeContext();
model = spectralab.report.internal.buildPageFrame(context);

verifyEqual(testCase, model.Format, ...
    "SLAB-REPORT-PAGE-FRAME");
verifyEqual(testCase, model.Version, "1.0");
verifyEqual(testCase, model.HeaderLeft, "SpectraLab");
verifyEqual(testCase, model.HeaderRight, ...
    "Color Rendering Index");
verifyEqual(testCase, model.FooterLeft, ...
    "Report ID RPT-001");
verifyEqual(testCase, model.FooterCenter, ...
    "SpectraLab 0.8.0-test");

end


function testMissingReportIdUsesEmDash(testCase)

context = makeContext();
context.Report.ReportId = "";

model = spectralab.report.internal.buildPageFrame(context);

verifyEqual(testCase, model.FooterLeft, "Report ID —");

end


function testDoesNotModifyContext(testCase)

context = makeContext();
before = context;

spectralab.report.internal.buildPageFrame(context);

verifyEqual(testCase, context, before);

end


function testRejectsMissingAnalysis(testCase)

context = rmfield(makeContext(), "Analysis");

verifyError(testCase, ...
    @() spectralab.report.internal.buildPageFrame(context), ...
    "SpectraLab:Report:InvalidPageFrameContext");

end


function testRejectsMissingAnalysisName(testCase)

context = makeContext();
context.Analysis = struct();

verifyError(testCase, ...
    @() spectralab.report.internal.buildPageFrame(context), ...
    "SpectraLab:Report:InvalidPageFrameContext");

end


function context = makeContext()

context.Analysis = struct( ...
    "Name", "Color Rendering Index");

context.Report = struct( ...
    "ReportId", "RPT-001", ...
    "SpectraLabVersion", "0.8.0-test");

end
