function [map ct_b bin] = binprofdyn(lat,lon,data,lat_edges,lon_edges)
% [map ct_b ibin] = BINPROFDYN(lat,lon,data,lat_edges,lon_edges)
%                       = BINPROFDYN(lat,lon,data,deg_size)
%                       = BINPROFDYN(lat,lon,data,lat_step,lon_step)
%
%     Input :   lat       : retrieval latitude loc. (N)
%               lon       : retrieval longitude loc. (N)
%               data      : retrieval values (N x b)
%               lat_egdes : edges for latitude bins (default -90:5:90)
%               lon_egdes : edges for longitude bins (default -180:5:180)
%               deg_size  : step size in degrees to bin profiles
%               lat_step  : step size in degrees to bin lat profiles
%               lon_step  : step size in degrees to bin lon profiles
%
%     Output :  map       : 2D averaged map
%               ct_b      : counts per bin
%               ibin      : bin index for data points
%
% Examples of usage:
%
%    x=-10:10;y=-20:2:20;dat=rand(1,21)*100;
%    binprofdyn(y,x,dat)
%    % or to specify a fine / coarse resolution:
%    binprofdyn(y,x,dat,2) % 2 degree bins
%    binprofdyn(y,x,dat,-40:10:40,-50:10:50) % or to specify the bin area

% BINPROFDYN - version 2.0 beta

% Written by Paul Schou - 29 Oct 2009  V1.1 (paulschou.com)
% Updates:
%   18 Nov 2009 - minor bug fixes, added 2D capabilities
%   31 Mar 2011 - added the returning of the ibin values for remapping the data

% Input checking
if nargin == 3
    lon_edges = -180:5:180;
    lat_edges = -90:5:90;
    lon = mod(lon+180,360)-180;
elseif nargin == 4
    if numel(lat_edges) == 1
        if lat_edges <= 0
            error('BINPROFDYN: Degree step must be positive')
        end
        lon_edges = -180:lat_edges:180;
        lat_edges = -90:lat_edges:90;
        lon = mod(lon+180,360)-180;
    else
        error('BINPROFDYN: Both lat_edges and lon_edges must be specified')
    end
elseif nargin == 5
    if numel(lat_edges) == 1 && numel(lon_edges) == 1
        if lat_edges <= 0 || lon_edges <= 0
            error('BINPROFDYN: Degree step must be positive')
        end
        lon_edges = -180:lon_edges:180;
        lat_edges = -90:lat_edges:90;
        lon = mod(lon+180,360)-180;
    elseif numel(lat_edges) == 1 || numel(lon_edges) == 1
        error('BINPROFDYN: Both lat_edges and lon_edges must be vectors')
    end
else
    error('BINPROFDYN: Not enough inputs')
end

% Size checks
if ~all(size(lat)==size(lon))
    error('BINPROFDYN: Size of LAT and LON do not match');
end

data_size = size(data);
% the single last dimension on the data may be allowed to pass as long as the rest are the same
if ~all(size(lat)==data_size(1:ndims(lat))) && sum(size(lat)>1) >= sum(data_size>1) - 1
    error('BINPROFDYN: Size of DATA does not match LAT/LON, or match except for only one additional dimension');
end

% bin the latitudes
[dum,bin(:,1)] = histc(lat(:),lat_edges,1);
nlat = length(lat_edges)-1;
bin(:,1) = min(bin(:,1),nlat); % prevent inf from adding a bin

% bin the longitudes
[dum,bin(:,2)] = histc(lon(:),lon_edges,1);
nlon = length(lon_edges)-1;
bin(:,2) = min(bin(:,2),nlon); % prevent inf from adding a bin

% do we need to repeat to match an extra dimension
if ndims(lat) < ndims(data)
    nums = repmat(1:data_size(end),[length(bin) 1]);
    bin = [repmat(bin,[data_size(end) 1]) nums(:)'];
end

% Average the points together to make a map of data
ct_b = accumarray(bin(all(bin>0,2),:),1,[nlat nlon]);
n = accumarray(bin(all(bin>0,2),:),data(all(bin>0,2)),[nlat nlon]) ./ ct_b;
n(ct_b == 0) = nan;

if nargout > 0 
    map = n;
    if nargout > 2
        bin = sub2ind(size(map),bin(:,1),bin(:,2))';
    end
    return
end

ax = imagesc(lon_edges,lat_edges,n,'AlphaData',~isnan(n));
ax = get(ax,'Parent');

% Plot out a world map
hold(ax,'on')
load coast
plot(ax,long,lat,'Color',[1 1 1]*0.5)
hold(ax,'off')
axis xy; ylim(lat_edges([1 end]));xlim(lon_edges([1 end]));
