function revision = rev_version()
% function revision = rev_version()
%
% Return a string with the GIT revision of the current running 
% rtp_prod code, acording to the "git describe" command.
%
% Breno Imbiriba - 2013.05.08


% get code directory:
base_dir = fileparts(mfilename('fullpath'));

% get version
[ss revision] = system(['cd ' base_dir ' && git describe']);

if(ss~=0)
  error(['git describe command returned ' num2str(ss) ]);
end

end
