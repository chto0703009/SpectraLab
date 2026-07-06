function spec = readJson(filename)
%READJSON  Read Spectrum from SpectraLab .slab.json file.

raw = fileread(filename);
doc = jsondecode(raw);

spectralab.io.slab.validateDocument(doc);

s = doc.spectrum;

tmp = struct();
tmp.label = s.label;
tmp.timestamp = s.timestamp;
tmp.wavelength_nm = s.wavelength_nm(:);
tmp.power = s.power(:);
tmp.units = s.units;

if isfield(s, "instrument"), tmp.instrument = s.instrument; else, tmp.instrument = struct(); end
if isfield(s, "calibration"), tmp.calibration = s.calibration; else, tmp.calibration = struct(); end
if isfield(s, "metadata"), tmp.metadata = s.metadata; else, tmp.metadata = struct(); end

spec = spectralab.core.Spectrum.fromStruct(tmp);

end
