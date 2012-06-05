function [head, prof]=cat_rtp(head1, prof1, head2, prof2);

% function [head, prof]=cat_rtp(head1, prof1, head2, prof2);
%
% Concatenates a pair of RTP profile structures into a single output.
% The profile structures must contain exactly the same fields; no
% more, no less.  In addition, all header variables (except pmin &
% pmax) must have the same value in head2 as they have in head1.
%
% Input:
%    head1 = first RTP "head" structure
%    prof1 = first RTP "prof" structure
%    head2 = second RTP "head" structure
%    prof2 = second RTP "prof" structure
% 
% Output:
%    head = concatenated "head" structure
%    prof = concatenated "prof" structure
%
% Note: also see "vcat_rtp.m".
%

% Created: 23 January 2002, Scott Hannon
% Some code taken from vcat_rtp.m by Scott Hannon
% Some code taken from rtpwrite.m by Howard Motteler
% Updated: 15 March 2002, Scott Hannon - new (rtpV104) PROF fields pnote
%    require special handling for character/string data.
% Update: 13 Jun 2005, S.Hannon - replace de2bi with int2bits
% Update: 14 Nov 2008, S.Hannon - updated for rtpV201 (delete MW checks)
% Update: 27 Jul 2011, S.Hannon - preserve class (was always double)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get lists of all fields in each structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% head fields
hfields1 = fieldnames(head1);
nhfields1 = length(hfields1);
for j = 1 : length(hfields1);
  fname = hfields1{j};
  eval(sprintf('[m,n] = size(head1.%s);', fname));
  if n ~= 1
    error('head1 fields must be column vectors');
  end
end
%
hfields2 = fieldnames(head2);
nhfields2 = length(hfields2);
for j = 1 : length(hfields2);
  fname = hfields2{j};
  eval(sprintf('[m,n] = size(head2.%s);', fname));
  if n ~= 1
    error('head2 fields must be column vectors');
  end
end
if (nhfields1 ~= nhfields2)
   error('different number of fields in head1 and head2');
end
junk=ismember(hfields1,hfields2);
ibad=find(junk == 0);
nbad=length(ibad);
if (nbad > 0)
   for ii=1:nbad
      hfields1{ibad(ii)}
   end
   disp('head2 is missing the above fields found in head1:');
end


% prof fields
pfields1 = fieldnames(prof1);
npfields1 = length(pfields1);
fname = pfields1{1};
eval(sprintf('[m,nprof1] = size(prof1.%s);', fname));
for j = 2 : npfields1;
  fname = pfields1{j};
  eval(sprintf('[m,n] = size(prof1.%s);', fname));
  if n ~= nprof1
    error('prof1 structure fields must all have the same number of columns');
  end
end
%
pfields2 = fieldnames(prof2);
npfields2 = length(pfields2);
fname = pfields2{1};
eval(sprintf('[m,nprof2] = size(prof2.%s);', fname));
for j = 2 : npfields2;
  fname = pfields2{j};
  eval(sprintf('[m,n] = size(prof2.%s);', fname));
  if n ~= nprof2
    error('prof2 structure fields must all have the same number of columns');
  end
end
if (npfields1 ~= npfields2)
   error('different number of fields in prof1 and prof2');
end
junk=ismember(pfields1,pfields2);
ibad=find(junk == 0);
nbad=length(ibad);
if (nbad > 0)
   for ii=1:nbad
      pfields1{ibad(ii)}
   end
   error('prof2 is missing the above fields found in prof1');   
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check header
%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%
% Check pfields
if (~isfield(head1,'pfields'))
   error('head1 lacks pfields');
end
%
% Convert pfields into flags(PROF,IRCAL,IROBS)
flags = int2bits(head1.pfields,3);
%
if (flags(1) == 1)
   % Contains profile data so ptype must exist
   if (~isfield(head1,'ptype'))
      error('pfields indicates profile data but no head1.ptype!')
   end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check that the flags make sense
nchan=0;
if (max(flags) == 0)
   error('pfields indicates no data of any kind!')
end
if (flags(1) == 1)
   % Contains profile data
   if (~isfield(prof1,'nlevs'))
      error('pfields indicates profile data but no prof1.nlevs!')
   end
end
if (flags(2) == 1)
   % Contains cal rad data
   if (~isfield(head1,'nchan'))
      error('pfields indicates cal rad data but no head1.nchan!')
   else
      nchan=head1.nchan;
   end
   if (~isfield(head1,'ichan'))
      error('pfields indicates cal rad data but no head1.ichan!')
   end
   %
   if (~isfield(prof1,'rcalc'))
      error('pfields indicates cal rad data but no prof1.rcalc!')
   end
end
if (flags(3) == 1)
   % Contains obs rad data
   if (~isfield(head1,'nchan'))
      error('pfields indicates obs rad data but no head1.nchan!')
   else
      nchan=head1.nchan;
   end
   if (~isfield(head1,'ichan'))
      error('pfields indicates obs rad data but no head1.ichan!')
   end
   if (~isfield(prof1,'robs1'))
      error('pfields indicates obs rad data but no prof1.robs1!')
   end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compare all header variables except nocomp
nocomp={'pmin', 'pmax'};
for i=1:nhfields1;
   fname=char( hfields1{i} );
   if ( max(strcmp(fname,nocomp)) == 0 )
      eval(['junk1=head1.' fname ';']);
      eval(['junk2=head2.' fname ';']);
      if (junk1 ~= junk2)
         error([fname ' differs in head1 and head2'])
      end
   end
end


%%%%%%%%%%%%%%%%%%%%
% Assign output head
head=head1;


%%%%%%%%%%%%%%%%%%%%
% Adjust pmin & pmax
if (isfield(head,'pmin'))
   head.pmin=min([head1.pmin, head2.pmin]);
end
if (isfield(head,'pmax'))
   head.pmax=max([head1.pmax, head2.pmax]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Concatenate prof1 & prof2
%%%%%%%%%%%%%%%%%%%%%%%%%%%
nprof=nprof1 + nprof2;
offset=nprof1 + 1;

for i=1:npfields1;
   fname=char( pfields1{i} );
   eval(['[mrow1,ncol1]=size(prof1.' fname ');']);
   eval(['[mrow2,ncol2]=size(prof2.' fname ');']);
   if (mrow1 == 1 & mrow2 == 1)
      % 1 x nprof
      eval(['prof.' fname '=[prof1.' fname ', prof2.' fname '];']);
   else
      switch fname
         case 'pnote'
            prof.pnote=[prof1.pnote, prof2.pnote];
         case 'calflag'
            prof.calflag=[prof1.calflag, prof2.calflag];
         otherwise
            mrow=max([mrow1, mrow2]);
            eval(['classname=class(prof1.' fname ');']);
            eval(['prof.' fname '=zeros(mrow,nprof,classname);']);
            eval(['prof.' fname '(1:mrow1,1:nprof1)=prof1.' fname ...
               '(1:mrow1,:);']);
            eval(['prof.' fname '(1:mrow2,offset:nprof)=prof2.' fname ...
               '(1:mrow2,:);']);
      end
      %
   end
end


%%% end of file %%%
