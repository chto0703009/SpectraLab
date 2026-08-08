function tests = test_report_figureLayoutProfile
%TEST_REPORT_FIGURELAYOUTPROFILE Protect the canonical report figure geometry.

tests = functiontests(localfunctions);
end

function testProfileReservesLabelAndSideColumnSpace(testCase)
profile = spectralab.report.internal.figureLayoutProfile();

verifyGreaterThanOrEqual(testCase, profile.AxesWithSidebar(1), 0.10);
verifyGreaterThanOrEqual(testCase, profile.AxesWithLegend(1), 0.10);
verifyLessThan(testCase, profile.AxesWithSidebar(1) + ...
    profile.AxesWithSidebar(3), profile.SidePanel(1));
verifyLessThan(testCase, profile.AxesWithLegend(1) + ...
    profile.AxesWithLegend(3), profile.SideLegend(1));
verifyEqual(testCase, profile.SidePanel(1), profile.SideLegend(1));
verifyEqual(testCase, profile.SidePanel(3), profile.SideLegend(3));
verifyGreaterThanOrEqual(testCase, profile.MaximumSideColumnCharacters, 20);
end
