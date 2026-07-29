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
verifyEqual(testCase, style.InformationBox.VerticalGap, 8);
verifyEqual(testCase, style.InformationBox.RowHeight, 16);
verifyEqual(testCase, style.InformationBox.SectionGap, 8);
verifyEqual(testCase, style.InformationBox.BoxPadding, 12);
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


function testInformationBoxHeightUsesCanonicalStyle(testCase)
style = spectralab.report.internal.createReportStyle();

row = struct("Label","","DisplayText","");
model = struct( ...
    "MetadataRows", repmat(row,4,1), ...
    "ResultRows", repmat(row,3,1));

actual = spectralab.report.internal.estimateInformationBoxHeight(model);

expected = style.Box.TitleHeight + ...
    2 * style.InformationBox.BoxPadding + ...
    4 * style.InformationBox.RowHeight + ...
    style.InformationBox.SectionGap + ...
    3 * style.InformationBox.RowHeight;

verifyEqual(testCase, actual, expected);
end
