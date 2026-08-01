classdef FakeOneShotRunner < handle
    %FAKEONESHOTRUNNER Deterministic result queue for driver tests.

    properties
        Results cell
        Calls cell = {}
        Index (1,1) double = 0
    end

    methods
        function obj = FakeOneShotRunner(results)
            obj.Results = results;
        end

        function result = run(obj, arguments)
            obj.Index = obj.Index + 1;
            if obj.Index > numel(obj.Results)
                error("SpectraLab:Test:NoFakeResult", ...
                    "No fake one-shot result remains.");
            end
            obj.Calls{end + 1} = string(arguments);
            definition = obj.Results{obj.Index};

            workingDirectory = string(tempname);
            mkdir(workingDirectory);
            if isfield(definition, "spectrum_file") && ...
                    strlength(string(definition.spectrum_file)) > 0
                copyfile(definition.spectrum_file, ...
                    fullfile(workingDirectory, "spectrum.sp"));
            end

            result = struct();
            result.status = readField(definition, "status", 0);
            result.timed_out = readField(definition, "timed_out", false);
            result.duration_seconds = readField( ...
                definition, "duration_seconds", 0.1);
            result.command = ["fake-spotread", string(arguments)];
            result.output = string(readField(definition, "output", ""));
            result.error_output = string(readField( ...
                definition, "error_output", ""));
            result.working_directory = workingDirectory;
            result.artifacts_retained = true;
        end
    end
end

function value = readField(data, name, defaultValue)
if isfield(data, name)
    value = data.(name);
else
    value = defaultValue;
end
end
