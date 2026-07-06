classdef MockInstrument < spectralab.core.Instrument
    %MOCKINSTRUMENT  Simulated instrument for testing.

    properties
        NoiseLevel (1,1) double = 0.01
        Scale (1,1) double = 1.0
    end

    methods
        function obj = MockInstrument(varargin)
            if ~isempty(varargin)
                for k = 1:2:numel(varargin)
                    switch lower(string(varargin{k}))
                        case "noiselevel"
                            obj.NoiseLevel = varargin{k+1};
                        case "scale"
                            obj.Scale = varargin{k+1};
                        otherwise
                            error("SpectraLab:MockInstrument:UnknownOption", ...
                                "Unknown option: %s", string(varargin{k}));
                    end
                end
            end
        end

        function info = getInfo(obj)
            info = struct();
            info.name = "SpectraLab MockInstrument";
            info.driver = "spectralab.drivers.MockInstrument";
            info.serial = "MOCK-0001";
            info.version = spectralab.version();
            info.is_open = obj.IsOpen;
            info.scale = obj.Scale;
        end

        function open(obj)
            obj.IsOpen = true;
        end

        function close(obj)
            obj.IsOpen = false;
        end

        function cal = calibrate(obj, mode)
            obj.requireOpen();
            if nargin < 2 || strlength(string(mode)) == 0
                mode = "interactive";
            end

            data = struct();
            data.white_reference = "simulated";
            data.dark_reference = "simulated";

            cal = spectralab.core.Calibration.valid( ...
                obj.getInfo(), "mock-white-dark", "Calibration OK.", data);

            obj.LastCalibration = cal;
        end

        function spec = measure(obj, label, mode)
            obj.requireOpen();
            obj.requireCalibration();
            if nargin < 3 || strlength(string(mode)) == 0
                mode = "interactive";
            end

            if nargin < 2 || strlength(string(label)) == 0
                label = "Mock spectrum";
            end

            wl = (380:5:740).';
            blue = exp(-0.5*((wl - 455)/18).^2);
            green = 0.65 * exp(-0.5*((wl - 535)/35).^2);
            red = 0.45 * exp(-0.5*((wl - 625)/28).^2);
            baseline = 0.03;

            y = obj.Scale * (baseline + blue + green + red);
            y = y + obj.NoiseLevel * randn(size(y));
            y(y < 0) = 0;

            metadata = struct();
            metadata.note = "Simulated RGB-like LED spectrum.";
            metadata.measurement_context = "Simulated test source";

            spec = spectralab.core.Spectrum( ...
                wl, y, label, obj.getInfo(), obj.LastCalibration.toStruct(), metadata, "arbitrary");
        end
    end
end
