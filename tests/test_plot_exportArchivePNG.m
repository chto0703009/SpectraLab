function tests = test_plot_exportArchivePNG
tests = functiontests(localfunctions);
end

function testExportsDetailedPNGWithoutPDF(testCase)
folder = string(tempname); mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, "s")); %#ok<NASGU>
spec = spectralab.core.Spectrum([400; 500; 600], [1; 4; 2], ...
    "Emission", struct("Name", "Instrument", "SerialNumber", "42"), ...
    struct(), struct("measurement_kind", "emissive", ...
    "Operator", "Operator"), "arbitrary");
archive = spectralab.archive.create(spec);
pngFile = fullfile(folder, "measurement.png");

info = spectralab.plot.exportArchivePNG( ...
    archive, pngFile, Information=true, ShowFigure=false);

verifyTrue(testCase, isfile(pngFile));
verifyGreaterThan(testCase, dir(pngFile).bytes, 0);
verifyEqual(testCase, info.PNGFile, pngFile);
verifyEmpty(testCase, dir(fullfile(folder, "*.pdf")));
end

function testOneShotCouplesInformationToStandaloneExport(testCase)
source = fileread(fullfile(projectRoot(), "spectralab", "+spectralab", ...
    "+measurement", "oneShot.m"));
verifyTrue(testCase, contains(source, ...
    "options.ExportPNG || options.PNGInformation"));
end

function root = projectRoot()
root = fileparts(fileparts(mfilename("fullpath")));
end
