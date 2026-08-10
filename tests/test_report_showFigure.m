function tests = test_report_showFigure
%TEST_REPORT_SHOWFIGURE Protect registered display-only figures.

tests = functiontests(localfunctions);
end

function setup(~)
close all force
end

function teardown(~)
close all force
end

function testShowsRegisteredSpectrumWithoutWritingFiles(testCase)
archive = makeArchive();
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() removeFolder(folder));

before = string({dir(folder).name});
view = spectralab.report.showFigure(archive, "ANL-SPECTRUM");
after = string({dir(folder).name});

profile = spectralab.report.internal.figureLayoutProfile();
verifyTrue(testCase, isgraphics(view.Figure, "figure"));
verifyTrue(testCase, isgraphics(view.Axes, "axes"));
verifyEqual(testCase, view.AnalysisId, "ANL-SPECTRUM");
verifyEqual(testCase, view.Figure.Position, ...
    profile.InteractiveFigurePosition, "AbsTol", 1e-12);
verifyEqual(testCase, after, before);
end

function testRejectsAnalysisWithoutFigure(testCase)
archive = makeArchive();
verifyError(testCase, ...
    @() spectralab.report.showFigure(archive, "ANL-004"), ...
    "SpectraLab:Report:AnalysisHasNoFigure");
end

function archive = makeArchive()
instrument = spectralab.drivers.MockInstrument();
session = spectralab.core.Session(instrument);
session = session.open();
session = session.calibrate();
measurement = session.measure("Display-only spectrum");
archive = spectralab.archive.create(measurement);
end

function removeFolder(folder)
if isfolder(folder), rmdir(folder, "s"); end
end
