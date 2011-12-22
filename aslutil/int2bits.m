function [bitarray] = int2bits( int, nbits );

% function [bitarray] = int2bits( int, nbits );
%
% Convert a 1-D array of integers to a 2-D array of up to 16 bit flags.
%
% Input:
%    int      = [m x 1] positive integers 0 <= int <= 65535
%    nbits    = [1 x 1] number of bit flags
%               The number of bits n must be 1 <= n <= 16
%
% Output:
%    bitarray = [m x nbits] array of bit flags {0 or 1}
%

% note: free replacement for the communications toolbox routine "de2bi"
%

% Created: 16 March 2005, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% powers of two = 2^(0 to 15)
powers=[1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768];
maxint = 65535;

% Check input
d = size(nbits);
n = round( nbits(1) );
junk = abs( n - nbits(1) );
if (length(d) ~= 2 | max(d) ~= 1 | n < 1 | n > 16 | junk > 1E-6)
   error('nbits must be a [1 x 1] integer 1 <= nbits <= 16array')
end
%
d = size(int);
m = d(1);
k = d(2);
intx = round( int );
junk = abs(int - intx);
if (length(d) ~= 2 | m < 1 | k ~= 1 | min(intx) < 0 | max(intx) > maxint ...
   | min(junk) > 1E-3)
   error('int must be a [m x 1] array of positive integers')
end


% Declare work arrays
bitwork = zeros(m, 16);
intwork = intx;


% Loop over the bits
for ib = 16:-1:1
   i1 = find( intwork >= powers(ib) );
   if (length(i1) > 0)
      bitwork(i1,ib) = 1;
      intwork(i1) = round( intwork(i1) - powers(ib) );
   end
end


% Assign output
bitarray = bitwork(:,1:nbits);

%%% end of function %%%
