function validate(session)
%VALIDATE Validate the stable ColorChecker session contract.

arguments
    session (1,1) struct
end

required = ["Schema", "Identity", "Definition", "MeasurementDefinition", "Context", ...
    "CalibrationPolicy", "Calibrations", "Patches", "History"];
for field = required
    if ~isfield(session, field)
        error("SpectraLab:ColorChecker:InvalidSession", ...
            "ColorChecker session is missing required field '%s'.", field);
    end
end
if string(session.MeasurementDefinition.MeasurementKind) ~= "reflectance" || ...
        string(session.MeasurementDefinition.Quantity) ~= ...
            "spectral reflectance factor"
    error("SpectraLab:ColorChecker:InvalidMeasurementDefinition", ...
        "A ColorChecker camera-calibration session must contain spectral reflectance factor data.");
end
if string(session.Schema) ~= "spectralab.colorchecker-session.v1"
    error("SpectraLab:ColorChecker:UnsupportedSchema", ...
        "Unsupported ColorChecker session schema: %s", session.Schema);
end
if numel(session.Patches) ~= session.Definition.Rows * session.Definition.Columns
    error("SpectraLab:ColorChecker:InvalidPatchCount", ...
        "Patch count does not match the declared chart geometry.");
end
if isfield(session.Definition, "TargetDefinition")
    target = session.Definition.TargetDefinition;
    requiredTargetFields = ["Schema", "CanonicalID", "Name", ...
        "Manufacturer", "Model", "Rows", "Columns", "PatchCount"];
    for field = requiredTargetFields
        if ~isfield(target, field)
            error("SpectraLab:ColorChecker:InvalidTargetDefinition", ...
                "ColorChecker target definition is missing required field '%s'.", ...
                field);
        end
    end
    canonical = spectralab.colorchecker.targetDefinition( ...
        string(target.CanonicalID));
    expectedHash = spectralab.archive.contentHash(canonical);
    normalizedTarget = jsondecode(jsonencode(target));
    normalizedCanonical = jsondecode(jsonencode(canonical));
    if ~isfield(session.Definition, "TargetDefinitionHash") || ...
            string(session.Definition.TargetDefinitionHash) ~= expectedHash || ...
            ~isequaln(normalizedTarget, normalizedCanonical)
        error("SpectraLab:ColorChecker:TargetDefinitionMismatch", ...
            "The embedded ColorChecker target definition does not match its architecture-controlled definition.");
    end
    if target.Rows ~= session.Definition.Rows || ...
            target.Columns ~= session.Definition.Columns || ...
            target.PatchCount ~= numel(session.Patches)
        error("SpectraLab:ColorChecker:TargetGeometryMismatch", ...
            "ColorChecker session geometry does not match the selected target definition.");
    end
end
coordinates = string({session.Patches.Coordinate});
if numel(unique(coordinates)) ~= numel(coordinates)
    error("SpectraLab:ColorChecker:DuplicateCoordinate", ...
        "ColorChecker session contains duplicate patch coordinates.");
end
end
