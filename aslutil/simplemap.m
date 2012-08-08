function [data_out handle ibin out] = simplemap(varargin)
% function [data handle ibin stats] = simplemap(...) 
%   Makes a plot of data spaced evenly on a cartesian coordinate map. 
%
% This routine was made to provide a very simple to use visualization
%  toolbox where maps are overlayed on a satellite image / coast outlines
%
% Inputs:
%   rlat/lon - location coordinates in vectors for data matrix
%   data     - Matrix with data to display on map, either 2D or a vector
%     *see below for usage and explainations*
%
% Outputs:
%   data_out - Matrix of data displayed on map
%   handle   - axis handle of the matlab figure
%   ibin     - binning for each of the data points
%   stats    - statistics per bin, structure with min/max/mean/mode/kurtosis/skewness
%
% Example of usage:
%   data = rand(10);                   % generate a random data set
%   data(rand(10) > 0.7) = nan;        % with fewer than a quarter nans
%   simplemap(data)                    % this will plot data on a basic coast map
%   simplemap(rlat,rlon,data)          % .. using rlat/rlon and the default 1x1 degree grid
%   simplemap(rlat,rlon,data,'auto')   % .. estimates a good grid size based on lat/lon values
%   simplemap(rlat,rlon,data,gridsize) % .. specifies the grid size (0.25 = quarter degree)
%   simplemap(... ,'Background',0.5)   % satellite image underlay (default=nan)
%   simplemap(... ,'Coast',[0 0 0])    % coastal lines overlay (default=[1 1 1]*0.5)
%   simplemap(... ,'State',[0 0 0])    % state lines overlay (default=nan)
%   simplemap(... ,'Country',[0 0 0])  % country lines overlay (default=nan)
%   simplemap(... ,'Alpha',0.9)        % data image overlay transparency (default=0.9)
%   simplemap(... ,'Cities',pop)       % Mark cities above population: pop
%               note: pop can be an array [2E6 4E6 6E6] to make circles of increasing size
%   simplemap(... ,'CityPosition',p)   % Where to put name -1 Rand, Clockwise: [0:.5:3.5]
%
%   An empty map example:
%     simplemap(nan,'Cities',[8E6 10E6 12E6],'CityPosition',[1.5 3.5 .5],'Background',0.5)
%
% Image functions:
%   simplemap(... ,'flip')             % flip the map upsidedown (when data is a matrix)
%   simplemap(... ,'shift')            % shift the map by 180 degrees
%   simplemap(... ,'shiftto',lon)      % shift the map to starting longitude (default=-180)
%   simplemap(... ,'clabel','Kelvin')  % label the colorbar
%
% Location bounds:
%   simplemap(... ,'lat',[-90 90])     % specify latitude range of data (default=[-90 90])
%   simplemap(... ,'lon',[-180 180])   % specify longitude range of data (default=[-180 180])
%   simplemap(... ,'auto')             % automatically specify the range in the plot
%
% Filters to choose from:
%   simplemap(... ,'nfilt')            % single pixel noise filter
%   simplemap(... ,'ngrow')            % fill in point-wise single nan pixels in data
%   simplemap(... ,'pgrow')            % expand single pixels for better visualization

% Written by Paul Schou - 19 Nov 2009  V1.0 (paulschou.com)
% Not implemented yet--
%   simplemap(... ,'Type','Google')    % Google satellite image underlay
%   simplemap(... ,'Type','Night')     % Night time satellite image underlay

% defaults for line colors:
coast_color = [1 1 1]*0.5;
country_color = nan;
state_color = nan;

% defaults for data range:
lat_range = [-90 90];
lon_range = [-180 180];
data = [];
shift_to = -180;

% defaults for alpha maps:
alph = 0.9;
bg = nan;
type = [];

c_pops = nan;
c_pos = 4;

to_bin = {};
to_filt = {};

colorbar_label = [];

