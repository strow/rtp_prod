function j = JOB(n)

t=getenv('JOB');
j(1)=datenum(t(1:8),'yyyymmdd');
j(2)=datenum(t(end-7:end),'yyyymmdd');

if(nargin == 1)
  j = j(n);
end
