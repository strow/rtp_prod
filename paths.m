%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% RTP_PROD/MATLIB PATH SETUP CODE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Default path roots are:
% /asl/rtp_prod/
% /asl/matlib/
%
% If you want to specify another root, 
% simply redefine the variables "rtprod" and
% "matlib". Eg:
%
% rtprod = '~/git/rtp_prod/'
% matlib = '~/git/matlib/'
% 
% Breno Imbiriba - 2013.10.18


if(~exist('rtprod','var'))
  disp('PATHS: rtprod does not exist - using default /asl/rtprod/');
  rtprod = '/asl/rtp_prod/';
  %rtprod = '~/git/rtp_prod';
%  rtprod = fileparts(mfilename('fullpath'));
end

if(~exist('matlib','var'))
  disp('PATHS: matlib does not exist - using default /asl/matlib/');
  matlib = '/asl/matlib/';
%  matlib = '~/git/matlib';
%  matlib = [fileparts(rtprod) '/matlib'];
end

addpath([rtprod]);
addpath([rtprod '/diurnal_sst']);
addpath([rtprod '/extra_routines']);

addpath([rtprod '/airs/gstats']);
addpath([rtprod '/airs/readers']);
addpath([rtprod '/airs/rtp']);
addpath([rtprod '/airs/uniform']);
addpath([rtprod '/airs/utils']);

addpath([rtprod '/iasi/clear']);
addpath([rtprod '/iasi/gstats']);
addpath([rtprod '/iasi/readers']);
addpath([rtprod '/iasi/rtp']);
addpath([rtprod '/iasi/uniform']);
addpath([rtprod '/iasi/utils']);

addpath([rtprod '/cris/gstats']);
addpath([rtprod '/cris/clear']);
addpath([rtprod '/cris/readers']);
addpath([rtprod '/cris/rtp']);
addpath([rtprod '/cris/unapod']);
addpath([rtprod '/cris/uniform']);
addpath([rtprod '/cris/utils']);

addpath([ matlib]);
addpath([ matlib '/aslutil']);
addpath([ matlib '/clouds']);
addpath([ matlib '/clouds/sarta']);
addpath([ matlib '/fconv']);
addpath([ matlib '/gribtools']);
addpath([ matlib '/h4tools']);
addpath([ matlib '/opendap']);
addpath([ matlib '/rtptools']);
addpath([ matlib '/science']);
addpath([ matlib '/sconv']);

