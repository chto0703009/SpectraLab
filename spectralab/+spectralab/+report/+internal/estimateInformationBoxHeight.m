function height = estimateInformationBoxHeight(model)
%ESTIMATEINFORMATIONBOXHEIGHT Deterministic InformationBox height.
arguments
    model (1,1) struct
end
if ~isfield(model,"MetadataRows") || ~isfield(model,"ResultRows") || ...
        ~isstruct(model.MetadataRows) || ~isstruct(model.ResultRows)
    error("SpectraLab:Report:InvalidInformationBox", ...
        "InformationBox must contain MetadataRows and ResultRows.");
end
rowHeight = 16;
titleHeight = 22;
sectionGap = 8;
boxPadding = 12;
height = titleHeight + boxPadding + ...
    numel(model.MetadataRows)*rowHeight + ...
    sectionGap + numel(model.ResultRows)*rowHeight + boxPadding;
end
