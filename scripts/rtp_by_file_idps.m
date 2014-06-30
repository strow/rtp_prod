% rtp_by_file.m
%
% Script to run much of rtp_prod processing interactively at home by
% L. Strow.
% 
% This script is the first part of testing a large re-write of
% rtp_prod grib readers, and maybe emissivity assignments.
%
% June, 20, 2014
rtprod = '~/Git/rtp_prod';
matlib = '~/Git/matlib';
gribtype = 'ecmwf';

fin_hdr  = fullfile('/asl/data/cris/sdr60/hdf','2013','240');
fout_hdr = fullfile('/asl/s1/strow/');

flist    = dir(fullfile(fin_hdr,'SDR*.mat'));

% Before any loops on filenames, assign current grib name as empty
current_ename = '';

addpath(rtprod);
paths
setenv('RTPROD',rtprod);

% Combination of matlib and rtp_prod git hash/tags
version = version_number();

% Just do the first file for now
% 26 is our test granule for hi-res data
ifile = 26;

fn2='SCRIS_npp_d20130828_t0326579_e0334557_b09502_c20130828093458042989_noaa_ops.h5';

fn_in = fullfile(fin_hdr,fn2);



% Vary name here, add version, remove SDR, etc.
fn_out = 'idps.rtp';%flist(ifile).name;
% fn_out = strrep(fn_out,'SDR_','cris_ccast_hr_');
% fn_out = strrep(fn_out,'.mat',['-git' version '.rtp']);

fn_out = fullfile(fout_hdr,fn_out);
fn_out_dir = fileparts(fn_out);

disp('Input File:');
disp(fn_in);
disp('Output File:');
disp(fn_out);

if(~exist(fn_out_dir,'dir'))
  disp(['Creating output directory']);
  mkdir(fn_out_dir);
end

% Test for file existence
if(exist(fn_out ,'file'))
  disp(['Attention: Output file "' fn_out '" already exist. Skipping...']); 
  return
end

% Read SDR file
[head hattr prof pattr] = sdr2rtp_bc(fn_in); 

% Assign some headers
head.ngas = 0;
hattr = set_attr(hattr,'version',version);

% Remove buggy CrIS rtime, rlat, and rlon
[head prof] = cris_filter_bad_data(head, prof);

% Add landfrac
[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr,'/asl');

% % Get grib data
% [head, hattr, prof, pattr, current_ename] = ...
%     rtpadd_grib_data(current_ename, gribtype, head, hattr, prof, pattr);

% Assign emissivities (land and ocean)
% [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr);

% % Find clear FOVs and compute SARTA clear
% instrument='CRIS_888';
% [head hattr prof pattr summary] = ...
%        compute_clear_wrapper(head, hattr, prof, pattr, instrument);

% Save output
  [dd, ~, ~] = fileparts(fn_out);
  if(~exist(dd,'dir'))
    system(['mkdir -p ' dd]);
  end 
  disp(['Saving ' fn_out]);
  rtpwrite(fn_out, head,hattr,prof,pattr);


