function [h ha p pa] = rtpgrow(h,ha,p,pa,varargin)
%function [h ha p pa] = rtpgrow(h,ha,p,pa)
%
%  This function grows an rtp structure ready for writing out to a file.
%
%  Inputs are the standard header and profile fields
%    head / hattr / prof / pattr  [ optional directory search path ]
%
%  Outputs are the standard header and profile fields
%    head / hattr / prof / pattr
%
%  How the rtpgrow function works:
%    rtpgrow loads in the header and profile structures and attributes and looks
%    in the header attributes for the field `rtpfile'.  If this file exists, it will
%    then attempt to load in any missing fields from this parent files which is not 
%    present in the provided rtp structure.  The child is assumed to be a subset of the
%    data points which are in the parent file and any additional data fields.
% 
%  Examples:
%    [h ha p pa] = rtpgrow(h,ha,p,pa);  % `grows' the rtp structure by adding missing fields
%    [h ha p pa] = rtpgrow(h,ha,p,pa,'/asl/s2/schou/'); % looks in specified directory for parent
%
%  Usage note:  The rtp parent file, i, is searched in this order: 
%      {'./i','/originalpath/i','/originialpath/i.rtpZ'}
%
%  See also: rtptrim

% Written by Paul Schou - 1 July 2009  (paulschou.com)

rtpfile = get_attr(ha,'rtpfile');
if length(rtpfile) == 0
  disp('  RTPGROW: No rtpfile specified in the rtp header attribute');
  return
end

%disp(['rtpfile: ' rtpfile]);
searchdir = './';
openedfile = '';

debug = 0;
if nargin == 5 
  if strcmpi(varargin{1},'debug')
    debug = 1;
  elseif exist(varargin{1},'file')
    openedfile = varargin{1};
  else exist(varargin{1},'dir')
    searchdir = varargin{1};
  end
end

% lets search the suggested directory first for the parent file
if exist([searchdir '/' basename(rtpfile)],'file')
  rtpfile = [searchdir '/' basename(rtpfile)];
end
if isempty(rtpfile); 
  error(['  RTPGROW: rtpfile variable is empty! The code should not get to this point! Something is WRONG']);
end

% just in case the file we are referenced to was also trimmed:
if ~exist(rtpfile,'file') & exist([rtpfile 'Z'],'file')
  disp('  RTPGROW: parent file may refer to a trimmed target')
  rtpfile = [rtpfile 'Z'];
end
if ~exist(rtpfile,'file') & exist([rtpfile(1:end-1) 'Z'],'file')
  disp('  RTPGROW: parent file may refer to a trimmed target')
  rtpfile = [rtpfile(1:end-1) 'Z'];
end

% in the case the file is actually a pair of files
if ~exist(rtpfile,'file') & exist([rtpfile '_1'],'file')
  disp('  RTPGROW: parent file may refer to a pair of rtp files')
  rtpfile = [rtpfile '_1'];
end

% Let's check our current path for the same file:
if exist(basename(rtpfile),'file')
  disp(['  RTPGROW: Using rtpfile in ' pwd '/ as parent'])
  rtpfile = basename(rtpfile);
end

if isequal(openedfile,rtpfile)
  % parent file is self. Nothing to be done.
  return
end

if exist(rtpfile,'file');
  %try
    if(debug == 1);disp(['growing from ' rtpfile]);end
    if strcmp(rtpfile(end),'1') | strcmp(rtpfile(end-1:end),'1Z') ...
        | strcmp(rtpfile(end),'2') | strcmp(rtpfile(end-1:end),'2Z')
      % check to see if we are trying to grow off a single part or both parts by the
      %   channel size:
      %if isfield(p,'rcalc') & size(p.rcalc,1) < 5000
      %  [h0 ha0 p0 pa0] = rtpread(rtpfile);
      %elseif isfield(p,'robs1') & size(p.robs1,1) < 5000
      %  [h0 ha0 p0 pa0] = rtpread(rtpfile);
      %else
        % we are probably trying to grow off a joined file:
        if strcmp(rtpfile(end),'Z')
          [h0 ha0 p0 pa0] = rtpread_12(rtpfile(1:end-3));
        else
          [h0 ha0 p0 pa0] = rtpread_12(rtpfile(1:end-2));
        end
      %end
    else
      % your vanilla reader
      [h0 ha0 p0 pa0] = rtpread(rtpfile);
    end
    rtpfile0 = get_attr(ha0,'rtpfile');
    if ~(strcmpi(basename(rtpfile),basename(rtpfile0)) | strcmpi(basename(rtpfile),[basename(rtpfile0) 'Z']))
      if ~strcmp(rtpfile0,'')
        if(debug == 1);
          disp('growing again');
          [h0 ha0 p0 pa0] = rtpgrow(h0,ha0,p0,pa0,'debug');
        else
          [h0 ha0 p0 pa0] = rtpgrow(h0,ha0,p0,pa0,rtpfile);
        end
      end
    end
  %catch
  %  error(['Error reading in original file ' rtpfile]);
  %end

  % get our indexing value
  if(isfield(p0,'rtime') & isfield(p,'rtime') & ...
      length(unique(sort(p.rtime))) == length(p.rtime))
    % use time if it is unique per profile
    isel0 = [p0.rtime]; isel = [p.rtime];
  else
    % or use a combination of fields which are common in both
    isel0 = [];
    isel = [];
    if(isfield(p0,'rtime') & isfield(p,'rtime')); isel0 = [isel0;p0.rtime]; isel = [isel;p.rtime]; end
    if(isfield(p0,'findex') & isfield(p,'findex')); isel0 = [isel0;p0.findex]; isel = [isel;p.findex]; end
    if(isfield(p0,'atrack') & isfield(p,'atrack')); isel0 = [isel0;p0.atrack]; isel = [isel;p.atrack]; end
    if(isfield(p0,'xtrack') & isfield(p,'xtrack')); isel0 = [isel0;p0.xtrack]; isel = [isel;p.xtrack]; end
    if(isfield(p0,'ifov') & isfield(p,'ifov')); isel0 = [isel0;p0.ifov]; isel = [isel;p.ifov]; end
  end

  % profile subset selection
  [c sel]=ismember(isel',isel0','rows');
  sel = sel(c);

  % frequency subset selection
  [c sel_f]=ismember(h.ichan,h0.ichan);
  sel_f = sel_f(c);

  if length(sel) == 0; return; end
  f = fields(p0);
  for i = 1:length(f)
    % if the field already exists in the profile structure, do nothing
    if(isfield(p,f{i})); continue; end
    % if it doesn't, lets grab the field and get ready to subset it
    val0 = getfield(p0,f{i});
    % Check if we have a channel field:
    if(strcmp(f{i},'robs1') | strcmp(f{i},'rcalc') | strcmp(f{i},'calflag'))
      if(h0.nchan < h.nchan & size(val0,1) == h0.nchan)
        % if there are more channels in the child, let's pad the parent channels with 0's
        val0(h0.nchan+1:h.nchan,:)=0;
      elseif(h0.nchan > h.nchan)
        % if it is a subset of the channels, then subset for this
        val0=val0(sel_f,:);
      end
    end % channel field check
    if(debug == 1);disp(['adding field ' f{i}]);end
    % add the missing field to the new structure
    p = setfield(p,f{i},val0(:,sel));
  end
else
  disp(['  RTPGROW: Parent does not exist ' rtpfile])
end

