% list_archive_folder
%
% Print a read-only inventory of the bundled synthetic MAT archives.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
archiveFolder = fullfile(examplesRoot, "data");
files = dir(fullfile(archiveFolder, "*.mat"));

fprintf("\nSpectraLab example archive inventory\n");
fprintf("====================================\n");
fprintf("Folder : %s\n", archiveFolder);
fprintf("Files  : %d\n\n", numel(files));

validCount = 0;
for fileIndex = 1:numel(files)
    archiveFile = fullfile(files(fileIndex).folder, files(fileIndex).name);
    fprintf("[%d/%d] %s\n", fileIndex, numel(files), files(fileIndex).name);
    try
        archive = spectralab.archive.load( ...
            archiveFile, Quiet=true, Validation="error");
        fprintf("  Measurement : %s\n", archive.Measurement.Name);
        fprintf("  Samples     : %d\n", ...
            numel(archive.Measurement.Wavelength));
        fprintf("  Range       : %.1f - %.1f nm\n", ...
            archive.Measurement.Wavelength(1), ...
            archive.Measurement.Wavelength(end));
        fprintf("  UUID        : %s\n", archive.Identity.UUID);
        fprintf("  Validation  : VALID\n\n");
        validCount = validCount + 1;
    catch exception
        fprintf("  Validation  : INVALID/UNREADABLE\n");
        fprintf("  Reason      : %s\n\n", exception.message);
    end
end

fprintf("Valid archives    : %d\n", validCount);
fprintf("Invalid archives  : %d\n\n", numel(files) - validCount);
