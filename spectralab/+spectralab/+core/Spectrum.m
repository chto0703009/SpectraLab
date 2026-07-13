classdef Spectrum
    %SPECTRUM  Spectral measurement container.

    properties (SetAccess = private)
        WavelengthNm (:,1) double
        Power (:,1) double
        Label (1,1) string = "Spectrum"
        Timestamp (1,1) datetime
        Instrument struct = struct()
        Calibration struct = struct()
        Metadata struct = struct()
        PowerUnit (1,1) string = "arbitrary"
    end

    methods
        function obj = Spectrum(wavelengthNm, power, label, instrument, calibration, metadata, powerUnit)
            if nargin < 3 || strlength(string(label)) == 0, label = "Spectrum"; end
            if nargin < 4 || isempty(instrument), instrument = struct(); end
            if nargin < 5 || isempty(calibration), calibration = struct(); end
            if nargin < 6 || isempty(metadata), metadata = struct(); end
            if nargin < 7 || strlength(string(powerUnit)) == 0, powerUnit = "arbitrary"; end

            validateattributes(wavelengthNm, {'numeric'}, {'vector','real','finite','nonempty'});
            validateattributes(power, {'numeric'}, {'vector','real','finite','nonempty'});

            wavelengthNm = wavelengthNm(:);
            power = power(:);

            if numel(wavelengthNm) ~= numel(power)
                error("SpectraLab:Spectrum:SizeMismatch", ...
                    "Wavelength and power vectors must have the same length.");
            end
            if any(diff(wavelengthNm) <= 0)
                error("SpectraLab:Spectrum:WavelengthOrder", ...
                    "Wavelength vector must be strictly increasing.");
            end

            obj.WavelengthNm = wavelengthNm;
            obj.Power = power;
            obj.Label = string(label);
            obj.Timestamp = datetime("now", "TimeZone", "local");
            obj.Instrument = instrument;
            obj.Calibration = calibration;
            obj.Metadata = metadata;
            obj.PowerUnit = string(powerUnit);
        end

        function obj = withTimestamp(obj, timestamp)
            %WITHTIMESTAMP Return a spectrum with a preserved timestamp.
            arguments
                obj
                timestamp (1,1) datetime
            end

            obj.Timestamp = timestamp;
        end

        function p = integratedPower(obj)
            p = trapz(obj.WavelengthNm, obj.Power);
        end

        function [lambdaPeak, powerPeak] = peak(obj)
            [powerPeak, idx] = max(obj.Power);
            lambdaPeak = obj.WavelengthNm(idx);
        end

        function y = normalizedPower(obj)
            m = max(abs(obj.Power));
            if m == 0
                y = obj.Power;
            else
                y = obj.Power ./ m;
            end
        end

        function obj2 = normalize(obj)
            obj2 = spectralab.core.Spectrum( ...
                obj.WavelengthNm, obj.normalizedPower(), ...
                obj.Label + " normalized", obj.Instrument, obj.Calibration, ...
                obj.Metadata, "normalized");
        end

        function obj2 = withLabel(obj, label)
            obj2 = spectralab.core.Spectrum( ...
                obj.WavelengthNm, obj.Power, label, obj.Instrument, ...
                obj.Calibration, obj.Metadata, obj.PowerUnit);
        end

        function obj = withMetadataField(obj, name, value)
            %WITHMETADATAFIELD Return a copy with one metadata field updated.
            arguments
                obj
                name (1,1) string
                value
            end

            name = strtrim(name);

            if strlength(name) == 0
                error("SpectraLab:Spectrum:InvalidMetadataName", ...
                    "Metadata field name must not be empty.");
            end

            if ~isvarname(char(name))
                error("SpectraLab:Spectrum:InvalidMetadataName", ...
                    "'%s' is not a valid metadata field name.", name);
            end

            obj.Metadata.(char(name)) = value;
        end

        function out = toStruct(obj)
            out = struct();
            out.type = "spectralab.core.Spectrum";
            out.version = "0.5.1";
            out.label = obj.Label;
            out.timestamp = char(obj.Timestamp);
            out.wavelength_nm = obj.WavelengthNm;
            out.power = obj.Power;
            out.units = struct("wavelength", "nm", "power", obj.PowerUnit);
            out.instrument = obj.Instrument;
            out.calibration = obj.Calibration;
            out.metadata = obj.Metadata;
            out.summary = obj.summaryStruct();
        end

        function s = summaryStruct(obj)
            [lp, pp] = obj.peak();
            s = struct();
            s.samples = numel(obj.WavelengthNm);
            s.range_nm = [min(obj.WavelengthNm), max(obj.WavelengthNm)];
            s.peak_wavelength_nm = lp;
            s.peak_power = pp;
            s.integrated_power = obj.integratedPower();
        end

        function txt = summary(obj)
            ss = obj.summaryStruct();
            txt = sprintf([ ...
                "%s\n" + ...
                "  Samples:          %d\n" + ...
                "  Range:            %.1f - %.1f nm\n" + ...
                "  Peak wavelength:  %.1f nm\n" + ...
                "  Integrated power: %.6g %s*nm"], ...
                obj.Label, ss.samples, ss.range_nm(1), ss.range_nm(2), ...
                ss.peak_wavelength_nm, ss.integrated_power, obj.PowerUnit);
        end

        function plot(obj, varargin)
            plot(obj.WavelengthNm, obj.Power, varargin{:});
            grid on;
            xlabel("Wavelength (nm)");
            ylabel("Spectral power (" + obj.PowerUnit + ")");
            title(obj.Label, "Interpreter", "none");
        end

        function plotNormalized(obj, varargin)
            plot(obj.WavelengthNm, obj.normalizedPower(), varargin{:});
            grid on;
            xlabel("Wavelength (nm)");
            ylabel("Normalized spectral power");
            title(obj.Label + " normalized", "Interpreter", "none");
        end

        function d = compareTo(obj, other)
            if ~isa(other, "spectralab.core.Spectrum")
                error("SpectraLab:Spectrum:InvalidComparison", ...
                    "Can only compare to another Spectrum.");
            end

            commonWl = intersect(obj.WavelengthNm, other.WavelengthNm);
            if numel(commonWl) < 2
                error("SpectraLab:Spectrum:NoCommonGrid", ...
                    "Spectra do not share enough common wavelength samples.");
            end

            p1 = interp1(obj.WavelengthNm, obj.Power, commonWl);
            p2 = interp1(other.WavelengthNm, other.Power, commonWl);

            d = struct();
            d.wavelength_nm = commonWl;
            d.delta = p2 - p1;
            d.ratio = p2 ./ p1;
            d.label_a = obj.Label;
            d.label_b = other.Label;
            d.integrated_power_a = obj.integratedPower();
            d.integrated_power_b = other.integratedPower();
            d.integrated_power_ratio = d.integrated_power_b / d.integrated_power_a;
        end
    end

    methods (Static)
        function obj = fromStruct(s)
            required = ["wavelength_nm", "power"];
            for k = 1:numel(required)
                if ~isfield(s, required(k))
                    error("SpectraLab:Spectrum:InvalidStruct", ...
                        "Missing field '%s'.", required(k));
                end
            end

            label = "Spectrum";
            if isfield(s, "label"), label = s.label; end

            instrument = struct();
            if isfield(s, "instrument"), instrument = s.instrument; end

            calibration = struct();
            if isfield(s, "calibration"), calibration = s.calibration; end

            metadata = struct();
            if isfield(s, "metadata"), metadata = s.metadata; end

            powerUnit = "arbitrary";
            if isfield(s, "units") && isfield(s.units, "power")
                powerUnit = s.units.power;
            elseif isfield(s, "power_unit")
                powerUnit = s.power_unit;
            end

            obj = spectralab.core.Spectrum( ...
                s.wavelength_nm, s.power, label, instrument, calibration, metadata, powerUnit);

            if isfield(s, "timestamp")
                try
                    obj.Timestamp = datetime(s.timestamp);
                catch
                end
            end
        end
    end
end
