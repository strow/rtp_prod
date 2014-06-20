% test_timblock.m
%
% Script to run much of rtp_prod processing interactively at home by
% L. Strow.
% 
% This script is the first part of testing a large re-write of
% rtp_prod grib readers, and maybe emissivity assignments.
%
% Right now this mimics some slurm stuff, the goal was just to get
% something close to timeblock_dealer2.m working before larger
% changes.
%
% Taken from Howard's timeblock_dealer2 and cris_ccast_sdr60_ecmwf_umw.m
% 
% June, 20, 2014
% 

npe = 20;
pe = 1;

t2=[2013, 08, 28, 23, 59, 59.999];
t1=[2013, 08, 28,  0,  0,  0];
dt=[   0,  0,  0,  0, 20,  0];
s_vtime = t1;
e_vtime = t2;
d_vtime = dt;
stime = datenum(s_vtime);
etime = datenum(e_vtime);
dtime = datenum(d_vtime);

Nb = nearest((etime - stime)./dtime);

tsi = stime + dtime.*([1:Nb]-1);
tei = stime + dtime.*([1:Nb]  );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Deal blocks among processors:
Blocks = zeros(npe,ceil(Nb./npe));

for iblock = 1:Nb
  iproc = mod((iblock - 1),npe) + 1;
  idxblk = floor((iblock-1)./npe) + 1;

  Blocks(iproc, idxblk) = iblock;
end

Nb = nearest((etime - stime)./dtime);
rtprod = '~/Git/rtp_prod';
matlib = '~/Git/matlib';

asldata ='/asl/data';

addpath(rtprod);
paths

% Export environment variable
setenv('RTPROD',rtprod);
version = version_number();
root = '/asl/';

iblock = Blocks(pe,:)

disp(['I am processor ' num2str(pe) '/' num2str(npe) ]);

sdate = tsi(iblock);
edate = tei(iblock);

% Haven't figured out yet why have to use sdate(1) and not sdate
file_list = cris_ccast_filenames(sdate(1),edate(1),asldata,'ccast_sdr60_hr');

  str_obs1.instr	= 'cris';
  str_obs1.sat_data	= 'ccast_hr';
  str_obs1.atm_model 	= 'ecmwf';	% Will contain profile information
  str_obs1.surfflags 	= 'umw'; 	% Will contain usgs topo (u),
                                        % Model stemp (m), Wisc emis (w)
  str_obs1.calc 	= 'calc';
  str_obs1.subset 	= '';	% clear subset only 
  str_obs1.infix 	= '';
  str_obs1.mdate 	= [sdate edate];
  str_obs1.ver 		= version;
  str_obs1.file_type 	= 'rtp';

  output_file_obs1 = rtp_str2name(str_obs1);


  % Get output directory
  output_file_dir = fileparts(output_file_obs1);

  disp('Input Files:');
  for iff=1:numel(file_list)
    disp(file_list{iff});
  end

  disp('Output Files:');
  disp(output_file_obs1);

  if(~exist(output_file_dir,'dir'))
    disp(['Creating output directory']);
    mkdir(output_file_dir);
  end

  % Test for file existence
  if(exist(output_file_obs1 ,'file'))
    disp(['Attention: Output file "' output_file_obs1 '" already exist. Skipping...']); 
    return
  end

for ifile=1:numel(file_list)
  [head hattr profi pattr] = sdr2rtp_bc(file_list{ifile}); 
  prof(ifile) = profi;
end
clear profi;
prof = structmerge(prof);
head.ngas = 0;

% Remove buggy CrIS rtime, rlat, and rlon
[head prof] = cris_filter_bad_data(head, prof);

hattr = set_attr(hattr,'version',version);

[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr,root);

% grib goes here, puttin gin fake wspeed, zang for now so can run emis
plen = length(prof.rlat);
prof.wspeed = zeros(1,plen);
prof.zang = zeros(1,plen);

%[head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);
[head, hattr, prof, pattr] = rtpadd_grib_data('', 'ecmwf', head, hattr, prof, pattr);


[head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr);

%---------------------------------------------------------------------------
% Can't run the rest at home.  rtpadd_emis_Wisc.m is a *mess*    
%---------------------------------------------------------------------------    
 

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do clear selection - for now this is instrument dependent
  % 
  % For CrIS 888 (high res) we also perform the calculations.
  % 
%   instrument='CRIS_888'; %'IASI','CRIS'
%   [head hattr prof pattr summary] = ...
%                    compute_clear_wrapper(head, hattr, prof, pattr, instrument);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 5 - Save Obs File + Model information
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   [dd, ~, ~] = fileparts(output_file_obs1);
%   if(~exist(dd,'dir'))
%     system(['mkdir -p ' dd]);
%   end 
%   disp(['Saving ' output_file_obs1]);
%   rtpwrite(output_file_obs1, head,hattr,prof,pattr);


