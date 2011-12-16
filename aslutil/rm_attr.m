function xattr = rm_attr( xattr , field );

% function xattr = rm_attr( xattr , field );
%
% Remove a specified attribute if it exists.
%
% Input:
%    xattr = RTP hattr or pattr (cell array with 1x3 elements per entry)
%    field = Name of attribute
%
% Output:
%    xattr = Updated attribute cell array
%

% Created 21 August 2009, Paul Schou  (paulschou.com)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nattr=length(xattr);

for ia=1:nattr
   if strcmpi(xattr{ia}(2),field)
       xattr = xattr(setdiff(1:end,ia));
       return
   end
end

%%% end of function %%%
