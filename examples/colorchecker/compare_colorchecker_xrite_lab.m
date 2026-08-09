function [comparison, csvFile] = compare_colorchecker_xrite_lab(options)
%COMPARE_COLORCHECKER_XRITE_LAB Compare measured and nominal chart Lab.
%
% Compare a converted SpectraLab ColorChecker session with a user-supplied
% nominal X-Rite Digital ColorChecker SG CIELAB text file.
% The comparison is valid for D50 and the CIE 1931 2 degree observer.
% This is a measurement-chain consistency check, not a formal metrological
% comparison: nominal and measured data were acquired at different places,
% with different instruments and under different practical conditions.
%
% Output columns contain nominal and measured Lab values plus
% dL = measured L* - nominal L*. Values are written with two decimals.
%
% Official X-Rite references:
%   https://www.xrite.com/categories/calibration-profiling/colorchecker-digital-sg
%   https://www.xrite.com/-/media/xrite/files/apps_engineering_techdocuments/c/custom_reference_data_en.pdf

arguments
    options.JsonFile (1,1) string = ""
    options.NominalFile (1,1) string = ""
end

scriptFolder = string(fileparts(mfilename("fullpath")));
nominalFile = options.NominalFile;
if nominalFile == ""
    [nominalName, nominalFolder] = uigetfile( ...
        {"*.txt", "Nominal ColorChecker Lab text (*.txt)"}, ...
        "SpectraLab - Select nominal X-Rite Lab file", scriptFolder);
    if isequal(nominalName, 0)
        comparison = table();
        csvFile = "";
        disp("ColorChecker comparison cancelled. Nothing was saved.");
        return
    end
    nominalFile = string(fullfile(nominalFolder, nominalName));
end

if ~isfile(nominalFile)
    error("SpectraLab:Examples:XriteNominalFileNotFound", ...
        "X-Rite nominal Lab file not found:\n%s", nominalFile);
end

jsonFile = options.JsonFile;
if jsonFile == ""
    [jsonName, jsonFolder] = uigetfile( ...
        {"*.json", "Converted ColorChecker JSON (*.json)"}, ...
        "SpectraLab - Select converted ColorChecker JSON", ...
        scriptFolder);
    if isequal(jsonName, 0)
        comparison = table();
        csvFile = "";
        disp("ColorChecker comparison cancelled. Nothing was saved.");
        return
    end
    jsonFile = string(fullfile(jsonFolder, jsonName));
end
if ~isfile(jsonFile)
    error("SpectraLab:Examples:ColorCheckerJsonNotFound", ...
        "Converted ColorChecker JSON not found:\n%s", jsonFile);
end
jsonFolder = string(fileparts(jsonFile));

session = spectralab.colorchecker.load(jsonFile);
if ~isfield(session, "ColorimetryConversions") || ...
        isempty(session.ColorimetryConversions)
    error("SpectraLab:Examples:ColorimetryConversionMissing", ...
        "The selected JSON contains no ColorChecker colorimetry conversion.");
end
conversion = session.ColorimetryConversions(end);

illuminantLabel = string(conversion.Illuminant.Label);
observer = string(conversion.Observer);
if ~contains(upper(illuminantLabel), "D50") || observer ~= "CIE1931_2"
    error("SpectraLab:Examples:XriteComparisonConditionsMismatch", ...
        ["The X-Rite nominal values require D50 and CIE1931_2.\n" ...
         "Selected conversion: %s; %s."], illuminantLabel, observer);
end

[nominalPatch, nominalLab] = readNominalLab(nominalFile);
results = conversion.Results;
measuredPatch = string({results.Coordinate}).';
labResults = [results.Lab];
measuredLab = [[labResults.L]; [labResults.a]; [labResults.b]].';

validatePatchSet(nominalPatch, "X-Rite nominal file");
validatePatchSet(measuredPatch, "SpectraLab JSON");

