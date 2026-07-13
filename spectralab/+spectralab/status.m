function s = status(varargin)
%STATUS  Print a SpectraLab installation and runtime status report.
%
%   S = spectralab.status() checks the current MATLAB session and prints a
%   concise status report. The report is intended to answer the practical
%   question: what should the user do next?
%
%   S = spectralab.status("ProjectRoot", ROOT) uses ROOT as the expected
%   SpectraLab project directory.

p = inputParser;
addParameter(p, "ProjectRoot", "", @(x)ischar(x) || isstring(x));
addParameter(p, "Startup", false, @(x)islogical(x) && isscalar(x));
parse(p, varargin{:});

versionText = spectralab.version();
motto = "Measure once. Save forever.";

rootDir = string(p.Results.ProjectRoot);
if strlength(rootDir) == 0
    rootDir = spectralab.projectRoot();
end

% SpectraLab currently starts Python as an external process through the
% selected executable. It does not rely on MATLAB's pyenv bridge. Therefore
% the key diagnostic is the Python executable that SpectraLab itself will
% use, not the Python executable configured for MATLAB's Python interface.
minMatlabRelease = "2024b";
minPythonVersion = [3 10 0];
minArgyllVersion = [3 5 0];

s = struct();
s.name = "SpectraLab";
s.version = versionText;
s.motto = motto;
s.project_root = rootDir;
s.native_file_format = "spectralab.spectrum.v1";
s.project_ok = isfolder(fullfile(rootDir, "spectralab", "+spectralab"));
s.examples_ok = isfolder(fullfile(rootDir, "examples")) && containsPath(fullfile(rootDir, "examples"));

s.matlab_release = normalizeRelease(string(version("-release")));
s.matlab_version = string(version());
s.matlab_ok = compareRelease(s.matlab_release, minMatlabRelease) >= 0;

s.spotread = spectralab.drivers.spotread.findSpotread();
s.spotread_ok = strlength(s.spotread) > 0;
s.spotread_version = "";
s.argyll_ok = false;
if s.spotread_ok
    s.spotread_version = getSpotreadVersion(s.spotread);
    s.argyll_ok = isVersionAtLeast(s.spotread_version, minArgyllVersion);
end

s.python = spectralab.drivers.spotread.ManualSafeBridge.findPython();
s.python_ok = strlength(s.python) > 0;
s.python_version = "";
s.python_version_ok = false;
s.pexpect_ok = false;
s.pexpect_version = "";

if s.python_ok
    s.python_version = getPythonVersion(s.python);
    s.python_version_ok = isVersionAtLeast(s.python_version, minPythonVersion);
    [s.pexpect_ok, s.pexpect_version] = checkPythonModule(s.python, "pexpect");
end

spectralab.ui.banner(versionText, motto, "Ready");

fprintf("Project root:\n  %s\n\n", rootDir);
fprintf("Status\n");
fprintf("  Project ........ %s\n", okText(s.project_ok));
fprintf("  Examples ....... %s\n", okText(s.examples_ok));
fprintf("  MATLAB ......... %s  %s\n", statusText(s.matlab_ok, true), s.matlab_release);

fprintf("  Python ......... %s", statusText(s.python_ok && s.python_version_ok, s.python_ok));
if s.python_ok
    fprintf("  %s", s.python);
    if strlength(s.python_version) > 0
        fprintf("  (%s)", s.python_version);
    end
end
fprintf("\n");

fprintf("  pexpect ........ %s", okText(s.pexpect_ok));
if s.pexpect_ok && strlength(s.pexpect_version) > 0
    fprintf("  %s", s.pexpect_version);
end
fprintf("\n");

fprintf("  ArgyllCMS ...... %s", statusText(s.spotread_ok && s.argyll_ok, s.spotread_ok));
if s.spotread_ok && strlength(s.spotread_version) > 0
    fprintf("  %s", s.spotread_version);
end
fprintf("\n");

fprintf("  spotread ....... %s", okText(s.spotread_ok));
if s.spotread_ok
    fprintf("  %s", s.spotread);
end
fprintf("\n");

allOk = s.project_ok && s.examples_ok && s.matlab_ok && ...
    s.python_ok && s.python_version_ok && s.pexpect_ok && ...
    s.spotread_ok && s.argyll_ok;

if ~allOk
    fprintf("\nWhat to do next\n");
    if ~s.project_ok
        fprintf("  [SPL-001] Run startup from the SpectraLab project directory.\n");
    end
    if ~s.examples_ok
        fprintf("  [SPL-002] The examples folder is not on the MATLAB path. Run startup again from the project root.\n");
    end
    if ~s.matlab_ok
        fprintf("  [SPL-010] SpectraLab is tested with MATLAB %s or later.\n", minMatlabRelease);
        fprintf("            Current MATLAB release: %s.\n", s.matlab_release);
    end
    if ~s.python_ok
        fprintf("  [SPL-003] Install Python 3.10 or later, or configure the Python executable used by SpectraLab.\n");
    elseif ~s.python_version_ok
        fprintf("  [SPL-011] SpectraLab is using Python %s. Python 3.10 or later is recommended.\n", unknownText(s.python_version));
        fprintf("            Current executable: %s\n", s.python);
    elseif ~s.pexpect_ok
        fprintf("  [SPL-004] Install pexpect in the Python environment used by SpectraLab.\n");
        fprintf("            Example: %s -m pip install pexpect\n", s.python);
    end
    if ~s.spotread_ok
        fprintf("  [SPL-005] Install ArgyllCMS and make sure spotread is on the system PATH.\n");
    elseif ~s.argyll_ok
        fprintf("  [SPL-012] ArgyllCMS/spotread version could not be verified or is older than recommended.\n");
        fprintf("            Current version: %s. Recommended: 3.5.0 or later.\n", unknownText(s.spotread_version));
    end
    fprintf("\nSee docs/GETTING_STARTED.md and docs/TROUBLESHOOTING.md.\n");
