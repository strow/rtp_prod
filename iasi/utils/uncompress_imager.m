function [image_out lat_out lon_out] = uncompress_imager(calflag)

% function [image_out lat_out lon_out] = uncompress_imager(calflag)
%
% Convert compressed IASI imager data stored in calflag back into
% useable numbers (of type "single").
%
% Input:
%    calflag - [8461 x n] char or uint8 compressed data
%
% Output:
%    image_out - [4096 x n] 64x64 imager pixel radiances
%    lat_out   - [25 x n] 5x5 subgrid latitudes
%    lon_out   - [25 x n] 5x5 subgrid longitudes
%
% Also see "compress_imager.m"
%

% Created: 03 May 2010, Scott Hannon/Paul Schou
% Update: 19 May 2010, S.Hannon - bug fix for endian reverse indices
% Update: 21 May 2010, S.Hannon - bug fix for char conversion to
%    uint8 for char data read from RTP file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 1)
   error('Unexpected number of input arguments')
end
d = size(calflag);
if (length(d) ~= 2)
   error('Unexpected number of dimensions for calflag');
end
if (d(1) ~= 8461)
   error('Unexpected lead dimension for calflag')
end
nax = d(2);
%
if (~isa(calflag,'uint8') & ~isa(calflag,'char'))
   error('Unexpected data class for calflag; must be uint8 or char')
end


% Convert char to uint8
% Note: this is a work-around for a probem with matlab 2byte char data
% getting screwy after written to and read from an HDF4 RTP file. 
if (isa(calflag,'char'))
   junk = double(calflag);
   ii = find(junk > 128);
   junk(ii) = junk(ii) - 65536 + 256;
   calflag = cast(junk,'uint8');
end


% Check endian
junk = calflag(8393:8394,:);
endian_dat = typecast(junk(:),'uint16');
irev = find(endian_dat == 256);
nrev = length(irev);


% Do uncompression
junk = calflag(1:8192,:);
junk2 = reshape( typecast(junk(:),'int16'), 4096,nax);
%
junk = calflag(8193:8292,:);
lat_out = reshape( typecast(junk(:),'single'), 25,nax);
%
junk = calflag(8293:8392,:);
lon_out = reshape( typecast(junk(:),'single'), 25,nax);
clear junk
%
if (nrev > 0)
   junk2(:,irev) = swapbytes(junk2(:,irev));
   lat_out(:,irev) = swapbytes(lat_out(:,irev));
   lon_out(:,irev) = swapbytes(lon_out(:,irev));
end
image_out = single(junk2)/100.0;


%%% end of function %%%
