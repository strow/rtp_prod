function [head hattr prof pattr summary] = compute_clear_wrapper(head, hattr, prof, pattr, instrument);
% function [head hattr prof pattr] = compute_clear_wrapper(head, hattr, prof, pattr, instrument);
%
%   instrument = 'AIRS', 'IASI', or 'CRIS'
%
%   Wrapper to clear selection routines
%

  switch instrument
  case 'AIRS'

    % Uniformity test - uniform2.m
    % This is replacing the convolved sequence of calls on 
    % airs_uniform_clear_func.m
    % readl1b_uniform2.m
    % uniform2.m

    % This is originally in "airs_uniform_clear_func.m"

    % Channels
    idtest=[760 903 2328 2333]'; % (900.22, 960.95, 2610.8, 2616.1 cm^-1)
    % Note: these are all surface channels, so the uniformity test will
    % really be a surface uniformity test.  That is, the surface radiances
    % must be uniform, but it is possible that the profiles might be
    % quite different.

    % Set max allowed delta BT for uniformity test
    %dbtmax=0.25;
    %dbtmax=0.4;
    dbtmax=0.3;

    % Set max allowed (ie passing) radiance calibration flag
    flgmax=7;  % Bits 2^{0,1,2} currently not used

    % Call uniform2 
    srad = size(prof.robs1);
    nxtrack = 90;
    nchan = srad(1);
    natot = srad(2)/nxtrack;

    tcflag = reshape(prof.calflag,[nchan, nxtrack, natot]);

    [nun indun dbtun] = uniform2(head.vchan, ...
		reshape(prof.robs1,[nchan, nxtrack, natot]), ...
		reshape(tcflag(:,1,:),[nchan, natot]),...
		idtest, dbtmax, flgmax);
    clear tcflag;
    % nun - number of uniform FOVs per scanline [natrack*ngranules, 1]
    %         ** below we index these entries by "ia"
    % indun - index of each uniform fov per scanline [natrack*ngranules, nxtrack]
    %         ** only valid: [1:nun(ia)]
    % dbtun - max abd delta BT of uniform fovs [natrack*ngranules, nxtrack]
    %         ** only valid: [1:nun(ia)]

    % Make clear bit:

    iuniform = zeros(nxtrack, natot, 'int8');
    udbtun = -9999*ones(nxtrack, natot,'single');
    for ia=1:natot
      idxclr = indun(ia, 1:nun(ia));
      iuniform(idxclr, ia) = 1;
      udbtun(idxclr, ia) = dbtun(ia, 1:nun(ia));
    end

    %%% Do clear selection... 
     
    


  case 'IASI'

    temp_file = mktemp();
    rtpwrite(temp_file, head, hattr, prof, pattr);
    [head, hattr, prof_out, pattr,  summary] = iasi_uniform_clear_func_rtp(temp_file);
    
  case 'CRIS'

    subset = 0; % keep all fovs and channels
    keepcalcs = 0; % Don't keep them! Files will be too large
    [head hattr prof pattr summary] = rtp_cris_subset_hr(head, hattr, prof, pattr, subset, keepcalcs)

  case 'CRIS_888'

    subset = 0; % keep all fovs and channels
    keepcalcs = 1; % Keep calculations - it's too expensive for CrIS HR
    [head hattr prof pattr summary] = rtp_cris_subset_hr(head, hattr, prof, pattr, subset, keepcalcs)

  otherwise
    error('Bad instrument request - must be either AIRS/IASI/CRIS.');
  end

end

