function [head, hattr, prof, pattr] = rtpadd_gfs(head, hattr, prof, pattr);

% function [head, hattr, prof, pattr] = rtpadd_gfs(head, hattr, prof, pattr);
%
% Routine to read in 47 level standard+supplemental NCEP GFS model profiles
% that are the closest grid points to the specified (lat,lon) locations.
% The GFS profile is added to the existing RTP structures.
%
% Input:
%    head     : RTP header structure
%    hattr    : header attributes
%    prof       RTP profiles structure with the following fields:
%       rlat  : (1 x nprof) latitudes (degrees -90 to +90)
%       rlon  : (1 x nprof) longitude (degrees, either 0 to 360 or -180 to 180)
%       rtime : (1 x nprof) observation time in seconds
%    pattr    : profile attributes; "rtime" must be specified
%
% Output:
%    head : (RTP "head" structure of header info)
%    hattr: header attributes
%    prof : (RTP "prof" structure of profile info)
%    pattr: profile attributes
%


% Created: 13 Dec 2011, Scott Hannon
% Update: 14 Dec 2011, S.Hannon - bug fix for pfields2bits/bits2pfields calls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed


% GFS fields to be added to RTP
GFS_head_fields = {'ngas', 'glist', 'gunit', 'pmin', 'pmax'};
GFS_prof_fields = {'plat', 'plon', 'ptime', 'stemp', 'spres', 'wspeed', ...
   'nlevs', 'plevs', 'ptemp', 'gas_1', 'gas_3'};
% Note: head.pfields will also be updated.  Any matching existing fields
% will be replaced, and any existing gas_* fields will be removed.
GFS_udef_indices = [1 2 3];
GFS_udef_attr = {'GFS sea ice' 'GFS salti' 'GFS landfrac'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check nargin
if (nargin ~= 4)
   error('Unexpect number of input arguments')
end


% Determine TAI start year and convert prof.rtime to MATLAB date number
[rtime rtime_st] = rtpdate(head,hattr,prof,pattr);


% Determine the number of GFS model date/times required
nprof = length(rtime);
rrtime8 = round(rtime * 8);
urrtime8 = unique( round(rrtime8) );
ntime = length(urrtime8);
utime = urrtime8/8;
%
[year,month,day,hour,minute,second] = datevec(utime);
clear minute second


% Determine the GFS filenames
[fname, fnameb, iok, iokb] = get_gfs_name(year,month,day,hour);
ibad = find(iok == 0);
ibadb = find(iok == 0);
if(length(ibad) > 0 | length(ibadb) > 0)
   if (length(ibad) > 0)
      disp('missing required GFS standard model files:')
      fname{ibad}
   end
   if (length(ibadb) > 0)
      disp('missing required GFS supplemental model files:')
      fnameb{ibadb}
   end
   return
end


% Remove any existing profile and rcalc fields from RTP
[profbit, calbit, obsbit] = pfields2bits(head.pfields);
if (calbit == 1)
   if (isfield(prof,'rcalc'))
      prof = rmfield(prof,'rcalc');
   end
   calbit = 0;
end
if (isfield(head,'ngas'));
   if (head.ngas > 0)
      for ii = 1:head.ngas
         gstr = ['gas_' int2str(head.glist(ii))];
         if (isfield(prof,gstr))
            prof = rmfield(prof,gstr);
         end
      end
      head.ngas = 0;
      head = rmfield(head,'glist');
      head = rmfield(head,'gunit');
   end
end
for jj=1:length(GFS_prof_fields)
   fstr = GFS_prof_fields{jj};
   if (isfield(prof,fstr))
      prof = rmfield(prof,fstr);
   end
end
profbit = 0;
calbit = 0;
head.pfields = bits2pfields(profbit, calbit, obsbit);


% Check/prepare prof.udef and free_udef
if (isfield(prof,'udef'))
   % Pull out prof field names of all pattr
   pattr_fields = {};
   for ii=1:length(pattr)
      pattr_fields{ii} = pattr{ii}(2);
   end
   % Resize udef if less than 20 elements
   d = size(prof.udef);
   nudef = d(1);
   if (nudef < 20)
      oldudef = prof.udef;
      prof.udef = zeros(20,nprof,'single');
      prof.udef(1:nudef,:) = oldudef;
      nudef = 20;
      clear oldudef
   end
   % Look for udef in pattr
   free_udef = zeros(1,nudef);
   for ii=1:nudef
      astr = ['udef(' int2str(ii) ',:)'];
      tf = strcmp(astr,pattr_fields);
      tf = max(tf);
      if (tf == 0)
         free_udef(ii) = ii;
      end
   end
   ii = find(free_udef > 0);
   free_udef = free_udef(ii);
else
   prof.udef = zeros(20,nprof,'single');
   free_udef=1:20;
end
%
nfree_udef = length(free_udef);
nGFS_udef = length(GFS_udef_indices);
if (nfree_udef < nGFS_udef)
   disp('WARNING! insufficent free prof.udef for all GFS udef')
   iomit = (nfree_udef+1):nGFS_udef;
   disp(['omitting GFS udefs for: ' GFS_udef_attr{iomit}])
end
nGFS_udef = min([nGFS_udef,nfree_udef]);


% Loop over the utime
for ii=1:ntime
   disp(['doing GFS model ' int2str(ii) ' of ' int2str(ntime)])
   %
   % profile indices
   ind = find(rrtime8 == urrtime8(ii));
   %
   % Get GFS for ind
   lat = prof.rlat(ind);
   lon = prof.rlon(ind);
   [hx, px] = readncep2hi_nearest(fname{ii}, fnameb{ii}, lat, lon);
   %
   % If first time thru loop, declare empty prof fields & assign head fields
   if (ii == 1)
      % Declare empty GFS prof fields
      for jj = 1:length(GFS_prof_fields)
         fstr = GFS_prof_fields{jj};
         eval(['d = size(px.' fstr ');']);
         eval(['dc=class(px.' fstr ');'])
         eval(['prof.' fstr '=zeros(d(1),nprof,dc);'])
      end
      %
      % Assign GFS head fields
      for jj = 1:length(GFS_head_fields)
         fstr = GFS_head_fields{jj};
         eval(['head.' fstr '=hx.' fstr ';'])
      end
      profbit = 1;
      head.pfields = bits2pfields(profbit, calbit, obsbit);
   end
   %
   % Copy data for ind into prof
   for jj = 1:length(GFS_prof_fields)
      fstr = GFS_prof_fields{jj};
      eval(['prof.' fstr '(:,ind)=px.' fstr ';'])
   end
   % Copy udef data
   for jj=1:nGFS_udef
      prof.udef(free_udef(jj),ind) = px.udef(jj,:);
   end
end


% Update hattr & pattr
nattr = length(hattr);
if (nattr == 0)
   hattr = { {'header' 'profile' 'nearest standard+supplemental NCEP GFS'} };
else
   hattr{nattr+1} = ...
   {'header' 'profile' 'nearest standard+supplemental NCEP GFS'};
end
%
nattr = length(pattr);
for ii=1:nGFS_udef
   jj = free_udef(ii);
   astr = ['udef(' int2str(jj) ',:)'];
   pattr{nattr+ii} = {'profiles' astr GFS_udef_attr{ii}};
end

%%% end of function %%%
