function patch = nextPatch(session)
%NEXTPATCH Return the next pending patch in declared row-major order.

arguments
    session (1,1) struct
end

spectralab.colorchecker.validate(session);
states = string({session.Patches.State});
index = find(states == "pending", 1, "first");
if isempty(index)
    patch = struct();
    return
end
patch = session.Patches(index);
end
