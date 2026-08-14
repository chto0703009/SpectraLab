function confirmInstrumentPlacement(message)
%CONFIRMINSTRUMENTPLACEMENT Show a blocking instrument-placement dialog.
%
% Intended as SpotreadInstrument's PlacementConfirmation callback for
% operator-controlled measurement workflows. The modal dialog must be
% dismissed before calibration or measurement can begin.

arguments
    message (1,1) string
end

if usejava("desktop")
    uiwait(msgbox(char(message), ...
        "SpectraLab - Instrument placement", "warn", "modal"));
    return
end

fprintf("\nSpectraLab instrument placement:\n%s\n", message);
input("Press ENTER to continue, or Ctrl-C to abort: ", "s");
end
