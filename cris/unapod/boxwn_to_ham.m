function [rham] = boxwn_to_ham(vchan, rbox)
% function [rham] = boxwn_to_ham(vchan, rbox)
% 
% Convert CrIS radiance from boxcar (unapodized) data to
% Hamming spodized.
%
% This routine uses 'vchan' instead of 'ichan' (as boxg4_to_ham.m uses)
% hence it can operate with a variable number of guard-channels.
%
% Input:
%    vchan  -  [nchan x 1] channel wavenumbers.
%    rbox   -  [nchan x nobs] unapodized (boxcar) radiance
%
% Output:
%    rham   - [nchan x nobs] Hamming apodized radiance.  All
%       channels are returned, but any channel lacking a low
%       and/or high adjacent neighbor channel is NaN.
%
% Breno Imbiriba - 2013.03.26


  % Check input
  if (nargin ~= 2)
     error('Unexpected number of input arguments')
  end
  d = size(vchan);
  if (length(d) ~= 2 | min(d) ~= 1)
     error('Unexpected dimensions for argument ichan')
  end
  nchan = max(d);
  [n,nobs] = size(rbox);
  if (n ~= nchan)
     error('Lead dimension of rbox must match length of ichan')
  end


  % Find channel Banks. 
  % Banks are blocks separated by more the 20wn
  [uf ib] = unique(diff(vchan),'last');
  nbancks = find(uf > 20)';

  % ib carries the index of the last channel of each bank.
  % Add the last channel to add the last bank.
  ib(end+1) = numel(vchan);
  nbancks(end+1) = numel(ib);

  ic0=1;
  ic1=-1;
  for ii=nbancks
    ic1=ib(ii);
    rbox_blk = rbox(ic0:ic1,:);
    vchan_blk = vchan(ic0:ic1,:);

    rham_blk = box_to_ham(rbox_blk);
    
    rham(ic0:ic1,:) = rham_blk;
    rham([ic0 ic1],:) = NaN;  
    ic0=ic1+1;
    ic1=-1;
  end

   
  
end  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
% % A few sanity tests so that things to go too wrong.
% % uf(1) = smallet grid spacing (0.625 or something like that)
% % uf(:) = for low res files, you'll have extra grid spacing here:
% %         1.25 and 2.5
% % uf(end-1) = Break between Bank 1 and 2 (of about 110 wn)
% % uf(end)   = Break between Bank 2 and 3 (of about 400 wn)
% 
% ishires = numel(uf)==3;
% islowres = numel(uf)==5;
% is3banks = false;
% iswvok = false;
% 
% if(ishires)
%   is3banks = uf(2)>=100 & uf(3)>=390;
% end
% if(islowres)
%   is3banks = uf(4)>=100 & uf(5)>=390;
% end
% if(ishires)
%   iswvok = uf(1)==0.625;
% end
% if(islowres)
%   iswvok = uf(1)==0.625 & uf(2)==1.25 & uf(3)==2.5;
% end
% 
% if(ishires)
%   if(~iswvok)
%     warninig(['boxgc_to_ham: This looks like HiRes CrIS but the grid resolution is wrong: dwn=' num2str(uf(1)) '.']);
%   end
% end
% if(islowres)
%   if(~iswvok)
%     warning(['boxgc_to_ham: This looks like LowRes CrIS data but the resolutions are wrong: ' num2str(uf(1)) ', ' num2str(uf(2)) ', and ' num2str(uf(3)) '.']);
%   end
% end
% if(~islowres & ~ishires)
%   warning(['CrIS is supposed to have only 3 banks, but I found ' num2str(numel(uf)-1) '. Will continue blindly.']);
% end
% 
% if((ishires | islowres) & ~is3banks)
%   warning(['boxgc_to_ham: This data seems to have three banks (like CrIS data) but the gap between the bands is too small: ' num2str(uf(2)) ' and ' num2str(uf(3)) ]);
% end
% 
% if(~is3banks)
%   warning(['Data does not seem to have 3 banks']);
% end
% 
% 
