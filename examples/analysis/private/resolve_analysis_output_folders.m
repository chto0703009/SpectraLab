function locations = resolve_analysis_output_folders(anchorArchiveFile)
%RESOLVE_ANALYSIS_OUTPUT_FOLDERS Locate outputs beside an archive collection.
%
% The selected MAT file is assumed to reside in an archive collection
% folder. Analysis products are placed one level above that folder:
%
%   <analysis root>/report
%   <analysis root>/plot
%
% The archive collection folder may have any name. Missing output folders
% are created. Existing files are never modified by this helper.

arguments
    anchorArchiveFile (1,1) string
end

anchorArchiveFile = strtrim(anchorArchiveFile);
if ismissing(anchorArchiveFile) || strlength(anchorArchiveFile) == 0 || ...
        ~isfile(anchorArchiveFile)
    error("SpectraLab:Work:ArchiveFileNotFound", ...
        "Selected archive file not found:\n%s", anchorArchiveFile);
end

archiveFolder = string(fileparts(anchorArchiveFile));
analysisRoot = string(fileparts(archiveFolder));
if string(java.io.File(char(archiveFolder)).getName())=="data" && ...
        isfolder(fullfile(analysisRoot,"analysis"))
    analysisRoot=fullfile(analysisRoot,"output");
end
if strlength(analysisRoot) == 0 || analysisRoot == archiveFolder
    error("SpectraLab:Work:InvalidAnalysisRoot", ...
        ["Could not resolve an analysis root one level above the " ...
         "selected archive folder:\n%s"], archiveFolder);
end

reportFolder = fullfile(analysisRoot, "report");
plotFolder = fullfile(analysisRoot, "plot");
for folderName = [reportFolder, plotFolder]
    if isfolder(folderName)
        continue
    end
    [created, message] = mkdir(folderName);
    if ~created
        error("SpectraLab:Work:OutputFolderCreationFailed", ...
            "Could not create output folder:\n%s\n\n%s", ...
            folderName, message);
    end
end

locations = struct( ...
    "Root", analysisRoot, ...
    "ArchiveFolder", archiveFolder, ...
    "ReportFolder", reportFolder, ...
    "PlotFolder", plotFolder);

end
