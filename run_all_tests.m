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
examplesDir = fullfile(rootDir, "examples");
addpath(examplesDir);
for category = ["measurement", "analysis", "inventory"]
    categoryDir = fullfile(examplesDir, category);
    if isfolder(categoryDir)
        addpath(categoryDir);
    end
end
addpath(genpath(fullfile(rootDir, "spectralab")));

versionText = spectralab.version();
fprintf("\nSpectraLab v%s test runner\n", versionText);
fprintf("===================================\n\n");

testListing = dir(fullfile(rootDir, "tests", "test_*.m"));
[~, testOrder] = sort({testListing.name});
testListing = testListing(testOrder);

nPass = 0;
nFail = 0;
nTestCases = 0;
failures = strings(0,1);

for k = 1:numel(testListing)
    tf = fullfile(testListing(k).folder, testListing(k).name);
    relativeFile = "tests/" + string(testListing(k).name);
    shortName = erase(string(testListing(k).name), ".m");
    fprintf("[%02d/%02d] %-40s", k, numel(testListing), shortName);

    try
        sourceText = fileread(tf);
        isFunctionBased = ~isempty(regexp( ...
            sourceText, ...
            "^\s*function\s+tests\s*=", ...
            "once", ...
            "lineanchors"));

        if isFunctionBased
            testOutput = evalc( ...
                "fileResults = runtests(tf); assertSuccess(fileResults);");
            nTestCases = nTestCases + numel(fileResults);
        else
            testOutput = evalc("run(tf);");
            nTestCases = nTestCases + 1;
        end

        nPass = nPass + 1;
        fprintf(" PASS\n");
        important = extractImportantOutput(testOutput);
        for j = 1:numel(important)
            fprintf("          %s\n", important(j));
        end
    catch ME
        nFail = nFail + 1;
        failures(end+1,1) = relativeFile + " :: " + ...
            string(ME.identifier) + " :: " + string(ME.message); %#ok<SAGROW>
        fprintf(2," FAIL\n");
        fprintf(2, "          %s\n", ME.message);
    end
end

fprintf("\n=====================================\n");
fprintf("SpectraLab test summary\n");
fprintf("  Test files passed: %d\n", nPass);
fprintf("  Test files failed: %d\n", nFail);
fprintf("  Test cases run:    %d\n", nTestCases);

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
addpath(examplesDir);
for category = ["measurement", "analysis", "inventory"]
    categoryDir = fullfile(examplesDir, category);
    if isfolder(categoryDir)
        addpath(categoryDir);
    end
end
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
