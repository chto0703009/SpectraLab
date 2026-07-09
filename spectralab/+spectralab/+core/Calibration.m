classdef Calibration
    %CALIBRATION  Instrument-independent calibration record.

    properties (SetAccess = private)
        IsValid (1,1) logical = false
        Timestamp (1,1) datetime
        Instrument struct = struct()
        Method (1,1) string = "unspecified"
        Message (1,1) string = ""
        Data struct = struct()
    end

    methods
        function obj = Calibration(isValid, instrument, method, message, data)
            if nargin < 1, isValid = false; end
            if nargin < 2 || isempty(instrument), instrument = struct(); end
            if nargin < 3 || strlength(string(method)) == 0, method = "unspecified"; end
            if nargin < 4, message = ""; end
            if nargin < 5 || isempty(data), data = struct(); end

            obj.IsValid = logical(isValid);
            obj.Timestamp = datetime("now", "TimeZone", "local");
            obj.Instrument = instrument;
            obj.Method = string(method);
            obj.Message = string(message);
            obj.Data = data;
        end

        function s = toStruct(obj)
            s = struct();
            s.type = "spectralab.core.Calibration";
            s.version = "0.5.0";
            s.is_valid = obj.IsValid;
            s.timestamp = char(obj.Timestamp);
            s.instrument = obj.Instrument;
            s.method = obj.Method;
            s.message = obj.Message;
            s.data = obj.Data;
        end
    end

    methods (Static)
        function obj = valid(instrument, method, message, data)
            if nargin < 4, data = struct(); end
            obj = spectralab.core.Calibration(true, instrument, method, message, data);
        end

        function obj = invalid(instrument, message)
            if nargin < 1, instrument = struct(); end
            if nargin < 2, message = "Calibration not valid."; end
            obj = spectralab.core.Calibration(false, instrument, "none", message, struct());
        end
    end
end
