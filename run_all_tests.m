%RUN_ALL_TESTS  Run all SpectraLab tests.
%
% Run this file from the repository root.

clear
clc

restoredefaultpath;
rehash toolboxcache;
try
    clear classes
catch
end

rootDir = fileparts(mfilename("fullpath"));
cd(rootDir);
addpath(rootDir);
addpath(fullfile(rootDir, "examples"));
addpath(genpath(fullfile(rootDir, "spectralab")));

versionText = spectralab.version();
fprintf("\nSpectraLab v%s test runner\n", versionText);
fprintf("===================================\n\n");

testFiles = {
    "tests/test_core_spectrum.m"
    "tests/test_core_collection.m"
    "tests/test_status_and_result.m"
    "tests/test_mock_workflow.m"
    "tests/test_file_format_json.m"
    "tests/test_collection_io.m"
    "tests/test_export_csv_txt.m"
    "tests/test_error_paths.m"
    "tests/test_spotread_parser_fixtures.m"
    "tests/test_spotread_detection.m"
    "tests/test_plot_helpers.m"
};

nPass = 0;
nFail = 0;
failures = strings(0,1);

for k = 1:numel(testFiles)
    tf = fullfile(rootDir, testFiles{k});
    shortName = erase(erase(testFiles{k}, "tests/"), ".m");
    fprintf("[%02d/%02d] %-32s", k, numel(testFiles), shortName);

    try
        testOutput = evalc("run(tf);");
        nPass = nPass + 1;
        fprintf(" PASS\n");
        important = extractImportantOutput(testOutput);
        for j = 1:numel(important)
            fprintf("          %s\n", important(j));
        end
    catch ME
        nFail = nFail + 1;
        failures(end+1,1) = string(testFiles{k}) + " :: " + string(ME.identifier) + " :: " + string(ME.message); %#ok<SAGROW>
        fprintf(2," FAIL\n");
        fprintf(2, "          %s\n", ME.message);
    end
end

fprintf("\n=====================================\n");
fprintf("SpectraLab test summary\n");
fprintf("  Passed: %d\n", nPass);
fprintf("  Failed: %d\n", nFail);

if nFail > 0
    fprintf(2, "\nFailures:\n");
    for k = 1:numel(failures)
        fprintf(2, "  %s\n", failures(k));
    end
    error("SpectraLab:Tests:Failed", "%d test file(s) failed.", nFail);
else
    fprintf("\nAll SpectraLab tests passed.\n");
end

% Leave SpectraLab ready for interactive use after the test runner.
% In particular, examples/ must remain on the MATLAB path so that
% measure_led works immediately after run_all_tests.
addpath(rootDir);
addpath(fullfile(rootDir, "examples"));
addpath(genpath(fullfile(rootDir, "spectralab")));
rehash;

function lines = extractImportantOutput(testOutput)
%EXTRACTIMPORTANTOUTPUT  Keep useful one-line diagnostics from test output.

raw = splitlines(string(testOutput));
raw = strip(raw);
raw(raw == "") = [];
keep = false(size(raw));
for i = 1:numel(raw)
    line = raw(i);
    keep(i) = startsWith(line, "spotread found:") || startsWith(line, "WARNING") || startsWith(line, "ERROR");
end
lines = raw(keep);
end
