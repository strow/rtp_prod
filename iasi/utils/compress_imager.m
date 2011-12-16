function [ImageZ] = compress_imager(IASI_Image, ImageLat, ImageLon);

% function [ImageZ] = compress_imager(IASI_Image, ImageLat, ImageLon);
%
% Compressed IASI Imager data in RTP calflag.  The radiance is multiplied
% by 100 and rounded to 2 byte integers, while lat/lon is converted to
% 4 byte reals.  All data is then converted to uint8 (ie char).
%
% Input:
%    IASI_Image - [n x 4096] 64x64 pixel radiances
%    ImageLat   - [n x 25] 5x5 subgrid latitude
%    ImageLon   - [n x 25] 5x5 subgrid longitude
%
% Output:
%    ImageZ     - [8461 x n] uint8 compressed imager data
%
% Also see "uncompress_imager.m"
%

% Created: 03 May 2010, Scott Hannon & Paul Schou
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 3)
   error('Unexpected number of input arguments')
end
%
d = size(IASI_Image);
if (length(d) ~= 2)
  error('Unexpected number of dimensions for IASI_Image')
end
nax = d(1);
if (d(2) ~= 4096)
   error('Unexpected number of pixels for IASI_Image')
end
%
d = size(ImageLat);
if (length(d) ~= 2)
   error('Unexpected number of dimensions for ImageLat')
end
if (d(1) ~= nax)
   error('Lead dimension of all input arguments must match')
end
if (d(2) ~= 25)
   error('Unexpected number of subgrid latitudes for ImageLon')
end
%
d = size(ImageLon);
if (length(d) ~= 2)
   error('Unexpected number of dimensions for ImageLon')
end
if (d(1) ~= nax)
   error('Lead dimension of all input arguments must match')
end
if (d(2) ~= 25)
   error('Unexpected number of subgrid longitudes for ImageLon')
end


% Compress imager pixel data
junk = int16( round(IASI_Image*100) )'; %' [4096 x nax]
image_dat = reshape( typecast(junk(:),'uint8'), 8192,nax);

% Compress imager subgrid lat/lon data
junk = single([ImageLat ImageLon])'; %' [25+25 x nax]
location_dat = reshape( typecast(junk(:),'uint8'), 200,nax);

% Append a uint16 value of 1 to end for endian determination
% Note: a uint16 value of 1 will appear as 256 if endian is switched
endian_dat = reshape( typecast(uint16(ones(1,nax)),'uint8'), 2,nax);

% Combine compressed data in output argument
ImageZ = zeros(8461,nax,'uint8');
ImageZ(1:8394,:) = [image_dat; location_dat; endian_dat]; % [8192+200+2 x nax]

%%% end of function %%%
