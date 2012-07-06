function psub=ProfSubset2(prof, subset)
% function psub=ProfSubset2(prof, subset)
% 
% Generate a subset of profiles in prof. 
% Subset is an array of selected profiles [p1 p2 ... pn].
%
% Concept by Breno Imbiriba 2007.03.10
%  vectorized by Paul Schou 2012

psub=structfun(@(x) (x(:,subset,:,:)), prof, 'UniformOutput', false);

