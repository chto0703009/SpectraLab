function folder = archiveFolder(defaultFolder, selectedFolder)
%ARCHIVEFOLDER Remember the latest archive folder this MATLAB session.
%
% folder = spectralab.ui.archiveFolder(defaultFolder) returns the most
% recently selected, still existing archive folder. If no folder has been
% recorded in this MATLAB session, defaultFolder is returned.
%
% folder = spectralab.ui.archiveFolder(defaultFolder, selectedFolder)
% records a successful archive-dialog selection and returns selectedFolder.

arguments
    defaultFolder (1,1) string
    selectedFolder (1,1) string = ""
end

applicationKey = "SpectraLabWorkLastArchiveFolder";
defaultFolder = strtrim(defaultFolder);
selectedFolder = strtrim(selectedFolder);

if strlength(selectedFolder) > 0
    if ~isfolder(selectedFolder)
        error("SpectraLab:UI:SelectedArchiveFolderNotFound", ...
            "Selected archive folder not found:\n%s", selectedFolder);
    end
    setappdata(groot, applicationKey, char(selectedFolder));
    folder = selectedFolder;
    return
end

if isappdata(groot, applicationKey)
    rememberedFolder = string(getappdata(groot, applicationKey));
    if isscalar(rememberedFolder) && ~ismissing(rememberedFolder) && ...
            isfolder(rememberedFolder)
        folder = rememberedFolder;
        return
    end
    rmappdata(groot, applicationKey);
end

if strlength(defaultFolder) == 0 || ~isfolder(defaultFolder)
    error("SpectraLab:UI:DefaultArchiveFolderNotFound", ...
        "Default archive folder not found:\n%s", defaultFolder);
end
folder = defaultFolder;
end
