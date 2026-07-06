classdef CommandRunner
    %COMMANDRUNNER  Small wrapper around system command execution.

    properties
        Executable (1,1) string
        TimeoutSeconds (1,1) double = 120
    end

    methods
        function obj = CommandRunner(executable, timeoutSeconds)
            if nargin < 1 || strlength(string(executable)) == 0
                error("SpectraLab:CommandRunner:MissingExecutable", ...
                    "Executable is required.");
            end
            if nargin >= 2
                obj.TimeoutSeconds = timeoutSeconds;
            end
            obj.Executable = string(executable);
        end

        function r = run(obj, args)
            if nargin < 2
                args = "";
            end

            cmd = obj.buildCommand(args);
            [status, output] = system(cmd);

            r = struct();
            r.command = cmd;
            r.status = status;
            r.output = string(output);
        end

        function cmd = buildCommand(obj, args)
            exe = char(obj.Executable);
            if contains(exe, " ") || startsWith(string(exe), "/")
                exe = ['"', exe, '"'];
            end

            args = strtrim(string(args));
            if strlength(args) == 0
                cmd = exe;
            else
                cmd = exe + " " + args;
            end
            cmd = char(cmd);
        end
    end
end
