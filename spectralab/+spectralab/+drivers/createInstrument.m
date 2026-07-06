function inst = createInstrument(kind, varargin)
%CREATEINSTRUMENT  Create a SpectraLab instrument driver.

if nargin < 1 || strlength(string(kind)) == 0
    error("SpectraLab:Drivers:MissingKind", "ERROR [SPL-008]\n\nInstrument kind is required.\n\nWhat to do:\nUse for example:\n    spectralab.drivers.createInstrument(""spotread"")");
end

kind = lower(string(kind));

switch kind
    case {"mock", "simulated", "simulation"}
        inst = spectralab.drivers.MockInstrument(varargin{:});

    case {"spotread", "argyll", "i1pro2", "i1pro"}
        inst = spectralab.drivers.SpotreadInstrument(varargin{:});

    otherwise
        error("SpectraLab:Drivers:UnknownInstrument", ...
            "ERROR [SPL-009]\n\nUnknown instrument kind: %s\n\nWhat to do:\nUse one of:\n    spotread\n    mock", kind);
end

end
