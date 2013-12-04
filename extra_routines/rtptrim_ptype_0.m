function [head hattr prof pattr] = rtptrim_ptype_0(head, hattr, prof, pattr, parent)
% function [head hattr prof pattr] = rtptrim_ptype_0(head, hattr, prof, pattr, parent)
%
% Sometimes we want to trim a calculated RTP file but keeping only the "level"
% profiles, which will remain saved in the parent file.
%
% This routine trims the provided *calculated* RTP structures, removing level 
% gases and adjusting the header appropriatedely.
%
% INPUT
%   head, hattr, prof, pattr - RTP structures after klayers and sarta. 
%   parent - parent file name.
% 
% OUTPUT
%   head, hattr, prof, pattr - Trimmed RTP structures.
%    
% Breno Imbiriba - 2013.09.05


  % Remove ptype=1 type profiles:
  fns={'gas_1','gas_2','gas_3','gas_4','gas_5','gas_6',...
                       'gas_9','gas_12','plevs','palts','ptemp'};
  for iff=1:numel(fns)
    if(isfield(prof,fns{iff}))
      prof = rmfield(prof,fns{iff});
    end
  end
  [head hattr prof pattr] = rtptrim(head,hattr,prof,pattr,'parent',parent,'allowempty');


  % Fix header 
  % - Remove fields modified by Klayers
  head = rmfield(head, {'glist','gunit','ngas','pmin','pmax'});
  % - Change ptype to Level profiles
  head.ptype = 0;



end

