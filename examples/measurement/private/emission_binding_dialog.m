function binding=emission_binding_dialog(defaultFrame,defaultSeries)
%EMISSION_BINDING_DIALOG Explicit semantic identity for a measured signal.
answer=inputdlg({'Role (lamp, light_reference, base_plus_fog, gray_exposure, colorchecker_exposure, unassigned)','Film ID','Roll ID','Physical frame / step ID','Series ID','Reference measurement UUID (if known)'},'Emission measurement identity',[1 85],{'unassigned','','',char(defaultFrame),char(defaultSeries),''});
assert(~isempty(answer),'SpectraLab:Measurement:Cancelled','Emission measurement cancelled before acquisition.');
role=strip(string(answer{1}));assert(any(role==["lamp","light_reference","base_plus_fog","gray_exposure","colorchecker_exposure","unassigned"]),'Unknown measurement role.');
binding=struct('Role',char(role),'FilmID',answer{2},'RollID',answer{3},'FrameID',answer{4},'SeriesID',answer{5},'ReferenceMeasurementID',answer{6});
end
