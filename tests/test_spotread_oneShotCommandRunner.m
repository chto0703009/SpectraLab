% Bounded one-shot command runner tests

if ispc
    fprintf("OneShotCommandRunner process tests skipped on Windows.\n");
else
    pythonExe = spectralab.drivers.spotread.ManualSafeBridge.findPython();
    assert(strlength(pythonExe) > 0);

    runner = spectralab.drivers.spotread.OneShotCommandRunner( ...
        "/bin/sh", ...
        PythonExecutable=pythonExe, ...
        TimeoutSeconds=5);
    result = runner.run(["-c", "printf 'Calibration complete\\n'"]);
    assert(result.status == 0);
    assert(~result.timed_out);
    assert(contains(result.output, "Calibration complete"));
    assert(~isfolder(result.working_directory));

    retainedRunner = spectralab.drivers.spotread.OneShotCommandRunner( ...
        "/bin/sh", ...
        PythonExecutable=pythonExe, ...
        TimeoutSeconds=5, ...
        KeepArtifacts=true);
    retained = retainedRunner.run(["-c", "printf 'retained output\\n'"]);
    retainedCleanup = onCleanup(@() removeFolder( ...
        retained.working_directory)); %#ok<NASGU>
    assert(retained.artifacts_retained);
    assert(isfolder(retained.working_directory));
    assert(isfile(retained.stdout_file));
    assert(isfile(retained.metadata_file));
    assert(~retained.kept_stdin_open);

    openInputRunner = spectralab.drivers.spotread.OneShotCommandRunner( ...
        "/bin/sh", ...
        PythonExecutable=pythonExe, ...
        TimeoutSeconds=5, ...
        KeepStandardInputOpen=true);
    openInput = openInputRunner.run(["-c", "printf 'open input\\n'"]);
    assert(openInput.status == 0);
    assert(openInput.kept_stdin_open);
    assert(contains(openInput.output, "open input"));
    assert(~openInput.instrument_prompt_seen);

    promptRunner = spectralab.drivers.spotread.OneShotCommandRunner( ...
        "/bin/sh", ...
        PythonExecutable=pythonExe, ...
        TimeoutSeconds=5, ...
        KeepStandardInputOpen=true);
    promptResult = promptRunner.run(["-c", ...
        "printf 'instrument switch or any other key to take a reading:'"]);
    assert(promptResult.status == 0);
    assert(promptResult.instrument_prompt_seen);

    timeoutRunner = spectralab.drivers.spotread.OneShotCommandRunner( ...
        "/bin/sh", ...
        PythonExecutable=pythonExe, ...
        TimeoutSeconds=0.1);
    timed = timeoutRunner.run(["-c", "sleep 2"]);
    assert(timed.status == 124);
    assert(timed.timed_out);
end

fprintf("test_spotread_oneShotCommandRunner OK\n");

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
