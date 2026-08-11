% calculate_colorchecker_colorimetry
%
% Work script for deriving ColorChecker XYZ and CIELAB from an immutable
% measurement session. The original session JSON and patch MAT archives
% are never modified. A separate suffixed JSON file is created.

if ~exist("exportCSV", "var")
    exportCSV = false;
end
% Set exportCSV=true before running to also save a traceable CSV.
colorimetryCsvFile = "";
createdNewConversion = false;

scriptFolder = string(fileparts(mfilename("fullpath")));
workRoot = string(fileparts(scriptFolder));
[sessionName, sessionFolder] = uigetfile( ...
    {"*.json", "ColorChecker session JSON (*.json)"}, ...
    "SpectraLab - Select original or converted ColorChecker JSON", ...
    workRoot);
if isequal(sessionName, 0)
    disp("ColorChecker colorimetry conversion cancelled. Nothing was saved.");
    return
end
selectedJsonFile = fullfile(string(sessionFolder), string(sessionName));
selectedManifest = jsondecode(fileread(selectedJsonFile));
selectedAmendment = isfield(selectedManifest, "Schema") && ...
    string(selectedManifest.Schema) == ...
        "spectralab.colorchecker-amendment.v1";
if selectedAmendment
    amendment = spectralab.colorchecker.loadRemeasurement(selectedJsonFile);
    if string(amendment.Identity.State) ~= "complete" || ...
            ~isfield(amendment, "Output")
        error("SpectraLab:Work:ColorCheckerAmendmentIncomplete", ...
            "The selected amendment is incomplete and has no corrected session.");
    end
    correctedFile = string(amendment.Output.CorrectedSessionFile);
    if ~isfile(correctedFile)
        correctedFile = fullfile(string(sessionFolder), correctedFile);
    end
    if ~isfile(correctedFile)
        error("SpectraLab:Work:CorrectedColorCheckerSessionMissing", ...
            "The corrected session recorded by the amendment could not be found.");
    end
    if fileSha256(correctedFile) ~= ...
            string(amendment.Output.CorrectedManifestSHA256)
        error("SpectraLab:Work:CorrectedColorCheckerSessionChanged", ...
            "The corrected session hash does not match the completed amendment.");
    end
    selectedJsonFile = correctedFile;
    [sessionFolder, sessionName] = fileparts(selectedJsonFile);
    fprintf("Selected amendment resolved to corrected session:\n  %s\n", ...
        selectedJsonFile);
end
selectedSession = spectralab.colorchecker.load(selectedJsonFile);
if selectedAmendment && string(selectedSession.Identity.UUID) ~= ...
        string(amendment.Output.CorrectedSessionUUID)
    error("SpectraLab:Work:CorrectedColorCheckerSessionIdentityMismatch", ...
        "The corrected session UUID does not match the completed amendment.");
end
isConvertedJson = isfield(selectedSession, "ColorimetryConversions") && ...
    ~isempty(selectedSession.ColorimetryConversions);

if isConvertedJson
    colorcheckerSession = selectedSession;
    colorimetryConversion = colorcheckerSession.ColorimetryConversions(end);
    convertedJsonFile = selectedJsonFile;
    sessionFile = string(colorimetryConversion.SourceSessionFile);
    if ~isfile(sessionFile)
        sessionFile = fullfile(string(sessionFolder), sessionFile);
    end
    if ~isfile(sessionFile)
        error("SpectraLab:Work:ConvertedColorimetrySourceMissing", ...
            "The source session recorded by the converted JSON could not be found.");
    end
    sourceSession = spectralab.colorchecker.load(sessionFile);
    if string(sourceSession.Identity.UUID) ~= ...
            string(colorimetryConversion.SourceSessionUUID)
        error("SpectraLab:Work:ConvertedColorimetrySourceMismatch", ...
            "The converted JSON does not match its recorded source session JSON.");
    end
    [convertedFolder, convertedBaseName] = fileparts(convertedJsonFile);
    expectedPdfFile = fullfile(convertedFolder, "report", ...
        string(convertedBaseName) + "_report.pdf");
    expectedCsvFile = fullfile(convertedFolder, ...
        string(convertedBaseName) + ".csv");
    illuminant = selectColorimetryIlluminant(workRoot);
    if isempty(illuminant)
        disp("ColorChecker colorimetry verification cancelled. Nothing was saved.");
        return
    end
