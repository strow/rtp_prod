function [fname, fnameb, iok, iokb] = get_gfs_name(year,month,day,dhour);

% function [fname, fnameb, iok, iokb] = get_gfs_name(year,month,day,dhour);
%
% Return NCEP GFS 0.5x0.5 standard+supplemental filenames for the
% specified time.  Also returns ierr to say if the files exists or not.
%
% Input:
%    year  - [1 x n] year
%    month - [1 x n] month
%    day   - [1 x n] day
%    dhour - [1 x n] decimal hour
%
% Output:
%    fname  - [1 x n] cell string for standard GFS file
%    fnameb - [1 x n] cell string for supplemetnal GFS file
%    iok    - [1 x n] file fname exists? 0=no; 1=yes
%    iokb   - [1 x n] file fnameb exists? 0=no; 1=yes
%

% Created: 13 Dec 2011, Scott Hannon
% Update: 14 Dec 2011, S.Hannon - revised toplevel & subdir_form
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NCEP GFS filenames
%old toplevel = '/asl/data/ncep/';
%old subdir_form = '<YYYY>/<MM>/<YYYY><MM><DD><AH>/';
toplevel = '/asl/data/gfs/';
subdir_form = '<YYYY>/<MM>/<DD>/';
fname_form = 'gfs.t<AH>z.pgrb2f<FH>';
fnameb_form = 'gfs.t<AH>z.pgrb2bf<FH>';

model_hours    = [0 3 6 9 12 15 18 21 24];
analysis_hours = [0 0 6 6 12 12 18 18];
forecast_hours = [0 3 0 3  0  3  0  3];
nhours = length(analysis_hours);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 4)
  error('Unexpected number of input arguments')
end
%
d = size(year);
if (length(d) ~= 2 | min(d) ~= 1)
  error('unexpected dimensions for argument year');
end
nin = length(year);
%
d = size(month);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= nin)
  error('unexpected dimensions for argument month');
end
%
d = size(day);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= nin)
  error('unexpected dimensions for argument day');
end
%
d = size(dhour);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= nin)
  error('unexpected dimensions for argument dhour');
end


% Loop over the times
iok = zeros(1,nin);
iokb = zeros(1,nin);
for ii=1:nin

   % Determine nearest model hour
   dt = abs(dhour(ii) - model_hours);
   dt_min = min(dt);
   ih = find(dt == dt_min);
   ih = ih(1);
   junk = datenum(year(ii),month(ii),day(ii),model_hours(ih),0,0);
   [y,m,d,h,mm,ss] = datevec(junk);
   if (ih > nhours)
      ih = ih - nhours;
   end

   % Generate dir and filename strings
   YYYY = sprintf('%4u',y);
   MM = sprintf('%02u',m);
   DD = sprintf('%02u',d);
   AH = sprintf('%02u',analysis_hours(ih));
   FH = sprintf('%02u',forecast_hours(ih));
   snew= strrep(subdir_form,'<YYYY>',YYYY);
   sold = snew;
   snew= strrep(sold,'<MM>',MM);
   sold = snew;
   snew= strrep(sold,'<DD>',DD);
   sold = snew;
   snew= strrep(sold,'<AH>',AH);
   dir_str = [toplevel snew];
   snew = strrep(fname_form,'<YYYY>',YYYY);
   sold = snew;
   snew= strrep(sold,'<MM>',MM);
   sold = snew;
   snew= strrep(sold,'<DD>',DD);
   sold = snew;
   snew= strrep(sold,'<AH>',AH);
   sold = snew;
   snew= strrep(sold,'<FH>',FH);
   fname{ii} = [dir_str snew];
   snew = strrep(fnameb_form,'<YYYY>',YYYY);
   sold = snew;
   snew= strrep(sold,'<MM>',MM);
   sold = snew;
   snew= strrep(sold,'<DD>',DD);
   sold = snew;
   snew= strrep(sold,'<AH>',AH);
   sold = snew;
   snew= strrep(sold,'<FH>',FH);
   fnameb{ii} = [dir_str snew];

   % Check if files exist
   iok(ii)= min([1 exist(fname{ii})]);
   iokb(ii) = min([1 exist(fnameb{ii})]);
end

%%% end of function %%%
