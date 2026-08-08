function session = save(session)
%SAVE Atomically persist the controlled ColorChecker session manifest.
%
%   The manifest is the only mutable ColorChecker record. Patch MAT
%   archives are saved separately through spectralab.archive.save and are
%   never overwritten.

arguments
    session (1,1) struct
end

spectralab.colorchecker.validate(session);

folder = string(session.Context.SessionFolder);
target = fullfile(folder, "colorchecker_session.json");
temporary = target + ".tmp-" + string(java.util.UUID.randomUUID);

session.Identity.Revision = double(session.Identity.Revision) + 1;
session.History(end+1,1) = string(datetime("now", ...
    "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss")) + ...
    "  Session manifest saved (revision " + string(session.Identity.Revision) + ").";

text = jsonencode(session, "PrettyPrint", true);
fid = fopen(temporary, "w");
if fid < 0
    error("SpectraLab:ColorChecker:SessionWriteFailed", ...
        "Could not open session manifest for writing: %s", temporary);
end
try
    fprintf(fid, "%s\n", text);
    fclose(fid);
catch ME
    fclose(fid);
    if isfile(temporary), delete(temporary); end
    rethrow(ME)
end

[ok, message] = movefile(temporary, target, "f");
if ~ok
    error("SpectraLab:ColorChecker:SessionWriteFailed", ...
        "Could not replace session manifest:\n%s\n\n%s", target, message);
end
end
