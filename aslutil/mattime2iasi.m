function dateout = mattime2iasi(varargin)
% Convert MATLAB time to IASI time
%
% use either:
%  mattime2iasi(datenum(2001,2,3,4,5,6))
%  mattime2iasi(2001,2,3,4,5,6)
%
% See also:  iasi2mattime, tai2mattime, mattime2tai

% Written by Paul Schou - 10 Sep 2009  (paulschou.com)
if nargin == 1
  dateout = (varargin{1}-datenum(2000,1,1,0,0,0))*86400;
elseif nargin == 6
  dateout = (datenum(varargin)-datenum(2000,1,1,0,0,0))*86400;
end
