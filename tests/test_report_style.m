function tests = test_report_style
%TEST_REPORT_STYLE Verify the canonical internal report style.

tests = functiontests(localfunctions);
end

function testCreatesCanonicalStyle(testCase)
style = spectralab.report.internal.createReportStyle();

verifyEqual(testCase, style.Format, "SLAB-REPORT-STYLE");
verifyEqual(testCase, style.Version, "1.0");
verifyEqual(testCase, style.Font.Name, "Helvetica");
verifyEqual(testCase, style.Box.TitleHeight, 22);
verifyEqual(testCase, style.ResultsTable.VerticalGap, 28);
verifyEqual(testCase, style.ResultsTable.RowHeight, 18);
verifyEqual(testCase, style.ResultsTable.SpaceAfter, 8);
end

function testResultsHeightUsesCanonicalStyle(testCase)
style = spectralab.report.internal.createReportStyle();
model = struct( ...
    "Rows", repmat(struct("Label", "", "DisplayText", ""), 3, 1));

actual = spectralab.report.internal.estimateResultsTableHeight(model);

expected = style.Box.TitleHeight + ...
    style.ResultsTable.VerticalGap + ...
    3 * style.ResultsTable.RowHeight + ...
    style.ResultsTable.SpaceAfter;

verifyEqual(testCase, actual, expected);
end
