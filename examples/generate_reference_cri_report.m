function info = generate_reference_cri_report(outputFolder)
%GENERATE_REFERENCE_CRI_REPORT Create the registered CRI reference report.
%
%   info = generate_reference_cri_report()
%   info = generate_reference_cri_report(outputFolder)
%
% The example uses deterministic synthetic spectrum data for visual design
% review. RP-020 requires all report metadata, analysis execution, and
% figure rendering to come from the canonical ANL-CRI registry entry. The
% PDF Results section presents CRI and spectral summary values; the spectrum
% figure embedded in the PDF and the companion PNG remain curve-and-legend
% figures without a duplicated information panel.

arguments
    outputFolder (1,1) string = fullfile(pwd, "reference_report_output")
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

wavelengthNm = (380:10:730).';
power = 0.12 + ...
    0.55 * exp(-0.5 * ((wavelengthNm - 455) / 24).^2) + ...
    0.92 * exp(-0.5 * ((wavelengthNm - 545) / 46).^2) + ...
    0.48 * exp(-0.5 * ((wavelengthNm - 615) / 34).^2);

spec = spectralab.core.Spectrum( ...
    wavelengthNm, ...
    power, ...
    "CRI reference spectrum", ...
    struct("Name", "X-Rite i1Pro 2"), ...
    struct(), ...
    struct(), ...
    "relative");

temporaryFolder = string(tempname);
mkdir(temporaryFolder);
cleanup = onCleanup(@() removeTemporaryFolder(temporaryFolder)); %#ok<NASGU>

archive = spectralab.archive.create(spec);
archiveFile = fullfile(temporaryFolder, "SpectraLab_CRI_reference.mat");
spectralab.archive.save(archive, archiveFile);

info = spectralab.report.generate( ...
    archiveFile, ...
    "ANL-CRI", ...
    outputFolder, ...
    GenerationTime=datetime(2026,7,28,12,0,0));

fprintf("Registered CRI reference report created:\n");
fprintf("  %s\n", info.PDFFile);
fprintf("  %s\n", info.PNGFile);
end

function removeTemporaryFolder(folder)

if isfolder(folder)
    rmdir(folder, "s");
end
end
