function info = package_release(outputFolder)
%PACKAGE_RELEASE Build a self-contained SpectraLab release ZIP.
%
%   info = package_release()
%   info = package_release(outputFolder)
%
% The package is assembled from an explicit allow-list. Existing ZIP files
% are never overwritten.

arguments
    outputFolder (1,1) string = ""
end

projectRoot = string(fileparts(fileparts(mfilename("fullpath"))));
version = strtrim(string(fileread(fullfile(projectRoot, "VERSION"))));

if strlength(version) == 0 || contains(lower(version), "dev")
    error("SpectraLab:Release:InvalidVersion", ...
        "VERSION must contain a final non-development version.");
end

if outputFolder == ""
    outputFolder = fullfile(projectRoot, "releases");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

packageName = "SpectraLab_v" + version;
zipFile = fullfile(outputFolder, packageName + ".zip");

if isfile(zipFile)
    error("SpectraLab:Release:PackageAlreadyExists", ...
        "Release package already exists: %s", zipFile);
end

stagingRoot = string(tempname);
mkdir(stagingRoot);
cleanup = onCleanup(@() removeFolder(stagingRoot)); %#ok<NASGU>
packageRoot = fullfile(stagingRoot, packageName);
mkdir(packageRoot);

topLevelFiles = [ ...
    "README.md"
    "LICENSE"
    "VERSION"
    "setup.m"
    "startup.m"
    "run_all_tests.m"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "DISCLAIMER.md"
    "MANIFEST.md"
    "ROADMAP.md"
    "RELEASE_CHECKLIST.md"];

directories = [ ...
    "spectralab"
    "examples"
    "tests"
    "docs"
    "tools"];

for sourceName = topLevelFiles.'
    copyRequired(fullfile(projectRoot, sourceName), packageRoot);
end

for sourceName = directories.'
    copyRequired( ...
        fullfile(projectRoot, sourceName), ...
        fullfile(packageRoot, sourceName));
end

releaseNotesFolder = fullfile(packageRoot, "releases");
mkdir(releaseNotesFolder);
releaseNotes = dir(fullfile(projectRoot, "releases", "RELEASE_NOTES_*.md"));

for k = 1:numel(releaseNotes)
    copyRequired( ...
        fullfile(releaseNotes(k).folder, releaseNotes(k).name), ...
        releaseNotesFolder);
end

zip(zipFile, packageName, stagingRoot);

if ~isfile(zipFile)
    error("SpectraLab:Release:PackageCreationFailed", ...
        "Release ZIP was not created: %s", zipFile);
end

fileInfo = dir(zipFile);
info = struct( ...
    "Version", version, ...
    "PackageName", packageName, ...
    "ZIPFile", string(zipFile), ...
    "Bytes", double(fileInfo.bytes));

fprintf("SpectraLab release package created:\n  %s\n", zipFile);
end

function copyRequired(source, destination)

if ~(isfile(source) || isfolder(source))
    error("SpectraLab:Release:MissingRequiredComponent", ...
        "Required release component is missing: %s", source);
end

[ok, message] = copyfile(source, destination);
if ~ok
    error("SpectraLab:Release:CopyFailed", ...
        "Could not copy release component '%s': %s", source, message);
end
end

function removeFolder(folder)

if isfolder(folder)
    rmdir(folder, "s");
end
end
