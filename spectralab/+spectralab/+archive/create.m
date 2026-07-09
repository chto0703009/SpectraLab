% NOTE
%
% The archive structure is part of the SpectraLab
% engineering contract (ED-001).
%
% Changes to this structure require an Engineering
% Decision review.
function archive = create(spec)
%CREATE Create a SpectraLab archive from a Spectrum object.
%
%   archive = spectralab.archive.create(spec)
%
% This function converts a Spectrum object into the
% standard SpectraLab archive structure. The returned
% structure is independent of MATLAB class definitions
% and is intended for long-term preservation.

arguments
    spec (1,1) spectralab.core.Spectrum
end

%----------------------------------------------------------
% Archive version
%----------------------------------------------------------

archive.Version.Format   = "SLAB-MAT";
archive.Version.Version  = "0.5";
archive.Version.Software = spectralab.version();
archive.Version.Created  = datetime("now");

%----------------------------------------------------------
% Measurement
%----------------------------------------------------------

archive.Measurement.Name       = spec.Label;
archive.Measurement.Wavelength = spec.WavelengthNm;
archive.Measurement.Value      = spec.Power;
archive.Measurement.Unit       = spec.PowerUnit;
archive.Measurement.Operator   = "";
archive.Measurement.Timestamp = spec.Timestamp;

%----------------------------------------------------------
% Metadata
%----------------------------------------------------------

archive.Metadata.Project     = "";
archive.Metadata.SampleID    = "";
archive.Metadata.Description = "";
archive.Metadata.Tags        = strings(0);
archive.Metadata.Comment     = "";

%----------------------------------------------------------
% Instrument
%----------------------------------------------------------

archive.Instrument.Name          = "";
archive.Instrument.Driver        = "";
archive.Instrument.SerialNumber  = "";
archive.Instrument.CalibrationID = "";

%----------------------------------------------------------
% Quality
%----------------------------------------------------------

archive.Quality.Valid       = true;
archive.Quality.Warning     = "";
archive.Quality.Saturated   = false;
archive.Quality.SignalLevel = [];
archive.Quality.Comment     = "";

%----------------------------------------------------------
% History
%----------------------------------------------------------

archive.History = struct.empty;