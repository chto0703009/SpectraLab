function tests = test_plot_archiveInformationPanel
%TEST_PLOT_ARCHIVEINFORMATIONPANEL End-to-end standalone plot information.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
folder = string(tempname);
mkdir(folder);
testCase.TestData.TempDir = folder;
testCase.TestData.Cleanup = onCleanup(@() rmdir(folder, "s"));
end

function testDerivedEmissionMeanShowsResultsAndProvenance(testCase)
folder = string(testCase.TestData.TempDir);
a = makeArchive("A", [1; 3; 2]);
b = makeArchive("B", [2; 4; 3]);
files = [fullfile(folder, "a.mat"), fullfile(folder, "b.mat")];
spectralab.archive.save(a, files(1));
spectralab.archive.save(b, files(2));
analysis = spectralab.analysis.spectralMean(a, b, SourceFiles=files);
derived = analysis.Result.DerivedArchive;
% Reproduce a pre-fix 1.0.1-dev mean whose Kind was not retained.
derived.Measurement.Context.Kind = "";
derived = refreshContentHash(derived);
spec = spectralab.archive.restore(derived);

fig = figure(Visible="off");
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
ax = axes(Parent=fig);
spectralab.plot.archiveInformationPanel( ...
    ax, spec, derived, ArchiveName="derived_mean");
content = string(findall(fig, Type="text", ...
    Tag="SpectraLabReflectanceColorimetry").String);

for expected = ["Integral:", "Peak wavelength:", "Peak height:", ...
        "Instrument:", "Serial:", "Operator:", "Archive: derived_mean"]
    verifyTrue(testCase, any(contains(content, expected), "all"));
end
end

function archive = makeArchive(name, values)
metadata = struct("measurement_kind", "emissive", "Operator", "Test operator");
instrument = struct("Name", "Test instrument", "SerialNumber", "1234");
spec = spectralab.core.Spectrum([400; 500; 600], values, name, ...
    instrument, struct(), metadata, "arbitrary");
archive = spectralab.archive.create(spec);
end

function archive = refreshContentHash(archive)
payload = struct("Measurement", archive.Measurement, ...
    "Instrument", archive.Instrument, "Quality", archive.Quality, ...
    "Derivation", archive.Derivation);
archive.Identity.ContentHash = spectralab.archive.contentHash(payload);
end
