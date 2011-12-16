function tname = mktemp(TempDir,namePrefix);
%MKTEMP Create a unique temporary file name.
%   NAME = MKTEMP(dir,prefix), MKTEMP(dir_w_prefix), or MKTEMP()
%   MKTEMP uses the built-in unix system binary that generates 
%   unique temporary file names and verifies they don't
%   cause collisions.
%
%   Examples:
%      file1 = mktemp()
%      file2 = mktemp('/tmp/testme')
%      file3 = mktemp('/tmp','testme')
%      tmp_dir = mktemp('dir')  % an empty directory
%      ls /tmp
%      mktemp('clean')
%
%   Note: when specifying the directories /dev/shm this function will automatically
%     postfix the directory with a random number (per JOB / day span) on the cluster 
%     to avoid collisions.  The same will happen when /tmp is specified.
%
%   Warning: In MATLAB versions 2008a and later all files generated using 
%   this function will automatically be deleted when MatLab closes.

% Version 1.1, Written by Paul Schou - 26 Oct 2008
%  updated:  18 June 2011 - Paul Schou  added the ability to clear all files ending with name.*

persistent AlternateDir
global mktemp_handles

% cleanup routine for removing temporary files
if(nargin == 1 && strcmpi(TempDir,'clean'))
  if(verLessThan('matlab','7.6.0'))
    for i=1:length(mktemp_handles)
      disp(['  cleaning ' mktemp_handles{i}])
      unlink(mktemp_handles{i});
      for f = findfiles([mktemp_handles{i} '.*'])
        disp(['  cleaning extra ' f{1}])
        unlink(f{1});
      end
    end
    mktemp_handles = {};
  else
    mktemp_handles = [];
  end

  % Exit status if requested
  if(nargout == 1)
    tname=0;
  end
  return
elseif(nargin > 0 & strcmpi(TempDir,'dir'))
  if(nargin == 1)
    tname = mktemp();
  else
    tname = mktemp(namePrefix);
  end
  delete(tname);
  mkdir(tname);
  return;
end

if(nargout == 0)
  error('MKTEMP: no output variable specified');
end

%%% Main function %%%

  % handle the input arguments and assign variables
  if(nargin == 0)
    TempDir = getenv('TMPDIR');
    namePrefix = 'mktemp';
  elseif(nargin == 1)
    namePrefix = TempDir;
    TempDir = dirname(TempDir);
    if strcmp(TempDir,'.')
      TempDir = getenv('TMPDIR');
    end
  elseif(~ isdir(TempDir) && isempty(AlternateDir))
    disp(['Warning: ' TempDir ' does not exist, using alternate temporary directory'])
    AlternateDir = 1; % supress future error messages
  end

  % verify that the directory given is a valid location
  if(~ isdir(TempDir)) % if the directory does not exist, choose another
    if(isdir('/tmp'))
      TempDir = '/tmp';
    elseif(isdir('/dev/shm'))
      TempDir = '/dev/shm';
    else
      error('MKTEMP:  No temporary folder found on system')
    end
  end

  if strcmp(TempDir(1:min(end,8)),'/dev/shm') & ~isempty(getenv('SHMDIR'))
    TempDir = getenv('SHMDIR');
  elseif strcmp(TempDir,'/tmp') & ~isempty(getenv('TMPDIR'))
    TempDir = getenv('TMPDIR');
  end
  
  % generate a random file name and verify it doesn't already exist
  validchars = [(0:25)+'a' (0:25)+'A' (0:9)+'0'];
  fid = fopen('/dev/urandom','r');
  while ( 1 )
    t=mod(fread(fid,8),62)+1;
    randval = validchars(t);
    [pathstr name ext] = fileparts(namePrefix);
    tname = [TempDir '/' name '_' randval ext];
    if ( ~ exist(tname,'file') )
      tfid = fopen(tname,'w+');
      if tfid
        fclose(tfid);
        break;
      else
        error(['MKTEMP: Could not create ' tname]);
      end
    end
  end
  fclose(fid);

  % add the file name to a cell array or the handle
  if(verLessThan('matlab','7.6.0'))
    mktemp_handles = {mktemp_handles , tname};
  else
    c = onCleanup(@()unlink(tname));
    mktemp_handles = [mktemp_handles c];
  end
