% Reject accidental dependencies on MathWorks add-on toolboxes.
repoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
sourceRoots = [fullfile(repoRoot,"spectralab"), fullfile(repoRoot,"examples")];
files = dir(fullfile(sourceRoots(1),"**","*.m"));
files = [files; dir(fullfile(sourceRoots(2),"**","*.m"))]; %#ok<AGROW>
sourceFiles = fullfile(string({files.folder}),string({files.name}));
reportGeneratorUsers = strings(0,1);
for index = 1:numel(sourceFiles)
    sourceText=fileread(sourceFiles(index));
    if contains(sourceText, "mlreportgen")
        reportGeneratorUsers(end+1,1) = sourceFiles(index); %#ok<SAGROW>
    end
end
assert(isempty(reportGeneratorUsers), ...
    "SpectraLab:Dependencies:ReportGeneratorForbidden", ...
    "Standard/base MATLAB policy forbids MATLAB Report Generator. Files: %s", ...
    join(reportGeneratorUsers, ", "));
[~,products] = matlab.codetools.requiredFilesAndProducts(cellstr(sourceFiles));
names = string({products.Name});
numbers = string({products.ProductNumber});
assert(isequal(names,"MATLAB") && isequal(numbers,"1"), ...
    "SpectraLab:Dependencies:ToolboxForbidden", ...
    "SpectraLab must require only standard/base MATLAB; found: %s", ...
    join(names,", "));
fprintf("test_base_matlab_only OK\n");