else
    isOriginalSession = string(sessionName) == "colorchecker_session.json";
    isAmendedSession = startsWith(string(sessionName), ...
        "colorchecker_session_amended_") && ...
        isfield(selectedSession, "Derivation");
    if ~isOriginalSession && ~isAmendedSession
        error("SpectraLab:Work:UnsupportedColorCheckerJson", ...
            ["Select an original session, a controlled amended session, " ...
             "or a converted ColorChecker JSON."]);
    end
    sessionFile = selectedJsonFile;
    illuminant = selectColorimetryIlluminant(workRoot);
    if isempty(illuminant)
        disp("ColorChecker colorimetry conversion cancelled. Nothing was saved.");
        return
    end
    [expectedJsonFile, expectedPdfFile, expectedCsvFile] = ...
        spectralab.colorchecker.colorimetryOutputFiles( ...
            sessionFile, illuminant, "CIE1931_2");
    if isfile(expectedJsonFile)
        colorcheckerSession = ...
            spectralab.colorchecker.load(expectedJsonFile);
        colorimetryConversion = ...
            colorcheckerSession.ColorimetryConversions(end);
        if string(colorcheckerSession.Identity.UUID) ~= ...
                string(selectedSession.Identity.UUID) || ...
                string(colorimetryConversion.SourceSessionUUID) ~= ...
                    string(selectedSession.Identity.UUID) || ...
                string(colorimetryConversion.Observer) ~= "CIE1931_2" || ...
                string(colorimetryConversion.Illuminant.Label) ~= ...
                    string(illuminant.Label)
            error("SpectraLab:Work:ExistingColorimetryDoesNotMatch", ...
                "The existing converted JSON does not match the selected session and calculation settings.");
        end
        convertedJsonFile = expectedJsonFile;
    else
        [colorcheckerSession, colorimetryConversion, convertedJsonFile, ...
            colorimetryCsvFile] = ...
            spectralab.colorchecker.calculateColorimetry( ...
                sessionFile, Illuminant=illuminant, ...
                Observer="CIE1931_2", ExportCSV=exportCSV);
        createdNewConversion = true;
    end
end
verification = spectralab.colorchecker.verifyColorimetry( ...
    convertedJsonFile, Illuminant=illuminant);
if exportCSV && colorimetryCsvFile == ""
    if isfile(expectedCsvFile)
        colorimetryCsvFile = expectedCsvFile;
    else
        colorimetryCsvFile = ...
            spectralab.colorchecker.exportColorimetryCsv( ...
                colorimetryConversion, expectedCsvFile);
    end
end
if isfile(expectedPdfFile)
    colorimetryReport = struct( ...
        "PDFFile", expectedPdfFile, ...
        "ConvertedJsonFile", convertedJsonFile, ...
        "PatchCount", colorimetryConversion.PatchCount, ...
        "ContainsPlot", false, "ContainsXYZ", true, "ContainsLab", true);
else
    colorimetryReport = spectralab.colorchecker.generateColorimetryReport( ...
        convertedJsonFile, OpenPDF=false, ...
        VerificationIlluminant=illuminant);
end
open(char(colorimetryReport.PDFFile));

if createdNewConversion
    outcome = "ColorChecker colorimetry created.";
    consoleOutcome = "created";
else
    outcome = "Existing ColorChecker colorimetry recalculated and verified; the JSON was not rewritten.";
    consoleOutcome = "recalculated and verified (existing JSON preserved)";
end
message = outcome + newline + newline + ...
    "Patches: " + string(colorimetryConversion.PatchCount) + newline + ...
    "Illuminant: " + string(colorimetryConversion.Illuminant.Label) + newline + ...
    "Observer: " + string(colorimetryConversion.Observer) + newline + newline + ...
    "Recalculation verified: " + string(verification.Verified) + newline + ...
    "Maximum XYZ difference: " + ...
        string(verification.MaximumXYZDifference) + newline + ...
    "Maximum Lab difference: " + ...
        string(verification.MaximumLabDifference) + newline + newline + ...
    "Converted JSON:" + newline + convertedJsonFile + newline + newline + ...
    "PDF report:" + newline + colorimetryReport.PDFFile + newline + newline + ...
    csvMessage(colorimetryCsvFile) + ...
    "The original session JSON and MAT archives were not modified.";
uiwait(msgbox(message, ...
    "SpectraLab - ColorChecker colorimetry complete", "help", "modal"));

fprintf("SpectraLab ColorChecker colorimetry %s:\n", consoleOutcome);
fprintf("  Source session: %s\n", sessionFile);
fprintf("  Converted JSON: %s\n", convertedJsonFile);
fprintf("  PDF report: %s\n", colorimetryReport.PDFFile);
if colorimetryCsvFile ~= ""
    fprintf("  CSV export: %s\n", colorimetryCsvFile);
end

function value = csvMessage(csvFile)
if csvFile == ""
    value = "";
else
    value = "CSV export:" + newline + csvFile + newline + newline;
end
end

function illuminant = selectColorimetryIlluminant(workRoot)
choice = questdlg( ...
    "Select the illuminant spectrum for calculation and verification.", ...
    "SpectraLab - ColorChecker illuminant", ...
    "CIE D50", "CIE D65", "Other MAT spectrum", "CIE D50");
if isempty(choice)
    illuminant = [];
elseif choice == "CIE D50"
    illuminant = spectralab.filters.cie.d50();
elseif choice == "CIE D65"
    illuminant = spectralab.filters.cie.d65();
else
    [name, folder] = uigetfile( ...
        {"*.mat", "SpectraLab archive (*.mat)"}, ...
        "SpectraLab - Select illuminant spectrum archive", workRoot);
    if isequal(name, 0)
        illuminant = [];
        return
    end
    archive = spectralab.archive.load( ...
        fullfile(string(folder), string(name)), ...
        Quiet=true, Validation="error");
    illuminant = spectralab.archive.restore(archive);
end
end

function hash = fileSha256(file)
fid = fopen(file, "r");
if fid < 0
    error("SpectraLab:Work:ColorCheckerManifestReadFailed", ...
        "Could not read ColorChecker manifest: %s", file);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, "*uint8");
md = java.security.MessageDigest.getInstance("SHA-256");
digest = typecast(md.digest(bytes), "uint8");
hash = lower(string(reshape(dec2hex(digest, 2).', 1, [])));
clear cleanup
end
