function tests = test_report_sideLegendFontSize
tests = functiontests(localfunctions);
end

function testKeepsNormalSizeForShortLegend(testCase)
actual = spectralab.report.internal.sideLegendFontSize(["A", "B"]);
verifyEqual(testCase, actual, 8);
end

function testReducesSizeForLongMeanLegend(testCase)
labels = "Source " + (1:10) + ...
    ": emission_series_20260817_205516_" + compose("%02d.mat", 1:10);
actual = spectralab.report.internal.sideLegendFontSize(labels);
verifyLessThanOrEqual(testCase, actual, 6);
end
