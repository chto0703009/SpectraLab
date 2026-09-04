function artifacts = createTransmissionArtifactSeries(reference, samples, options)
%CREATETRANSMISSIONARTIFACTSERIES Normalize N samples by one reference.
arguments
    reference (1,1) struct
    samples (1,:) cell
    options.ReferenceFile (1,1) string = ""
    options.SampleFiles string = strings(1,0)
    options.Resample (1,1) logical = true
    options.RefinementFactor (1,1) double ...
        {mustBeInteger,mustBePositive} = 4
    options.InterpolationMethod (1,1) string = "pchip"
    options.WavelengthRangeNm (1,2) double = [400 730]
end

assert(~isempty(samples),"SpectraLab:Artifact:EmptySeries", ...
    "At least one sample spectrum is required.");
sampleFiles=reshape(options.SampleFiles,1,[]);
if isempty(sampleFiles), sampleFiles=repmat("",1,numel(samples)); end
assert(numel(sampleFiles)==numel(samples), ...
    "SpectraLab:Artifact:SampleFileCount", ...
    "SampleFiles must be empty or contain one filename per sample.");

artifacts=cell(1,numel(samples));
for index=1:numel(samples)
    sample=samples{index};
    assert(isstruct(sample) && isscalar(sample), ...
        "SpectraLab:Artifact:InvalidSeriesSample", ...
        "Every series sample must be one SpectraLab archive structure.");
    name=string(sample.Measurement.Name)+" spectral transmission";
    artifacts{index}=spectralab.analysis.createTransmissionArtifact( ...
        reference,sample,ReferenceFile=options.ReferenceFile, ...
        SampleFile=sampleFiles(index),Resample=options.Resample, ...
        RefinementFactor=options.RefinementFactor, ...
        InterpolationMethod=options.InterpolationMethod,Name=name, ...
        WavelengthRangeNm=options.WavelengthRangeNm);
end
end
