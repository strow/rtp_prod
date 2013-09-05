function [dirlist]=Sys_ls(dirname,opt)
% function [dirlist]=Sys_ls(dirname)
% 
% Returns a cell array list of entries in the dyrectory dirname.
%
% ex.:  flist=Sys_ls('-1 *.rtp');
%
% opt = 'echo' : will use 'echo' instead of ls.
% Breno Imbiriba

if( nargin()==2 && strcmp(opt,'echo'))
  [j fnames]=system(['echo ' dirname ]);
  char10=strfind(fnames,' ');
  fnames(char10)=10;
else  
  [s fnames]=system(['ls ' dirname]);
  if(s~=0)
    dirlist={};
    return
  end
end

char10=strfind(fnames,10);

dirlist{1}=fnames(1:char10(1)-1);
for ic=2:length(char10)
  dirlist{ic}=fnames(char10(ic-1)+1:char10(ic)-1);
end

end
