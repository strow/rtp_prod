function [raderr] = readl2cc_raderr_list(fn, iatrack, ixtrack);

% function [raderr] = readl2cc_raderr_list(fn, iatrack, ixtrack);
%
% Reads an AIRS level 2 cloud-clear radiance granule file and returns
% an RTP-like structure of those FOVs specified by (iatrack,ixtrack).
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%       'AIRS.2004.05.01.183.L2.CC.v5.0.14.0.G07227135246.hdf'
%    iatrack = [1 x n] desired along-track (scanline) indices {1-45}
%    ixtrack = [1 x n] desired cross-track (footprint) indices {1-30}
%
% Output:
%    raderr = (nchan x n) radiance error estimate
%

% Created: 02 Apr 2008, Scott Hannon - based on readl2cc_list.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Granule dimensions
nchan=2378;
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;

raderr = [];


% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error: bad fn: ' fn])
   return
end


% Check along-track indices
d = size(iatrack);
if (length(d) ~= 2 | min(d) ~= 1)
   disp('Error: iatrack must be a [1 x n] vector')
   return
end
if (min(iatrack) < 1 | max(iatrack) > natrack)
   disp(['Error: iatrack must be within range 1-' num2int(natrack)]);
   return
end
n0 = length(iatrack);


% Check cross-track indices
d = size(ixtrack);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n0)
   disp('Error: ixtrack must be the same length as iatrack')
   return
end
if (min(ixtrack) < 1 | max(ixtrack) > nxtrack)
   disp(['Error: ixtrack must be within range 1-' num2int(nxtrack)]);
   return
end


% Open granule file
file_name=fn;
file_id  =hdfsw('open',file_name,'read');
swath_id =hdfsw('attach',file_id,'L2_Standard_cloud-cleared_radiance_product');


% Indices of desired FOVs
i0 = round( ixtrack + (iatrack-1)*nxtrack );


% Read in radiance error, reshape, and subset
% Note: this is a large array!
% radiance error is stored as (nchan x nxtrack x natrack)
[junk,s]=hdfsw('readfield',swath_id,'radiance_err',[],[],[]);
if s == -1; disp('Error reading radiance_err');end;
% reshape but do not convert to double yet
junk2 = reshape(junk, nchan,nobs);
clear junk
% subset and convert to double
raderr = double( junk2(:,i0) );
clear junk2


% Close L2CC granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2CC');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2CC');end;

%%% end of function %%%
