function [h ha p pa] = rtptrim(h,ha,p,pa,varargin)
% function [h ha p pa] = rtptrim(h,ha,p,pa,[options])
%
%  This function trims an rtp structure ready for writing out to a file.
%
%  Inputs are the standard header and profile fields
%    head / hattr / prof / pattr
%
%  Outputs are the standard header and profile fields
%    head / hattr / prof / pattr
%
%  Other matlab options:
%  'parent','/path/rtpfile.rtp' - set the parent to the given file
%  'keep',{'robs1','rcalc'}     - keep a given field
%  'debug'      - print out what is happening in the trim process
%  'rmcalflag'  - remove calflag
%  'rmdustflag' - remove dustflag
%  'allowempty' - allow empty profiles to be created (Dangerous: trimming a parent file will create
%                   an empty profile)
%
%  See also: rtpgrow

% Written by Paul Schou - 1 July 2009  (paulschou.com)

p_orig = p; %save our original just in case something goes bad

debug = 0;
rmcalflag = 0;
rmdustflag = 0;
keep = [];
allowempty = 0;
grow = 1;

for i = 5:nargin
  if strcmpi(varargin{i-4},'parent')
    [h ha p pa] = rtpgrow(h,ha,p,pa);
    ha = set_attr(ha,'rtpfile',varargin{i-3});
  elseif strcmpi(varargin{i-4},'keep')
    keep = varargin{i-3};
  elseif strcmpi(varargin{i-4},'debug'); debug = 1;
  elseif strcmpi(varargin{i-4},'nogrow'); grow = 0;
  elseif strcmpi(varargin{i-4},'allowempty'); allowempty = 1;
  elseif strcmpi(varargin{i-4},'rmcalflag'); rmcalflag = 1;
  elseif strcmpi(varargin{i-4},'rmdustflag'); rmdustflag = 1;
  end
end

if exist(getenv('SARTA'),'file'); pa = set_attr(pa,'sarta_exec',getenv('SARTA')); disp('setting sarta'); end
if exist(getenv('KLAYERS'),'file'); pa = set_attr(pa,'klayers_exec',getenv('KLAYERS')); disp('setting klayers'); end

if isstr(keep); keep = {keep}; end

total_bytes = 0;
trimmed_bytes = 0;

rtpfile = get_attr(ha,'rtpfile');
if ~isempty(getenv('RTPFILE'))
  rtpfile = getenv('RTPFILE');
  ha = set_attr(ha,'rtpfile',rtpfile);
end

if exist(basename(rtpfile),'file')
  disp('Using local cache')
  rtpfile = basename(rtpfile);
end

if exist(rtpfile,'file');
  if debug == 1;disp(['Using parent file: ' rtpfile]);end
  
  try
    [h0 ha0 p0 pa0] = rtpread(rtpfile);
    if grow
      if(debug == 1);
        [h0 ha0 p0 pa0] = rtpgrow(h0,ha0,p0,pa0,'debug');
      else
        [h0 ha0 p0 pa0] = rtpgrow(h0,ha0,p0,pa0);
      end
    end
  catch
    disp(['Error reading in original file ' rtpfile]);
    ha = rm_attr(ha,'rtpfile');
    h0 = struct; ha0 = {}; p0 = struct; pa0 = {};
  end

  % get our indexing value
  if(isfield(p0,'rtime') & isfield(p,'rtime') & ...
      length(unique(sort(p.rtime))) == length(p.rtime)) 
    isel0 = [p0.rtime]; isel = [p.rtime];
  else
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
  [c sel_f]=ismember(h.vchan,h0.vchan);
  sel_f = sel_f(c);

  if rmcalflag == 1 & isfield(p,'calflag'); p = rmfield(p,'calflag'); end
  if rmdustflag == 1 & isfield(p,'dustflag'); p = rmfield(p,'dustflag'); end 

  f = fields(p);
  skipped = 0;
  for i = 1:length(f)
    val = getfield(p,f{i});
    g = whos('val');
    total_bytes = total_bytes + g.bytes;

    if strcmp(f{i},'findex') | strcmp(f{i},'atrack') | strcmp(f{i},'xtrack') | strcmp(f{i},'ifov') | strcmp(f{i},'rtime') | ~isfield(p0,f{i})
      skipped = skipped + 1;
      continue
    end
    for j = 1:length(keep)
      if strcmp(f{i},keep{j})
        if debug == 1;disp(['  skipping keep field: ' f{i}]);end
        break % break keep loop
      end
    end
    if ~isempty(keep) & strcmp(f{i},keep{j}); continue; end % continue to next field

    val0 = getfield(p0,f{i});
    % Check if we have a channel field:
    if(strcmp(f{i},'robs1') | strcmp(f{i},'rcalc') | strcmp(f{i},'calflag'))
      if(h0.nchan < h.nchan & size(val0,1) == h0.nchan)
        % if there are more channels in the child, let's pad the parent channels with 0's
        val0(h0.nchan+1:h.nchan,:)=0;
        allowempty = 1;
      elseif(h0.nchan > h.nchan)
        % if it is a subset of the channels, then subset for this
        val0=val0(sel_f,:);
        allowempty = 1;
      end
    end % channel field check

    if debug == 1;disp(['[ Checking field ' f{i} ' ( ' num2str(g.bytes) ' bytes) ]']);end
    

    if all(size(val0(:,sel)) == size(val)) & all(all(val0(:,sel) == val))
      p = rmfield(p,f{i});
      if debug == 1;disp(['  - removing']);end
      trimmed_bytes = trimmed_bytes + g.bytes;
    end
  end

  % do we have any profile fields remaining? If not then this may be the original file!
  if length(fields(p)) == skipped
    if allowempty == 0
      % let's be safe and do nothing just in case the files are the same.
      p = p_orig;
      if debug == 1;disp(['  Warning: all data fields were removed, going back to the original.  Use: ''allowempty'' to override this safety.']);end
      trimmed_bytes = 0;
    else
      disp(['  Warning: all data fields were removed.'])
    end
  end
  
  disp(['Data: ' num2str((total_bytes-trimmed_bytes)/1024^2,'%0.1f') 'MB / ' ...
    num2str((total_bytes)/1024^2,'%0.1f') 'MB = ' num2str(100-100*trimmed_bytes/total_bytes,'%0.1f') '%']);
elseif debug == 1;disp(['  Warning: parent file ' rtpfile ' not found, doing nothing.'])
end
