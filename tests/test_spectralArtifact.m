function tests = test_spectralArtifact
tests = functiontests(localfunctions);
end

function testTransmissionArtifactIsOneSelfContainedInput(testCase)
reference = makeArchive([400;500;600],[10;20;30],"Reference");
sample = makeArchive([400;500;600],[5;10;15],"Sample");
artifact = spectralab.analysis.createTransmissionArtifact(reference,sample, ...
    Resample=false,ReferenceFile="reference.mat",SampleFile="sample.mat");
verifyTrue(testCase,spectralab.archive.validateSpectralArtifact(artifact).IsValid);
verifyEqual(testCase,artifact.Kind,"single_spectrum");
verifyEqual(testCase,artifact.Quantity,"spectral_transmittance");
verifyEqual(testCase,artifact.Payload.Archive.Measurement.Value,0.5*ones(3,1), ...
    "AbsTol",1e-12);
verifyEqual(testCase,artifact.Payload.StatusM.DensityRGB, ...
    -log10(.5)*ones(1,3),"AbsTol",1e-12);
verifyEqual(testCase,artifact.Payload.ISOVisual.Density,-log10(.5), ...
    "AbsTol",1e-12);
verifyEqual(testCase,artifact.Payload.SourceArchives.Reference,reference);
verifyEqual(testCase,artifact.Payload.SourceArchives.Sample,sample);
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

function testReflectanceArtifactAndProofPNG(testCase)
referenceSource=makeArchive((400:10:700)',2*ones(31,1),"Reference");
meanResult=spectralab.analysis.spectralMean(referenceSource,referenceSource, ...
    ResultName="Reference mean");
reference=meanResult.Result.DerivedArchive;
sample=makeArchive((400:10:700)',linspace(.4,1.6,31)',"Sample");
artifact=spectralab.analysis.createReflectanceArtifact(reference,sample, ...
    Resample=false,ReferenceFile="reference_mean.mat",SampleFile="sample.mat");
verifyTrue(testCase,spectralab.archive.validateSpectralArtifact(artifact).IsValid);
verifyEqual(testCase,artifact.Quantity,"spectral_reflectance");
verifyEqual(testCase,artifact.Payload.Archive.Measurement.Value, ...
    linspace(.2,.8,31)',"AbsTol",1e-12);
verifyEqual(testCase,artifact.Provenance.Definition.Type,"ReflectanceSpectrum");
folder=string(tempname); mkdir(folder); cleanup=onCleanup(@() rmdir(folder,"s")); %#ok<NASGU>
pngFile=fullfile(folder,"proof.png");
proof=spectralab.plot.spectralArtifactProof(artifact,pngFile,ShowFigure=false, ...
    Resolution=96);
verifyTrue(testCase,isfile(pngFile));
verifyEqual(testCase,proof.Minimum,.2,"AbsTol",1e-12);
verifyEqual(testCase,proof.Maximum,.8,"AbsTol",1e-12);
verifyEqual(testCase,proof.DisplayUnit,"percent");
verifyEqual(testCase,proof.DisplayYLimits,[0 100]);
end

function testPairArtifactsRestrictOutputToCamera41Range(testCase)
wavelength=(350:10:760)';
reference=makeArchive(wavelength,2*ones(size(wavelength)),"Reference");
sample=makeArchive(wavelength,ones(size(wavelength)),"Sample");
transmission=spectralab.analysis.createTransmissionArtifact( ...
    reference,sample,Resample=false);
reflectance=spectralab.analysis.createReflectanceArtifact( ...
    reference,sample,Resample=false);
verifyEqual(testCase,transmission.Payload.Archive.Measurement.Wavelength([1 end]), ...
    [400;730]);
verifyEqual(testCase,reflectance.Payload.Archive.Measurement.Wavelength([1 end]), ...
    [400;730]);
verifyEqual(testCase, ...
    transmission.Provenance.Parameters.RequestedOutputWavelengthRangeNm, ...
    [400 730]);
verifyEqual(testCase, ...
    reflectance.Provenance.Parameters.EffectiveOutputWavelengthRangeNm, ...
    [400 730]);
verifyEqual(testCase, ...
    transmission.Payload.SourceArchives.Reference.Measurement.Wavelength([1 end]), ...
    [350;760]);
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
