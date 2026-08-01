classdef (Abstract) Instrument < handle
    %INSTRUMENT  Abstract base class for all SpectraLab instruments.

    properties (SetAccess = protected)
        IsOpen (1,1) logical = false
        LastCalibration spectralab.core.Calibration = spectralab.core.Calibration.invalid()
    end

    methods (Abstract)
        info = getInfo(obj)
        open(obj)
        close(obj)
        cal = calibrate(obj, varargin)
        spec = measure(obj, label, varargin)
    end

    methods
        function tf = hasValidCalibration(obj)
            tf = ~isempty(obj.LastCalibration) && obj.LastCalibration.IsValid;
        end

        function requireOpen(obj)
            if ~obj.IsOpen
                error("SpectraLab:Instrument:NotOpen", ...
                    "Instrument is not open.");
            end
        end

        function requireCalibration(obj)
            if ~obj.hasValidCalibration()
                error("SpectraLab:Instrument:NotCalibrated", ...
                    "Instrument has no valid calibration. Run calibrate() first.");
            end
        end

        function tf = supportsInteractionMode(~, mode)
            %SUPPORTSINTERACTIONMODE Report modes implemented by a driver.
            tf = lower(strtrim(string(mode))) == "interactive";
        end
    end
end
