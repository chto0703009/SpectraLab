% spotread detection test
%
% This test does not fail when spotread is absent.

exe = spectralab.drivers.spotread.findSpotread();

if strlength(exe) == 0
    fprintf("spotread not found. Skipping executable response check.\n");
else
    fprintf("spotread found: %s\n", exe);
    runner = spectralab.drivers.spotread.CommandRunner(exe, 20);
    r = runner.run("-?");
    assert(strlength(r.output) > 0);
end

fprintf("test_spotread_detection OK\n");
