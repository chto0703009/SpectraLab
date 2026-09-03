% plot_compare_spectra.m
%
% Compare either two Camera-41 derived artifacts, two reference/sample
% transmission pairs, or two measured SpectraLab archives. Inputs are
% read-only and are never modified.

%% Select two archives

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
archiveFolder = fullfile(examplesRoot, "data");

if ~isfolder(archiveFolder)
    error("plot_compare_spectra:ArchiveFolderNotFound", ...
        "Archive folder not found:\n%s", archiveFolder);
end

archiveFolder = analysis_archive_folder(string(archiveFolder));
[modeIndex,confirmed]=listdlg("SelectionMode","single", ...
    "ListString",cellstr([ ...
    "Two derived Camera-41 MAT files (no new ratio calculation)" ...
    "Two REFERENCE/SAMPLE pairs (calculate transmission)" ...
    "Two measured or mean spectra (direct overlay)"]), ...
    "InitialValue",1,"Name","SpectraLab - Select comparison input", ...
    "PromptString","What should plot_compare_spectra compare?");
if ~confirmed
    disp("Spectrum comparison cancelled.");
    return
end
if modeIndex==2
    run(fullfile(scriptFilePath(scriptFile),"compare_transmission_pairs.m"));
    return
elseif modeIndex==1
    selectionFunction=@selectDerivedArtifact;
    comparisonType="derived Camera-41 artifacts";
else
    selectionFunction=@selectSpectrum;
    comparisonType="measured or mean spectra";
end

first = selectionFunction(archiveFolder, "FIRST");
if isempty(first)
    disp("First archive selection cancelled.");
    return
end

second = selectionFunction(first.Folder, "SECOND");
if isempty(second)
    disp("Second archive selection cancelled.");
    return
end
if first.File == second.File && first.Name == second.Name
    error("plot_compare_spectra:IdenticalSelection", ...
        "Select two different spectra for comparison.");
end
if modeIndex==1 && first.Quantity~=second.Quantity
    error("plot_compare_spectra:ArtifactQuantityMismatch", ...
        "Select two artifacts of the same quantity, not %s and %s.", ...
        first.Quantity,second.Quantity);
end
if lower(strtrim(first.Spectrum.PowerUnit)) ~= ...
        lower(strtrim(second.Spectrum.PowerUnit))
    error("plot_compare_spectra:UnitMismatch", ...
        "Spectra use different units and cannot share one y-axis:\n  %s\n  %s", ...
        first.Spectrum.PowerUnit, second.Spectrum.PowerUnit);
end

lowerNm = max([400, min(first.Spectrum.WavelengthNm), ...
    min(second.Spectrum.WavelengthNm)]);
upperNm = min([730, max(first.Spectrum.WavelengthNm), ...
    max(second.Spectrum.WavelengthNm)]);
if lowerNm >= upperNm
    error("plot_compare_spectra:NoCommonWavelengthRange", ...
        "The selected spectra have no common wavelength range.");
end

%% Create comparison figure

profile = spectralab.report.internal.figureLayoutProfile();
fig = figure("Name", "Compare spectra", "NumberTitle", "off", ...
    "Color", "white", "Position", profile.InteractiveFigurePosition);
ax = axes("Parent", fig, "Position", profile.AxesWithSidebar);

spectralab.plot.spectrum(first.Spectrum, Parent=ax, Normalize=false, ...
    Title="Spectrum comparison", LineWidth=1.6, Color=[0.85 0.15 0.15], ...
    LineStyle="-", Marker="none", DisplayName=first.Name, ...
    ShowGrid=true, ShowSummary=false,ShowSpectralColorBar=false);
hold(ax, "on");
spectralab.plot.spectrum(second.Spectrum, Parent=ax, Normalize=false, ...
    Title="Spectrum comparison", LineWidth=1.6, Color=[0.10 0.35 0.85], ...
    LineStyle="-", Marker="none", DisplayName=second.Name, ...
    ShowGrid=true, ShowSummary=false,ShowSpectralColorBar=false);
hold(ax, "off");
xlim(ax, [lowerNm upperNm]);
ylim(ax,"padded");
if modeIndex==1
    if first.Quantity=="spectral_transmittance"
        ylabel(ax,"Transmission (%)");
        title(ax,"Spectral transmission comparison");
    else
        ylabel(ax,"Reflectance (%)");
        title(ax,"Spectral reflectance comparison");
    end
end

legendHandle = legend(ax, "Location", "eastoutside", "Interpreter", "none");
legendHandle.Units = "normalized";
legendHandle.Position = ...
    spectralab.report.internal.sideLegendPosition(legendHandle.String);
ax.Toolbar.Visible = "off";

addComparisonInformation(fig, first, second, lowerNm, upperNm,comparisonType);
drawnow;

%% Save comparison PNG

locations = resolve_analysis_output_folders(first.File);
safeFirst = safeFilePart(first.Name);
safeSecond = safeFilePart(second.Name);
pngFile = fullfile(locations.PlotFolder, ...
    "compare_" + safeFirst + "_vs_" + safeSecond + ".png");

