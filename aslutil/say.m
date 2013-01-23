function stack=say(message,all)
% function stack=say(message,all)
%
% say('message');
% >> routine1::routine2::...::routineN: message.
%
% stk=say(); % will return the stack
%
% Set all=true to print the whole stack.
%
% Will use dbstack to figure out where it is and use that as a header

  if(nargin==1)
    all=false;
  end
  if(nargout==1)
    all=true;
  end

  a=dbstack;
  if(all)
    nn=numel(a);
    txt=a(nn).name;
    for ic=nn-1:-1:2
      txt=[txt '::' a(ic).name];
    end
  else
    if(numel(a)>1)
      txt=a(2).name;
    elseif(numel(a)==1)
      txt=a(1).name;
    else 
      txt='';
    end
  end

  if(nargout==1)
    stack=txt;
    return
  end
  if(nargin==0)
    message='';
  end
  txt=[txt ': ' message '.'];

  tme=datestr(now,'<yyyy/mm/dd HH:MM:ss.FFF>');

  disp([txt tme]);

end

