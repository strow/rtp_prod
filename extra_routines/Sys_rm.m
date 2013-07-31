function [s output]=Sys_rm(filename)
% function [s output]=Sys_rm(filename)
% 
% Remove a file of list of files.
  special=char([0:31]);

  if(nargin==0)
    s=0; 
    output=[];    
    return
  end

  if(~iscell(filename))
    filename={filename};
  end
  filenames='';
  for ic=1:length(filename);

    % Check for empty file names
    if(numel(filename{ic})==0)
      continue
    end 

    % Check for iligal characters
    if(length(strfind(special,filename{ic}))>0)
      fprintf('Sys_rm: You are providing a file name that has invalid characters: %s.\n',filename{ic});
      error('Sys_rm: Invalid Filename')
    end

    % Check for how many files fit the request - accumulate.
    if(length(Sys_ls(filename{ic})))
      [success message messageid]=fileattrib(filename{ic});
      if(success==0)
        disp(['Sys_rm: file ' filename{ic} ' : ' message '.']);
      else 
	if(message.UserWrite)
	  filenames=[filenames ' ' filename{ic}];
	end
      end
    end
  end
  % check for unusual/problematic characters.
  %[s output]=system(['rm -i -- ' filenames  ' < /dev/null >/dev/null 2>/dev/null']);
  %[s output]=system(['rm -i  -- ' filenames  ' < /dev/null >/dev/null']);
  [s output]=system(['rm  -- ' filenames  ' < /dev/null >/dev/null']);
  %[s output]=system(['rm -f -- ' filenames  ' < /dev/null >/dev/null']);
  if(length(output)>0 & s==0)
    s=-1;
  end 
end

