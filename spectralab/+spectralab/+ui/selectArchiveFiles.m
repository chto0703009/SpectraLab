function sourceFiles = selectArchiveFiles(initialFolder, options)
%SELECTARCHIVEFILES Select multiple archives without a custom blocking UI.
%
% The native file dialog may select one or several files. After each
% selection, choose Add files, SELECT, or Cancel. This also permits reliable
% multi-file selection on systems where native modifier-key selection is
% unavailable or unclear.

arguments
    initialFolder (1,1) string = pwd
    options.Title (1,1) string = "SpectraLab - Select archive files"
    options.MinimumSelection (1,1) double ...
        {mustBeInteger,mustBePositive} = 2
end

if ~isfolder(initialFolder), initialFolder=string(pwd); end
sourceFiles=strings(1,0);
currentFolder=spectralab.ui.archiveFolder(initialFolder);

while true
    dialogTitle=options.Title+" (currently selected: "+ ...
        numel(sourceFiles)+")";
    [selectedNames,selectedFolder]=uigetfile( ...
        fullfile(currentFolder,"*.mat"),dialogTitle, ...
        "MultiSelect","on");
    if isequal(selectedNames,0)
        sourceFiles=strings(1,0);
        return
    end

    selectedFolder=string(selectedFolder);
    spectralab.ui.archiveFolder(currentFolder,selectedFolder);
    selectedNames=reshape(string(selectedNames),1,[]);
    currentFolder=selectedFolder;
    additions=fullfile(selectedFolder,selectedNames);
    sourceFiles=unique([sourceFiles,additions],"stable");

    summaryText=selectionSummary(sourceFiles,options.MinimumSelection);
    choice=questdlg(char(summaryText),options.Title, ...
        "Add files","SELECT","Cancel","SELECT");
    if isempty(choice) || strcmp(choice,"Cancel")
        sourceFiles=strings(1,0);
        return
    elseif strcmp(choice,"SELECT")
        if numel(sourceFiles)>=options.MinimumSelection
            return
        end
        warning("SpectraLab:UI:TooFewArchives", ...
            "Select at least %d archive files.",options.MinimumSelection);
    end
end
end

function text=selectionSummary(sourceFiles,minimumSelection)
lines="";
for index=1:numel(sourceFiles)
    [~,name,extension]=fileparts(sourceFiles(index));
    lines=lines+newline+"  "+index+". "+name+extension;
end
text=numel(sourceFiles)+" archive file(s) selected:"+lines+ ...
    newline+newline+"Required minimum: "+minimumSelection+ ...
    newline+"Choose Add files to select more, or SELECT to continue.";
end
