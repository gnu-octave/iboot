% Function file for generating bootstrap sample indices
%
% USAGE
% BOOTSAM = boot (N, NBOOT)
% BOOTSAM = boot (X, NBOOT)
% BOOTSAM = boot (N, NBOOT, UNBIASED)
% BOOTSAM = boot (N, NBOOT, UNBIASED, WEIGHTS)
% BOOTSAM = boot (N, NBOOT, UNBIASED, WEIGHTS, SEED)
%
% INPUT VARIABLES
% N (double) is the number of rows (of the data vector)
% X (double) is a data vector intended for resampling
% NBOOT (double) is the number of bootstrap resamples
% UNBIASED (boolean): false (for bootstrap) or true (for bootknife)
% WEIGHTS (double) is a weight vector of length n. 
% SEED (double) is a seed for the pseudo-random number generator. 
%
% OUTPUT VARIABLE
% bootsam (double) is an n x nboot matrix of resampled data or indices
%
% NOTES
% Uniform random numbers are generated by the Mersenne Twister 19937 generator.
% UNBIASED is an optional input argument. The default is false. If UNBIASED is 
% true then the sample index for omission in each bootknife resample is selected
% systematically. If the remaining number of bootknife resamples is not 
% divisible by the sample size (N), then the sample index omitted is selected
% randomly. 
% WEIGHTS is an optional input argument. If WEIGHTS is empty or not provided,
% the default is a vector of each element equal to nboot (i.e. uniform weighting). 
% Each element of WEIGHTS is the number of times that the corresponding index is
% represented in BOOTSAM. For example, if the second element is 500, then the
% value 2 will be assigned to 500 elements within BOOTSAM. Therefore, the sum of
% WEIGHTS should equal N * NBOOT.
% Note that the mex function compiled from this source code is not thread 
% safe. Below is an example of a line of code one can run in Octave/Matlab 
% before attempting parallel operation of boot.mex in order to ensure that 
% the initial random seeds of each thread are unique:
%
% In Octave:
% >> pararrayfun(nproc, @boot, 1, 1, false, [], 1:nproc)
% In Matlab:
% >> ncpus = feature('numcores'); parfor i = 1:ncpus; boot (1, 1, false, [], i); end;
%
% Author: Andrew Charles Penn (2022)
%

function bootsam = boot (x, nboot, u, w, s)

  % Input variables
  n = numel(x);
  if (n > 1)
    sz = size(x);
    isvec = true;
    if all(sz > 1)
      error('the first input argument must be a scalar or a vector');
    end
  else
    n = x;
    isvec = false;
    if ( (n <= 0) || (n ~= fix(n)) || isinf(n) || isnan(n) )
      error ('the first input argument must be a finite positive integer')
    end
  end
  if (nboot <= 0) || (nboot ~= fix(nboot)) || isinf(nboot) || isnan(nboot) || (max (size (nboot)) > 1)
    error ('the second input argument (nboot) must be a finite positive integer')
  end
  if (nargin < 3)
    u = 0;
  else
    if ~islogical (u)
      error ('the third input argument (u) must be a logical scalar value')
    end
  end
  if (nargin > 4)
    if (isinf(s) || isnan(s) || (max (size (s)) > 1))
      error ('the fifth input argument (s) must be a finite scalar value')
    end
    rand ('twister', s);
  end

  % Preallocate bootsam
  bootsam = zeros (n, nboot);

  % Initialize weight vector defining the available row counts remaining
  if (nargin > 3) && ~isempty(w)
    % Assign user defined weights (counts)
    % Error checking
    if (numel(w) ~= n)
      error('weights must be a vector of length n');
    end
    if (sum(w) ~= n * nboot)
      error('weights must add up to n * nboot')
    end
    c = w;
  else
    % Assign weights (counts) for uniform sampling
    c = ones (n, 1) * nboot; 
  end

  % Perform balanced sampling
  r = 0;
  for b = 1:nboot
    R = rand (n, 1);
    if (u)
      % Choose which row of the data to exclude for this bootknife sample
      if (fix ((b - 1) / n) == fix (nboot / n))
        r = 1 + fix (rand (1) * n);     % random
      else
        r = b - fix ((b - 1) / n) * n;  % systematic
      end
    end
    for i = 1:n
      d = c;  
      if (u)
        d(r) = 0;
      end
      if ~sum (d)
        d = c;
      end
      d = cumsum (d);
      j = sum (R(i) >= d ./ d(end)) + 1;
      if (isvec) 
        bootsam (i, b) = x(j);
      else
        bootsam (i, b) = j;
      end
      c(j) = c(j) - 1; 
    end
  end


%!demo
%!
%! % N as input; balanced resampling with replacement
%! boot(3,20,false)

%!demo
%!
%! % N as input; balanced bootknife resampling with replacement
%! boot(3,20,true)

%!demo
%! % Vector (X) as input;balanced resampling with replacement; setting weights
%! x = [23; 44; 36];
%! boot(x,10,false)            % equal weighting
%! boot(x,10,false,[20;0;10])  % unequal weighting, no x(2) in BOOTSAM 

%!demo
%! 
%! % N as input; balanced resampling with replacement; setting the random seed
%! boot(3,20,false,[],1) % Set random seed
%! boot(3,20,false,[],1) % Reset random seed, BOOTSAM is the same (if running on the same core)
%! boot(3,20,false,[])   % Without setting random seed, BOOTSAM is different

