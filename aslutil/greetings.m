function greetings(rn,bye)
% greetings - show a greeting message at the beginning of the routine 'rn'
% bye - (logical) if present and true, will preset the 'farewell' message.
%
% rn - routine name (string) to show
% The function name "rn" will have hierachy set by dbstack() routine. 
% 
% This is ment to organize the output and help debuggig.
%
% Breno Imbiriba - 2012.12.26 (based on my 'IO' routine)


  stack = dbstack;
  level = numel(stack);

  if(nargin==2 && bye)
    if(level>1)
      if(strcmp(stack(2).name,'farewell'))
	% If this is being called from the "farewell" routine, reduce in one the level to 
	% reflect the correct calling routine level (not the one added by the farewell call)
	level=level-1;
      end
    end
  end
  % We don't want to add an extra level because of "greetings" itself.
  % Remove one from the level
  level=level-1;
   
  msg='';

  for il=1:level
    msg=[msg '***'];
  end
  if(level>0)
    msg=[msg ' '];
  end

  if(nargin==2 && bye)
    msg = [msg 'END   ***** ' rn '********************************************************************************'];
    disp(msg(1:80));
    disp('********************************************************************************');

  else
    msg = [msg 'BEGIN ***** ' rn '********************************************************************************'];
    disp('********************************************************************************');
    disp(msg(1:80));

  end

end



