% Spotread bounded-operation outcome parser tests

thisFile = mfilename("fullpath");
base = fullfile(fileparts(thisFile), "fixtures");
required = fileread(fullfile(base, ...
    "spotread_outcome_calibration_required.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    required, 0, false);
assert(outcome.kind == "CALIBRATION_REQUIRED");
assert(~outcome.success);
assert(outcome.calibration_was_required);

calibrated = fileread(fullfile(base, ...
    "spotread_outcome_calibration_succeeded.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    calibrated, 0, false);
assert(outcome.kind == "CALIBRATION_SUCCEEDED");
assert(outcome.success);
assert(~outcome.calibration_was_required);

actualStyleCalibration = fileread(fullfile(base, ...
    "spotread_i1pro2_calibration_complete.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    actualStyleCalibration, 0, false);
assert(outcome.kind == "CALIBRATION_SUCCEEDED");
assert(outcome.success);
assert(outcome.calibration_was_required);

failed = fileread(fullfile(base, ...
    "spotread_outcome_calibration_failed.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    failed, 1, false);
assert(outcome.kind == "CALIBRATION_FAILED");
assert(~outcome.success);

communication = fileread(fullfile(base, ...
    "spotread_outcome_communication_failure.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    communication, 1, false);
assert(outcome.kind == "COMMUNICATION_FAILURE");

cancelled = fileread(fullfile(base, ...
    "spotread_outcome_cancelled.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    cancelled, 130, false);
assert(outcome.kind == "CANCELLED");

spectrum = fileread(fullfile(base, ...
    "spotread_argyll_spectrum_block.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    spectrum, 0, false);
assert(outcome.kind == "MEASUREMENT_SUCCEEDED");
assert(outcome.success);

actualMeasurement = fileread(fullfile(base, ...
    "spotread_i1pro2_measurement_complete.txt"));
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    actualMeasurement, 0, false);
assert(outcome.kind == "MEASUREMENT_SUCCEEDED");
assert(outcome.success);
assert(~outcome.calibration_was_required);
[actualWavelength, actualPower] = ...
    spectralab.drivers.spotread.Parser.parseSpectrum(actualMeasurement);
assert(numel(actualPower) == 36);
assert(actualWavelength(1) == 380);
assert(actualWavelength(end) == 730);
assert(all(actualPower > 0));
assert(abs(max(actualPower) - 277.815) < 1e-12);

missingInstrument = ...
    "Diagnostic: Unknown, inappropriate or no instrument detected";
outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    missingInstrument, 1, false);
assert(outcome.kind == "INSTRUMENT_NOT_DETECTED");
assert(~outcome.success);
assert(contains(outcome.message, "USB instrument"));

outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    spectrum, 7, false);
assert(outcome.kind == "PROCESS_FAILED");
assert(~outcome.success);

outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    "", 124, true);
assert(outcome.kind == "TIMEOUT");

outcome = spectralab.drivers.spotread.OutcomeParser.classify( ...
    "unexpected text", 0, false);
assert(outcome.kind == "UNRECOGNIZED_OUTPUT");

fprintf("test_spotread_outcomeParser OK\n");
