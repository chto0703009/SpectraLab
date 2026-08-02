classdef OutcomeParser
    %OUTCOMEPARSER Classify one bounded Spotread operation.

    methods (Static)
        function outcome = classify(output, status, timedOut)
            if nargin < 2, status = 0; end
            if nargin < 3, timedOut = false; end

            raw = string(output);
            text = lower(raw);
            kind = "UNRECOGNIZED_OUTPUT";
            message = "Spotread output was not recognized.";
            calibrationWasRequired = containsAny(text, [ ...
                "calibration required", ...
                "needs calibration", ...
                "needs a calibration", ...
                "place instrument on its calibration", ...
                "place instrument on the calibration", ...
                "place instrument on white reference", ...
                "reflective white reference", ...
                "hit any key to continue"]);

            if timedOut || status == 124
                kind = "TIMEOUT";
                message = "Spotread did not finish before the timeout.";
            elseif containsAny(text, [ ...
                    "unknown, inappropriate or no instrument detected", ...
                    "no instrument detected"])
                kind = "INSTRUMENT_NOT_DETECTED";
                message = "Spotread did not detect a supported instrument. " + ...
                    "Reconnect the USB instrument and try again.";
            elseif containsAny(text, [ ...
                    "communications failure", ...
                    "instrument initialisation failed", ...
                    "instrument initialization failed", ...
                    "device or resource busy"])
                kind = "COMMUNICATION_FAILURE";
                message = "Spotread could not communicate with the instrument.";
            elseif containsAny(text, [ ...
                    "interrupted by user", "operation cancelled", ...
                    "operation canceled", "user aborted"])
                kind = "CANCELLED";
                message = "The Spotread operation was cancelled.";
            elseif containsAny(text, [ ...
                    "calibration failed", "calibration error"])
                kind = "CALIBRATION_FAILED";
                message = "Spotread reported failed calibration.";
            elseif hasSpectrum(raw)
                if status == 0
                    kind = "MEASUREMENT_SUCCEEDED";
                    message = "Spotread returned a complete spectral measurement.";
                else
                    kind = "PROCESS_FAILED";
                    message = "Spotread returned spectral text but exited with an error.";
                end
            elseif containsAny(text, [ ...
                    "calibration complete", ...
                    "calibration succeeded", ...
                    "calibration ok"])
                if status == 0
                    kind = "CALIBRATION_SUCCEEDED";
                    message = "Spotread reported successful calibration.";
                else
                    kind = "CALIBRATION_FAILED";
                    message = "Spotread calibration ended with an error status.";
                end
            elseif calibrationWasRequired
                kind = "CALIBRATION_REQUIRED";
                message = "Spotread requires instrument calibration.";
            elseif status ~= 0
                kind = "PROCESS_FAILED";
                message = "Spotread exited with an error status.";
            end

            outcome = struct();
            outcome.kind = kind;
            outcome.success = any(kind == [ ...
                "CALIBRATION_SUCCEEDED", "MEASUREMENT_SUCCEEDED"]);
            outcome.status = double(status);
            outcome.timed_out = logical(timedOut);
            outcome.message = message;
            outcome.raw_output = raw;
            outcome.calibration_was_required = calibrationWasRequired;
        end
    end
end

function tf = containsAny(text, patterns)
tf = false;
for index = 1:numel(patterns)
    tf = tf || contains(text, patterns(index));
end
end

function tf = hasSpectrum(output)
try
    [wavelength, power] = ...
        spectralab.drivers.spotread.Parser.parseSpectrum(output);
    tf = numel(wavelength) >= 3 && ...
        numel(wavelength) == numel(power) && ...
        all(isfinite(wavelength)) && all(isfinite(power));
catch
    tf = false;
end
end
