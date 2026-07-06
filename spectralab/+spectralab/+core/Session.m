classdef Session
    %SESSION  High-level SpectraLab workflow controller.

    properties (SetAccess = private)
        Instrument = []
        State (1,1) string = "CREATED"
        History (:,1) string = strings(0,1)
    end

    methods
        function obj = Session(instrument)
            if nargin < 1 || isempty(instrument)
                error("SpectraLab:Session:MissingInstrument", ...
                    "A spectralab.core.Instrument instance is required.");
            end
            if ~isa(instrument, "spectralab.core.Instrument")
                error("SpectraLab:Session:InvalidInstrument", ...
                    "Instrument must inherit from spectralab.core.Instrument.");
            end

            obj.Instrument = instrument;
            obj = obj.log("Session created.");
        end

        function obj = open(obj)
            obj.Instrument.open();
            obj.State = "READY";
            obj = obj.log("Instrument opened.");
        end

        function obj = close(obj)
            obj.Instrument.close();
            obj.State = "CLOSED";
            obj = obj.log("Instrument closed.");
        end

        function obj = calibrate(obj, varargin)
            %CALIBRATE Calibrate the instrument.
            %
            %   SESS = SESS.CALIBRATE() runs the default calibration workflow.
            %   SESS = SESS.CALIBRATE("Mode", "interactive") makes the
            %   user-guided calibration workflow explicit. This is
            %   recommended in scripts that require user action.
            obj.Instrument.requireOpen();
            mode = spectralab.core.Session.parseInteractionMode(varargin{:});
            cal = obj.Instrument.calibrate(mode);

            if ~isa(cal, "spectralab.core.Calibration") || ~cal.IsValid
                obj.State = "CALIBRATION_FAILED";
                obj = obj.log("Calibration failed.");
                error("SpectraLab:Session:CalibrationFailed", ...
                    "Calibration failed or returned invalid calibration.");
            end

            obj.State = "CALIBRATED";
            obj = obj.log("Calibration OK.");
        end

        function status = status(obj)
            details = struct();
            details.state = obj.State;
            details.instrument = obj.Instrument.getInfo();
            details.has_valid_calibration = obj.Instrument.hasValidCalibration();
            details.history = obj.History;

            status = spectralab.core.Status.ok("Session status.", details);
        end

        function spec = measure(obj, label, varargin)
            %MEASURE Acquire a spectrum.
            %
            %   SPEC = SESS.MEASURE(LABEL) measures a spectrum using the
            %   default workflow.
            %
            %   SPEC = SESS.MEASURE(LABEL, "Mode", "interactive") makes the
            %   user-guided measurement workflow explicit. This is
            %   recommended when SpectraLab is used inside larger MATLAB scripts.
            if nargin < 2 || strlength(string(label)) == 0
                label = "Spectrum";
            end

            obj.Instrument.requireOpen();
            obj.Instrument.requireCalibration();

            mode = spectralab.core.Session.parseInteractionMode(varargin{:});
            spec = obj.Instrument.measure(label, mode);

            if ~isa(spec, "spectralab.core.Spectrum")
                error("SpectraLab:Session:InvalidMeasurement", ...
                    "Instrument returned invalid measurement object.");
            end
        end

        function result = measureResult(obj, label, varargin)
            try
                spec = obj.measure(label, varargin{:});
                result = spectralab.core.MeasurementResult.ok(spec);
            catch ME
                details = struct();
                details.identifier = ME.identifier;
                details.message = ME.message;
                result = spectralab.core.MeasurementResult.failed( ...
                    ME.identifier, ME.message, details);
            end
        end

        function collection = measureMany(obj, labels)
            labels = string(labels);
            collection = spectralab.core.SpectrumCollection("SpectraLab measurement series");

            for k = 1:numel(labels)
                r = obj.measureResult(labels(k));
                if r.Success
                    collection = collection.add(r.Spectrum);
                else
                    warning("SpectraLab:Session:MeasurementSkipped", ...
                        "Measurement failed for '%s': %s", labels(k), r.Status.Message);
                end
            end
        end
    end

    methods (Static, Access = private)
        function mode = parseInteractionMode(varargin)
            %PARSEINTERACTIONMODE  Parse and validate measurement mode.
            %
            %   Default mode is "interactive".
            %
            %   Supported syntax:
            %       sess.calibrate()
            %       sess.calibrate("interactive")
            %       sess.calibrate("Mode", "interactive")
            %
            %   "automatic" is reserved for future instruments. It is
            %   recognized so users get a clear error instead of an
            %   ambiguous option failure.

            mode = "interactive";

            if isempty(varargin)
                return
            end

            % Positional mode syntax, kept for readability and backward
            % compatibility with positional interactive examples.
            if numel(varargin) == 1
                token = lower(strtrim(string(varargin{1})));
                mode = spectralab.core.Session.validateInteractionMode(token);
                return
            end

            % Name-value syntax. This is the recommended public form for
            % scripts because it makes the interactive workflow explicit.
            if mod(numel(varargin), 2) ~= 0
                error("SpectraLab:Session:InvalidInteractionMode", ...
                    ["ERROR [SPL-014]\n\n" + ...
                     "Invalid interaction mode syntax.\n\n" + ...
                     "What to do:\n" + ...
                     "Use one of these forms:\n\n" + ...
                     "    sess = sess.calibrate();\n" + ...
                     "    sess = sess.calibrate(""Mode"", ""interactive"");\n" + ...
                     "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");"]);
            end

            for k = 1:2:numel(varargin)
                name = lower(strtrim(string(varargin{k})));
                value = varargin{k+1};

                switch name
                    case "mode"
                        mode = spectralab.core.Session.validateInteractionMode(value);

                    case "interactive"
                        % Legacy compatibility for older scripts that used
                        % an Interactive logical option during development.
                        if islogical(value) && isscalar(value)
                            if value
                                mode = "interactive";
                            else
                                mode = "automatic";
                            end
                        else
                            error("SpectraLab:Session:InvalidInteractiveOption", ...
                                ["ERROR [SPL-014]\n\n" + ...
                                 "The Interactive option must be true or false.\n\n" + ...
                                 "What to do:\n" + ...
                                 "Prefer the explicit mode syntax:\n\n" + ...
                                 "    sess = sess.calibrate(""Mode"", ""interactive"");"]);
                        end

                    otherwise
                        error("SpectraLab:Session:UnknownOption", ...
                            ["ERROR [SPL-014]\n\n" + ...
                             "Unknown option:\n\n" + ...
                             "    %s\n\n" + ...
                             "Supported option:\n\n" + ...
                             "    Mode\n\n" + ...
                             "Example:\n\n" + ...
                             "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");"], string(varargin{k}));
                end
            end
        end

        function mode = validateInteractionMode(value)
            mode = lower(strtrim(string(value)));

            if mode == "interactive"
                return
            end

            if mode == "automatic"
                error("SpectraLab:Session:AutomaticModeUnsupported", ...
                    ["ERROR [SPL-015]\n\n" + ...
                     "Automatic mode is recognized, but is not supported by the current instrument workflow.\n\n" + ...
                     "What to do:\n" + ...
                     "Use interactive mode for instruments that require user placement and ENTER prompts:\n\n" + ...
                     "    sess = sess.calibrate(""Mode"", ""interactive"");\n" + ...
                     "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");\n\n" + ...
                     "Automatic mode is reserved for future instruments that can calibrate and measure without user input."]);
            end

            error("SpectraLab:Session:UnknownInteractionMode", ...
                ["ERROR [SPL-014]\n\n" + ...
                 "Unknown interaction mode:\n\n" + ...
                 "    %s\n\n" + ...
                 "Supported modes:\n\n" + ...
                 "    interactive\n" + ...
                 "    automatic  (reserved; not supported by the current instrument workflow)\n\n" + ...
                 "What to do:\n" + ...
                 "Use:\n\n" + ...
                 "    sess = sess.calibrate(""Mode"", ""interactive"");\n" + ...
                 "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");"], mode);
        end
    end

    methods (Access = private)
        function obj = log(obj, msg)
            stamp = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
            obj.History(end+1,1) = stamp + "  " + string(msg);
        end
    end
end
