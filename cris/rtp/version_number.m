function CODE_VERSION = version_number();
%% function CODE_VERSION = version_number();
%%
%% Setup a global variable CODE_VERSION with a release version number
%% string of the form (sample):
%%
%% Rv1.1-17-g64dc9bf-Mv1.0-59-gc41a047
%%
%% meaning:
%% 
%% rtp_prod TAG: v1.1
%% number of commits past this tag: 17
%% commit short hash code: g64dc9bf
%% matlib TAG: v1.0
%% number of commits past this tag: 59
%% commit short had code: gc41a047
%%
%% Get the version number from the GIT repository by calling
%% `rev_rtp_prod.m' and `rev_matlib.m'
%%
%% For this to work you must also have the matlib paths enabled
%% (by running either xxxx_paths.m code - xxxx=instrument) 
%%
%% Breno Imbiriba - 2013.05.08




global CODE_VERSION



%% 1. Get the "rtp_prod" version number
rtp_prod_version = rev_rtp_prod();



%% 2. Get the "matlib" version number
matlib_version = rev_matlib();

CODE_VERSION = ['R' rtp_prod_version(1:end-1) '-M' matlib_version(1:end-1)];

end
