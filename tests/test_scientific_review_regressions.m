function tests=test_scientific_review_regressions
tests=functiontests(localfunctions);
end
function testStandardDensityIsIndependentOfAcquisitionLamp(t)
w=(400:10:730)';T=0.01+0.4*((w-400)/330).^2;
a=struct('WavelengthNm',w,'Value',ones(size(w)));
b=struct('WavelengthNm',w,'Value',0.1+3*((w-400)/330));
sa=a;sa.Value=a.Value.*T;sb=b;sb.Value=b.Value.*T;
x=spectralab.analysis.statusMDensity(a,sa);y=spectralab.analysis.statusMDensity(b,sb);
verifyEqual(t,x.DensityRGB,y.DensityRGB,AbsTol=1e-12);
x=spectralab.analysis.isoVisualDensity(a,sa);y=spectralab.analysis.isoVisualDensity(b,sb);
verifyEqual(t,x.Density,y.Density,AbsTol=1e-12);
x=spectralab.analysis.statusMDensity(a,sa,IntegrationBasis="source-weighted");
y=spectralab.analysis.statusMDensity(b,sb,IntegrationBasis="source-weighted");
verifyGreaterThan(t,max(abs(x.DensityRGB-y.DensityRGB)),0.01);
end
function testNoHiddenRepairOfZeroOrNegativeSignals(t)
w=(400:10:730)';a=struct('WavelengthNm',w,'Value',ones(size(w)));b=a;b.Value(10)=-1e-8;
verifyError(t,@()spectralab.analysis.statusMDensity(a,b),'spectralab:core:weightedDensity:NegativeSignal');
b=a;a.Value(10)=0;
verifyError(t,@()spectralab.analysis.statusMDensity(a,b),'spectralab:core:weightedDensity:InvalidReferenceSupport');
end
function testPercentageAndFractionColorimetryMatch(t)
w=(380:10:730)';v=20+60*(w-380)/350;ill=spectralab.filters.cie.d50();
a=spectralab.core.Spectrum(w,v,"percent",struct(),struct(),struct(),"relative reflectance (%)");
b=spectralab.core.Spectrum(w,v/100,"fraction",struct(),struct(),struct(),"1");
x=spectralab.analysis.colorimetry(a,Illuminant=ill);y=spectralab.analysis.colorimetry(b,Illuminant=ill);
verifyEqual(t,x.Samples.Colorimetry.XYZ,y.Samples.Colorimetry.XYZ);
b=spectralab.core.Spectrum(w,v,"ambiguous",struct(),struct(),struct(),"reflectance mystery");
verifyError(t,@()spectralab.analysis.colorimetry(b,Illuminant=ill),'SpectraLab:Colorimetry:UnsupportedQuantity');
end
function testCriRoundsTheUnroundedMean(t)
w=(380:5:780)';v=exp(-.5*((w-438)/15).^2)+.7*exp(-.5*((w-550)/60).^2)+.3;
a=spectralab.core.Spectrum(w,v);
x=spectralab.analysis.cri(a,Quiet=true);y=spectralab.analysis.cri(a,Quiet=true,RoundIndices=true);
verifyEqual(t,y.Result.Ra,round(mean(x.Result.R(1:8))));
end
function testFixedContractRejectsPartialCoverage(t)
verifyError(t,@()spectralab.io.applyCamera41ExportContract((410:10:730)',ones(33,1)), ...
 'SpectraLab:Camera41:IncompleteWavelengthRange');
[w,~,c]=spectralab.io.applyCamera41ExportContract((380:10:780)',ones(41,1));
verifyEqual(t,[w(1) w(end)],[400 730]);verifyEqual(t,c.Requirement,"complete_interval");
end

function testExplicitSpotreadUnits(t)
verifyEqual(t,spectralab.drivers.spotread.spectralUnit("emissive","-e -s"),"mW/(m^2 sr nm)");
verifyEqual(t,spectralab.drivers.spotread.spectralUnit("emissive","-a -s"),"mW/(m^2 nm)");
verifyEqual(t,spectralab.drivers.spotread.spectralUnit("emissive","-ew -s"),"arbitrary");
end

function testDocumentarySlopeIsInterpolatedInLogSpace(t)
f=spectralab.filters.statusM.blue();
a=f.Value(f.WavelengthNm==410);b=f.Value(f.WavelengthNm==420);mid=f.Value(f.WavelengthNm==415);
verifyEqual(t,mid,sqrt(a*b),AbsTol=1e-12);
verifyNotEqual(t,mid,(a+b)/2);
end

function testNegativeOutsideWeightingRangeIsRecordedNotClipped(t)
w=(380:10:780)';ref=struct('WavelengthNm',w,'Value',ones(size(w)));sample=ref;sample.Value(:)=.1;sample.Value(1)=-.0005;
x=spectralab.analysis.statusMDensity(ref,sample);
verifyEqual(t,x.DensityRGB,[1 1 1],AbsTol=1e-12);
verifyEqual(t,x.Blue.ExcludedNegativeSamples.SampleWavelengthNm,380);
verifyEqual(t,sample.Value(1),-.0005);
verifyError(t,@()spectralab.analysis.isoVisualDensity(ref,sample),'spectralab:core:weightedDensity:NegativeSignal');
end
