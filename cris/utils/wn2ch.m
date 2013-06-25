function [ichan index] = wn2ch(head, wavenumber, check)
% function ichan index] = wn2ch(head, wavenumber, check)
% Returns the closed wavenumber present on head.
%
% INPUTS
%   head       - header structure with fields vchan and ichan.
%   wavenumber - list of wavenumbers to match
%   check      - if true, will check if the chennels exist to the Kcarta grid 0.0001wn.
%                (default is 1)
%                if check==1, will issue an error, 
%                if check==2, will issue a warning.
% 
% OUTPUTS
% 
%   ichan - the ichan value
%   index - the linear index 
%
%   They are related by: head.ichan(index) == ichan.
%
% Breno Imbiriba - 2013.03.26

  if(nargin()~=3)
    check=true;
  end

  wavenumber = reshape_nx1_l(wavenumber);
  head.vchan = reshape_nx1_l(head.vchan);
  head.ichan = reshape_nx1_l(head.ichan);
  head.ichan = single(head.ichan);

  vc_0=head.vchan;
  ic_0=head.ichan;

  [~, is_01] = sort(vc_0);
  vc_1 = vc_0(is_01);
  ic_1 = ic_0(is_01);

  [ic_w] = interp1(vc_1, ic_1, wavenumber, 'nearest');
  [~, im_1, im_w] = intersect(ic_1, ic_w);

  index = is_01(im_1);
  ichan = ic_0(index);



  % Check
  if(check)
    if(numel(ichan)~=numel(wavenumber))
      msg1=['Missing channels! Can not find match for wavenumber(s): ' num2str(flat(setdiff(wavenumber, wavenumber(im_w)))')];
      if(check~=2)
	error(msg1);
      else
	warning(msg1);
      end
    end
    lfail = abs(vc_1(im_1)-wavenumber(im_w))>0.0001;
    if(any(lfail))
      msg2=['Missing channels! Can not find precision match to wavenumber(s): ' num2str(flat(wavenumber(lfail))') '.'];
      if(check~=2)
	error(msg2);
      else
	warning(msg2);
      end
    end
  end

end

function xt = reshape_nx1_l(x)
  % make the vector 'x' into a [Nx1] vector
  xt=reshape(x,[numel(x),1]);
end
