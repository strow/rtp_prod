function timeblock_dealer(s_vtime, e_vtime, d_vtime, pe, npe, cmd)
% function timeblock_dealer(s_vtime, e_vtime, d_vtime, pe, npe, cmd)
%
%   Given a time span (s_vtime to e_vtime) and a time block duration (d_vtime),
%   compute the number of time blocks, divide them amond all the processor (npe)
%   and call the desired matlab routine (cmd) for the current processor (pe).
%
%   s_vtime = starting time [yyyy mm dd HH MM SS]
%   e_vtime = ending time   [yyyy mm dd HH MM SS]
%   d_vtime = time duration on each file [yyyy mm dd HH MM SS]
%   pe = this processor
%   npe = number of processors
%   cmd = matlab function accepting TWO matlab times (start, end):
%         test_routine(stime, etime);
%
% Eg. 
%   s_vtime = [2012,09,20,0,0,0];
%   e_vtime = [2012,09,20,0,59,59.999];
%   d_vtime = [0,0,0,0,10,0];  % 10 minutes;
%   pe = 1;
%   npe = 2; % two processors
%   cmd = @test_cris_clear
%
%   Calling from the shell: see "test_cris_clear_run.sh"
%    
% Breno Imbiriba - 2013.07.31   
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 0 - Paralell loop setup
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert vector times into datenum

stime = datenum(s_vtime);
etime = datenum(e_vtime);
dtime = datenum(d_vtime);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Divide time into Dt sized blocks
Nb = nearest((etime - stime)./dtime);

tsi = stime + dtime.*([1:Nb]-1);
tei = stime + dtime.*([1:Nb]  );



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Deal blocks among processors:
Blocks = zeros(npe,ceil(Nb./npe));

for iblock = 1:Nb
  iproc = mod((iblock - 1),npe) + 1;
  idxblk = floor((iblock-1)./npe) + 1;

  Blocks(iproc, idxblk) = iblock;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Loop over blocks of THIS processor

for iblock = Blocks(pe,:)

  if(iblock==0)
    continue
  end

  disp(['I am processor ' num2str(pe) '/' num2str(npe) ]);

  sdate = tsi(iblock);
  edate = tei(iblock);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Call Processing script
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  disp(['Start date = ' datestr(sdate) ' -  End date = ' datestr(edate)]);

  try
    cmd(sdate, edate)
  catch errstr
    fprintf('\nError: %s (%s).\n',errstr.message, errstr.identifier);
    for it=1:length(errstr.stack)
      fprintf('   IN: %s>%s at %d.\n',errstr.stack(it).file, ...
				      errstr.stack(it).name, errstr.stack(it).line);
    end
    fprintf('Continuing timeblock_dealer loop.\n');
  end
 

end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
