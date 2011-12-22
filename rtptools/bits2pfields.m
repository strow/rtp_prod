function [pfields] = bits2pfields(profbit,ircalbit,irobsbit );

% function [pfields] = bits2pfields( profbit, ircalbit, irobsbit );
%
% Convert three bit flags into an RTP header "pfields" integer value.
%
% Input:
%    profbit  : (1 x 1) profile data flag             {bit 1}
%    ircalbit : (1 x 1) calculated radiance data flag {bit 2}
%    irobsbit : (1 x 1) observed radiance data flag   {bit 3}
%
% Output:
%    pfields : (1 x 1) RTP header field "pfields" (integer 0-7)
%
% Note: all bit flags are integers with 0=false, 1=true.
% The conversion is sum(n=1,3){ bit(n)*2^(n-1) }
%

% Created: Scott Hannon, 13 June 2002
% Update: 26 Feb 2007, Scott Hannon - replace bi2de with bit2int
% Update: 14 Nov 2008,S.Hannon - remove mwcalbit & mwobsbit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%
% Check the input
if ( max( size(profbit) ) ~= 1)
   error('setpfields: profbit must be a scaler')
end
if ( max( size(ircalbit) ) ~= 1)
   error('setpfields: ircalbit must be a scaler')
end
if ( max( size(irobsbit) ) ~= 1)
   error('setpfields: irobsbit must be a scaler')
end

bits=[profbit, ircalbit, irobsbit];

if (max(bits)-1 > 1E-5)
   error('setpfields: bit flag values must be 0 or 1')
end
if (min(bits) < -1E-5)
   error('setpfields: bit flag values must be 0 or 1')
end


%%%%%%
% Convert bit flags to pfields
junk = bits2int(bits);
pfields=round(junk);  % ensure certain pfields is an exact integer


%%% end of function %%%
