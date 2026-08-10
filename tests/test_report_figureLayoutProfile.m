function tests = test_report_figureLayoutProfile
%TEST_REPORT_FIGURELAYOUTPROFILE Protect the canonical report figure geometry.

tests = functiontests(localfunctions);
end

function testLegendHeightGrowsWithContent(testCase)
profile = spectralab.report.internal.figureLayoutProfile();
one = spectralab.report.internal.sideLegendPosition("One curve");
three = spectralab.report.internal.sideLegendPosition( ...
    ["Curve one", "Curve two", "Curve three"]);

verifyLessThan(testCase, one(4), three(4));
verifyLessThanOrEqual(testCase, three(4), profile.SideLegend(4));
verifyLessThan(testCase, one(3), profile.SideLegend(3));
verifyEqual(testCase, one(1) + one(3), ...
    profile.SideLegend(1) + profile.SideLegend(3), AbsTol=1e-12);
verifyEqual(testCase, one(2) + one(4), ...
    profile.SideLegend(2) + profile.SideLegend(4), AbsTol=1e-12);
end

function testProfileReservesLabelAndSideColumnSpace(testCase)
profile = spectralab.report.internal.figureLayoutProfile();

verifyEqual(testCase, profile.InteractiveFigurePosition, ...
    [100 100 1400 700]);
verifyEqual(testCase, profile.PNGFigureSizePoints, [1008 504]);
verifyEqual(testCase, profile.PNGResolution, 100);
verifyGreaterThanOrEqual(testCase, profile.AxesWithSidebar(1), 0.10);
verifyGreaterThanOrEqual(testCase, profile.AxesWithLegend(1), 0.10);
verifyLessThan(testCase, profile.AxesWithSidebar(1) + ...
    profile.AxesWithSidebar(3), profile.SidePanel(1));
verifyLessThan(testCase, profile.AxesWithLegend(1) + ...
    profile.AxesWithLegend(3), profile.SideLegend(1));
verifyEqual(testCase, profile.SidePanel(1), profile.SideLegend(1));
verifyEqual(testCase, profile.SidePanel(3), profile.SideLegend(3));
verifyGreaterThanOrEqual(testCase, profile.SidePanel(4), 0.55);
verifyGreaterThanOrEqual(testCase, profile.SidePanel(3), 0.28);
verifyLessThanOrEqual(testCase, profile.SidePanelFontSize, 8);
verifyLessThanOrEqual(testCase, profile.MaximumSideLegendCharacters, 12);
verifyGreaterThanOrEqual(testCase, profile.MaximumSideColumnCharacters, 20);
end
