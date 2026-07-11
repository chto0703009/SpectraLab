classdef SpectrumCollection
    %SPECTRUMCOLLECTION  Container for several Spectrum objects.

    properties (SetAccess = private)
        Name (1,1) string = "Spectrum collection"
        Spectra cell = {}
        Timestamp (1,1) datetime
        Metadata struct = struct()
    end

    methods
        function obj = SpectrumCollection(name, metadata)
            if nargin >= 1 && strlength(string(name)) > 0
                obj.Name = string(name);
            end
            if nargin >= 2 && ~isempty(metadata)
                obj.Metadata = metadata;
            end
            obj.Timestamp = datetime("now", "TimeZone", "local");
        end

        function obj = add(obj, spec)
            if ~isa(spec, "spectralab.core.Spectrum")
                error("SpectraLab:Collection:InvalidSpectrum", ...
                    "Can only add spectralab.core.Spectrum objects.");
            end
            obj.Spectra{end+1} = spec;
        end

        function n = count(obj)
            n = numel(obj.Spectra);
        end

        function spec = get(obj, idx)
            spec = obj.Spectra{idx};
        end

        function labels = labels(obj)
            labels = strings(obj.count(), 1);
            for k = 1:obj.count()
                labels(k) = obj.Spectra{k}.Label;
            end
        end

        function s = summaryTable(obj)
            n = obj.count();
            label = strings(n,1);
            samples = zeros(n,1);
            range_min_nm = zeros(n,1);
            range_max_nm = zeros(n,1);
            peak_nm = zeros(n,1);
            integrated_power = zeros(n,1);

            for k = 1:n
                sp = obj.Spectra{k};
                ss = sp.summaryStruct();
                label(k) = sp.Label;
                samples(k) = ss.samples;
                range_min_nm(k) = ss.range_nm(1);
                range_max_nm(k) = ss.range_nm(2);
                peak_nm(k) = ss.peak_wavelength_nm;
                integrated_power(k) = ss.integrated_power;
            end

            s = table(label, samples, range_min_nm, range_max_nm, peak_nm, integrated_power);
        end

        function plotOverlay(obj, varargin)
            p = inputParser;
            addParameter(p, "Normalize", false, @(x)islogical(x) || isnumeric(x));
            parse(p, varargin{:});
            normalize = logical(p.Results.Normalize);

            if obj.count() == 0
                error("SpectraLab:Collection:Empty", "Collection is empty.");
            end

            holdState = ishold;
            hold on;

            for k = 1:obj.count()
                sp = obj.Spectra{k};
                if normalize
                    y = sp.normalizedPower();
                else
                    y = sp.Power;
                end
                plot(sp.WavelengthNm, y, "DisplayName", sp.Label);
            end

            grid on;
            xlabel("Wavelength (nm)");
            if normalize
                ylabel("Normalized spectral power");
            else
                ylabel("Spectral power");
            end
            title(obj.Name, "Interpreter", "none");
            legend("Interpreter", "none", "Location", "best");

            if ~holdState
                hold off;
            end
        end

        function doc = toStruct(obj)
            doc = struct();
            doc.type = "spectralab.core.SpectrumCollection";
            doc.version = "0.5.1";
            doc.name = obj.Name;
            doc.timestamp = char(obj.Timestamp);
            doc.metadata = obj.Metadata;
            doc.count = obj.count();
            doc.spectra = cell(1, obj.count());

            for k = 1:obj.count()
                doc.spectra{k} = obj.Spectra{k}.toStruct();
            end
        end
    end

    methods (Static)
        function obj = fromStruct(s)
            name = "Spectrum collection";
            if isfield(s, "name"), name = s.name; end

            metadata = struct();
            if isfield(s, "metadata"), metadata = s.metadata; end

            obj = spectralab.core.SpectrumCollection(name, metadata);

            if isfield(s, "timestamp")
                try
                    obj.Timestamp = datetime(s.timestamp);
                catch
                end
            end

            if isfield(s, "spectra")
                spectra = s.spectra;
                if isstruct(spectra)
                    for k = 1:numel(spectra)
                        obj = obj.add(spectralab.core.Spectrum.fromStruct(spectra(k)));
                    end
                elseif iscell(spectra)
                    for k = 1:numel(spectra)
                        obj = obj.add(spectralab.core.Spectrum.fromStruct(spectra{k}));
                    end
                end
            end
        end
    end
end