if isfile(pngFile)
    warning("plot_compare_spectra:FigureAlreadyExists", ...
        "The PNG file already exists and was not overwritten:\n%s\n\n" + ...
        "Delete or rename the existing file before saving again.", pngFile);
else
    exportgraphics(fig, pngFile, "Resolution", 300);
    fprintf("\nComparison figure saved:\n  %s\n\n", pngFile);
end

function folder=scriptFilePath(scriptFile)
folder=string(fileparts(scriptFile));
end

function selected=selectDerivedArtifact(initialFolder,ordinal)
selected=[];
[fileName,pathName]=uigetfile(fullfile(initialFolder,"*.mat"), ...
    "SpectraLab - select "+ordinal+" derived Camera-41 MAT file");
if isequal(fileName,0), return; end
pathName=analysis_archive_folder(initialFolder,string(pathName));
artifactFile=string(fullfile(pathName,fileName));
artifact=spectralab.archive.loadSpectralArtifact(artifactFile);
assert(string(artifact.Kind)=="single_spectrum" && ...
    any(string(artifact.Quantity)== ...
    ["spectral_transmittance","spectral_reflectance"]), ...
    "plot_compare_spectra:NotDerivedCamera41Spectrum", ...
    "Select a derived Camera-41 transmission or reflectance MAT file. "+ ...
    "Measured archives require the measured/mean comparison mode.");
archive=artifact.Payload.Archive;
source=spectralab.archive.restore(archive);
quantity=string(artifact.Quantity);
if quantity=="spectral_transmittance"
    unit="Spectral transmission (%)";
else
    unit="Spectral reflectance (%)";
end
spec=spectralab.core.Spectrum(source.WavelengthNm,100.*source.Power, ...
    source.Label,source.Instrument,source.Calibration,source.Metadata,unit);
[~,fileStem]=fileparts(fileName);
displayName=string(archive.Measurement.Name);
if strlength(strtrim(displayName))==0, displayName=string(fileStem); end
selected=struct("Archive",archive,"Spectrum",spec, ...
    "Artifact",artifact,"Quantity",quantity,"File",artifactFile, ...
    "Folder",string(pathName),"Name",displayName);
end

function selected = selectSpectrum(initialFolder, ordinal)
selected = [];
[fileName, pathName] = uigetfile(fullfile(initialFolder, "*.mat"), ...
    "SpectraLab - Compare spectra: select " + ordinal + " archive");
if isequal(fileName, 0)
    return
end

pathName = analysis_archive_folder(initialFolder, string(pathName));
archiveFile = string(fullfile(pathName, fileName));
nameOverride = "";
try
    archive = spectralab.archive.load(archiveFile);
catch ME
    loaded = load(archiveFile, "series");
    if ~isfield(loaded, "series") || ...
            ~isfield(loaded.series, "Patches") || isempty(loaded.series.Patches)
        rethrow(ME)
    end
    patchLabels = string({loaded.series.Patches.Coordinate});
    [patchIndex, confirmed] = listdlg(SelectionMode="single", ...
        ListString=cellstr(patchLabels), InitialValue=1, ...
        Name="SpectraLab - Select ColorChecker patch", ...
        PromptString="Select the " + lower(ordinal) + " patch spectrum.");
    if ~confirmed
        return
    end
    patch = loaded.series.Patches(patchIndex);
    archive = spectralab.archive.create(patch.Spectrum);
    [~, collectionName] = fileparts(fileName);
    nameOverride = string(collectionName) + "_" + patch.Coordinate;
end

spec = spectralab.archive.restore(archive);
[~, archiveName] = fileparts(fileName);
displayName = string(archiveName);
if nameOverride ~= ""
    displayName = nameOverride;
elseif isfield(archive, "Measurement") && ...
        isfield(archive.Measurement, "Name") && ...
        strlength(strtrim(string(archive.Measurement.Name))) > 0
    displayName = string(archive.Measurement.Name);
end

selected = struct("Archive", archive, "Spectrum", spec, ...
    "File", archiveFile, "Folder", string(pathName), "Name", displayName);
end

function addComparisonInformation(fig, first, second, lowerNm, upperNm,type)
firstSummary = first.Spectrum.summaryStruct();
secondSummary = second.Spectrum.summaryStruct();
text = sprintf([ ...
    'COMPARISON\n%s\n\n' ...
    'First (red)\n%s\nPeak: %.2f nm\n\n' ...
    'Second (blue)\n%s\nPeak: %.2f nm\n\n' ...
    'Unit\n%s\n\nCommon range\n%.0f–%.0f nm'], ...
    type,first.Name, firstSummary.peak_wavelength_nm, ...
    second.Name, secondSummary.peak_wavelength_nm, ...
    first.Spectrum.PowerUnit, lowerNm, upperNm);
annotation(fig, "textbox", [0.77 0.18 0.21 0.48], ...
    "String", text, "Interpreter", "none", "EdgeColor", [0.8 0.8 0.8], ...
    "BackgroundColor", "white", "FitBoxToText", "off", ...
    "VerticalAlignment", "top", "FontSize", 9);
end

function value = safeFilePart(value)
value = regexprep(strtrim(string(value)), "[^A-Za-z0-9._-]+", "_");
value = strip(value, "_");
if strlength(value) == 0
    value = "spectrum";
end
end
