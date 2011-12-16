% determine where we are writing data out to:
base_dir = fileparts(mfilename('fullpath')); % current directory
base_dir1 = fileparts(base_dir);  % dir:  ../
base_dir2 = fileparts(base_dir1); % dir:  ../../

%if mfile(1:10)
%prod_dir = '/asl/data/rtprod_cris';
prod_dir = '/asl/data/rtprod_cris_test';

% CRiS Matlab utility box
%addpath([base_dir1 '/clear'])
addpath([base_dir1 '/readers'])
addpath([base_dir1 '/rtp'])
addpath([base_dir1 '/uniform'])
%addpath([base_dir1 '/utils'])

% ASL matlab utility box
addpath([base_dir2 '/gribtools/'])
addpath([base_dir2 '/aslutil/'])
addpath([base_dir2 '/science/'])
addpath([base_dir2 '/h4tools/'])
addpath([base_dir2 '/rtptools/'])

