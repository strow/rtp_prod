function [profbit, ircalbit, irobsbit] = pfields2bits(pfields);

% function [profbit, ircalbit, irobsbit] = pfields2bits(pfields);
%
% Convert the RTP "pfields" into its three individual bit flags.
%
% Input:
%    pfields : (1 x 1) RTP header field "pfields" (integer 0-31)
%
% Output:
%    profbit  : (1 x 1) profile data flag               {bit 1}
%    ircalbit : (1 x 1) calculated radiance data flag   {bit 2}
%    irobsbit : (1 x 1) observed radiance data flag     {bit 3}
%
% Note: all bit flags are integers with 0=false, 1=true.
%

% Created: Scott Hannon, 13 June 2002
% Update: 13 Feb 2007, Scott Hannon - replace de2be with int2bits
% Update: 14 Nov 2008, S.Hannon - remove mwcalbit & mwobsbit
% Update: 27 May 2009, S.Hannon - add path for int2bits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%
% Check pfields
if ( max( size(pfields) ) ~= 1)
   error('getfields: pfields must be a scaler')
end

junk=pfields - round(pfields);
if (junk > 1E-1 | pfields < 0 | pfields > 7)
   error('getfields: pfields must be an integer 0-7')
end


%%%%%%
% Convert to  bit flags
bitflags = int2bits(pfields,3);

profbit=bitflags(1);
ircalbit=bitflags(2);
irobsbit=bitflags(3);

%%% end of function %%%
