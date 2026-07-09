function doc = makeDocument(spec)
%MAKEDOCUMENT  Convert Spectrum to SpectraLab JSON document struct.

s = spec.toStruct();

doc = struct();
doc.format = "spectralab.spectrum.v1";
doc.schema_version = 1;
doc.created_by = "SpectraLab 0.5.0";
doc.saved_at = char(datetime("now", "TimeZone", "local"));
doc.spectrum = struct();

doc.spectrum.label = s.label;
doc.spectrum.timestamp = s.timestamp;
doc.spectrum.wavelength_nm = spec.WavelengthNm(:).';
doc.spectrum.power = spec.Power(:).';
doc.spectrum.units = s.units;
doc.spectrum.instrument = s.instrument;
doc.spectrum.calibration = s.calibration;
doc.spectrum.metadata = s.metadata;
doc.spectrum.summary = s.summary;

end
