function fname = tmpdir()
%function fname = tmpdir()
%
%  Basic function that returns a temporary directory based on the free space available.
%

% Written:  28 June 2011 - Paul Schou

  dirT = '/tmp/';
  if ~isempty(getenv('TMPDIR'))
    dirT = getenv('TMPDIR');
  end

  fname = dirT;


  if(false)
    import java.io.*;

    dirS = '/dev/shm/';
    if ~isempty(getenv('SHMDIR'))
      dirS = getenv('SHMDIR');
    end

    dirT = '/tmp/';
    if ~isempty(getenv('TMPDIR'))
      dirT = getenv('TMPDIR');
    end

    t=File(dirT);
    s=File(dirS);

    if rand < t.getFreeSpace / (t.getFreeSpace+s.getFreeSpace)
      fname = dirT;
    else
      %fname = dirS;
      fname = dirT;
    end
  end

end
