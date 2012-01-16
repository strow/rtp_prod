`>% Test version using "disp" to track run progress
%
% Start of file needs lines specifying the following variables:
%    grannum = granule number
%    granfile = granule file
%    ecmwffile = ECMWF model file
%    rtpfile = output RTP file

% Update: 27 May 2003 S.Hannon - change cal_seaemis calc from scanang to satzen
% Update: S.Hannon, 10 Mar 04 - make separate pattr entry for each prof.udef
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
%dbtmax=0.25;
%dbtmax=0.4;
dbtmax=0.3;

% Set max allowed (ie passing) radiance calibration flag
flgmax=7;  % Bits 2^{0,1,2} currently not used

disp('here 1: before addpath')

%addpath /asl/matlab/gribtools      % for readecmwf91_nearest
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

disp('here 2: about to call readl1b_uniform2')
disp('pre-"try"')

try
   disp('post-"try"')
   [meantime, f, gdata] = test_readl1b_uniform2(granfile, idtest, dbtmax, flgmax);
   nobs=length(gdata.rlat);
catch
   disp('error running readl1b_uniform2')
   lasterr
   exit
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (nobs > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('here 3: about to call readecmwf91_nearest')

% Read the ECMWF model and pull out nearest profile for each observation
[head, prof] = readecmwf91_nearest(ecmwffile, gdata.rlat, gdata.rlon);

disp('here 4: back from readecmwf91_nearest')

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
%
%%%
% Load udef fields
prof.udef=zeros(5,nobs);
%prof.udef(1,:)=gdata.salti;    % L1B surface altitude
%prof.udef(2,:)=gdata.landfrac; % L1B land fraction
%prof.udef(3,:)=prof.spres;     % ECMWF surface pressure
prof.udef(4,:)=gdata.udef1;    % uniform2 variable dBTun
%prof.udef(5,:)=0; % will fill later with column mm of H2O
%%%
%prof.udef(1,:)=prof.salti;     % ECMWF surface altitude
%prof.udef(2,:)=prof.landfrac;  % ECMWF land fraction
%%%

%% Update surface parameters
prof.salti=gdata.salti;
prof.landfrac=gdata.landfrac;
%spres=z_to_p_chris(prof.spres, prof.salti, prof.stemp, gdata.salti);
%prof.spres=spres;
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

disp('here 5: about to assign attr')

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

%%%
%pattr={ {'profiles' 'robs1' robs1_str}, ...
%        {'profiles' 'udef(1,:)' 'L1B salti'}, ...
%        {'profiles' 'udef(2,:)' 'L1B landfrac'}, ...
%        {'profiles' 'udef(3,:)' 'ECMWF spres'}, ...
%        {'profiles' 'udef(4,:)' 'dBTun'}, ...
%        {'profiles' 'udef(5,:)' 'mm H2O'} };
%%%

disp('setting pattr')
pattr={ {'profiles' 'robs1' robs1_str}, ...
        {'profiles' 'udef(4,:)' 'dBTun'}, ...
        {'profiles' 'udef(5,:)' 'mm H2O'} };

clear robs1_str prof_str uniform_str

disp('here 6: about to write RTP')

% Write to an RTP file
rtpwrite(rtpfile, head, hattr, prof, pattr)

clear AIRSinst dbtmax flgmax idtest meantime f nobs

disp('here 7: back from write RTP')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   % Make sure no rtpfile exists if no FOVs passed the uniform test
   disp('No FOVs passed uniform test')
   delete(rtpfile)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of file %%%
