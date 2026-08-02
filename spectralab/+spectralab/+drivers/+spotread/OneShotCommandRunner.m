classdef OneShotCommandRunner
    %ONESHOTCOMMANDRUNNER Run one bounded Spotread operation and exit.

    properties
        Executable (1,1) string
        PythonExecutable (1,1) string
        TimeoutSeconds (1,1) double = 120
        KeepArtifacts (1,1) logical = false
        KeepStandardInputOpen (1,1) logical = false
    end

    methods
        function obj = OneShotCommandRunner(executable, options)
            arguments
                executable (1,1) string
                options.PythonExecutable (1,1) string = ""
                options.TimeoutSeconds (1,1) double {mustBePositive} = 120
                options.KeepArtifacts (1,1) logical = false
                options.KeepStandardInputOpen (1,1) logical = false
            end

            if strlength(executable) == 0
                error("SpectraLab:Spotread:MissingExecutable", ...
                    "A Spotread executable is required.");
            end

            obj.Executable = executable;
            obj.PythonExecutable = options.PythonExecutable;
            if strlength(obj.PythonExecutable) == 0
                obj.PythonExecutable = ...
                    spectralab.drivers.spotread.ManualSafeBridge.findPython();
            end
            if strlength(obj.PythonExecutable) == 0
                error("SpectraLab:Spotread:PythonNotFound", ...
                    "Python 3 is required for bounded Spotread execution.");
            end

            obj.TimeoutSeconds = options.TimeoutSeconds;
            obj.KeepArtifacts = options.KeepArtifacts;
            obj.KeepStandardInputOpen = options.KeepStandardInputOpen;
        end

        function result = run(obj, arguments)
            if nargin < 2
                arguments = strings(0, 1);
            end
            arguments = string(arguments(:));

            workingDirectory = string(tempname);
            mkdir(workingDirectory);
            cleanupDirectory = onCleanup(@() cleanupIfRequired( ...
                workingDirectory, obj.KeepArtifacts)); %#ok<NASGU>

            helper = spectralab.drivers.spotread.ManualSafeBridge.bridgeScript( ...
                "spotread_one_shot.py");
            configPath = fullfile(workingDirectory, "command.json");
            config = struct();
            config.executable = char(obj.Executable);
            config.arguments = cellstr(arguments);
            config.timeout_seconds = obj.TimeoutSeconds;
            config.working_directory = char(workingDirectory);
            config.keep_stdin_open = obj.KeepStandardInputOpen;
            writeText(configPath, jsonencode(config, PrettyPrint=true));

            bridgeCommand = quoteArgument(obj.PythonExecutable) + " " + ...
                quoteArgument(helper) + " " + quoteArgument(configPath);
            if obj.KeepStandardInputOpen
                [bridgeStatus, bridgeOutput] = ...
                    system(char(bridgeCommand), "-echo");
            else
                [bridgeStatus, bridgeOutput] = system(char(bridgeCommand));
            end
            if bridgeStatus ~= 0
                error("SpectraLab:Spotread:OneShotBridgeFailed", ...
                    "The bounded command helper failed with status %d: %s", ...
                    bridgeStatus, strtrim(bridgeOutput));
            end

            metadataPath = fullfile(workingDirectory, "process.json");
            if ~isfile(metadataPath)
                error("SpectraLab:Spotread:OneShotMetadataMissing", ...
                    "The bounded command helper produced no process metadata.");
            end

            metadata = jsondecode(fileread(metadataPath));
            stdoutPath = fullfile(workingDirectory, "stdout.txt");
            stderrPath = fullfile(workingDirectory, "stderr.txt");

            result = struct();
            result.status = double(metadata.exit_code);
            result.timed_out = logical(metadata.timed_out);
            result.duration_seconds = double(metadata.duration_seconds);
            result.command = string(metadata.command(:)).';
            result.output = readText(stdoutPath);
            result.error_output = readText(stderrPath);
            result.working_directory = workingDirectory;
            result.stdout_file = string(stdoutPath);
            result.stderr_file = string(stderrPath);
            result.metadata_file = string(metadataPath);
            result.artifacts_retained = obj.KeepArtifacts;
            result.kept_stdin_open = logical(metadata.kept_stdin_open);
            result.instrument_prompt_seen = ...
                logical(metadata.instrument_prompt_seen);
        end
    end
end

function value = quoteArgument(value)
value = char(string(value));
if ispc
    value = string(['"', strrep(value, '"', '""'), '"']);
else
    value = string(['''', strrep(value, '''', '''"''"'''), '''']);
end
end

function writeText(path, value)
fileId = fopen(path, "w");
if fileId < 0
    error("SpectraLab:Spotread:TemporaryFileFailed", ...
        "Could not create temporary file: %s", path);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, "%s", value);
end

function value = readText(path)
if isfile(path)
    value = string(fileread(path));
else
    value = "";
end
end

function cleanupIfRequired(path, keepArtifacts)
if ~keepArtifacts && isfolder(path)
    rmdir(path, "s");
end
end
