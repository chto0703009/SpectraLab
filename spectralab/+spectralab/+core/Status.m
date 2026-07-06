classdef Status
    %STATUS  Small structured status object.

    properties
        Ok (1,1) logical = true
        Code (1,1) string = "OK"
        Message (1,1) string = ""
        Timestamp (1,1) datetime
        Details struct = struct()
    end

    methods
        function obj = Status(ok, code, message, details)
            if nargin < 1, ok = true; end
            if nargin < 2 || strlength(string(code)) == 0, code = "OK"; end
            if nargin < 3, message = ""; end
            if nargin < 4 || isempty(details), details = struct(); end

            obj.Ok = logical(ok);
            obj.Code = string(code);
            obj.Message = string(message);
            obj.Timestamp = datetime("now", "TimeZone", "local");
            obj.Details = details;
        end

        function s = toStruct(obj)
            s = struct();
            s.ok = obj.Ok;
            s.code = obj.Code;
            s.message = obj.Message;
            s.timestamp = char(obj.Timestamp);
            s.details = obj.Details;
        end
    end

    methods (Static)
        function obj = ok(message, details)
            if nargin < 1, message = "OK"; end
            if nargin < 2, details = struct(); end
            obj = spectralab.core.Status(true, "OK", message, details);
        end

        function obj = error(code, message, details)
            if nargin < 3, details = struct(); end
            obj = spectralab.core.Status(false, code, message, details);
        end
    end
end
