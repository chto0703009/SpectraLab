function session = load(filename)
%LOAD Load and validate a ColorChecker session manifest.

arguments
    filename (1,1) string
end

if isfolder(filename)
    filename = fullfile(filename, "colorchecker_session.json");
end
if ~isfile(filename)
    error("SpectraLab:ColorChecker:SessionNotFound", ...
        "ColorChecker session manifest not found: %s", filename);
end

session = jsondecode(fileread(filename));
session.Context.SessionFolder = string(fileparts(filename));
session.History = reshape(string(session.History), [], 1);
spectralab.colorchecker.validate(session);
end
