function [head hattr prof pattr] = uniform_clear(head, hattr, prof, pattr);
% function [head hattr prof pattr] = uniform_clear(head, hattr, prof, pattr);
%
% Implements the "Uniform Clear" algorithm for all three instruments.
%
% Breno Imbiriba - 2013.06.27

% Based on rtp_cris_subset_hr

  % 1. Setup frequencies

  % 1.1 Uniformity test wavenumbers:
  ftestu = [819.375; 961.25; 1232.5];
  itestu = wn2ch(head, ftestu);

  % 1.2 Clear test wavenumbers
  ftestc = [819.375;856.875; 912.5  ; 961.25 ;....
            1043.75;1071.25;1083.125;1093.125;1232.5];
  itestc = wn2ch(head, ftestc);

  % 2. Uniformity test: 

  [dbtun, mbt] = xuniform3f(head, prof, ftestu);
  nobs = length(dbtun);
  ibad1 = find(mbt < 150); % indicates non-uniform fovs


  % 3. Clear test

  [head prof] = subset_rtp(head, prof, [], ftestc, []);


end
