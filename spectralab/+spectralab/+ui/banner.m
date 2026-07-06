function banner(version, motto, statusText)
%BANNER  Print the SpectraLab startup banner.

if nargin < 1 || strlength(string(version)) == 0
    version = "";
end
if nargin < 2 || strlength(string(motto)) == 0
    motto = "Measure once. Save forever.";
end
if nargin < 3
    statusText = "";
end

fprintf("SpectraLab %s\n", string(version));
fprintf("%s\n", string(motto));

if strlength(string(statusText)) > 0
    fprintf("%s\n", string(statusText));
end

end
