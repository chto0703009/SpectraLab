function files = exportColorimetry(dataset, outputFolder, options)
%EXPORTCOLORIMETRY Serialize one canonical colourimetry dataset.
%
%   FILES = spectralab.io.exportColorimetry(DATASET, OUTPUTFOLDER)
%
% Exporters do not calculate colour values. They only serialize the
% dataset returned by spectralab.analysis.colorimetry.

arguments
    dataset (1,1) struct
    outputFolder {mustBeTextScalar}
    options.BaseName (1,1) string = ""
    options.Formats string = ["json" "cgats" "csv" "xyz" "lab"]
end

validateDataset(dataset);
outputFolder = string(outputFolder);
if ~isfolder(outputFolder), mkdir(outputFolder); end
baseName = strtrim(options.BaseName);
if strlength(baseName) == 0, baseName = safeName(dataset.Samples(1).SampleID); end
formats = lower(string(options.Formats));
formats = unique(formats, "stable");
files = struct("JSON", "", "CGATS", "", "CSVColorimetry", "", ...
    "CSVSpectral", "", "XYZ", "", "Lab", "");

for format = formats(:).'
    switch format
        case "json"
            files.JSON = target(outputFolder, baseName + "_colorimetry.json");
        case "csv"
            files.CSVColorimetry = target( ...
                outputFolder, baseName + "_colorimetry.csv");
            files.CSVSpectral = target( ...
                outputFolder, baseName + "_spectral_data.csv");
        case "cgats"
            files.CGATS = target(outputFolder, baseName + "_colorimetry.cgats");
        case "xyz"
            files.XYZ = target(outputFolder, baseName + "_XYZ.txt");
        case "lab"
            files.Lab = target(outputFolder, baseName + "_Lab.txt");
        otherwise
            error("SpectraLab:Colorimetry:UnsupportedExportFormat", ...
                "Unsupported colourimetry export format: %s", format);
    end
end
validateTargets(files);

if files.JSON ~= ""
    writeText(files.JSON, jsonencode(dataset, PrettyPrint=true));
end
if files.CSVColorimetry ~= ""
    writeColorimetryCsv(dataset, files.CSVColorimetry);
    writeSpectralCsv(dataset, files.CSVSpectral);
end
if files.CGATS ~= ""
    writeCgats(dataset, files.CGATS);
end
if files.XYZ ~= ""
    writeTriplets(dataset, files.XYZ, "XYZ");
end
if files.Lab ~= ""
    writeTriplets(dataset, files.Lab, "Lab");
end
end

function validateDataset(dataset)
if ~isfield(dataset, "Format") || dataset.Format ~= "spectralab.colorimetry.dataset.v1" || ...
        ~isfield(dataset, "Samples") || isempty(dataset.Samples)
    error("SpectraLab:Colorimetry:InvalidDataset", ...
        "Input must be a SpectraLab colourimetry dataset.");
end
end

function filename = target(folder, name)
filename = fullfile(folder, name);
end

function validateTargets(files)
%VALIDATETARGETS Refuse every collision before creating any export file.

filenames = string(struct2cell(files));
for filename = filenames(:).'
    if filename ~= "" && isfile(filename)
        error("SpectraLab:Colorimetry:ExportFileExists", ...
            "SpectraLab refuses to overwrite '%s'.", filename);
    end
end
end

