function setup()
%SETUP Compatibility helper for first-time SpectraLab users.
%
%   SpectraLab uses STARTUP to configure the MATLAB path. This helper exists
%   only to guide users who naturally try SETUP first.

fprintf("SpectraLab uses startup to prepare the MATLAB path.\n\n");
fprintf("Running startup now...\n\n");
startup;
end
