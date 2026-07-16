function tests = test_plot_spectrum_summaryLocation
%TEST_PLOT_SPECTRUM_SUMMARYLOCATION Tests summary placement.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)

    inst = spectralab.drivers.MockInstrument();
    sess = spectralab.core.Session(inst);
    sess = sess.open();
    sess = sess.calibrate();

    testCase.TestData.Spec = sess.measure("Summary location test");
end


function setup(~)

    close all force
end


function teardown(~)

    close all force
end


function testEastLocation(testCase)

    h = spectralab.plot.spectrum( ...
        testCase.TestData.Spec, ...
        SummaryLocation="east");

    txt = findSummary(h.Parent);

    verifyEqual(testCase, string(txt.Units), "normalized");
    verifyEqual(testCase, txt.Position(1:2), [0.98 0.50], "AbsTol", 1e-12);
    verifyEqual(testCase, string(txt.HorizontalAlignment), "right");
    verifyEqual(testCase, string(txt.VerticalAlignment), "middle");
end


function testNorthwestLocation(testCase)

    h = spectralab.plot.spectrum( ...
        testCase.TestData.Spec, ...
        SummaryLocation="northwest");

    txt = findSummary(h.Parent);

    verifyEqual(testCase, txt.Position(1:2), [0.02 0.98], "AbsTol", 1e-12);
    verifyEqual(testCase, string(txt.HorizontalAlignment), "left");
    verifyEqual(testCase, string(txt.VerticalAlignment), "top");
end


function testSouthwestLocation(testCase)

    h = spectralab.plot.spectrum( ...
        testCase.TestData.Spec, ...
        SummaryLocation="southwest");

    txt = findSummary(h.Parent);

    verifyEqual(testCase, txt.Position(1:2), [0.02 0.02], "AbsTol", 1e-12);
    verifyEqual(testCase, string(txt.HorizontalAlignment), "left");
    verifyEqual(testCase, string(txt.VerticalAlignment), "bottom");
end


function testRejectsUnsupportedLocation(testCase)

    verifyError(testCase, ...
        @() spectralab.plot.spectrum( ...
            testCase.TestData.Spec, ...
            SummaryLocation="center"), ...
        "MATLAB:validators:mustBeMember");
end


function txt = findSummary(ax)

    txt = findall(ax, "Type", "text", "Tag", "SpectraLabSummary");
    assert(isscalar(txt), "Expected exactly one SpectraLab summary text object.");
end
