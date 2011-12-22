function dateout = mattime2tai(varargin)
% Convert MATLAB time to AIRS time
%
% use either:
%  mattime2tai(datenum(2001,2,3,4,5,6))
%  mattime2tai(2001,2,3,4,5,6)
%
% See also:  iasi2mattime, tai2mattime, mattime2iasi

% Written by Paul Schou - 10 Sep 2009  (paulschou.com)
if nargin == 1
  dateout = (varargin{1}-datenum(1993,1,1,0,0,0))*86400;
elseif nargin == 6
  dateout = (datenum(varargin)-datenum(1993,1,1,0,0,0))*86400;
end
