function tests = test_report_style
%TEST_REPORT_STYLE Verify the canonical internal report style.

tests = functiontests(localfunctions);
end

function testCreatesCanonicalStyle(testCase)
style = spectralab.report.internal.createReportStyle();

verifyEqual(testCase, style.Format, "SLAB-REPORT-STYLE");
verifyEqual(testCase, style.Version, "1.0");
verifyEqual(testCase, style.Appearance.BackgroundColor, "white");
verifyEqual(testCase, style.Appearance.BoxBorderColor, [0.25 0.25 0.25]);
verifyEqual(testCase, style.Appearance.BoxBorderLineWidth, 0.75);
verifyEqual(testCase, style.Appearance.PageFrameRuleColor, [0.55 0.55 0.55]);
verifyEqual(testCase, style.Appearance.PageFrameRuleLineWidth, 0.5);
verifyFalse(testCase, isfield(style.Box, "BorderColor"));
verifyFalse(testCase, isfield(style.Box, "BorderLineWidth"));
verifyFalse(testCase, isfield(style.PageFrame, "RuleColor"));
verifyFalse(testCase, isfield(style.PageFrame, "RuleLineWidth"));
verifyEqual(testCase, style.Font.Name, "Helvetica");
verifyEqual(testCase, style.Font.WeightBold, "bold");
verifyEqual(testCase, style.Font.WeightNormal, "normal");
verifyEqual(testCase, style.Font.AngleItalic, "italic");
verifyEqual(testCase, style.Box.TitleHeight, 22);
verifyEqual(testCase, style.ResultsTable.VerticalGap, 28);
verifyEqual(testCase, style.ResultsTable.RowHeight, 18);
verifyEqual(testCase, style.ResultsTable.SpaceAfter, 8);
verifyEqual(testCase, style.InformationBox.VerticalGap, 8);
verifyEqual(testCase, style.InformationBox.RowHeight, 16);
verifyEqual(testCase, style.InformationBox.SectionGap, 8);
verifyEqual(testCase, style.InformationBox.BoxPadding, 12);
verifyEqual(testCase, style.Text.HeadingFontSize, 16);
verifyEqual(testCase, style.Text.ParagraphFontSize, 10);
verifyEqual(testCase, style.Text.Margin, 0);
verifyFalse(testCase, isfield(style.Text, "FontName"));
verifyFalse(testCase, isfield(style.PageFrame, "FontName"));
verifyEqual(testCase, style.PageFrame.HeaderTitleFontSize, 12);
verifyEqual(testCase, style.PageFrame.HeaderInformationFontSize, 8);
verifyEqual(testCase, style.PageFrame.FooterFontSize, 7);
verifyEqual(testCase, style.PageFrame.TextMargin, 0);
verifyEqual(testCase, style.PageFrame.RuleOffset, 8);
verifyEqual(testCase, style.Figure.BottomPadding, 40);
verifyEqual(testCase, style.Figure.TopPadding, 24);
verifyEqual(testCase, style.Caption.FontSize, 9);
verifyEqual(testCase, style.Caption.Margin, 0);
verifyFalse(testCase, isfield(style.Caption, "FontAngle"));
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
    "MeasurementInformationRows", repmat(row,4,1), ...
    "ResultRows", repmat(row,3,1));

actual = spectralab.report.internal.estimateInformationBoxHeight(model);

expected = style.Box.TitleHeight + ...
    2 * style.InformationBox.BoxPadding + ...
    4 * style.InformationBox.RowHeight + ...
    style.InformationBox.SectionGap + ...
    3 * style.InformationBox.RowHeight;

verifyEqual(testCase, actual, expected);
end
