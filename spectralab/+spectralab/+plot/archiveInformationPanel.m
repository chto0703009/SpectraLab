function panel = archiveInformationPanel(ax, spec, archive, options)
%ARCHIVEINFORMATIONPANEL Add measurement results and provenance beside plot.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    spec (1,1) spectralab.core.Spectrum
    archive (1,1) struct
    options.ArchiveName (1,1) string = ""
end

lines = [ ...
    "Measurement: " + archiveValue(archive, "Measurement.Name", spec.Label)
    "Project: " + archiveValue(archive, "Metadata.Project", "—")
    "Sample: " + archiveValue(archive, ...
        ["Measurement.Sample", "Metadata.Sample", "Metadata.SampleID"], "—")
    "Operator: " + archiveValue(archive, ...
        ["Measurement.Operator", "Metadata.Operator"], "—")
    "Date: " + archiveValue(archive, ...
        ["Measurement.Timestamp", "Measurement.Date", "Metadata.Date"], "—")
    "Instrument: " + archiveValue(archive, ...
        ["Instrument.Name", "Instrument.Model", "Instrument.Instrument"], "—")
    "Serial: " + archiveValue(archive, "Instrument.SerialNumber", "—")];
if options.ArchiveName ~= ""
    lines(end+1) = "Archive: " + options.ArchiveName;
end

if measurementKind(archive) == "emissive"
    summary = spec.summaryStruct();
    unit = string(spec.PowerUnit);
    if unit == "", unit = "spectral units"; end
    resultLines = [ ...
        compose("Integral: %.6g %s*nm", summary.integrated_power, unit)
        compose("Peak wavelength: %.2f nm", summary.peak_wavelength_nm)
        compose("Peak height: %.6g %s", summary.peak_power, unit)];
    lines = [lines(1); resultLines; lines(2:end)];
end

panel = spectralab.plot.reflectanceColorimetryPanel(ax, archive, ...
    AdditionalLines=lines, ShowColorimetryText=false);
end

function kind = measurementKind(archive)
kind = lower(archiveValue(archive, "Measurement.Context.Kind", ""));
if kind ~= "" || ~isfield(archive, "Derivation") || ...
        ~isfield(archive.Derivation, "Sources")
    return
end

sources = archive.Derivation.Sources;
kinds = strings(1, numel(sources));
for index = 1:numel(sources)
    filename = archiveValue(sources(index), "Filename", "");
    if filename == "" || ~isfile(filename), kind = ""; return, end
    try
        source = spectralab.archive.load(filename, Quiet=true, Validation="error");
    catch
        kind = "";
        return
    end
    kinds(index) = lower(archiveValue( ...
        source, "Measurement.Context.Kind", ""));
end
if ~isempty(kinds) && all(kinds ~= "") && all(kinds == kinds(1))
    kind = kinds(1);
end
end

function value = archiveValue(container, paths, fallback)
value = string(fallback);
for path = string(paths)
    current = container;
    found = true;
    for fieldName = split(path, ".").'
        if ~isstruct(current) || ~isscalar(current) || ...
                ~isfield(current, char(fieldName))
            found = false;
            break
        end
        current = current.(char(fieldName));
    end
    if found
        if isdatetime(current) && isscalar(current)
            candidate = string(current, "yyyy-MM-dd HH:mm:ss");
        else
            candidate = string(current);
        end
        if isscalar(candidate) && ~ismissing(candidate) && ...
                strlength(strtrim(candidate)) > 0
            value = strtrim(candidate);
            return
        end
    end
end
end
