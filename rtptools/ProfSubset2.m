function psub=ProfSubset2(prof, subset)
% function psub=ProfSubset2(prof, subset)
% 
% Generate a subset of profiles in prof. 
% Subset is an array of selected profiles [p1 p2 ... pn].
%
% Concept by Breno Imbiriba 2007.03.10
%  vectorized by Paul Schou 2012
%  updated by Breno Imbiriba to extend to multiple dimensions

psub=structfun(@(x) (func(x,subset)), prof, 'UniformOutput', false);


function y=func(x,subset)
  if(ndims(x)==2)
    y=x(:,subset);
  elseif(ndims(x)==3)
    y=x(:,:,subset);
  elseif(ndims(x)==4)
    y=x(:,:,:,subset);
  else
    error('ProfSubset2_git not configured to handle more than ndims=4');
  end
end
end
