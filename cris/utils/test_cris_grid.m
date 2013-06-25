function [type ngc] = test_cris_grid(vchan)
% function [type ngc]  = test_cris_grid(vchan)
%
% Returns the type (888 or 842) cris grid and the 
% number of guard channels.
%
% INPUT
%   vchan - list of channels
%
% OUTPUT
%   type - 888/842 - HighRes or LowRes grid indicator
%          Will return -1 if main grid is wrong.
%
%   ngc  - the number of guard channels on each side of each bank.
%          Will return -1 if grid is inconsistent
%
% Breno Imbiriba - 2013.03.27

  vc888 = make_cris_grid(888,0);
  
  % Test for grid type
  [ii ix] = wn2ch(struct('vchan',vchan,'ichan',[1:numel(vchan)]), vc888,0);

  lhr = numel(ii)==2211;
  llr = numel(ii)==1305;

  if(lhr)
    ngc = (numel(vchan)-2211)/6;
    type=888;
  elseif(llr)
    ngc = (numel(vchan)-1305)/6;
    type=842;
  else
    ngc = -1;
    type=-1;
  end

  if(ngc~=nearest(ngc))
    ngc=-1;
  end
end 