expectedPatch = chartCoordinates(14, 10);
if ~isequal(sort(nominalPatch), sort(expectedPatch))
    error("SpectraLab:Examples:XritePatchSetMismatch", ...
        "The X-Rite file must contain every patch from A1 through N10.");
end
if ~isequal(sort(measuredPatch), sort(expectedPatch))
    error("SpectraLab:Examples:MeasuredPatchSetMismatch", ...
        "The SpectraLab JSON must contain every patch from A1 through N10.");
end

[found, nominalIndex] = ismember(expectedPatch, nominalPatch);
if ~all(found)
    error("SpectraLab:Examples:XritePatchMissing", ...
        "One or more required patches are missing from the X-Rite file.");
end
[found, measuredIndex] = ismember(expectedPatch, measuredPatch);
if ~all(found)
    error("SpectraLab:Examples:MeasuredPatchMissing", ...
        "One or more required patches are missing from the SpectraLab JSON.");
end

nominalLab = nominalLab(nominalIndex, :);
measuredLab = measuredLab(measuredIndex, :);
dL = measuredLab(:, 1) - nominalLab(:, 1);

comparison = table( ...
    expectedPatch, ...
    round(nominalLab(:, 1), 2), ...
    round(nominalLab(:, 2), 2), ...
    round(nominalLab(:, 3), 2), ...
    round(measuredLab(:, 1), 2), ...
    round(measuredLab(:, 2), 2), ...
    round(measuredLab(:, 3), 2), ...
    round(dL, 2), ...
    VariableNames=["Patch", ...
    "L_nominal", "a_nominal", "b_nominal", ...
    "L_measured", "a_measured", "b_measured", ...
    "dL_measured_minus_nominal"]);

[~, jsonBaseName] = fileparts(jsonFile);
csvFile = fullfile(string(jsonFolder), ...
    jsonBaseName + "_xrite_lab_chain_check.csv");
if isfile(csvFile)
    error("SpectraLab:Examples:XriteComparisonExists", ...
        "SpectraLab refuses to overwrite the comparison CSV:\n%s", csvFile);
end
writetable(comparison, csvFile);

fprintf("SpectraLab/X-Rite ColorChecker chain check created:\n");
fprintf("  Source JSON:   %s\n", jsonFile);
fprintf("  X-Rite values: %s\n", nominalFile);
fprintf("  CSV:           %s\n", csvFile);
fprintf("  dL definition: measured L* - nominal L*\n");
fprintf("  Patches:       %d\n", height(comparison));
fprintf("  Interpretation: consistency check, not formal validation\n");
end

function [patch, lab] = readNominalLab(file)
lines = readlines(file);
patch = strings(0, 1);
lab = zeros(0, 3);
for index = 1:numel(lines)
    pattern = "^\s*([A-N](?:10|[1-9]))\s+" + ...
        "([-+]?\d+(?:\.\d+)?)\s+" + ...
        "([-+]?\d+(?:\.\d+)?)\s+" + ...
        "([-+]?\d+(?:\.\d+)?)\s*$";
    tokens = regexp(char(lines(index)), char(pattern), ...
        'tokens', 'once');
    if isempty(tokens), continue, end
    patch(end+1, 1) = string(tokens{1}); %#ok<AGROW>
    lab(end+1, :) = str2double(tokens(2:4)); %#ok<AGROW>
end
if isempty(patch)
    error("SpectraLab:Examples:XriteNominalDataMissing", ...
        "No nominal patch Lab values could be read from:\n%s", file);
end
end

function validatePatchSet(patch, sourceName)
if numel(unique(patch)) ~= numel(patch)
    error("SpectraLab:Examples:DuplicateColorCheckerPatch", ...
        "%s contains duplicate patch identifiers.", sourceName);
end
end

function coordinates = chartCoordinates(columns, rows)
coordinates = strings(columns * rows, 1);
index = 0;
for row = 1:rows
    for column = 1:columns
        index = index + 1;
        coordinates(index) = string(char('A' + column - 1)) + string(row);
    end
end
end
