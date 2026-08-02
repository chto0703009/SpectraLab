function tf = isSpectraLabFile(filename)
%ISSPECTRALABFILE  Return true if file appears to be a SpectraLab JSON file.


try
    raw = fileread(filename);
    data = jsondecode(raw);
    tf = isfield(data, "format") && startsWith(string(data.format), "spectralab.");
catch
    tf = false;
end

end
