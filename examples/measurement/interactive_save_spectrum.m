% interactive_save_spectrum
%
% Save MEAS from an interactive measurement. Run one of the interactive
% setup examples first; this wrapper delegates to the shared private saver.

requiredVariables = ["MEAS", "measurementName", "outputRoot"];
for variableName = requiredVariables
    if ~exist(variableName, "var")
        error("SpectraLab:Examples:MissingInteractiveState", ...
            "Required workspace variable '%s' is missing.", variableName);
    end
end

saveInfo = internal_save_spectrum_outputs( ...
    MEAS, string(measurementName), string(outputRoot));
