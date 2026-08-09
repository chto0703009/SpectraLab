function startup()
%STARTUP Prepare the MATLAB path for SpectraLab.
%
%   Run this command from the SpectraLab project root before using
%   SpectraLab examples or API functions.
%
%   Example
%       startup
%       measure_led

% Remove old SpectraLab objects from the base workspace before clearing
% classes. This is needed when switching between unpacked build folders in
% the same MATLAB session; otherwise MATLAB may keep class definitions from
% an older, now inaccessible folder.
try
    vars = evalin('base', 'whos');
    for k = 1:numel(vars)
        cls = string(vars(k).class);
        if startsWith(cls, "spectralab.")
            evalin('base', "clear " + vars(k).name);
        end
    end
catch
    % Continue; class clearing below will still improve the path state.
end

% Clear stale class definitions before adding this build to the path.
try
    evalc('clear classes');
catch
    % Continue; startup diagnostics below will still report path problems.
end

startupFile = mfilename("fullpath");
rootDir = fileparts(startupFile);

expectedPackage = fullfile(rootDir, "spectralab", "+spectralab");
expectedExamples = fullfile(rootDir, "examples");

if ~isfolder(expectedPackage) || ~isfolder(expectedExamples)
    error("SpectraLab:Startup:InvalidProjectRoot", ...
        ["ERROR [SPL-001]\n\n" + ...
         "SpectraLab project structure was not found.\n\n" + ...
         "Expected to find:\n" + ...
         "    spectralab/+spectralab\n" + ...
         "    examples\n\n" + ...
         "What to do:\n" + ...
         "1. Change MATLAB current folder to the SpectraLab project directory.\n" + ...
         "2. Run:\n\n" + ...
         "    startup\n"]);
end

% Reset MATLAB path so switching between different SpectraLab builds does
% not leave stale paths behind. The current folder remains active in MATLAB.
restoredefaultpath;
rehash toolboxcache;

addpath(rootDir);
addpath(expectedExamples);
% Add only user-facing workflow categories. Example data, generated output
% and private helpers must not become public MATLAB commands.
exampleCategories = ["measurement", "analysis", "inventory", "colorchecker"];
for category = exampleCategories
    categoryFolder = fullfile(expectedExamples, category);
    if isfolder(categoryFolder)
        addpath(categoryFolder);
    end
end
addpath(genpath(fullfile(rootDir, "spectralab")));
rehash;

spectralab.status("ProjectRoot", rootDir, "Startup", true);
end
