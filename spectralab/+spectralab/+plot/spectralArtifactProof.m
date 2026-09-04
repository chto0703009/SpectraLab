function result = spectralArtifactProof(artifact, pngFile, options)
%SPECTRALARTIFACTPROOF Render source spectra and derived ratio to one PNG.
arguments
    artifact (1,1) struct
    pngFile (1,1) string
    options.ShowFigure (1,1) logical = true
    options.Resolution (1,1) double {mustBePositive} = 300
end

validation=spectralab.archive.validateSpectralArtifact(artifact);
if ~validation.IsValid
    error("SpectraLab:ArtifactProof:InvalidArtifact","%s", ...
        strjoin(validation.Errors,newline));
end
if ~any(string(artifact.Quantity)== ...
        ["spectral_transmittance","spectral_reflectance"])
    error("SpectraLab:ArtifactProof:UnsupportedQuantity", ...
        "The proof figure requires transmission or reflectance data.");
end
if isfile(pngFile)
    error("SpectraLab:ArtifactProof:OutputExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s",pngFile);
end
folder=string(fileparts(pngFile));
if folder~="" && ~isfolder(folder), mkdir(folder); end

visibility="off";
if options.ShowFigure, visibility="on"; end
fig=figure("Color","white","Visible",visibility, ...
    "Name","SpectraLab spectral artifact proof", ...
    "Position",[100 100 1500 900]);
cleanup=onCleanup(@() closeIfHidden(fig,options.ShowFigure));
hasSources=isfield(artifact.Payload,"SourceArchives");
layout=tiledlayout(fig,1+double(hasSources),1, ...
    "TileSpacing","compact","Padding","compact");

if hasSources
    reference=artifact.Payload.SourceArchives.Reference.Measurement;
    sample=artifact.Payload.SourceArchives.Sample.Measurement;
    ax1=nexttile(layout);
    plot(ax1,double(reference.Wavelength(:)),double(reference.Value(:)), ...
        "LineWidth",1.5,"DisplayName","Reference");
    hold(ax1,"on");
    plot(ax1,double(sample.Wavelength(:)),double(sample.Value(:)), ...
        "LineWidth",1.5,"DisplayName","Sample");
    grid(ax1,"on"); box(ax1,"on");
    xlabel(ax1,"Wavelength (nm)"); ylabel(ax1,"Measured spectral value");
    title(ax1,"Source spectra on their original common scale");
    legend(ax1,"Location","eastoutside","Interpreter","none");
end

derived=artifact.Payload.Archive.Measurement;
value=double(derived.Value(:)); wavelength=double(derived.Wavelength(:));
percentValue=100.*value;
if hasSources, xlim(ax1,[wavelength(1) wavelength(end)]); end
ax2=nexttile(layout);
plot(ax2,wavelength,percentValue,"k-","LineWidth",1.7, ...
    "DisplayName",displayName(artifact.Quantity));
hold(ax2,"on"); yline(ax2,100,"--","100 %","HandleVisibility","off");
grid(ax2,"on"); box(ax2,"on");
xlabel(ax2,"Wavelength (nm)");
ylabel(ax2,displayName(artifact.Quantity)+" (%)");
title(ax2,displayName(artifact.Quantity)+" = sample / reference");
legend(ax2,"Location","eastoutside","Interpreter","none");
xlim(ax2,[wavelength(1) wavelength(end)]);
ylim(ax2,[0 100]);

above=sum(value>1); below=sum(value<0);
sgtitle(layout,sprintf("SpectraLab Camera-41 input proof | " + ...
    "range %.3g-%.3g %% | >100 %%: %d | <0 %%: %d", ...
    min(percentValue),max(percentValue),above,below));
exportgraphics(fig,pngFile,"Resolution",options.Resolution);
result=struct("PNGFile",pngFile,"Minimum",min(value), ...
    "Maximum",max(value),"SamplesAboveOne",above, ...
    "SamplesBelowZero",below,"DisplayUnit","percent", ...
    "DisplayYLimits",[0 100]);
end

function value=displayName(quantity)
if string(quantity)=="spectral_transmittance"
    value="Spectral transmittance";
else
    value="Spectral reflectance";
end
end

function closeIfHidden(fig,showFigure)
if ~showFigure && isgraphics(fig), close(fig); end
end
