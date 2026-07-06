function exe = findSpotread()
%FINDSPOTREAD  Try to locate ArgyllCMS spotread executable.

candidates = strings(0,1);

if ispc
    candidates(end+1) = "spotread.exe";
else
    candidates(end+1) = "/usr/local/bin/spotread";
    candidates(end+1) = "/opt/homebrew/bin/spotread";
    candidates(end+1) = "/usr/bin/spotread";
    candidates(end+1) = "spotread";
end

exe = "";

for k = 1:numel(candidates)
    c = candidates(k);

    if contains(c, filesep) || startsWith(c, "/")
        if isfile(c)
            exe = c;
            return
        end
    else
        [status, out] = system(sprintf("command -v %s", char(c)));
        if status == 0 && strlength(strtrim(string(out))) > 0
            exe = strtrim(string(out));
            return
        end
    end
end

end
