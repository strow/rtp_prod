

clear all
a=[];
n=10000;

while (true)
  a=rand(n);
  [s r] = system('./mlmem.sh');
  r=eval(['[' r ']']);
  disp(['A ' num2str(n) 'x' num2str(n) ' -> Memory used: ' num2str(r/1024) ' Mb']);
  n=n+500;
  clear a
end


