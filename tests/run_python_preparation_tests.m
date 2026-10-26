function run_python_preparation_tests(options)
%RUN_PYTHON_PREPARATION_TESTS Read-only discovery; optional disposable online setup.
arguments
 options.Download (1,1) logical=false
end
root=string(fileparts(fileparts(mfilename('fullpath'))));addpath(fullfile(root,'spectralab'));
before=dir(fullfile(root,'.python'));report=spectralab.runtime.ensurePython(Mode="identify");after=dir(fullfile(root,'.python'));
assert(isequal(before,after),'Identify must not modify managed interpreter files.');
assert(isfield(report,'Status'));
if ~options.Download
 disp('PYTHON_IDENTIFY_READ_ONLY_PASS; use Download=true for a new isolated environment.');return
end
folder=string(tempname);mkdir(folder);cleanup=onCleanup(@() rmdir(folder,'s'));
python=spectralab.runtime.preparePython(folder,600);
copyfile(fullfile(root,'requirements.txt'),fullfile(folder,'requirements.txt'));
if isfile(fullfile(root,'requirements-tools.txt')),copyfile(fullfile(root,'requirements-tools.txt'),fullfile(folder,'requirements-tools.txt'));end
[status,output]=spectralab.runtime.invoke(python,["-I",fullfile(root,'tools','manage_python_environment.py'),"sync","--root",folder],900);
assert(status==0,'Suite:Preparation','%s',output);
local=fullfile(folder,'.venv','bin','python');
[status,output]=spectralab.runtime.invoke(local,["-I",fullfile(root,'tools','manage_python_environment.py'),"check","--root",folder],180);
assert(status==0,'Suite:Health','%s',output);
report=jsondecode(output);assert(string(report.PythonVersion)=="3.13.6" && report.Isolated);
disp('PRIVATE_PYTHON_PREPARATION_AND_HEALTH_PASS');
end
