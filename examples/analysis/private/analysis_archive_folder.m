function folder = analysis_archive_folder(defaultFolder, selectedFolder)
%ANALYSIS_ARCHIVE_FOLDER Remember the latest archive folder this session.
%
% folder = analysis_archive_folder(defaultFolder) returns the most recently
% selected, still existing archive folder in the current MATLAB session.
% If none has been recorded, defaultFolder is returned.
%
% folder = analysis_archive_folder(defaultFolder, selectedFolder) records a
% successful file-dialog selection and returns selectedFolder. The value is
% stored only in MATLAB application memory and is not persisted to disk.

arguments
    defaultFolder (1,1) string
    selectedFolder (1,1) string = ""
end

applicationKey = "SpectraLabWorkLastArchiveFolder";
defaultFolder = strtrim(defaultFolder);
selectedFolder = strtrim(selectedFolder);

if strlength(selectedFolder) > 0
    if ~isfolder(selectedFolder)
        error("SpectraLab:Work:SelectedArchiveFolderNotFound", ...
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
    error("SpectraLab:Work:DefaultArchiveFolderNotFound", ...
        "Default archive folder not found:\n%s", defaultFolder);
end
folder = defaultFolder;

end
