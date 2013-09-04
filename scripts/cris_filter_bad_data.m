function [head prof] = cris_filter_bad_data(head, prof)
% function [head prof] = cris_filter_bad_data(head, prof)
%
% Remove FoVs with bad rtime, rlat, or rlon.
%
% Bad data means either:
%   NaNs, invalid times, invalid lats and lons.
%
% Breno Imbiriba - 2013.09.04


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Remove buggy CrIS rtime, rlat, and rlon
  lbad_rtime = (tai2mattime(prof.rtime,2000)<datenum(2008,1,1) |...
                tai2mattime(prof.rtime,2000)>now | isnan(prof.rtime));
  lbad_geo = (abs(prof.rlat)>90 | prof.rlon<-180 | prof.rlon > 360 | isnan(prof.rlon) | isnan(prof.rlat));
  if(numel(find(lbad_rtime | lbad_geo))>0)
    disp(['Warning: There are ' num2str(numel(find(lbad_rtime | lbad_geo))) ...
        ' FoVs with bad GEO/TIME. Removing']);
    [head prof] = subset_rtp(head, prof, [], [], find(~lbad_rtime & ~lbad_geo));
  end

end
