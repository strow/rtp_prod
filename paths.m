base_dir = fileparts(mfilename('fullpath'));
base_dir1 = fileparts(base_dir);

addpath([base_dir]);
addpath([base_dir '/diurnal_sst']);
addpath([base_dir '/extra_routines']);

addpath([base_dir '/airs/gstats']);
addpath([base_dir '/airs/readers']);
addpath([base_dir '/airs/rtp']);
addpath([base_dir '/airs/uniform']);
addpath([base_dir '/airs/utils']);

addpath([base_dir '/iasi/clear']);
addpath([base_dir '/iasi/gstats']);
addpath([base_dir '/iasi/readers']);
addpath([base_dir '/iasi/rtp']);
addpath([base_dir '/iasi/uniform']);
addpath([base_dir '/iasi/utils']);

addpath([base_dir '/cris/gstats']);
addpath([base_dir '/cris/clear']);
addpath([base_dir '/cris/readers']);
addpath([base_dir '/cris/rtp']);
addpath([base_dir '/cris/unapod']);
addpath([base_dir '/cris/uniform']);
addpath([base_dir '/cris/utils']);

addpath([ base_dir1 '/matlib/']);
addpath([ base_dir1 '/matlib/aslutil']);
addpath([ base_dir1 '/matlib/clouds']);
addpath([ base_dir1 '/matlib/fconv']);
addpath([ base_dir1 '/matlib/gribtools']);
addpath([ base_dir1 '/matlib/h4tools']);
addpath([ base_dir1 '/matlib/opendap']);
addpath([ base_dir1 '/matlib/rtptools']);
addpath([ base_dir1 '/matlib/science']);
addpath([ base_dir1 '/matlib/sconv']);

