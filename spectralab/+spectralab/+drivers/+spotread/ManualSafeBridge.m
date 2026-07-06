classdef ManualSafeBridge
    %MANUALSAFEBRIDGE  Manual-safe bridge for ArgyllCMS spotread.
    %
    % Calibration and measurement are performed in the same spotread
    % process. runCalibration() is readiness-only.

    methods (Static)
        function pythonExe = findPython()
            candidates = strings(0,1);

            if ispc
                candidates(end+1) = "python";
                candidates(end+1) = "py";
            else
                candidates(end+1) = "/Users/christer/SpectraLabPython/bin/python";
                candidates(end+1) = "/opt/homebrew/bin/python3";
                candidates(end+1) = "/usr/local/bin/python3";
                candidates(end+1) = "/usr/bin/python3";
                candidates(end+1) = "python3";
            end

            pythonExe = "";

            for k = 1:numel(candidates)
                c = candidates(k);
                if contains(c, filesep) || startsWith(c, "/")
                    if isfile(c)
                        pythonExe = c;
                        return
                    end
                else
                    [status, out] = system(sprintf("command -v %s", char(c)));
                    if status == 0 && strlength(strtrim(string(out))) > 0
                        pythonExe = strtrim(string(out));
                        return
                    end
                end
            end
        end

        function script = bridgeScript(scriptName)
            thisFile = mfilename("fullpath");
            parts = split(string(thisFile), filesep);
            idx = find(parts == "spectralab", 1, "first");
            if isempty(idx)
                error("SpectraLab:ManualSafeBridge:PathError", ...
                    "Could not locate repository root.");
            end
            rootParts = parts(1:idx-1);
            root = join(rootParts, filesep);
            if strlength(root) == 0
                root = filesep;
            end
            script = fullfile(root, "tools", scriptName);
        end

        function r = runCalibration(pythonExe, spotreadExe, options, timeoutSeconds)
            if nargin < 1, pythonExe = ""; end
            if nargin < 2, spotreadExe = ""; end
            if nargin < 3, options = "-e"; end
            if nargin < 4, timeoutSeconds = 300; end

            r = struct();
            r.status = 0;
            r.output = "Calibration will be performed in the measurement spotread session.";
            r.command = "no external calibration process";
            r.python_executable = string(pythonExe);
            r.spotread_executable = string(spotreadExe);
            r.options = string(options);
            r.timeout_seconds = timeoutSeconds;
        end

        function r = runMeasurement(pythonExe, spotreadExe, options, timeoutSeconds)
            if nargin < 1 || strlength(string(pythonExe)) == 0
                pythonExe = spectralab.drivers.spotread.ManualSafeBridge.findPython();
            end
            if nargin < 2, spotreadExe = ""; end
            if nargin < 3 || strlength(string(options)) == 0, options = "-e -s"; end
            if nargin < 4, timeoutSeconds = 300; end

            script = spectralab.drivers.spotread.ManualSafeBridge.bridgeScript("spotread_manual_measure.py");
            r = spectralab.drivers.spotread.ManualSafeBridge.runScript( ...
                pythonExe, script, spotreadExe, options, timeoutSeconds);
        end

        function r = runScript(pythonExe, script, spotreadExe, options, timeoutSeconds)
            if strlength(string(pythonExe)) == 0
                error("SpectraLab:ManualSafeBridge:PythonNotFound", ...
                    "Could not find Python 3.");
            end
            if ~isfile(script)
                error("SpectraLab:ManualSafeBridge:ScriptNotFound", ...
                    "Bridge script not found: %s", script);
            end

            cmd = sprintf('"%s" "%s" --options="%s" --timeout %d', ...
                pythonExe, script, options, timeoutSeconds);

            if strlength(string(spotreadExe)) > 0
                cmd = sprintf('%s --spotread "%s"', cmd, spotreadExe);
            end

            [status, output] = system(cmd, "-echo");

            r = struct();
            r.status = status;
            r.output = string(output);
            r.command = string(cmd);
        end
    end
end
