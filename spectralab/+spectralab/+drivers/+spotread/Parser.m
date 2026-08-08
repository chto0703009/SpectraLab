classdef Parser
    %PARSER  Parser for selected spotread textual output.

    methods (Static)
        function ok = calibrationSucceeded(output, status)
            txt = lower(string(output));
            failureWords = ["failed", "failure", "error", "communications failure", ...
                "instrument initialisation failed"];
            hasFailure = false;
            for k = 1:numel(failureWords)
                hasFailure = hasFailure || contains(txt, failureWords(k));
            end
            ok = (status == 0) && ~hasFailure;
        end

        function [wl, power, info] = parseSpectrum(output)
            txt = string(output);
            txt = spectralab.drivers.spotread.Parser.extractRawBlock(txt);

            [wl, power, ok] = spectralab.drivers.spotread.Parser.parseArgyllSpectrumBlock(txt);
            if ok
                info = struct();
                info.parser = "spectralab.drivers.spotread.Parser";
                info.samples = numel(wl);
                info.range_nm = [min(wl), max(wl)];
                info.note = "Parsed ArgyllCMS spotread -s spectrum block.";
                return
            end

            lines = splitlines(txt);
            wl = [];
            power = [];

            for i = 1:numel(lines)
                line = strtrim(lines(i));
                if strlength(line) == 0, continue; end

                nums = regexp(char(line), '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
                if numel(nums) < 2, continue; end

                vals = str2double(nums);
                if any(isnan(vals)), continue; end

                candidateWl = vals(1);
                candidatePower = vals(2);

                if candidateWl >= 300 && candidateWl <= 900
                    wl(end+1,1) = candidateWl; %#ok<AGROW>
                    power(end+1,1) = candidatePower; %#ok<AGROW>
                end
            end

            if numel(wl) < 3
                error("SpectraLab:Spotread:ParseFailed", ...
                    "Could not parse spectrum from spotread output.");
            end

            [wl, idx] = sort(wl);
            power = power(idx);
            [wl, uniqueIdx] = unique(wl, "stable");
            power = power(uniqueIdx);

            info = struct();
            info.parser = "spectralab.drivers.spotread.Parser";
            info.samples = numel(wl);
            info.range_nm = [min(wl), max(wl)];
            info.note = "Parsed generic spectral wavelength/power data.";
        end

        function [wl, power, info] = parseSpectrumFile(filename)
            filename = string(filename);
            if ~isfile(filename)
                error("SpectraLab:Spotread:SpectrumFileMissing", ...
                    "Spotread spectrum file was not created: %s", filename);
            end

            txt = string(fileread(filename));
            bands = readHeaderNumber(txt, "SPECTRAL_BANDS");
            startNm = readHeaderNumber(txt, "SPECTRAL_START_NM");
            endNm = readHeaderNumber(txt, "SPECTRAL_END_NM");

            dataTokens = regexp(char(txt), ...
                'BEGIN_DATA[ \t]*\r?\n([\s\S]*?)\r?\nEND_DATA(?:\r?\n|$)', ...
                'tokens', 'once');
            if isempty(dataTokens)
                error("SpectraLab:Spotread:InvalidSpectrumFile", ...
                    "Spotread spectrum file contains no data block.");
            end

            numbers = regexp(dataTokens{1}, ...
                '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
            power = str2double(numbers(:));
            if numel(power) ~= bands || any(~isfinite(power))
                error("SpectraLab:Spotread:InvalidSpectrumFile", ...
                    "Spotread spectrum file expected %d finite values but contained %d.", ...
                    bands, numel(power));
            end

            wl = linspace(startNm, endNm, bands).';
            info = struct();
            info.parser = "spectralab.drivers.spotread.Parser";
            info.format = "Argyll SPECT";
            info.samples = bands;
            info.range_nm = [startNm, endNm];
            info.filename = filename;
        end

        function colorimetry = parseColorimetry(output)
            %PARSECOLORIMETRY Parse Spotread's derived XYZ and Lab result.

            colorimetry = struct( ...
                "available", false, ...
                "xyz", zeros(0,1), ...
                "lab", zeros(0,1), ...
                "illuminant", "", ...
                "source", "spotread Result is XYZ");
            tokens = regexp(char(string(output)), ...
                ['Result is XYZ:\s*' ...
                 '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s+' ...
                 '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s+' ...
                 '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s*,\s*' ...
                 '([^\s,]+)\s+Lab:\s*' ...
                 '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s+' ...
                 '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s+' ...
                 '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)'], ...
                "tokens", "once");
            if isempty(tokens)
                return
            end

            values = str2double(tokens([1 2 3 5 6 7]));
            if any(~isfinite(values))
                return
            end
            colorimetry.available = true;
            colorimetry.xyz = values(1:3).';
            colorimetry.lab = values(4:6).';
            colorimetry.illuminant = string(tokens{4});
        end

        function raw = extractRawBlock(output)
            txt = char(string(output));

            hiddenExpr = '__SPECTRALAB_RAW_FILE__(.*?)__END_SPECTRALAB_RAW_FILE__';
            hiddenTokens = regexp(txt, hiddenExpr, 'tokens');
            if ~isempty(hiddenTokens)
                candidate = strtrim(hiddenTokens{end}{1});
                if isfile(candidate)
                    raw = string(fileread(candidate));
                    return
                end
            end

            fileExpr = 'SPECTRALAB_RAW_FILE:\s*(.*)';
            fileTokens = regexp(txt, fileExpr, 'tokens');
            if ~isempty(fileTokens)
                candidate = strtrim(fileTokens{end}{1});
                if isfile(candidate)
                    raw = string(fileread(candidate));
                    return
                end
            end

            blockExpr = 'SPECTRALAB_RAW_BEGIN\s*([\s\S]*?)\s*SPECTRALAB_RAW_END';
            blockTokens = regexp(txt, blockExpr, 'tokens');
            if ~isempty(blockTokens)
                raw = string(blockTokens{end}{1});
            else
                raw = string(output);
            end
        end

        function [wl, power, ok] = parseArgyllSpectrumBlock(output)
            txt = char(string(output));

            expr = ['Spectrum from\s+' ...
                    '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s+to\s+' ...
                    '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s+nm\s+in\s+' ...
                    '(\d+)\s+steps\s*([\s\S]*?)(?:Peak value|Result is XYZ|SPECTRALAB_DONE|$)'];

            tokens = regexp(txt, expr, 'tokens');
            ok = ~isempty(tokens);
            wl = [];
            power = [];

            if ~ok
                return
            end

            tok = tokens{end};
            startNm = str2double(tok{1});
            endNm = str2double(tok{2});
            nSteps = str2double(tok{3});
            dataBlock = tok{4};

            nums = regexp(dataBlock, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
            vals = str2double(nums);
            vals = vals(isfinite(vals));

            if numel(vals) < nSteps
                ok = false;
                return
            end

            vals = vals(1:nSteps);
            wl = linspace(startNm, endNm, nSteps).';
            power = vals(:);
            ok = true;
        end
    end
end

function value = readHeaderNumber(text, fieldName)
expression = [char(fieldName), '\s+"?', ...
    '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)"?'];
token = regexp(char(text), expression, 'tokens', 'once');
if isempty(token)
    error("SpectraLab:Spotread:InvalidSpectrumFile", ...
        "Spotread spectrum file is missing %s.", fieldName);
end
value = str2double(token{1});
if ~isfinite(value) || (fieldName == "SPECTRAL_BANDS" && ...
        (value < 1 || value ~= fix(value)))
    error("SpectraLab:Spotread:InvalidSpectrumFile", ...
        "Spotread spectrum file has invalid %s.", fieldName);
end
end
