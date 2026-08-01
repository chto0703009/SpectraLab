function captureFolder = capture_spotread_one_shot(scenario, options)
%CAPTURE_SPOTREAD_ONE_SHOT Capture an actual Spotread -O transcript.
%
%   capture_spotread_one_shot("calibration-required")
%   capture_spotread_one_shot("calibration-succeeded")
%   capture_spotread_one_shot("measurement-succeeded")
%
% The operator is responsible for placing the i1Pro2 appropriately before
% calling this function. A measurement-succeeded capture uses -N only for
% the one-shot measurement attempt and must follow a verified calibration.
% Captures are parser evidence, not measurement archives.

arguments
    scenario (1,1) string
    options.Executable (1,1) string = ""
    options.PythonExecutable (1,1) string = ""
    options.TimeoutSeconds (1,1) double {mustBePositive} = 120
    options.CaptureRoot (1,1) string = ""
    options.Trigger (1,1) string = "dialog"
    options.HighResolution (1,1) logical = false
end

validScenarios = [ ...
    "calibration-required", ...
    "calibration-succeeded", ...
    "measurement-succeeded", ...
    "calibration-failed", ...
    "cancelled", ...
    "communication-failure"];
if ~any(scenario == validScenarios)
    error("SpectraLab:Spotread:InvalidCaptureScenario", ...
        "Unknown capture scenario: %s", scenario);
end

trigger = lower(strtrim(options.Trigger));
if ~any(trigger == ["dialog", "instrument"])
    error("SpectraLab:Spotread:InvalidCaptureTrigger", ...
        "Trigger must be 'dialog' or 'instrument'.");
end

executable = options.Executable;
if strlength(executable) == 0
    executable = spectralab.drivers.spotread.findSpotread();
end
if strlength(executable) == 0
    error("SpectraLab:Spotread:NotFound", ...
        "spotread was not found.");
end

root = repositoryRoot();
captureRoot = options.CaptureRoot;
if strlength(captureRoot) == 0
    captureRoot = fullfile(root, "work", "spotread-captures");
end
if ~isfolder(captureRoot)
    mkdir(captureRoot);
end

fprintf("\nSpotread one-shot capture: %s\n", scenario);
fprintf("Position the i1Pro2 for this exact scenario before continuing.\n");
if trigger == "dialog"
    input("Press ENTER to run one bounded -O operation, or Ctrl-C to abort: ", "s");
else
    fprintf( ...
        "Spotread will start now. Wait for the READY message, then " + ...
        "press the button on the i1Pro2.\n");
end

runner = spectralab.drivers.spotread.OneShotCommandRunner( ...
    executable, ...
    PythonExecutable=options.PythonExecutable, ...
    TimeoutSeconds=options.TimeoutSeconds, ...
    KeepArtifacts=true, ...
    KeepStandardInputOpen=(trigger == "instrument"));
spotreadArguments = ["-e", "-s"];
if options.HighResolution
    spotreadArguments(end + 1) = "-H";
end
if scenario == "measurement-succeeded"
    spotreadArguments(end + 1) = "-N";
end
spotreadArguments(end + 1:end + 2) = ["-O", "spectrum.sp"];
result = runner.run(spotreadArguments);

combinedOutput = result.output + newline + result.error_output;
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    combinedOutput, result.status, result.timed_out);

stamp = string(datetime("now", "Format", "yyyyMMdd-HHmmss"));
captureFolder = fullfile(captureRoot, stamp + "_" + scenario);
movefile(result.working_directory, captureFolder);

manifest = struct();
manifest.expected_scenario = scenario;
manifest.classified_outcome = outcome.kind;
manifest.calibration_was_required = outcome.calibration_was_required;
manifest.operator_verified = false;
manifest.captured_at = char(datetime("now", "TimeZone", "local"));
manifest.spotread_executable = char(executable);
manifest.status = result.status;
manifest.timed_out = result.timed_out;
manifest.effective_options = cellstr(spotreadArguments);
manifest.trigger = trigger;
manifest.kept_stdin_open = result.kept_stdin_open;
manifest.instrument_prompt_seen = result.instrument_prompt_seen;
manifest.high_resolution_requested = options.HighResolution;

if outcome.kind == "MEASUREMENT_SUCCEEDED"
    [wavelength, power] = ...
        spectralab.drivers.spotread.Parser.parseSpectrum(combinedOutput);
    manifest.spectrum_samples = numel(power);
    manifest.spectrum_range_nm = [min(wavelength), max(wavelength)];
    manifest.signal_minimum = min(power);
    manifest.signal_maximum = max(power);
    manifest.signal_integral = trapz(wavelength, power);
    manifest.positive_samples = sum(power > 0);
    manifest.negative_samples = sum(power < 0);
    manifest.candidate_signal_valid = ...
        manifest.signal_maximum > 0 && ...
        manifest.signal_integral > 0;
else
    manifest.candidate_signal_valid = false;
end
writeText(fullfile(captureFolder, "capture.json"), ...
    jsonencode(manifest, PrettyPrint=true));

fprintf("Capture saved: %s\n", captureFolder);
fprintf("Parser classification: %s\n", outcome.kind);
if outcome.kind == "MEASUREMENT_SUCCEEDED"
    fprintf("Candidate signal valid: %s\n", ...
        string(manifest.candidate_signal_valid));
end
fprintf("Review the files and set operator_verified=true only after review.\n");
end

function root = repositoryRoot()
thisFile = string(mfilename("fullpath"));
root = fileparts(fileparts(thisFile));
end

function writeText(path, value)
fileId = fopen(path, "w");
if fileId < 0
    error("SpectraLab:Spotread:CaptureWriteFailed", ...
        "Could not write capture manifest: %s", path);
end
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, "%s", value);
end
