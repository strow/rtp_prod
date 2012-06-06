function [DATA rec] = readgrib_offset_data(fh,varargin)
%function [DATA rec] = readgrib_offset_data(fh,offset)
%
%  Generic GRIB record reader written in MATLAB to speed up the binary reading of GRIB data into Matlab.
%
%  INPUTS:
%    fh        - file handle of the GRIB file being read, NB: make sure it is opened with big endian
%                  for example:  fh = fopen('UAD03270000032703001','r','b');
%    offset    - bytes offset of the desired parameter
%
%    grib_file - path of grib file to read
%    param     - field to read
%    level     - level of field to read (")
%
%  Written: 2 May 2011 by Paul Schou

fseek(fh,varargin{1},-1);
recpos = varargin{1};

%%%%%%%%%%%%%%%%%
%%  1. HEADER  %%
%%%%%%%%%%%%%%%%%
head = fread(fh,72,'*uint8');
if(~isequal('GRIB',head(1:4)'))
  error('GRIB Record not found')
end

%rec.GRIB_Size= uint3(head(5),head(6),head(7));

if head(8) ~= 1
  error('Unsupported GRIB Version')
end
curpos = 9;

%%%%%%%%%%%%%%%%%%%%%%
%%  2. PDS SECTION  %%
%%%%%%%%%%%%%%%%%%%%%%
PDS_LEN = uint3(head(9),head(10),head(11));  % About 28 bytes

PDS_DecScale = int2(head(curpos+26),head(curpos+27));
GDSBMS = head(curpos+7);

if nargout > 1
  pds = head(9:PDS_LEN+8);
  rec.PDS_OrigCenter = pds(5);
  rec.PDS_Model_ID = pds(6);
  rec.PDS_Grid_ID = pds(7);
  %if bitand(pds(8),128); disp('has GDS'); end
  %if bitand(pds(8),64); disp('has BMS'); end
  rec.PDS_Parameter = pds(9);
  rec.PDS_LevelType = pds(10);
  rec.PDS_Level = uint2(pds(11),pds(12));
  rec_time = [double(pds(13))+double(pds(25)-1)*100 double(pds(14:17)') 0];
  rec.PDS_RecordTime = datenum(rec_time);

  forecast_increment = [0 0 0 0 0 0];
  if pds(18) < 5  % determine the forecast unit
    forecast_increment(5-pds(18)) = pds(19);
  elseif pds(18) == 5; forecast_increment(1) = 10 * pds(19);
  elseif pds(18) == 6; forecast_increment(1) = 30 * pds(19);
  elseif pds(18) == 7; forecast_increment(1) = 100 * pds(19);
  elseif pds(18) == 254; forecast_increment(6) = pds(19);
  else error('Unrecognized forecast unit');
  end
  rec.PDS_ForecastTime = datenum(rec_time+forecast_increment);
  %rec.pds = pds;
end
curpos = curpos+PDS_LEN;

% buffer the next read if needed
if curpos + 28 > length(head)
  fseek(fh,-length(head)+double(curpos)-1,0);
  curpos = 1;
  head = fread(fh,28,'*uint8');
end

%%%%%%%%%%%%%%%%%%%%%%
%%  3. GDS SECTION  %%
%%%%%%%%%%%%%%%%%%%%%%
if bitget(GDSBMS,8) % GDS if/then

GDS_LEN = uint3(head(curpos),head(curpos+1),head(curpos+2));  % About 768 bytes

GDS_LatLon_nx = double(uint2(head(curpos+6),head(curpos+7)));
GDS_LatLon_ny = double(uint2(head(curpos+8),head(curpos+9)));
if nargout > 1
  gds = head(curpos:curpos+27);
  GDS_LatLon_La1 = single(int3(gds(11),gds(12),gds(13)))/1000;
  GDS_LatLon_Lo1 = single(int3(gds(14),gds(15),gds(16)))/1000;
  GDS_LatLon_La2 = single(int3(gds(18),gds(19),gds(20)))/1000;
  GDS_LatLon_Lo2 = single(int3(gds(21),gds(22),gds(23)))/1000;
  if GDS_LatLon_Lo1 > GDS_LatLon_Lo2
    GDS_LatLon_Lo2 = GDS_LatLon_Lo2+360;
  end

  GDS_LatLon_dx = single(int2(gds(24),gds(25)))/1000;
  GDS_LatLon_dy = -single(int2(gds(26),gds(27)))/1000;
  GDS_LatLon_scan = gds(28);
  if bitget(GDS_LatLon_scan,8); GDS_LatLon_dx = -GDS_LatLon_dx; end
  if bitget(GDS_LatLon_scan,7); GDS_LatLon_dy = -GDS_LatLon_dy; end

  rec.Longitude = GDS_LatLon_Lo1:GDS_LatLon_dx:GDS_LatLon_Lo2;
  rec.Latitude = GDS_LatLon_La1:GDS_LatLon_dy:GDS_LatLon_La2;

  %rec.gds=gds;
end
curpos = curpos + GDS_LEN;

end % end GDS if

% buffer the next read if needed
if curpos + 4 > length(head)
  fseek(fh,-length(head)+double(curpos)-1,0);
  curpos = 1;
  head = fread(fh,20,'*uint8');
end

%%%%%%%%%%%%%%%%%%%%%%
%%  4. BMS SECTION  %%
%%%%%%%%%%%%%%%%%%%%%%
if bitget(GDSBMS,7) % BMS if/then
  BMS_LEN = uint3(head(curpos),head(curpos+1),head(curpos+2));
  %head(curpos+4)

  fseek(fh,-length(head)+double(curpos)+5,0);
  in = fread(fh,BMS_LEN-6,'*uint8')';
  BMS_DATA = reshape([bitget(in,8);bitget(in,7);bitget(in,6);bitget(in,5);bitget(in,4);bitget(in,3);bitget(in,2);bitget(in,1)],GDS_LatLon_nx,[]);

  %return % we have all we need, so return now!

  curpos = 1;
  head = [];

elseif bitget(GDSBMS,8) & GDS_LatLon_nx == 65535 % thin grid 
  BMS_LEN = uint3(head(curpos),head(curpos+1),head(curpos+2));

  %head(curpos:end)
  %head(curpos+3)

  fseek(fh,-length(head)+double(curpos)-double(GDS_LEN),0);
  gds = fread(fh,GDS_LEN,'uint8=>double');

  head = fread(fh,head(curpos+3)+1,'*uint8');
  in = fread(fh,(BMS_LEN-12)/2,'*uint16')';
  fread(fh,10,'*uint8');

  rec.BinScale = int2(head(4),head(5));
  rec.RefValue = double(ibm2flt(head(6:9)));

  grid_size = gds(32:2:end-1)*256+gds(33:2:end-1);

  DATA=nan(length(grid_size),max(grid_size),'single');

  %lats = [];
  %lons = [];
  isum = 1;
  for i = 1:length(grid_size)
    %lats = [lats ones(1,grid_size(i))*(90-180*(i-0.5)/length(grid_size))];
    %lons = [lons ((0:grid_size(i)-1)/grid_size(i)+.5)*360-180];
    DATA(i,:) = interp1(linspace(0,1,grid_size(i)+1),single(in([isum:isum+grid_size(i)-1 isum])),linspace(0,1,size(DATA,2)),'linear');
    isum = isum + grid_size(i);
  end
  %simplemap(lats,lons,in);

  DATA = DATA' * 2 ^ double(rec.BinScale) + rec.RefValue;

	[rec.GDS_LatLon_nx rec.GDS_LatLon_ny] = size(DATA);
  %rec.Longitude = GDS_LatLon_Lo1:rec.GDS_LatLon_dx:GDS_LatLon_Lo2;
  %rec.Latitude = GDS_LatLon_La1:rec.GDS_LatLon_dy:GDS_LatLon_La2;

  return
end % end BMS if

% buffer the next read if needed
if curpos + 20 > length(head)
  fseek(fh,-length(head)+double(curpos)-1,0);
  curpos = 1;
  head = fread(fh,20,'*uint8');
end

%%%%%%%%%%%%%%%%%%%%%%
%%  5. BDS SECTION  %%
%%%%%%%%%%%%%%%%%%%%%%
bds = head(curpos:curpos+15);
BDS_LEN = uint3(bds(1),bds(2),bds(3));

BDS_BinScale = int2(bds(5),bds(6));
BDS_RefValue = double(ibm2flt(bds(7:10)));
BDS_NumBits = double(bds(11));
BDS_DataStart = 11 + double(bitget(bds(4),5))*3;
%rec.bds = bds;

%rec.BDS_RefValue = BDS_RefValue;
%rec.BDS_BinScale = BDS_BinScale;
%rec.BDS_NumBits = BDS_NumBits;

% Data scaling parameters
scale = 2^double(BDS_BinScale) * 10^double(-PDS_DecScale);
rec.Scale = scale;
rec.RefValue = BDS_RefValue;

fseek(fh,-length(head)+double(curpos)+BDS_DataStart-1,0);
dat_len = BDS_LEN-BDS_DataStart-1;

if bitget(GDSBMS,7) & sum(BMS_DATA(:)==1)*BDS_NumBits/8 ~= dat_len;
  % a bug in the ECMWF grib writer seems to not present the correct number of bits in the BDS length
  disp(['Warning: indicated data length in BDS inconsistent with BMS selection, attempting to fix.'])
  dat_len = sum(BMS_DATA(:)==1)*BDS_NumBits/8;
end

%if dat_len == 0;
%elseif dat_len/(double(BDS_NumBits)/8) ~= GDS_LatLon_nx*GDS_LatLon_ny
%  recpos
%  dat_len
%  [GDS_LatLon_nx GDS_LatLon_ny]
%  BDS_LEN
%  BDS_NumBits
%  if exist('rec','var')
%    rec
%  end
%  error('Reshape failed: length changes in data field')
%end

if GDS_LatLon_nx == -1
  % do nothing
elseif BDS_NumBits == 8
  DATA = fread(fh,dat_len,'uint8=>double')*scale+BDS_RefValue;
elseif BDS_NumBits == 12
  % Three different methods for doing the next part.  The first is the best
  in = fread(fh,[3 dat_len/3],'*uint8');
  DATA = double([bitshift(typecast(reshape(in([2 1],:),1,[]),'uint16'),-4) ; bitand(typecast(reshape(in([3 2],:),1,[]),'uint16'),2^12-1)])*scale+BDS_RefValue;

  % Matrix op method
  %DATA = reshape(mod([16 1/16 0; 0 256 1]*fread(fh,[3 (BDS_LEN-BDS_DataStart-1)/3],'uint8=>double'),2^12)*scale+BDS_RefValue,[GDS_LatLon_nx GDS_LatLon_ny]);

  % Built-in matlab bit reader
  %DATA = fread(fh,[GDS_LatLon_nx GDS_LatLon_ny],'ubit12=>double')*scale+BDS_RefValue;

  % Matlab binary operators
  %in = fread(fh,(BDS_LEN-BDS_DataStart-1),'*uint8');
  %DATA = zeros(ceil(size(in)/1.5));
  %DATA(1:2:end) = bitshift(uint16(in(1:3:end)),4)+uint16(bitshift(in(2:3:end),-4));
  %DATA(2:2:end) = bitshift(uint16(bitand(in(2:3:end),uint8(15))),8)+uint16(in(3:3:end));
  %DATA = double(reshape(DATA,GDS_LatLon_nx,GDS_LatLon_ny)) * scale + double(BDS_RefValue);

  % MEX binary operators
  %DATA = reshape(int8to12(fread(fh,BDS_LEN-BDS_DataStart-1,'*uint8')),GDS_LatLon_nx,GDS_LatLon_ny)*scale+BDS_RefValue;
elseif BDS_NumBits == 16
  DATA = fread(fh,dat_len/2,'uint16=>double')*scale+BDS_RefValue;
  %DATA = fread(fh,(BDS_LEN-BDS_DataStart-1)/2,'uint16=>double')*scale+BDS_RefValue;
end

if isfield(rec,'rec.PDS_OrigCenter') & rec.PDS_OrigCenter == 7
  DATA = DATA - BDS_RefValue + BDS_RefValue * scale;
end

if bitget(GDSBMS,7)
  BMS_DATA = double(BMS_DATA);
  BMS_DATA(BMS_DATA==0) = NaN;
  if sum(BMS_DATA(:) == 1) == length(DATA)
    BMS_DATA(BMS_DATA==1) = DATA;
  else
    sum(BMS_DATA(:) == 1)
    length(DATA)
    dat_len
    BDS_NumBits
    error('  could not fix: BMS and BDS lengths differ');
  end
  DATA = BMS_DATA;
end

t = fread(fh,5,'*uint8')';
if ~isequal(t,[0 55 55 55 55]);
  if bitget(GDSBMS,7) & isequal(t(1:4),[55 55 55 55])
    disp('  fixed BDS selection');  % BMS length bug!
  else
    t
    GDSBMS
    BDS_NumBits
    [GDS_LatLon_nx,GDS_LatLon_ny]
    dat_len
    recpos
    error('Grib record does not end in \0 7777');
  end
end

try
DATA=reshape(DATA,GDS_LatLon_nx,GDS_LatLon_ny);
catch e
keyboard
end

end % End of function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Other supporting functions  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = ibm2flt(ibm);

mant = uint3(ibm(2),ibm(3),ibm(4));

% Zero cases
if mant == 0; value = 0; return; end
if isequal(ibm(:)',[55 17 151 127]); value = 0; return; end  % GRIB cfrac field

positive = bitget(ibm(1),8) == 0;
power = double(bitand(ibm(1),127)) - 64;
abspower = abs(power);

% calc exp
e_val = 16.0;
value = 1.0;
while (abspower ~= 0)
  if bitand(abspower,1)
    value = value * e_val;
  end
  e_val = e_val * e_val;
  abspower = bitshift(abspower,-1);
end

if (power < 0); value = 1.00 / value; end
value = value * double(mant) / 16777216.0;
if (positive == 0); value = -value; end

end

function i = int2(a,b)
i = (1-int16(bitshift(bitand(a,128),-6)))*int16(bitshift(bitand(a,127),8)+b);
end

function i = int3(a,b,c)
i = (1-int32(bitshift(a,-6))) * int32(bitshift(bitand(uint32(a),127),16) + (bitshift(uint32(b),8) + uint32(c)));
end

function i = uint2(a,b)
i = bitshift(uint16(a),8)+uint16(b);
end

function i = uint3(a,b,c)
i = bitshift(uint32(a),16)+bitshift(uint32(b),8)+uint32(c);
end
