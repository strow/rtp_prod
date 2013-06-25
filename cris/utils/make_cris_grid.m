function [vchan ichan] = make_cris_grid(type, ngc)
% function [vchan ichan] = make_cris_grid(type, ngc)
%
% Construct the spectral grid for CrIS instrument with 
% "gc" number of guard-channels on each side of each of the
% three bands.
%
% INPUT
%   type - 842 or 888, i.e. low res or high res data
%   ngc   - number of guard channels on each side of each band
%
% OUTPUT
%   vchan - wavenumbers
%   ichan - channel number - g4 style - guard-channels at the end.
%
% Breno Imbiriba - 2013/03/26

  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % Check to see if it is a 842 or a 888 grid

  if(type==842)
    % This is a LowRes grid

    % IDPS SDR channel frequencies - 842-type file
    dw_lw=0.625;
    dw_mw=1.250;
    dw_sw=2.500;
  elseif(type==888)
    % This is a High Res grid

    % HighRes Channel frequencies - 888-type file
    dw_lw=0.625;
    dw_mw=0.625;
    dw_sw=0.625;
  else
    error(['Wrong type']);
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

  % Make the BASE grid
  wn_lw0 = [650 :dw_lw:1095];
  wn_mw0 = [1210:dw_mw:1750];
  wn_sw0 = [2155:dw_sw:2550];

  nchan_lw0 = length(wn_lw0);
  nchan_mw0 = length(wn_mw0);
  nchan_sw0 = length(wn_sw0);

  ichan_lw0 = [1:nchan_lw0];
  ichan_mw0 = [1:nchan_mw0] + nchan_lw0;
  ichan_sw0 = [1:nchan_sw0] + nchan_lw0 + nchan_mw0;

  nchan_0 = nchan_lw0 + nchan_mw0 + nchan_sw0;

  % Add guard channels - ngc in each side of each band
  wn_lw = [wn_lw0(1)-dw_lw.*[ngc:-1:1],  wn_lw0,  wn_lw0(end)+dw_lw.*[1:ngc]];
  wn_mw = [wn_mw0(1)-dw_mw.*[ngc:-1:1],  wn_mw0,  wn_mw0(end)+dw_mw.*[1:ngc]];
  wn_sw = [wn_sw0(1)-dw_sw.*[ngc:-1:1],  wn_sw0,  wn_sw0(end)+dw_sw.*[1:ngc]];

  nchan_lw = length(wn_lw);
  nchan_mw = length(wn_mw);
  nchan_sw = length(wn_sw);

  nchan = nchan_lw + nchan_mw + nchan_sw;

  ichan_lw = [nchan_0+0*ngc+(1:ngc), ichan_lw0, nchan_0+1*ngc+(1:ngc)];
  ichan_mw = [nchan_0+2*ngc+(1:ngc), ichan_mw0, nchan_0+3*ngc+(1:ngc)];
  ichan_sw = [nchan_0+4*ngc+(1:ngc), ichan_sw0, nchan_0+5*ngc+(1:ngc)];

  % Make final grid vchan and ichan
  vchan = [wn_lw wn_mw wn_sw]';
  ichan = [ichan_lw ichan_mw ichan_sw]';

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  


end