end

end

function [tf, moduleVersion] = checkPythonModule(pythonExe, moduleName)
%CHECKPYTHONMODULE  Return true if MODULE can be imported by PYTHONEXE.

tf = false;
moduleVersion = "";
script = string(tempname) + ".py";
fid = fopen(script, "w");
if fid < 0
    return
end
cleanup = onCleanup(@() deleteIfExists(script));
fprintf(fid, "import sys\n");
fprintf(fid, "try:\n");
fprintf(fid, "    import %s\n", char(moduleName));
fprintf(fid, "    print(getattr(%s, '__version__', 'unknown'))\n", char(moduleName));
fprintf(fid, "    sys.exit(0)\n");
fprintf(fid, "except Exception:\n");
fprintf(fid, "    sys.exit(1)\n");
fclose(fid);

cmd = sprintf('"%s" "%s"', char(pythonExe), script);
[st, out] = system(cmd);
tf = st == 0;
if tf
    moduleVersion = strtrim(string(out));
end
end

function v = getPythonVersion(pythonExe)
v = "";
cmd = sprintf('"%s" --version', char(pythonExe));
[st, out] = system(cmd);
if st == 0
    v = strtrim(string(out));
end
end

function v = getSpotreadVersion(spotreadExe)
v = "";
cmd = sprintf('"%s" ''-?'' 2>&1', char(spotreadExe));
[~, out] = system(cmd);
out = string(out);
expr = "Version\s+(\d+(?:\.\d+){0,2})";
tok = regexp(out, expr, "tokens", "once");
if ~isempty(tok)
    v = string(tok{1});
end
end

function tf = isVersionAtLeast(versionText, minimumParts)
parts = parseVersionNumbers(versionText);
if isempty(parts)
    tf = false;
    return
end
n = max(numel(parts), numel(minimumParts));
parts(end+1:n) = 0;
minimumParts(end+1:n) = 0;
if parts(1) > minimumParts(1)
    tf = true;
elseif parts(1) < minimumParts(1)
    tf = false;
elseif n >= 2 && parts(2) > minimumParts(2)
    tf = true;
elseif n >= 2 && parts(2) < minimumParts(2)
    tf = false;
elseif n >= 3 && parts(3) >= minimumParts(3)
    tf = true;
else
    tf = n < 3;
end
end

function nums = parseVersionNumbers(txt)
txt = string(txt);
tok = regexp(txt, "(\d+)\.(\d+)(?:\.(\d+))?", "tokens", "once");
if isempty(tok)
    nums = [];
    return
end
nums = zeros(1, numel(tok));
for k = 1:numel(tok)
    if isempty(tok{k})
        nums(k) = 0;
    else
        nums(k) = str2double(tok{k});
    end
end
end

function r = compareRelease(currentRelease, minimumRelease)
currentYear = releaseYear(currentRelease);
currentHalf = releaseHalf(currentRelease);
minimumYear = releaseYear(minimumRelease);
minimumHalf = releaseHalf(minimumRelease);
if currentYear > minimumYear
    r = 1;
elseif currentYear < minimumYear
    r = -1;
elseif currentHalf > minimumHalf
    r = 1;
elseif currentHalf < minimumHalf
    r = -1;
else
    r = 0;
end
end

function rel = normalizeRelease(rel)
rel = string(rel);
if startsWith(rel, "R")
    rel = extractAfter(rel, 1);
end
end

function y = releaseYear(rel)
tok = regexp(normalizeRelease(string(rel)), "(\d{4})[ab]", "tokens", "once");
if isempty(tok)
    y = 0;
else
    y = str2double(tok{1});
end
end

function h = releaseHalf(rel)
rel = string(rel);
if endsWith(rel, "b")
    h = 2;
elseif endsWith(rel, "a")
    h = 1;
else
    h = 0;
end
end

function deleteIfExists(fileName)
try
    if isfile(fileName)
        delete(fileName);
    end
catch
end
end

function txt = statusText(ok, present)
if ok
    txt = "OK";
elseif present
    txt = "WARNING";
else
    txt = "MISSING";
end
end

function txt = okText(tf)
if tf
    txt = "OK";
else
    txt = "MISSING";
end
end

function txt = unknownText(txt)
if strlength(string(txt)) == 0
    txt = "unknown";
else
    txt = string(txt);
end
end

function tf = containsPath(folder)
folder = char(folder);
paths = strsplit(path, pathsep);
tf = any(strcmp(paths, folder));
end
