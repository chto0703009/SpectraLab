classdef Session
    %SESSION  High-level SpectraLab workflow controller.

    properties (SetAccess = private)
        Instrument = []
        State (1,1) string = "CREATED"
        History (:,1) string = strings(0,1)
        Operator (1,1) string = ""
        Comment (1,1) string = ""
        Project (1,1) string = ""
        SampleID (1,1) string = ""
        AudibleFeedback (1,1) logical = false
    end

    methods
        function obj = Session(instrument, options)
            arguments
                instrument
                options.Operator (1,1) string = ""
                options.Comment (1,1) string = ""
                options.Project (1,1) string = ""
                options.SampleID (1,1) string = ""
                options.AudibleFeedback = []
            end

            if isempty(instrument)
                error("SpectraLab:Session:MissingInstrument", ...
                    "A spectralab.core.Instrument instance is required.");
            end
            if ~isa(instrument, "spectralab.core.Instrument")
                error("SpectraLab:Session:InvalidInstrument", ...
                    "Instrument must inherit from spectralab.core.Instrument.");
            end

            obj.Instrument = instrument;
            obj.Operator = spectralab.core.validateMetadataText( ...
                options.Operator, "Operator", MaxLength=200);
            obj.Comment = spectralab.core.validateMetadataText( ...
                options.Comment, "Comment", ...
                MaxLength=4000, AllowMultiline=true);
            obj.Project = spectralab.core.validateMetadataText( ...
                options.Project, "Project", MaxLength=200);
            obj.SampleID = spectralab.core.validateMetadataText( ...
                options.SampleID, "SampleID", MaxLength=200);

            obj.AudibleFeedback = ...
                spectralab.core.Session.resolveAudibleFeedback( ...
                    instrument, ...
                    options.AudibleFeedback);

            obj = obj.log("Session created.");

            if strlength(obj.Operator) > 0
                obj = obj.log("Session operator set to " + obj.Operator + ".");
            end

            if strlength(obj.Comment) > 0
                obj = obj.log("Session comment set.");
            end

            if strlength(obj.Project) > 0
                obj = obj.log("Session project set to " + obj.Project + ".");
            end

            if strlength(obj.SampleID) > 0
                obj = obj.log("Session sample set to " + obj.SampleID + ".");
            end
        end

        function obj = withOperator(obj, operator)
            %WITHOPERATOR Return a session with an updated operator.
            arguments
                obj
                operator (1,1) string
            end

            obj.Operator = spectralab.core.validateMetadataText( ...
                operator, "Operator", MaxLength=200);

            if strlength(obj.Operator) == 0
                obj = obj.log("Session operator cleared.");
            else
                obj = obj.log("Session operator set to " + obj.Operator + ".");
            end
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
            obj.requireSupportedInteractionMode(mode);

            obj.prepareStartFeedback(mode);

            try
                cal = obj.Instrument.calibrate(mode);

                if ~isa(cal, "spectralab.core.Calibration") || ~cal.IsValid
                    obj.State = "CALIBRATION_FAILED";

                    error( ...
                        "SpectraLab:Session:CalibrationFailed", ...
                        "Calibration failed or returned invalid calibration.");
                end

            catch ME
                obj.playAudibleFeedback("error");
                if strcmp(ME.identifier, ...
                        "SpectraLab:Spotread:NoLightDetected")
                    throwAsCaller(ME)
                end
                rethrow(ME)
            end

            obj.playAudibleFeedback("success");

            obj.State = "CALIBRATED";
            obj = obj.log("Calibration OK.");
        end

        function obj = withComment(obj, comment)
            %WITHCOMMENT Return a session with an updated measurement comment.
            arguments
                obj
                comment (1,1) string
            end

            obj.Comment = spectralab.core.validateMetadataText( ...
                comment, "Comment", ...
                MaxLength=4000, AllowMultiline=true);

            if strlength(obj.Comment) == 0
                obj = obj.log("Session comment cleared.");
            else
                obj = obj.log("Session comment updated.");
            end
        end

        function obj = withProject(obj, project)
            %WITHPROJECT Return a session with an updated project identifier.
            arguments
                obj
                project (1,1) string
            end

            obj.Project = spectralab.core.validateMetadataText( ...
                project, "Project", MaxLength=200);

            if strlength(obj.Project) == 0
                obj = obj.log("Session project cleared.");
            else
                obj = obj.log("Session project updated to " + obj.Project + ".");
            end
        end

        function obj = withSample(obj, sampleID)
            %WITHSAMPLE Return a session with an updated sample identifier.
            arguments
                obj
                sampleID (1,1) string
            end

            obj.SampleID = spectralab.core.validateMetadataText( ...
                sampleID, "SampleID", MaxLength=200);

            if strlength(obj.SampleID) == 0
                obj = obj.log("Session sample cleared.");
            else
                obj = obj.log("Session sample updated to " + obj.SampleID + ".");
            end
        end

        function status = status(obj)
            details = struct();
            details.state = obj.State;
            details.instrument = obj.Instrument.getInfo();
            details.has_valid_calibration = obj.Instrument.hasValidCalibration();
            details.operator = obj.Operator;
            details.comment = obj.Comment;
            details.project = obj.Project;
            details.sample_id = obj.SampleID;
            details.audible_feedback = obj.AudibleFeedback;
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
            obj.requireSupportedInteractionMode(mode);

            obj.prepareStartFeedback(mode);

            try
                spec = obj.Instrument.measure(label, mode);

                if ~isa(spec, "spectralab.core.Spectrum")
                    error( ...
                        "SpectraLab:Session:InvalidMeasurement", ...
                        "Instrument returned invalid measurement object.");
                end

            catch ME
                obj.playAudibleFeedback("error");
                rethrow(ME)
            end

            obj.playAudibleFeedback("success");

            spec = spec.withMetadataField("Operator", obj.Operator);
            spec = spec.withMetadataField("Comment", obj.Comment);
            spec = spec.withMetadataField("Project", obj.Project);
            spec = spec.withMetadataField("SampleID", obj.SampleID);
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
        function enabled = resolveAudibleFeedback(instrument, requestedValue)
            %RESOLVEAUDIBLEFEEDBACK Resolve the session UX default.
            %
            % Physical instruments use audible feedback by default.
            % Mock instruments remain quiet unless explicitly enabled.

            if isempty(requestedValue)
                enabled = ~isa( ...
                    instrument, ...
                    "spectralab.drivers.MockInstrument");

                return
            end

            if ~(islogical(requestedValue) && isscalar(requestedValue))
                error( ...
                    "SpectraLab:Session:InvalidAudibleFeedback", ...
                    "AudibleFeedback must be true or false.");
            end

            enabled = requestedValue;
        end

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
            %   Support for "automatic" is decided by the selected driver.

            mode = "interactive";

            if isempty(varargin)
                return
            end

            % Positional mode syntax, kept for readability and backward
            % compatibility with positional interactive examples.
            if isscalar(varargin)
                token = lower(strtrim(string(varargin{1})));
                mode = spectralab.core.Session.validateInteractionMode(token);
                return
            end

            % Name-value syntax. This is the recommended public form for
            % scripts because it makes the interactive workflow explicit.
            if mod(numel(varargin), 2) ~= 0
                error("SpectraLab:Session:InvalidInteractionMode", ...
                    "ERROR [SPL-014]\n\n" + ...
                    "Invalid interaction mode syntax.\n\n" + ...
                    "What to do:\n" + ...
                    "Use one of these forms:\n\n" + ...
                    "    sess = sess.calibrate();\n" + ...
                    "    sess = sess.calibrate(""Mode"", ""interactive"");\n" + ...
                    "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");");
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
                                "ERROR [SPL-014]\n\n" + ...
                                "The Interactive option must be true or false.\n\n" + ...
                                "What to do:\n" + ...
                                "Prefer the explicit mode syntax:\n\n" + ...
                                "    sess = sess.calibrate(""Mode"", ""interactive"");");
                        end

                    otherwise
                        error("SpectraLab:Session:UnknownOption", ...
                            "ERROR [SPL-014]\n\n" + ...
                            "Unknown option:\n\n" + ...
                            "    %s\n\n" + ...
                            "Supported option:\n\n" + ...
                            "    Mode\n\n" + ...
                            "Example:\n\n" + ...
                            "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");", ...
                            string(varargin{k}));
                end
            end
        end

        function mode = validateInteractionMode(value)
            mode = lower(strtrim(string(value)));

            if mode == "interactive"
                return
            end

            if mode == "automatic"
                return
            end

            error("SpectraLab:Session:UnknownInteractionMode", ...
                "ERROR [SPL-014]\n\n" + ...
                "Unknown interaction mode:\n\n" + ...
                "    %s\n\n" + ...
                "Supported modes:\n\n" + ...
                "    interactive\n" + ...
                "    automatic  (when supported by the selected driver)\n\n" + ...
                "What to do:\n" + ...
                "Use:\n\n" + ...
                "    sess = sess.calibrate(""Mode"", ""interactive"");\n" + ...
                "    spec = sess.measure(""LED spectrum"", ""Mode"", ""interactive"");", ...
                mode);
        end
    end

    methods (Access = private)
        function requireSupportedInteractionMode(obj, mode)
            if obj.Instrument.supportsInteractionMode(mode)
                return
            end

            error("SpectraLab:Session:AutomaticModeUnsupported", ...
                "ERROR [SPL-015]\n\n" + ...
                "The selected instrument driver does not support mode '%s'.\n\n" + ...
                "What to do:\n" + ...
                "Use a mode supported by the instrument, for example:\n\n" + ...
                "    sess = sess.calibrate(""Mode"", ""interactive"");", ...
                mode);
        end

        function playAudibleFeedback(obj, eventName)
            %PLAYAUDIBLEFEEDBACK Play optional non-critical UX feedback.

            if ~obj.AudibleFeedback
                return
            end

            spectralab.ui.playFeedback(eventName);
        end


        function prepareStartFeedback(obj, mode)
            if obj.Instrument.synchronizesStartFeedback(mode)
                obj.Instrument.setOperationStartFeedback( ...
                    @() obj.playAudibleFeedback("start"));
            else
                obj.playAudibleFeedback("start");
            end
        end

        function obj = log(obj, msg)
            stamp = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
            obj.History(end+1,1) = stamp + "  " + string(msg);
        end
    end
end
