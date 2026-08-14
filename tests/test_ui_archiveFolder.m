function tests = test_ui_archiveFolder
%TEST_UI_ARCHIVEFOLDER Verify archive-folder memory for analysis dialogs.

tests = functiontests(localfunctions);
end


function setup(testCase)
applicationKey = "SpectraLabWorkLastArchiveFolder";
if isappdata(groot, applicationKey)
    previous = getappdata(groot, applicationKey);
    testCase.TestData.Cleanup = onCleanup( ...
        @() setappdata(groot, applicationKey, previous));
    rmappdata(groot, applicationKey);
else
    testCase.TestData.Cleanup = onCleanup(@() removeState(applicationKey));
end
end


function testDefaultsThenRemembersSelection(testCase)
defaultFolder = string(tempname);
selectedFolder = string(tempname);
mkdir(defaultFolder);
mkdir(selectedFolder);
cleanup = onCleanup( ...
    @() removeFolders([defaultFolder,selectedFolder])); %#ok<NASGU>

verifyEqual(testCase, ...
    spectralab.ui.archiveFolder(defaultFolder),defaultFolder);
verifyEqual(testCase, ...
    spectralab.ui.archiveFolder(defaultFolder,selectedFolder),selectedFolder);
verifyEqual(testCase, ...
    spectralab.ui.archiveFolder(defaultFolder),selectedFolder);
end


function testMissingRememberedFolderFallsBack(testCase)
defaultFolder = string(tempname);
mkdir(defaultFolder);
cleanup = onCleanup(@() rmdir(defaultFolder)); %#ok<NASGU>
setappdata(groot,"SpectraLabWorkLastArchiveFolder",char(string(tempname)));

verifyEqual(testCase, ...
    spectralab.ui.archiveFolder(defaultFolder),defaultFolder);
verifyFalse(testCase,isappdata(groot,"SpectraLabWorkLastArchiveFolder"));
end


function testRejectsMissingSelectedFolder(testCase)
defaultFolder = string(tempname);
mkdir(defaultFolder);
cleanup = onCleanup(@() rmdir(defaultFolder)); %#ok<NASGU>

verifyError(testCase, ...
    @() spectralab.ui.archiveFolder(defaultFolder,string(tempname)), ...
    "SpectraLab:UI:SelectedArchiveFolderNotFound");
end


function removeState(applicationKey)
if isappdata(groot,applicationKey), rmappdata(groot,applicationKey); end
end


function removeFolders(folders)
for folder = folders
    if isfolder(folder), rmdir(folder); end
end
end
