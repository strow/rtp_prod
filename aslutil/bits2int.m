function [int] = bits2int( bitarray );

% function [int] = bits2int( bitarray );
%
% Convert a 1-D or 2-D array of up to 16 bit flags to an integer.
%
% Input:
%    bitarray = [m x nbits] array of bit flags {elements 0 or 1}
%               The number of bits nbits must be 1 <= nbits <= 16
%
% Output:
%    int      = [m x 1] integer representation of bit flags
%
% note: free replacement for the communications toolbox routine "bi2de"
%

% Created: 16 March 2005, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
d = size(bitarray);
m = d(1);
n = d(2);
if (length(d) ~= 2 | n < 1 | n > 16)
   error('bitarray must be a [m x n] array with 1<= n <= 16')
end
%
[i01] = ismember( bitarray, [0 1] );
if (min(min(i01)) ~= 1)
   error('All elements of bitarray must be 0 or 1')
end
ind = 1:n;


% powers of two = 2^(0 to 15)
powers=[1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768];

% Convert bit flag array into an integer
int = round( sum( ones(m,1)*powers(ind) .* bitarray, 2 ) );

%%% end of function %%%
