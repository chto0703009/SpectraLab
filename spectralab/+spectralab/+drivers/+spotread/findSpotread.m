function exe = findSpotread()
%FINDSPOTREAD Find a runnable machine-local ArgyllCMS spotread.
candidates=fullfile(string(java.lang.System.getProperty("user.home")),"Applications","ArgyllCMS","bin","spotread");
if ismac
 prefixes=["/opt/homebrew","/usr/local"];
 hardware=spectralab.runtime.nativeArchitecture();
 if hardware.Physical=="x86_64",prefixes=fliplr(prefixes);end
 for prefix=prefixes
  candidates=[candidates,fullfile(prefix,'opt','argyll-cms','bin','spotread'),fullfile(prefix,'bin','spotread')]; %#ok<AGROW>
 end
end
suffix="";if ispc,suffix=".exe";end
for folder=reshape(split(string(getenv('PATH')),pathsep),1,[])
 if folder~="",candidates(end+1)=fullfile(folder,"spotread"+suffix);end %#ok<AGROW>
end
candidates=unique(candidates,'stable');hardware=spectralab.runtime.nativeArchitecture();
if hardware.Physical=="arm64"
 native=false(size(candidates));
 for k=1:numel(candidates),info=spectralab.runtime.nativeArchitecture(candidates(k));native(k)=info.Native;end
 candidates=[candidates(native),candidates(~native)];
end
exe="";
for candidate=candidates
 if isfile(candidate) && works(candidate),exe=candidate;return;end
end
end
function yes=works(executable)
yes=false;
try
 [code,output]=spectralab.runtime.invoke(executable,"-?",15);
 yes=any(code==[0,1]) && ~isempty(regexp(char(output),'Version\s+[0-9]+\.[0-9]+','once'));
catch
end
end
