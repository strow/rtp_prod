function [sat] = readl2sup_list_doppler(fn, iatrack, ixtrack);

% function [sat] = readl2sup_list_doppler(fn, iatrack, ixtrack);
%
% Read satellite position information from an AIRS L2.RetSup granule
% file. Intended for use with Doppler frequency shift calculations.
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%    'AIRS.2003.05.27.168.L2.RetSup.v5.0.3.0.Focus.T06344105956.hdf'
%    iatrack = [1 x n] desired along-track (1-45 scanline) indices
%    ixtrack = [1 x n] desired cross-track (1-30 footprint) indices
%
% Output:
%    sat = [structure] of satellite position info for three adjacent
%       scanlines, consisting of the following [1 x n] double fields:
%       lat1,lat2,lat3          : latitude at time1,2,3 {degrees}
%       lon1,lon2,lon3          : longitude at time1,2,3 {degrees}
%       height1,height2,height3 : height at time1,2,3 {meters}
%       time1,time2,time3       : TAI time {seconds}
%

% Created: 14 October 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Granule dimensions
nxtrack = 30;
natrack = 45;
nobs = nxtrack*natrack;


% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error, bad fn: ' fn])
   return
end


% Open granule file
file_name = fn;
file_id   = hdfsw('open',file_name,'read');
swath_str = 'L2_Support_atmospheric&surface_product';
swath_id  = hdfsw('attach',file_id,swath_str);


% Read satellite position info
[junk,s] = hdfsw('readfield',swath_id,'sat_lat',[],[],[]);
if s == -1; disp('Error reading sat_lat');end;
sat_lat = double(junk'); %'

[junk,s] = hdfsw('readfield',swath_id,'sat_lon',[],[],[]);
if s == -1; disp('Error reading sat_lon');end;
sat_lon = double(junk'); %'

[junk,s] = hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight');end;
satheight = 1000.0*double(junk'); %'

[junk,s] = hdfsw('readfield',swath_id,'nadirTAI',[],[],[]);
if s == -1; disp('Error reading nadirTAI');end;
nadirTAI = double(junk'); %'


% Close granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error');end;


% Indices for satellite positions 1,2,3
ind1 = [1, 1:(natrack-2), natrack-2];
ind2 = [2, 2:(natrack-1), natrack-1];
ind3 = [3, 3:natrack    , natrack];


% Indices for iatrack, ixtrack
[ikeep] = l2_track2ind(iatrack, ixtrack);


% Create output structure
junk = reshape(ones(nxtrack,1)*sat_lat(ind1),1,nobs);
sat.lat1 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*sat_lat(ind2),1,nobs);
sat.lat2 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*sat_lat(ind3),1,nobs);
sat.lat3 = junk(ikeep);
%
junk = reshape(ones(nxtrack,1)*sat_lon(ind1),1,nobs);
sat.lon1 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*sat_lon(ind2),1,nobs);
sat.lon2 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*sat_lon(ind3),1,nobs);
sat.lon3 = junk(ikeep);
%
junk = reshape(ones(nxtrack,1)*satheight(ind1),1,nobs);
sat.height1 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*satheight(ind2),1,nobs);
sat.height2 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*satheight(ind3),1,nobs);
sat.height3 = junk(ikeep);
%
junk = reshape(ones(nxtrack,1)*nadirTAI(ind1),1,nobs);
sat.time1 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*nadirTAI(ind2),1,nobs);
sat.time2 = junk(ikeep);
junk = reshape(ones(nxtrack,1)*nadirTAI(ind3),1,nobs);
sat.time3 = junk(ikeep);

%%% end of function %%%
