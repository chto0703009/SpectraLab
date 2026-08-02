function matrix = generate_release_report_matrix(outputFolder)
%GENERATE_RELEASE_REPORT_MATRIX Generate all registered v0.8.1 reports.
%
%   matrix = generate_release_report_matrix(outputFolder)
%
% The target folder must be empty. Deterministic synthetic archives are
% retained beside the reports so every release-review result is traceable.

arguments
    outputFolder (1,1) string
end

outputFolder = string(outputFolder);

if isfolder(outputFolder)
    contents = dir(outputFolder);
    contents = contents(~ismember({contents.name}, {'.', '..'}));
    if ~isempty(contents)
        error("SpectraLab:Release:OutputFolderNotEmpty", ...
            "Release report-matrix folder must be empty: %s", outputFolder);
    end
else
    mkdir(outputFolder);
end

archiveFolder = fullfile(outputFolder, "archive");
reportFolder = fullfile(outputFolder, "report");
mkdir(archiveFolder);
mkdir(reportFolder);

wavelengthNm = (380:10:730).';

measuredPower = 0.12 + ...
    0.55 * exp(-0.5 * ((wavelengthNm - 455) / 24).^2) + ...
    0.92 * exp(-0.5 * ((wavelengthNm - 545) / 46).^2) + ...
    0.48 * exp(-0.5 * ((wavelengthNm - 615) / 34).^2);

referencePower = 100 .* ones(size(wavelengthNm));
transmittance = 0.08 + ...
    0.16 * exp(-0.5 * ((wavelengthNm - 450) / 32).^2) + ...
    0.42 * exp(-0.5 * ((wavelengthNm - 610) / 75).^2);
samplePower = referencePower .* transmittance;
secondSamplePower = samplePower .* ...
    (1.01 + 0.015 * sin((wavelengthNm - 380) / 350 * 2 * pi));

measuredFile = saveArchive( ...
    archiveFolder, wavelengthNm, measuredPower, ...
    "Release_QA_measured");
referenceFile = saveArchive( ...
    archiveFolder, wavelengthNm, referencePower, ...
    "Release_QA_reference");
sampleFile = saveArchive( ...
    archiveFolder, wavelengthNm, samplePower, ...
    "Release_QA_sample");
secondSampleFile = saveArchive( ...
    archiveFolder, wavelengthNm, secondSamplePower, ...
    "Release_QA_second_sample");

firstSampleArchive = spectralab.archive.load(sampleFile, Quiet=true);
secondSampleArchive = spectralab.archive.load(secondSampleFile, Quiet=true);
meanResult = spectralab.analysis.spectralMean( ...
    firstSampleArchive, secondSampleArchive, ...
    ResultName="Release_QA_mean", ...
    SourceFiles=["Release_QA_sample.mat", ...
                 "Release_QA_second_sample.mat"]);
derivedArchiveFile = fullfile(archiveFolder, "Release_QA_mean.mat");
spectralab.archive.save( ...
    meanResult.Result.DerivedArchive, derivedArchiveFile);

analysisIds = [ ...
    "ANL-SPECTRUM"
    "ANL-CRI"
    "ANL-001"
    "ANL-002"
    "ANL-009"
    "ANL-010"
    "ANL-004"
    "ANL-005"
    "ANL-007"
    "ANL-008"];

matrix = repmat(struct( ...
    "AnalysisId", "", ...
    "PDFFile", "", ...
    "PNGFile", ""), numel(analysisIds), 1);

generationTime = datetime(2026, 8, 2, 12, 0, 0);

for k = 1:numel(analysisIds)
    analysisId = analysisIds(k);

    if ismember(analysisId, ["ANL-SPECTRUM", "ANL-CRI"])
        archiveFiles = measuredFile;
    elseif ismember(analysisId, ["ANL-009", "ANL-010"])
        archiveFiles = [sampleFile, secondSampleFile];
    else
        archiveFiles = [referenceFile, sampleFile];
    end

    if analysisId == "ANL-009"
        info = spectralab.report.generate( ...
            archiveFiles, analysisId, reportFolder, ...
            DerivedArchiveFile=derivedArchiveFile, ...
            ShowFigure=false, OpenPDF=false, ...
            GenerationTime=generationTime);
    else
        info = spectralab.report.generate( ...
            archiveFiles, analysisId, reportFolder, ...
            ShowFigure=false, OpenPDF=false, ...
            GenerationTime=generationTime);
    end

    matrix(k).AnalysisId = analysisId;
    matrix(k).PDFFile = string(info.PDFFile);
    matrix(k).PNGFile = string(info.PNGFile);
end

fprintf("SpectraLab v0.8.1 report matrix created:\n  %s\n", outputFolder);
end

function archiveFile = saveArchive(folder, wavelengthNm, power, name)

spec = spectralab.core.Spectrum( ...
    wavelengthNm, ...
    power, ...
    name, ...
    struct("Name", "Release QA synthetic instrument"), ...
    struct(), ...
    struct(), ...
    "relative");

archive = spectralab.archive.create(spec);
archiveFile = fullfile(folder, name + ".mat");
spectralab.archive.save(archive, archiveFile);
end
