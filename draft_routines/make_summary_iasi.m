function s = make_summary_iasi(head, hattr, prof, pattr)

  % Declare the summary file
  % Summary file suffix; full filename=<rtpfile><summary_suffix>.mat

  %say('allocating memory for summary');

  summary_suffix='_allfov_summary';
  st = 1;
  en = 0;
  % Note: granules contain up to 690 x 4 FOVs.
  %maxfov = 300; % tighten this down for the clear subset (an approximation)
  s.findex      =uint16(zeros(nfovs));
  s.qualflag    = uint8(zeros(nfovs));
  s.GQisFlagQual= uint8(zeros(nfovs));
 %s.coastflag   = uint8(zeros(nfovs));
  s.reason      = uint8(zeros(nfovs));
  s.clearflag   = uint8(zeros(nfovs));
  s.siteflag    = uint8(zeros(nfovs));
  s.hicloudflag = uint8(zeros(nfovs));
  s.randomflag  = uint8(zeros(nfovs));
  s.avhrrflag   = uint8(zeros(nfovs));
  s.imageunflag = uint8(zeros(nfovs));
  s.spectunflag = uint8(zeros(nfovs));
  s.modseaice100= uint8(zeros(nfovs));
  s.modcld100   = uint8(zeros(nfovs));
  s.avhrrcld100 = uint8(zeros(nfovs));
  s.nsubL       = uint8(zeros(nfovs));
  s.btsubL  = single(zeros(nfovs));
  s.stdsubL = single(zeros(nfovs));
  s.dbtq    = single(zeros(nfovs));
  s.dbt820  = single(zeros(nfovs));
  s.dbt960  = single(zeros(nfovs));
  s.retsst  = single(zeros(nfovs));
  s.modsst  = single(zeros(nfovs));
  s.landfrac= single(zeros(nfovs));
  s.rlat    = single(zeros(nfovs));
  s.rlon    = single(zeros(nfovs));
  s.rtime = double(zeros(nfovs));




end
