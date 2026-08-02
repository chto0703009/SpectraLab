function txt = summary(archive)
%SUMMARY Return and optionally display a human-readable archive summary.
%
%   TXT = spectralab.archive.summary(archive)
%
%   spectralab.archive.summary(archive)
%
% When called without an output argument, the summary is printed.
% When called with an output argument, the formatted text is returned.
%
% The function accepts current archives and older archives with missing
% optional fields. Missing values are displayed as "not specified".

    arguments
        archive (1,1) struct
    end

    required = [ ...
        "Identity", ...
        "Version", ...
        "Measurement", ...
        "Metadata", ...
        "Instrument", ...
        "Quality" ...
    ];

    for k = 1:numel(required)
        if ~isfield(archive, required(k))
            error( ...
                "SpectraLab:Archive:InvalidArchive", ...
                "Archive is missing required field '%s'.", ...
                required(k));
        end
    end

    identityLines = [
        "Identity"
        "--------"
        "UUID          : " + displayValue( ...
            readText(archive.Identity, "UUID"))
        "Created       : " + displayValue( ...
            readDate(archive.Identity, "Created"))
        "Created by    : " + displayValue( ...
            readText(archive.Identity, "CreatedBy"))
        "Content hash  : " + displayValue(shortHash( ...
            readText(archive.Identity, "ContentHash")))
    ];

    versionLines = [
        "Version"
        "-------"
        "Format        : " + displayValue( ...
            readText(archive.Version, "Format"))
        "Archive       : " + displayValue( ...
            readText(archive.Version, "Version"))
        "Software      : " + displayValue( ...
            readText(archive.Version, "Software"))
    ];

    wavelength = readNumeric(archive.Measurement, "Wavelength");
    sampleCount = numel(wavelength);

    if sampleCount > 0
        rangeText = sprintf( ...
            "%.1f - %.1f nm", ...
            min(wavelength), ...
            max(wavelength));
    else
        rangeText = "not available";
    end

    measurementLines = [
        "Measurement"
        "-----------"
        "Name          : " + displayValue(readText( ...
            archive.Measurement, "Name"))
        "Operator      : " + displayValue(readText( ...
            archive.Measurement, "Operator"))
        "Timestamp     : " + displayValue(readDate( ...
            archive.Measurement, "Timestamp"))
        "Unit          : " + displayValue(readText( ...
            archive.Measurement, "Unit"))
        "Samples       : " + string(sampleCount)
        "Range         : " + rangeText
    ];

    instrumentLines = [
        "Instrument"
        "----------"
        "Name          : " + displayValue(readText( ...
            archive.Instrument, "Name"))
        "Driver        : " + displayValue(readText( ...
            archive.Instrument, "Driver"))
        "Serial number : " + displayValue(readText( ...
            archive.Instrument, "SerialNumber"))
        "Calibration ID: " + displayValue(readText( ...
            archive.Instrument, "CalibrationID"))
    ];

    metadataLines = [
        "Metadata"
        "--------"
        "Project       : " + displayValue(readText( ...
            archive.Metadata, "Project"))
        "Sample ID     : " + displayValue(readText( ...
            archive.Metadata, "SampleID"))
        "Description   : " + displayValue(readText( ...
            archive.Metadata, "Description"))
        "Laboratory    : " + displayValue(readText( ...
            archive.Metadata, "Laboratory"))
        "Tags          : " + displayValue(readTags( ...
            archive.Metadata, "Tags"))
        "Comment       : " + displayValue(readText( ...
            archive.Metadata, "Comment"))
    ];

    qualityLines = [
        "Quality"
        "-------"
        "Valid         : " + displayLogical(readLogical( ...
            archive.Quality, "Valid"))
        "Warning       : " + displayValue(readText( ...
            archive.Quality, "Warning"))
        "Saturated     : " + displayLogical(readLogical( ...
            archive.Quality, "Saturated"))
        "Signal level  : " + displayNumeric(readNumeric( ...
            archive.Quality, "SignalLevel"))
        "Comment       : " + displayValue(readText( ...
            archive.Quality, "Comment"))
    ];

    historyCount = 0;

    if isfield(archive, "History") && ~isempty(archive.History)
        historyCount = numel(archive.History);
    end

    historyLines = [
        "History"
        "-------"
        "Entries       : " + string(historyCount)
    ];

    lines = [
        "SpectraLab Archive Summary"
        "=========================="
        ""
        identityLines
        ""
        versionLines
        ""
        measurementLines
        ""
        instrumentLines
        ""
        metadataLines
        ""
        qualityLines
        ""
        historyLines
    ];

    txt = strjoin(lines, newline);

    if nargout == 0
        fprintf("%s\n", txt);
        clear txt
    end
end


function value = readText(source, candidates)
    value = "";

    if ~isstruct(source) || isempty(source)
        return
    end

    available = string(fieldnames(source));

    for candidate = string(candidates)
        index = find(strcmpi(available, candidate), 1);

        if ~isempty(index)
            raw = source.(char(available(index)));

            if isempty(raw)
                return
            end

            try
                converted = string(raw);
            catch
                return
            end

            if ~isempty(converted)
                value = strtrim(converted(1));
            end

            return
        end
    end
end


function value = readDate(source, candidates)
    value = readText(source, candidates);
end


function value = readNumeric(source, candidates)
    value = [];

    if ~isstruct(source) || isempty(source)
        return
    end

    available = string(fieldnames(source));

    for candidate = string(candidates)
        index = find(strcmpi(available, candidate), 1);

        if ~isempty(index)
            raw = source.(char(available(index)));

            if isnumeric(raw)
                value = raw;
            end

            return
        end
    end
end


function value = readLogical(source, candidates)
    value = [];

    if ~isstruct(source) || isempty(source)
        return
    end

    available = string(fieldnames(source));

    for candidate = string(candidates)
        index = find(strcmpi(available, candidate), 1);

        if ~isempty(index)
            raw = source.(char(available(index)));

            if islogical(raw) && isscalar(raw)
                value = raw;
            end

            return
        end
    end
end


function value = readTags(source, candidates)
    value = "";

    if ~isstruct(source) || isempty(source)
        return
    end

    available = string(fieldnames(source));

    for candidate = string(candidates)
        index = find(strcmpi(available, candidate), 1);

        if ~isempty(index)
            raw = source.(char(available(index)));

            if isempty(raw)
                return
            end

            try
                tags = string(raw);
            catch
                return
            end

            tags = tags(strlength(tags) > 0);

            if ~isempty(tags)
                value = strjoin(tags(:).', ", ");
            end

            return
        end
    end
end


function value = displayValue(value)
    value = string(value);

    if isempty(value) || strlength(value(1)) == 0
        value = "not specified";
    else
        value = value(1);
    end
end


function value = displayLogical(value)
    if isempty(value)
        value = "not specified";
    elseif value
        value = "yes";
    else
        value = "no";
    end
end


function value = displayNumeric(value)
    if isempty(value)
        value = "not specified";
    elseif isscalar(value)
        value = string(value);
    else
        value = strjoin(string(value(:).'), ", ");
    end
end


function value = shortHash(value)
    value = string(value);

    if strlength(value) > 16
        value = extractBefore(value, 17) + "...";
    end
end
