function tests = test_spectralArtifact
tests = functiontests(localfunctions);
end

function testTransmissionArtifactIsOneSelfContainedInput(testCase)
reference = makeArchive([400;500;600;730],[10;20;30;40],"Reference");
sample = makeArchive([400;500;600;730],[5;10;15;20],"Sample");
artifact = spectralab.analysis.createTransmissionArtifact(reference,sample, ...
    Resample=false,ReferenceFile="reference.mat",SampleFile="sample.mat");
verifyTrue(testCase,spectralab.archive.validateSpectralArtifact(artifact).IsValid);
verifyEqual(testCase,artifact.Kind,"single_spectrum");
verifyEqual(testCase,artifact.Quantity,"spectral_transmittance");
verifyEqual(testCase,artifact.Payload.Archive.Measurement.Value,0.5*ones(4,1), ...
    "AbsTol",1e-12);
verifyEqual(testCase,fieldnames(artifact.Payload),{'Archive'});
end

function testCamera41ContractRejectsIncompleteCoverage(testCase)
wavelength=(400:10:720)';
reference=makeArchive(wavelength,2*ones(size(wavelength)),"Reference");
sample=makeArchive(wavelength,ones(size(wavelength)),"Sample");
verifyError(testCase,@() spectralab.analysis.createTransmissionArtifact( ...
    reference,sample,Resample=false), ...
    "SpectraLab:Camera41:IncompleteWavelengthRange");
end

function testTransmissionSeriesUsesOneReferenceForEverySample(testCase)
wavelength=(390:10:740)';
reference=makeArchive(wavelength,10*ones(size(wavelength)),"Reference");
samples={makeArchive(wavelength,2*ones(size(wavelength)),"Point 1"), ...
    makeArchive(wavelength,7*ones(size(wavelength)),"Point 2")};
artifacts=spectralab.analysis.createTransmissionArtifactSeries( ...
    reference,samples,ReferenceFile="reference.mat", ...
    SampleFiles=["sample_01.mat","sample_02.mat"],Resample=false);
verifyEqual(testCase,numel(artifacts),2);
verifyEqual(testCase,artifacts{1}.Payload.Archive.Measurement.Value, ...
    .2*ones(34,1),"AbsTol",1e-12);
verifyEqual(testCase,artifacts{2}.Payload.Archive.Measurement.Value, ...
    .7*ones(34,1),"AbsTol",1e-12);
verifyEqual(testCase, ...
    artifacts{1}.Provenance.Sources.Reference.Filename,"reference.mat");
verifyEqual(testCase, ...
    artifacts{2}.Provenance.Sources.Reference.Filename,"reference.mat");
verifyEqual(testCase, ...
    artifacts{2}.Provenance.Sources.Sample.Filename,"sample_02.mat");
end

function testRoundTrip(testCase)
reference = makeArchive((380:10:730)',ones(36,1),"Reference");
sample = makeArchive((380:10:730)',.25*ones(36,1),"Sample");
artifact = spectralab.analysis.createTransmissionArtifact(reference,sample, ...
    Resample=false);
folder=string(tempname); mkdir(folder); cleanup=onCleanup(@() rmdir(folder,"s")); %#ok<NASGU>
file=fullfile(folder,"artifact.mat");
spectralab.archive.saveSpectralArtifact(artifact,file);
loaded=spectralab.archive.loadSpectralArtifact(file);
verifyEqual(testCase,loaded.Identity.ContentHash,artifact.Identity.ContentHash);
embedded=spectralab.archive.load(file,Quiet=true,Validation="error");
verifyEqual(testCase,embedded.Measurement.Wavelength([1 end]),[400;730]);
verifyEqual(testCase,embedded.Measurement.Value,.25*ones(34,1),"AbsTol",1e-12);
end

function testMeasuredArchiveWrapper(testCase)
archive=makeArchive((400:10:700)',ones(31,1),"Lamp");
artifact=spectralab.archive.createSpectrumArtifact(archive, ...
    SourceFile="lamp.mat");
verifyTrue(testCase,spectralab.archive.validateSpectralArtifact(artifact).IsValid);
verifyEqual(testCase,artifact.Origin,"measured");
verifyEqual(testCase,artifact.Quantity,"spectral_power");
verifyEqual(testCase,artifact.Payload.Archive.Identity.UUID,archive.Identity.UUID);
end

function testMeasuredReflectanceIsWrappedWithoutDivision(testCase)
wavelength=(400:10:700)'; reflectance=linspace(20,80,31)';
spec=spectralab.core.Spectrum(wavelength,reflectance,"Reflectance", ...
    struct("Name","i1Pro2"),struct(),struct( ...
    "measurement_kind","reflectance", ...
    "signal_quantity","spectral reflectance factor"), ...
    "relative reflectance (%)");
archive=spectralab.archive.create(spec);
artifact=spectralab.archive.createSpectrumArtifact(archive, ...
    SourceFile="measured_reflectance.mat");
verifyTrue(testCase,spectralab.archive.validateSpectralArtifact(artifact).IsValid);
verifyEqual(testCase,artifact.Quantity,"spectral_reflectance");
verifyEqual(testCase,artifact.Payload.Archive.Measurement.Value,reflectance, ...
    "AbsTol",1e-12);
verifyEqual(testCase,fieldnames(artifact.Payload),{'Archive'});
end

function testTransmissionArtifactRestrictsOutputToCamera41Range(testCase)
wavelength=(350:10:760)';
reference=makeArchive(wavelength,2*ones(size(wavelength)),"Reference");
sample=makeArchive(wavelength,ones(size(wavelength)),"Sample");
transmission=spectralab.analysis.createTransmissionArtifact( ...
    reference,sample,Resample=false);
verifyEqual(testCase,transmission.Payload.Archive.Measurement.Wavelength([1 end]), ...
    [400;730]);
verifyEqual(testCase, ...
    transmission.Provenance.Parameters.RequestedOutputWavelengthRangeNm, ...
    [400 730]);
verifyEqual(testCase,fieldnames(transmission.Payload),{'Archive'});
end

function testShortAutomaticArtifactNaming(testCase)
folder=string(tempname); mkdir(folder); cleanup=onCleanup(@() rmdir(folder,"s")); %#ok<NASGU>
proofFolder=fullfile(folder,"plot"); mkdir(proofFolder);
first=spectralab.archive.nextArtifactOutput(folder, ...
    "Portra 160 ÅÄÖ very long measurement name that must be shortened", ...
    "transmission",ProofFolder=proofFolder);
verifyEqual(testCase,first.Revision,1);
verifyLessThanOrEqual(testCase,strlength(first.Stem+"_proof.png"),80);
verifyTrue(testCase,startsWith(first.ArtifactID,"portra_160_aao_"));
verifyLessThanOrEqual(testCase,strlength(first.ArtifactID),40);
fclose(fopen(first.ArtifactFile,"w"));
second=spectralab.archive.nextArtifactOutput(folder,first.ArtifactID, ...
    "transmission",ProofFolder=proofFolder);
verifyEqual(testCase,second.Revision,2);
verifyTrue(testCase,endsWith(second.Stem,"_v02"));
end

function archive=makeArchive(wavelength,value,name)
spec=spectralab.core.Spectrum(wavelength,value,name, ...
    struct("Name","Test instrument"),struct(),struct("Operator","Test"),"arbitrary");
archive=spectralab.archive.create(spec);
end
