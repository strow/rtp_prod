function txt=yesno(flag,yes,no)
% function txt=yesno(flag,yes,no)
%
% Write the string 'yes' or 'no' depending of the logical flag value:
%
% true -> "yes"
% false-> "no"
%
% Optional input variables:
%  
% yes - string to be printed instead of "yes"
% no  - string to be printed instead of "no"
%
%
% Breno Imbiriba - 2012.12.19

  switch nargin()
  case 1
    yes='yes';
    no='no';
  case 2
    no='no';
  end

  if(flag)
    txt=yes;
  else
    txt=no;
  end

end
