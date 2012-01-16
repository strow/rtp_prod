
% Start of file needs lines specifying the following variables:
%    grannum = granule number
%    granfile = granule file
%    ecmwffile = ECMWF model file
%    rtpfile = output RTP file

% Update: 27 May 2003 S.Hannon - change cal_seaemis from scanang to satzen
% Update: 17 Nov 2006, S.Hannon - update ECMWF reader to newer non-mex version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section only if needed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AIRS instrument code number
AIRSinst=800;

% Channel IDs for uniformity test
%idtest=[759 903 2328 2333]'; % (900.22, 960.95, 2610.8, 2616.1 cm^-1)
idtest=[760 903 2328 2333]'; % (900.22, 960.95, 2610.8, 2616.1 cm^-1)
% Note: these are all surface channels, so the uniformity test will
% really be a surface uniformity test.  That is, the surface radiances
% must be uniform, but it is possible that the profiles might be
% quite different.

% Set max allowed delta BT for uniformity test
dbtmax=0.25;

% Set max allowed (ie passing) radiance calibration flag
flgmax=7;  % Bits 2^{0,1,2} currently not used

%addpath /asl/matlab/gribtools      % for readecmwf_nearest
%addpath /asl/matlab/h4tools        % for rtpread & rtpwrite
%addpath /asl/matlab/airs/readers   % for readl1b_uniform
%addpath /asl/matlab/science        % for cal_seaemis
%addpath /asl/matlab/aslutil        % for radtot & ttorad


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make an RTP file for the uniform FOVs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read the AIRS granule data file
%%% Update "readl1b.m" to return the additional variables:
%%% along-track "satheight"
%%% along-track "calflag"

[meantime, f, gdata] = readl1b_uniform(granfile, idtest, dbtmax, flgmax);
nobs=length(gdata.rlat);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (nobs > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read the ECMWF model and pull out nearest profile for each observation
[head, prof] = readecmwf_nearest(ecmwffile, gdata.rlat, gdata.rlon);


% Append the observations to the profile data
%%%% Re-write this as a standard RTP tool %%%%%

% Add channel info
head.nchan=2378;
head.ichan=(1:2378)';
head.vchan=f;  % approximate frequency
% Update pfields
head.pfields=5; % (1=prof + 4=IRobs);

% Add observation info
prof.upwell=ones(1,nobs); % radiance is upwelling
prof.pobs=zeros(1,nobs);
prof.zobs=gdata.zobs;
%
prof.rlat=gdata.rlat;
prof.rlon=gdata.rlon;
prof.rtime=gdata.rtime;
prof.robs1=gdata.robs1;
prof.calflag=gdata.calflag; % fix "calflg" to calflag, 22 Oct 02 ScottH
prof.irinst=AIRSinst*ones(1,nobs);
%
prof.findex=grannum*ones(1,nobs);
prof.atrack=gdata.atrack;
prof.xtrack=gdata.xtrack;
%
prof.scanang=gdata.scanang;
prof.satzen=gdata.satzen;
prof.satazi=gdata.satazi;
prof.solzen=gdata.solzen;
prof.solazi=gdata.solazi;
%
% Force cfrac to zero
prof.cfrac=zeros(1,nobs);

%%%
% Fields found in both L1B and ECMWF
%       salti: [1x1350 double]
%    landfrac: [1x1350 double]
% For now, stick with the ECMWF values
prof.udef=zeros(2,nobs);
prof.udef(1,:)=gdata.salti;
prof.udef(2,:)=gdata.landfrac;
%%%

% Plug in sea surface emissivity & reflectivity
%[nemis,efreq,seaemis]=cal_seaemis(gdata.scanang);
[nemis,efreq,seaemis]=cal_seaemis(gdata.satzen);
prof.nemis=nemis;
prof.efreq=efreq;
prof.emis=seaemis;
prof.nrho=nemis;
prof.rfreq=efreq;
prof.rho=(1-seaemis)/pi;

clear gdata f seaemis efreq nemis


% attribute string for robs1 data
ii=max( find(granfile == '/') );
if (length(ii) == 0)
   ii=0;
end
junk=granfile((ii+1):length(granfile));
robs1_str=['airibrad file=' junk];

% attribute string for profile
ii=max( find(ecmwffile == '/') );
if (length(ii) == 0)
   ii=0;
end
junk=ecmwffile((ii+1):length(ecmwffile));
prof_str=['nearest ECMWF file=' junk];

% attribute comment string for uniform test
uniform_str=['dBTmax=' num2str(dbtmax) ', flgmax=' int2str(flgmax) ...
   ', idtest=[' int2str(idtest') ']'];

% Assign RTP attribute strings
hattr={ {'header' 'profile' prof_str}, ...
        {'header' 'uniform' uniform_str} };

pattr={ {'profiles' 'robs1' robs1_str}, ...
        {'profiles' 'udef' '1=L1B salti, 2=L1B landfrac'} };

clear robs1_str prof_str uniform_str


% Write to an RTP file
rtpwrite(rtpfile, head, hattr, prof, pattr)

clear AIRSinst dbtmax flgmax idtest meantime f nobs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   % Make sure no rtpfile exists if no FOVs passed the uniform test
   disp('No FOVs passed uniform test')
   delete(rtpfile)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of file %%%
