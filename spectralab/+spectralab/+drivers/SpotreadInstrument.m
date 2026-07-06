classdef SpotreadInstrument < spectralab.core.Instrument
    %SPOTREADINSTRUMENT  ArgyllCMS spotread-based instrument driver.
    %
    % ArgyllCMS spotread keeps calibration inside its own process.
    % Therefore calibration and measurement are performed together in one
    % manual-safe spotread session.

    properties
        Executable (1,1) string = ""
        MeasurementOptions (1,1) string = "-e -s"
        CalibrationOptions (1,1) string = "-e"
        TimeoutSeconds (1,1) double = 300
        PythonExecutable (1,1) string = ""
    end

    properties (Access = private)
        Runner
    end

    methods
        function obj = SpotreadInstrument(varargin)
            p = inputParser;
            addParameter(p, "Executable", "", @(x)ischar(x) || isstring(x));
            addParameter(p, "MeasurementOptions", "-e -s", @(x)ischar(x) || isstring(x));
            addParameter(p, "CalibrationOptions", "-e", @(x)ischar(x) || isstring(x));
            addParameter(p, "TimeoutSeconds", 300, @(x)isnumeric(x) && isscalar(x) && x > 0);
            addParameter(p, "PythonExecutable", "", @(x)ischar(x) || isstring(x));
            parse(p, varargin{:});

            obj.Executable = string(p.Results.Executable);
            obj.MeasurementOptions = string(p.Results.MeasurementOptions);
            obj.CalibrationOptions = string(p.Results.CalibrationOptions);
            obj.TimeoutSeconds = p.Results.TimeoutSeconds;
            obj.PythonExecutable = string(p.Results.PythonExecutable);
        end

        function info = getInfo(obj)
            info = struct();
            info.name = "ArgyllCMS spotread instrument";
            info.driver = "spectralab.drivers.SpotreadInstrument";
            info.backend = "manual-safe-one-spotread-session";
            info.executable = obj.Executable;
            info.python_executable = obj.PythonExecutable;
            info.measurement_options = obj.MeasurementOptions;
            info.calibration_options = obj.CalibrationOptions;
            info.version = spectralab.version();
            info.is_open = obj.IsOpen;
        end

        function open(obj)
            if strlength(obj.Executable) == 0
                obj.Executable = spectralab.drivers.spotread.findSpotread();
            end

            if strlength(obj.Executable) == 0
                error("SpectraLab:Spotread:NotFound", ...
                    ["ERROR [SPL-005]\n\n" + ...
                     "ArgyllCMS spotread was not found.\n\n" + ...
                     "What to do:\n" + ...
                     "1. Install ArgyllCMS.\n" + ...
                     "2. Verify in a terminal that this works:\n\n" + ...
                     "    spotread -?\n\n" + ...
                     "3. Restart MATLAB and run:\n\n" + ...
                     "    startup\n\n" + ...
                     "Advanced option: pass the executable path with:\n" + ...
                     "    spectralab.drivers.createInstrument(""spotread"", ""Executable"", ""/path/to/spotread"")"]);
            end

            if strlength(obj.PythonExecutable) == 0
                obj.PythonExecutable = spectralab.drivers.spotread.ManualSafeBridge.findPython();
            end

            if strlength(obj.PythonExecutable) == 0
                error("SpectraLab:Spotread:PythonNotFound", ...
                    ["ERROR [SPL-003]\n\n" + ...
                     "Python 3 was not found.\n\n" + ...
                     "What to do:\n" + ...
                     "1. Install Python 3.\n" + ...
                     "2. Install pexpect in that Python environment.\n" + ...
                     "3. Restart MATLAB and run:\n\n" + ...
                     "    startup\n\n" + ...
                     "Advanced option: pass the executable path with:\n" + ...
                     "    spectralab.drivers.createInstrument(""spotread"", ""PythonExecutable"", ""/path/to/python3"")"]);
            end

            obj.Runner = spectralab.drivers.spotread.CommandRunner( ...
                obj.Executable, obj.TimeoutSeconds);

            obj.IsOpen = true;
        end

        function close(obj)
            obj.IsOpen = false;
        end

        function cal = calibrate(obj, mode)
            obj.requireOpen();
            if nargin < 2 || strlength(string(mode)) == 0
                mode = "interactive";
            end
            if lower(string(mode)) ~= "interactive"
                error("SpectraLab:Spotread:UnsupportedInteractionMode", ...
                    ["ERROR [SPL-015]\n\n" + ...
                     "Automatic mode is currently not supported by SpotreadInstrument.\n\n" + ...
                     "What to do:\n" + ...
                     "Use interactive mode:\n\n" + ...
                     "    sess = sess.calibrate(""Mode"", ""interactive"");"]);
            end

            data = struct();
            data.note = "spotread calibration is process-local and is performed inside measure().";
            data.backend = "manual-safe-one-spotread-session";
            data.executable = obj.Executable;
            data.python_executable = obj.PythonExecutable;

            cal = spectralab.core.Calibration.valid( ...
                obj.getInfo(), "spotread-one-session-ready", ...
                "Ready; calibration will occur in measurement session.", data);

            obj.LastCalibration = cal;
        end

        function spec = measure(obj, label, mode)
            obj.requireOpen();
            obj.requireCalibration();

            if nargin < 2 || strlength(string(label)) == 0
                label = "Spotread spectrum";
            end
            if nargin < 3 || strlength(string(mode)) == 0
                mode = "interactive";
            end
            if lower(string(mode)) ~= "interactive"
                error("SpectraLab:Spotread:UnsupportedInteractionMode", ...
                    ["ERROR [SPL-015]\n\n" + ...
                     "Automatic mode is currently not supported by SpotreadInstrument.\n\n" + ...
                     "What to do:\n" + ...
                     "Use interactive mode:\n\n" + ...
                     "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");"]);
            end

            r = spectralab.drivers.spotread.ManualSafeBridge.runMeasurement( ...
                obj.PythonExecutable, obj.Executable, obj.MeasurementOptions, obj.TimeoutSeconds);

            if r.status ~= 0
                if r.status == 26
                    error("SpectraLab:Spotread:UserInputBridgeTimeout", ...
                        ["ERROR [SPL-013]\n\n" + ...
                         "SpectraLab waited for ENTER, but the Python bridge did not receive keyboard input.\n\n" + ...
                         "What to do:\n" + ...
                         "1. Click in the MATLAB Command Window.\n" + ...
                         "2. Run:\n\n" + ...
                         "    startup\n" + ...
                         "    measure_led\n\n" + ...
                         "3. When asked, press ENTER in the MATLAB Command Window.\n" + ...
                         "4. If the problem repeats, restart MATLAB and try again."]);
                elseif r.status == 24
                    error("SpectraLab:Spotread:CommunicationsFailure", ...
                        ["ERROR [SPL-006]\n\n" + ...
                         "spotread reported a communications failure.\n\n" + ...
                         "What to do:\n" + ...
                         "1. Check that the instrument is connected by USB.\n" + ...
                         "2. Close other software that may be using the instrument.\n" + ...
                         "3. Unplug and reconnect the instrument.\n" + ...
                         "4. Run in a terminal:\n\n" + ...
                         "    spotread -e\n\n" + ...
                         "Then restart MATLAB and run startup again."]);
                else
                    error("SpectraLab:Spotread:BridgeFailed", ...
                        ["ERROR [SPL-007]\n\n" + ...
                         "The spotread bridge failed with status %d.\n\n" + ...
                         "What to do:\n" + ...
                         "1. Run spectralab.status() and check Python, pexpect and spotread.\n" + ...
                         "2. If all checks are OK, run spotread manually in a terminal.\n" + ...
                         "3. See docs/TROUBLESHOOTING.md."], r.status);
                end
            end

            rawFile = fullfile(tempdir, "spectralab_spotread_last_output.txt");
            if isfile(rawFile)
                rawOutput = string(fileread(rawFile));
            else
                rawOutput = r.output;
            end

            [wl, power, parseInfo] = spectralab.drivers.spotread.Parser.parseSpectrum(rawOutput);

            metadata = struct();
            metadata.backend = "spotread-manual-safe-one-session";
            metadata.command = r.command;
            metadata.status = r.status;
            metadata.raw_output = rawOutput;
            metadata.raw_output_file = rawFile;
            metadata.parse_info = parseInfo;
            metadata.calibration_note = "White-reference calibration performed in same spotread process.";

            spec = spectralab.core.Spectrum( ...
                wl, power, label, obj.getInfo(), obj.LastCalibration.toStruct(), metadata, "arbitrary");
        end
    end
end
