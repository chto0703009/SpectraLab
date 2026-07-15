%% validate_cri
% Validate CIE CRI calculation using a measured LED archive.

startup

%[fileName, folderName] = uigetfile( ...
%    "*.mat", ...
%    "Select the LED reference archive");
%
%if isequal(fileName,0)
%    error("No LED archive selected.");
%end

fileName="/Users/christer/Desktop/SpectraLab_v0.7.0-analysis/redfilter_csw_ref.mat"
archive = spectralab.archive.load(fullfile(folderName,fileName));
spec = spectralab.archive.restore(archive);

assert(isa(spec,"spectralab.core.Spectrum"), ...
    "Archive did not restore to a Spectrum.");

criResult = spectralab.analysis.cri(spec);

fprintf("\nCIE 13.3 Colour Rendering\n");
fprintf("-------------------------\n");
fprintf("Reference illuminant : %s\n", criResult.ReferenceIlluminant.Kind);
fprintf("CCT                  : %.0f K\n", criResult.Result.CCT);
fprintf("Duv                  : %+0.6f\n", criResult.Result.Duv);
fprintf("Ra                   : %.2f\n\n", criResult.Result.Ra);

for k = 1:14
    fprintf("R%-2d = %7.2f\n",k,criResult.Result.R(k));
end