if nargin > 1
  if nargin > 2 & isnumeric(varargin{2}) & isnumeric(varargin{3})
    if nargin > 3 & isnumeric(varargin{4})
      to_bin = varargin(1:4);
      varargin = varargin(5:end);
    elseif nargin > 3 & isequal(varargin{4},'auto')
      to_bin = [varargin(1:3) median([abs(diff(varargin{1}(:)));abs(diff(varargin{2}(:)))])*10];
      varargin = varargin(4:end);
    else
      to_bin = [varargin(1:3) 1];
      varargin = varargin(4:end);
    end
  elseif ~isnumeric(varargin{2})
    data = varargin{1};
    varargin = varargin(2:end);
  end
  while length(varargin) > 0 
    if strcmp(varargin{1},'Background')
      bg = varargin{2};
    elseif strcmp(varargin{1},'Alpha')
      alph = varargin{2};
    elseif strcmp(varargin{1},'Coast')
      coast_color = varargin{2};
    elseif strcmp(varargin{1},'Country')
      country_color = varargin{2};
    elseif strcmp(varargin{1},'State')
      state_color = varargin{2};
    elseif strcmp(varargin{1},'lat')
      lat_range = varargin{2};
    elseif strcmp(varargin{1},'lon')
      lon_range = varargin{2};
      % make sure we wrap over the international dateline properly
      if lon_range(2) - lon_range(1) < 0
        lon_range(2) = lon_range(2) + 360;
      end
    elseif strcmp(varargin{1},'auto')
      if length(to_bin) >= 2 & ~any(to_bin{2}(:) < 90 & to_bin{2}(:) > -90)
        to_bin{2} = wrapTo360(to_bin{2});
      end
      if length(to_bin) > 1
        lat_range = [nanmin(to_bin{1}(:)) nanmax(to_bin{1}(:))]/to_bin{4};
        lat_range = [floor(lat_range(1)) ceil(lat_range(2))]*to_bin{4};
        lon_range = [nanmin(to_bin{2}(:)) nanmax(to_bin{2}(:))]/to_bin{4};
        lon_range = [floor(lon_range(1)) ceil(lon_range(2))]*to_bin{4};
      else
        lon_range = (minmax(find(any(data))-.5)+[-.5 .5])/size(data,2)*360 - 180;
        lat_range = (minmax(find(any(data'))-.5)+[-.5 .5])/size(data,1)*180 - 90;
        data = data(any(data'),any(data));
      end
      varargin = varargin(2:end); continue
    elseif strcmp(varargin{1},'Type')
      type = varargin{2};
    elseif strcmp(varargin{1},'Cities')
      c_pops = sort(varargin{2});
    elseif strcmp(varargin{1},'CityPosition')
      c_pos = varargin{2};
    elseif strcmp(varargin{1},'clabel')
      colorbar_label = varargin{2};
    elseif strcmp(varargin{1},'pgrow')
      to_filt = [to_filt 'pgrow'];
      varargin = varargin(2:end); continue
    elseif strcmp(varargin{1},'ngrow')
      to_filt = [to_filt 'ngrow'];
      varargin = varargin(2:end); continue
    elseif strcmp(varargin{1},'nfilt')
      to_filt = [to_filt 'nfilt'];
      varargin = varargin(2:end); continue
    elseif strcmp(varargin{1},'shift')
      data = mapshift(data);
      shift_to = 0;
      varargin = varargin(2:end); continue
    elseif strcmp(varargin{1},'shiftto')
      dl = 360/size(data,2);
      shift_to = varargin{2};
      data = mapshift(data',-180:dl:180-dl,shift_to)';
      lon_range = [shift_to shift_to+360];
    elseif strcmp(varargin{1},'flip')
      data = flipud(data);
      varargin = varargin(2:end); continue
    else
      break
    end
    if length(varargin) > 2
      varargin = varargin(3:end);
    else; break; end
  end
elseif nargin == 1
  data = varargin{1};
end

% If we are provided sets of longitude and latitude points, lets grid them up and plot them
if length(to_bin) > 0
  % if a map shift is requested and the lon_range has not been updated from the default
  if isequal(lon_range,[-180 180]) & shift_to ~= -180; 
    lon_range = [shift_to shift_to+360];
  end

  % make sure our bounds match on longitude
  %if any(lon_range > 180)
  %  to_bin{2} = wrapTo360(to_bin{2});
  %elseif any(lon_range < 0)
  %  to_bin{2} = wrapTo180(to_bin{2});
  %end
  to_bin{2} = mod(to_bin{2} - shift_to,360) + shift_to;

  if size(to_bin{3},2) == 3 % color binning
    for c = 1:3
      data(:,:,c) = binprofdyn(reshape(to_bin{1},[],1),reshape(to_bin{2},[],1),to_bin{3}(:,c),lat_range(1):to_bin{4}:lat_range(2),lon_range(1):to_bin{4}:lon_range(2));
    end
  elseif size(to_bin{3},3) == 3 % color binning
    for c = 1:3
      data(:,:,c) = binprofdyn(to_bin{1}(:,:,1),to_bin{2}(:,:,1),to_bin{3}(:,:,c),lat_range(1):to_bin{4}:lat_range(2),lon_range(1):to_bin{4}:lon_range(2));
    end
  else
    if ~isequal(size(to_bin{1}),size(to_bin{2}))
      error('Lat and Long vectors are different lengths');
    end
    if ~isequal(size(to_bin{1}),size(to_bin{3}))
      error('Data is a different dimension that the Lat / Long vectors');
    end
    %if size(to_bin{1},1) == 1 & size(to_bin{2},1) == 1
    %  [to_bin{1} to_bin{2}] = meshgrid(to_bin{1},to_bin{2});
    %end
    [data count ibin] = binprofdyn(to_bin{1},to_bin{2},to_bin{3},lat_range(1):to_bin{4}:lat_range(2),lon_range(1):to_bin{4}:lon_range(2));
  end
end

if ~isnan(bg)
  persistent g g_lat g_long
  %if p_zoom ~= zoom % is our cache useful? if not delete it
  %  g = [];
  %end
  %if isempty(g) % do we have a cache? if not load the data
    %load(['google-z' num2str(zoom)])
  if strcmpi(type,'google')
    [g g_lat g_long]=googlemap([lon_range(:)' lat_range(:)']);
  else
    load('earth_land')
  end
  %end
  hold off
  clf
  ax = imagesc(g_long,g_lat,g,'AlphaData',bg);
  hold on
  pa = get(ax,'Parent');
  %hold(pa,'on')
else
  pa = gca;
end

if ~isempty(data)
  alphamap = ~isnan(nanmean(data,3)).*alph;

  % run the requested filters
  for filt = to_filt
    if strcmp(filt{1},'nfilt')
      n_std = 1;
      data = nfilt(data,[],n_std);
    elseif strcmp(filt{1},'ngrow')
      for c = 1:size(data,3)
        data(:,:,c) = nchomp(ngrow(nwrap(data(:,:,c))));
      end
      gr = sqrt(5)/2+.5;
      alphamap = min((alphamap + ~isnan(nanmean(data,3)).*alph)/gr,1);
    elseif strcmp(filt{1},'pgrow')
      for c = 1:size(data,3)
        data(:,:,c) = nchomp(ngrow(nwrap(data(:,:,c)),0));
      end
      gr = sqrt(5)/2+.5;
      %alphamap = min((alphamap + ~isnan(nanmean(data,3)).*alph)/gr,1);
      alphamap = alphamap | ~isnan(nanmean(data,3));
    end
  end

  % figure out the offset amount between the center of the pixel and the corner of the map
  off = [diff(lat_range) diff(lon_range)]/2 ./ [size(data,1) size(data,2)];
  ax = imagesc([lon_range(1)+off(2) lon_range(2)-off(2)],[lat_range(1)+off(1) lat_range(2)-off(1)],data,'AlphaData',alphamap);

  sel = ~(isnan(data(:)) + isinf(data(:)));
  if min(data(sel)) < max(data(sel)) & size(data,3) ~= 3
    caxis([min(data(sel)) max(data(sel))])
    h = colorbar;
    if ~isempty(colorbar_label)
      xlabel(h,colorbar_label);
    end
  end

  if nargin > 1
    set(ax,'Parent',pa);
  else
    pa = get(ax,'Parent');
  end
end

% Plot out a world map
hold(pa,'on')
%imagesc(ax,[-180 180],[-90 90],data,'AlphaData',0.5);
if ~any(isnan(country_color))
   POpatch = worldhi(lat_range,lon_range,0);
   for i =1:length(POpatch)
         dlong = diff(POpatch(i).long);
         POpatch(i).long(abs(dlong)>180) = nan;
         %me = POpatch(i).long;
         plot(pa,POpatch(i).long,POpatch(i).lat,'color',country_color)
         %plot(pa,POpatch(i).long(me),POpatch(i).lat(me),...
         %     'color',country_color)
         %plot(pa,POpatch(i).long(~me),POpatch(i).lat(~me),...
         %     'color',country_color)
   end
end
if ~any(isnan(state_color))
   POpatch = usahi('stateline');
   for i =1:length(POpatch)
         me = POpatch(i).long>=0;
         plot(pa,POpatch(i).long(me),POpatch(i).lat(me),...
              'color',state_color)
         plot(pa,POpatch(i).long(~me),POpatch(i).lat(~me),...
              'color',state_color)
   end
end
if ~any(isnan(coast_color))
  load coast
  plot(pa,long,lat,'Color',coast_color)
  if any(lon_range > 180)
    plot(pa,long+360,lat,'Color',coast_color)
  end
end
if ~any(isnan(c_pops))
  % Fancy random city positions:
  for i = 1:length(c_pops)
    %c_pops(i:min(i+1,end))
    [c_lat c_lon c_name c_pop]=worldcities(c_pops(i:min(i+1,end)),lat_range,lon_range);
    [c_pop s] = sort(c_pop);
    c_lat = c_lat(s);
    c_lon = c_lon(s);
    c_name = c_name(s);
    h = plot(pa,c_lon,c_lat,'.k','MarkerSize',i*5+5);
    %get(pa,'Children');
    set(pa,'Children',flipud(get(pa,'Children')));
    %get(pa,'Children');
    for j = 1:length(c_lat)
      s = round(c_pos(mod(j-1,end)+1)*2)/2;
      if s < 0; s = fix(rand(1)*4)+1; end

      if mod(s,1) == 0.5
        hspace = ' ';
        vspace = {' '};
      else
        hspace = '  ';
        vspace = {' ' ' '};
      end

      % Left - Right alignment
      if mod(s,2) == 0
        HorizontalAlignment = 'Center';
      elseif mod(s,4) > 2
        HorizontalAlignment = 'Right';
        c_name{j} = [c_name{j} hspace];
      else
        HorizontalAlignment = 'Left';
        c_name{j} = [hspace c_name{j}];
      end

      % Top - Bottom
      if mod(s+1,4) == 0
        text(double(c_lon(j)),double(c_lat(j)),c_name{j},'HorizontalAlignment',HorizontalAlignment)
      elseif mod(s+1,4) < 2
        text(double(c_lon(j)),double(c_lat(j)),[c_name{j} vspace],'HorizontalAlignment',HorizontalAlignment)
      else
        text(double(c_lon(j)),double(c_lat(j)),[vspace c_name{j}],'HorizontalAlignment',HorizontalAlignment)
      end
      %disp([c_name{j} ' ' num2str(c_pop(j))])
    end
  end
end
hold(pa,'off')
axis xy;
axis([lon_range(:)' lat_range(:)'])
ylabel('Latitude [deg]')
xlabel('Longitude [deg]')
hold off

if nargout > 0
  handle = pa;
  data_out = data;
end
 
if nargout > 3
  dim = size(data);
  out = struct;
  out.min = nan(dim);
  out.max = nan(dim);
  out.mode = nan(dim);
  out.mean = nan(dim);
  out.std = nan(dim);
  out.skewness = nan(dim);
  out.kurtosis = nan(dim);
  out.count = count;

  for i = 1:max(ibin(:))
    i_sel  = ibin == i & ~isnan(to_bin{3});
    if sum(i_sel) == 0
      continue
    end
    subset = to_bin{3}(i_sel);
    out.min(i) = min(subset);
    out.max(i) = max(subset);
    out.mode(i) = mode(subset);
    out.mean(i) = mean(subset);
    out.std(i) = std(subset);
    out.skewness(i) = skewness(subset);
    out.kurtosis(i) = kurtosis(subset);
  end
end
