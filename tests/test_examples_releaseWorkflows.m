function tests = test_examples_releaseWorkflows
%TEST_EXAMPLES_RELEASEWORKFLOWS Release example structure and fixtures.
tests = functiontests(localfunctions);
end

function testSyntheticArchivesAreValidAndNeutral(testCase)
root = projectRoot();
dataFolder = fullfile(root, "examples", "data");
names = ["example_reference", "example_sample_a", "example_sample_b"];

for name = names
    archiveFile = fullfile(dataFolder, name + ".mat");
    verifyTrue(testCase, isfile(archiveFile));
    archive = spectralab.archive.load( ...
        archiveFile, Quiet=true, Validation="error");
    verifyEqual(testCase, string(archive.Measurement.Name), name);
    verifyEqual(testCase, string(archive.Measurement.Operator), ...
        "SpectraLab example");
    verifyEqual(testCase, string(archive.Metadata.Project), ...
        "SpectraLab examples");
    verifyEqual(testCase, string(archive.Instrument.SerialNumber), "");
    verifyEqual(testCase, numel(archive.Measurement.Wavelength), 36);
    verifyEqual(testCase, archive.Measurement.Wavelength([1 end]), ...
        [380; 730]);
end
end

function testWorkflowNamesCommunicateOutputContract(testCase)
root = projectRoot();
analysisFolder = fullfile(root, "examples", "analysis");
inventoryFolder = fullfile(root, "examples", "inventory");

verifyTrue(testCase, isfile(fullfile(analysisFolder, "plot_spectrum.m")));
verifyTrue(testCase, isfile(fullfile(analysisFolder, "plot_transmission.m")));
verifyTrue(testCase, ...
    isfile(fullfile(analysisFolder, "calculate_cri_report.m")));
verifyTrue(testCase, ...
    isfile(fullfile(inventoryFolder, "list_archive_folder.m")));

plotFiles = dir(fullfile(analysisFolder, "plot_*.m"));
for fileIndex = 1:numel(plotFiles)
    source = fileread(fullfile(plotFiles(fileIndex).folder, ...
        plotFiles(fileIndex).name));
    verifyFalse(testCase, contains(source, "spectralab.report.generate"));
end

calculateFiles = dir(fullfile(analysisFolder, "calculate_*.m"));
for fileIndex = 1:numel(calculateFiles)
    verifyTrue(testCase, endsWith(calculateFiles(fileIndex).name, ...
        "_report.m"));
end
end

function testCategorizedWorkflowsArePublicButDataIsNot(testCase)
root = projectRoot();
verifyEqual(testCase, string(which("plot_spectrum")), ...
    fullfile(root, "examples", "analysis", "plot_spectrum.m"));
verifyEqual(testCase, string(which("calculate_cri_report")), ...
    fullfile(root, "examples", "analysis", ...
    "calculate_cri_report.m"));
verifyEqual(testCase, string(which("list_archive_folder")), ...
    fullfile(root, "examples", "inventory", ...
    "list_archive_folder.m"));
verifyFalse(testCase, contains(path, fullfile(root, "examples", "data")));
verifyTrue(testCase, isempty(which("internal_save_spectrum_outputs")));
end

function testMeasurementExamplesAreNeutralAndCategorized(testCase)
root = projectRoot();
measurementFolder = fullfile(root, "examples", "measurement");
required = [ ...
    "measure_spectrum.m", ...
    "measure_spectrum_series_5.m", ...
    "interactive_measure_reference.m", ...
    "interactive_measure_sample.m", ...
    "interactive_save_spectrum.m"];
for name = required
    file = fullfile(measurementFolder, name);
    verifyTrue(testCase, isfile(file));
    source = fileread(file);
    verifyFalse(testCase, contains(source, "Christer"));
    verifyFalse(testCase, contains(source, "C41"));
    verifyFalse(testCase, contains(source, "SpectraLab_Work"));
end

privateFolder = fullfile(measurementFolder, "private");
verifyTrue(testCase, ...
    isfile(fullfile(privateFolder, "select_spotread_instrument.m")));
verifyTrue(testCase, ...
    isfile(fullfile(privateFolder, "verify_spotread_instrument.m")));

singleSource = fileread(fullfile(measurementFolder, "measure_spectrum.m"));
seriesSource = fileread(fullfile( ...
    measurementFolder, "measure_spectrum_series_5.m"));
verifyTrue(testCase, contains(singleSource, "select_spotread_instrument"));
verifyTrue(testCase, contains(singleSource, "calibrationSerialNumber"));
verifyTrue(testCase, contains(seriesSource, "select_spotread_instrument"));
verifyTrue(testCase, contains(seriesSource, "calibrationSerialNumber"));
end

function testColorCheckerQualityExamplesArePublicAndNeutral(testCase)
root = projectRoot();
folder = fullfile(root, "examples", "colorchecker");
required = ["compare_colorchecker_xrite_lab.m", ...
    "remeasure_colorchecker_patches.m"];
for name = required
    file = fullfile(folder, name);
    verifyTrue(testCase, isfile(file));
    source = fileread(file);
    verifyFalse(testCase, contains(source, "Christer"));
    verifyFalse(testCase, contains(source, "SpectraLab_Work"));
end
verifyEqual(testCase, string(which("compare_colorchecker_xrite_lab")), ...
    fullfile(folder, "compare_colorchecker_xrite_lab.m"));
verifyEqual(testCase, string(which("remeasure_colorchecker_patches")), ...
    fullfile(folder, "remeasure_colorchecker_patches.m"));
verifyTrue(testCase, isfile(fullfile(folder, "private", ...
    "verify_spotread_instrument.m")));
end

function root = projectRoot()
root = string(fileparts(fileparts(mfilename("fullpath"))));
end