function writeText(filename, content)
fid = fopen(filename, "w");
assert(fid >= 0, "SpectraLab:Colorimetry:ExportOpenFailed", ...
    "Could not open '%s' for writing.", filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", content);
end

function writeColorimetryCsv(dataset, filename)
%WRITECOLORIMETRYCSV Write one XYZ/Lab row for each patch.

fid = fopen(filename, "w");
assert(fid >= 0, "SpectraLab:Colorimetry:ExportOpenFailed", ...
    "Could not open '%s' for writing.", filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "sample_id,status,illuminant,observer,X,Y,Z,L,a,b,x,y\n");
for sample = dataset.Samples(:).'
    c = sample.Colorimetry;
    fprintf(fid, '"%s","%s","%s","%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', ...
        sample.SampleID, c.Status, c.Illuminant.Label, c.Observer, ...
        c.XYZ.X, c.XYZ.Y, c.XYZ.Z, c.Lab.L, c.Lab.a, c.Lab.b, ...
        c.xyY.x, c.xyY.y);
end
end

function writeSpectralCsv(dataset, filename)
%WRITESPECTRALCSV Write R(lambda) independently of derived colour values.

fid = fopen(filename, "w");
assert(fid >= 0, "SpectraLab:Colorimetry:ExportOpenFailed", ...
    "Could not open '%s' for writing.", filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "sample_id,wavelength_nm,spectral_value,spectral_unit\n");
for sample = dataset.Samples(:).'
    for index = 1:numel(sample.Spectrum.WavelengthNm)
        fprintf(fid, '"%s",%.12g,%.12g,"%s"\n', ...
            sample.SampleID, sample.Spectrum.WavelengthNm(index), ...
            sample.Spectrum.Value(index), sample.Spectrum.Unit);
    end
end
end

function writeCgats(dataset, filename)
assertCommonGrid(dataset.Samples);
fid = fopen(filename, "w");
assert(fid >= 0, "SpectraLab:Colorimetry:ExportOpenFailed", ...
    "Could not open '%s' for writing.", filename);
cleanup = onCleanup(@() fclose(fid));
wavelength = dataset.Samples(1).Spectrum.WavelengthNm;
fields = ["SAMPLE_ID" "XYZ_X" "XYZ_Y" "XYZ_Z" "LAB_L" "LAB_A" "LAB_B" ...
    "XYY_x" "XYY_y" "XYY_Y" "SPEC_" + string(round(wavelength))];
fprintf(fid, "CGATS.17\n");
fprintf(fid, "ORIGINATOR ""SpectraLab""\n");
fprintf(fid, "DESCRIPTOR ""SpectraLab canonical colourimetry export""\n");
fprintf(fid, "NUMBER_OF_FIELDS %d\nBEGIN_DATA_FORMAT\n%s\nEND_DATA_FORMAT\n", ...
    numel(fields), strjoin(fields, " "));
fprintf(fid, "NUMBER_OF_SETS %d\nBEGIN_DATA\n", numel(dataset.Samples));
for sample = dataset.Samples(:).'
    c = sample.Colorimetry;
    values = [c.XYZ.X c.XYZ.Y c.XYZ.Z c.Lab.L c.Lab.a c.Lab.b c.xyY.x c.xyY.y c.xyY.Y sample.Spectrum.Value];
    fprintf(fid, '"%s"', sample.SampleID);
    fprintf(fid, " %.12g", values);
    fprintf(fid, "\n");
end
fprintf(fid, "END_DATA\n");
end

function writeTriplets(dataset, filename, kind)
fid = fopen(filename, "w");
assert(fid >= 0, "SpectraLab:Colorimetry:ExportOpenFailed", ...
    "Could not open '%s' for writing.", filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "# SpectraLab %s export; calculation %s\n", kind, dataset.CalculationVersion);
for sample = dataset.Samples(:).'
    if kind == "XYZ", values = sample.Colorimetry.XYZ; labels = ["X" "Y" "Z"]; else, values = sample.Colorimetry.Lab; labels = ["L" "a" "b"]; end
    fprintf(fid, "%s", sample.SampleID);
    for label = labels
        fprintf(fid, " %s=%.12g", label, values.(char(label)));
    end
    fprintf(fid, "\n");
end
end

function assertCommonGrid(samples)
wavelength = samples(1).Spectrum.WavelengthNm;
for index = 2:numel(samples)
    if ~isequal(wavelength, samples(index).Spectrum.WavelengthNm)
        error("SpectraLab:Colorimetry:CGATSGridMismatch", ...
            "CGATS spectral export requires one common wavelength grid.");
    end
end
end

function name = safeName(value)
name = regexprep(string(value), "[^A-Za-z0-9_-]", "_");
if strlength(name) == 0, name = "measurement"; end
end
