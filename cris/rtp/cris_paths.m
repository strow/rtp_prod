% determine where we are writing data out to:
base_dir = fileparts(mfilename('fullpath')); % current directory
base_dir1 = fileparts(base_dir);  % dir:  ../
base_dir2 = fileparts(base_dir1); % dir:  ../../

% If not defined, set default dump path
if(~exist('prod_dir','var'))
  prod_dir = '/asl/data/rtprod_cris';
end

% CRiS Matlab utility box
addpath([base_dir2 ])
addpath([base_dir1 '/clear'])
addpath([base_dir1 '/readers'])
addpath([base_dir1 '/rtp'])
addpath([base_dir1 '/uniform'])
addpath([base_dir1 '/utils'])
addpath([base_dir1 '/unapod'])

% ASL MATLIB distribution location
% Is there an environment variable MATLIB?

matlib_root = getenv('MATLIB');

if(numel(matlib_root)==0 | ~exist(matlib_root,'dir'))
  % Not defined or invalid. Now look for it in two places
  base_dir3 = fileparts(base_dir2); % dir: ../../../
  if(exist([base_dir3 '/matlib/'],'dir'))
    matlib_root = [base_dir3 '/matlib/'];
  elseif(exist('/asl/matlib/','dir'))
    matlib_root = ['/asl/matlib/'];
  else
    error('Cannont find MATLIB');
  end
end

% ASL matlab utility box
addpath([matlib_root]);
addpath([matlib_root '/aslutil']);
addpath([matlib_root '/clouds']);
addpath([matlib_root '/fconv']);
addpath([matlib_root '/gribtools']);
addpath([matlib_root '/h4tools']);
addpath([matlib_root '/opendap']);
addpath([matlib_root '/rtptools']);
addpath([matlib_root '/science']);
addpath([matlib_root '/sconv']);

