function [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr)
%function [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr)
%
% This function takes an rtp profile / file and adds/replaces the emissivity data
%
% The idea behind this function is to add all the emissivity needed fields to a profile structure so 
%   that higher order functions may be able to interchangably call the emissivity of different methods

%  Written 17 March 2011 - Paul Schou


%addpath /asl/matlab/science        % emissivity function
%addpath /asl/matlab/aslutil/  % get_attr function

debug = 1; %indicate that we are in debug an print out a bunch of checks

if ~isfield(prof,'wspeed');
    error('Prof structure missing wspeed field')
end

%%%%%%  Begin rtpadd_emis_DanZhou

    % convert to matlab time
    rtime_str = get_attr(pattr,'rtime');
    if isempty(rtime_str); rtime_str = get_attr(pattr,'L1bCM rtime'); end  % backwards compatibility
    if debug; disp(['rtime str = ' rtime_str]); end

    st_year = 1993;  % default to 1993 year
    if length(rtime_str) > 4
      st_year = str2num(rtime_str(end-4:end));
      if st_year < 1993
        disp('Warning [rtpadd_ecmwf]: The rtime in pattr is in an invalid format')
        st_year = 1993;
      end
    else
      disp('Warning [rtpadd_ecmwf]: Could not find rtime in pattr for start year')
    end
    npro = length(prof.rtime);

    % load in the land and sea emissivities
    [land_efreq, land_emis]=emis_DanZhou(prof.rlat,prof.rlon,prof.rtime,st_year);
    [sea_nemis, sea_efreq, sea_emis]=cal_seaemis2(prof.satzen,prof.wspeed);

    % interpolate onto the land emissivity freqencies
    [prof.emis prof.efreq prof.nemis] = interp_emis(land_efreq,land_emis,sea_efreq,sea_emis,prof.landfrac,land_efreq);

    % set an attribute string to let the rtp know what we have done
    set_attr(pattr,'emis',['land(' which('emis_DanZhou') ')  water(' which('cal_seaemis2') ')']);
    
end % Function end
