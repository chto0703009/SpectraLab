function rootDir = projectRoot()
%PROJECTROOT  Return the SpectraLab project root directory.

thisFile = mfilename("fullpath");
parts = split(string(thisFile), filesep);
idx = find(parts == "spectralab", 1, "first");

if isempty(idx)
    rootDir = string(pwd);
    return
end

rootParts = parts(1:idx-1);
rootDir = join(rootParts, filesep);
if strlength(rootDir) == 0
    rootDir = filesep;
end

end
