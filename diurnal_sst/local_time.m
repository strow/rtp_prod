function [ylocaltime,raJD1] = local_time(raUTC,raJD,raLon);

%% simple function to change from UTC to local time

raJD1 = raJD;

iX = find(raLon >= 0);
if length(iX) > 0
  dt(iX) = 24/360 * raLon(iX);
  ylocaltime(iX) = raUTC(iX) + dt(iX);
end

iX = find(raLon < 0);
if length(iX) > 0
  xlon = 360 + raLon(iX);
  dt(iX) = 24/360 * xlon;
  ylocaltime(iX) = raUTC(iX) + dt(iX);
end

iX = find(ylocaltime > 24);
if length(iX) > 0
  ylocaltime(iX) =   ylocaltime(iX) - 24;
  raJD1(iX) =   raJD1(iX) + 1;
end

iX = find(ylocaltime < 0);
if length(iX) > 0
  ylocaltime(iX) =   24 + ylocaltime(iX);
  raJD1(iX) =   raJD1(iX) - 1;
end