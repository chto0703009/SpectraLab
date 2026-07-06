classdef MeasurementResult
    %MEASUREMENTRESULT  Result wrapper for measurement attempts.

    properties
        Success (1,1) logical = false
        Spectrum = []
        Status spectralab.core.Status = spectralab.core.Status.error("UNSET", "No result.")
        Timestamp (1,1) datetime
    end

    methods
        function obj = MeasurementResult(success, spectrum, status)
            if nargin < 1, success = false; end
            if nargin < 2, spectrum = []; end
            if nargin < 3 || isempty(status)
                if success
                    status = spectralab.core.Status.ok("Measurement OK.");
                else
                    status = spectralab.core.Status.error("FAILED", "Measurement failed.");
                end
            end

            obj.Success = logical(success);
            obj.Spectrum = spectrum;
            obj.Status = status;
            obj.Timestamp = datetime("now", "TimeZone", "local");
        end

        function s = toStruct(obj)
            s = struct();
            s.success = obj.Success;
            s.timestamp = char(obj.Timestamp);
            s.status = obj.Status.toStruct();

            if obj.Success && isa(obj.Spectrum, "spectralab.core.Spectrum")
                s.spectrum = obj.Spectrum.toStruct();
            else
                s.spectrum = [];
            end
        end
    end

    methods (Static)
        function obj = ok(spec)
            obj = spectralab.core.MeasurementResult(true, spec, ...
                spectralab.core.Status.ok("Measurement OK."));
        end

        function obj = failed(code, message, details)
            if nargin < 3, details = struct(); end
            obj = spectralab.core.MeasurementResult(false, [], ...
                spectralab.core.Status.error(code, message, details));
        end
    end
end
