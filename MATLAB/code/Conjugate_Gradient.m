function [best_rho,residuals] = Conjugate_Gradient(m,E,maxit,limit)
%
% Uses conjugate gradient iteration to solve:
%   (E^H*E)rho = E^H*m
%
%  INPUT ARGUMENTS:
%   - m                 : measured data [k,coil]
%   - S                 : complex sensitivities [x,y,z,coil]
%   - weights           : density compensation
%   - maxit:            : maximum number of iterations of CG
%   - precision:        : precision of gridding
%
%  OUTPUT:
%   - rho               : reconstruction result

% Variable parameters:
% limit = 5e-9;

% Form right hand side:
fprintf('Forming right hand side...');

rhs = E'*m;
siz = size(rhs);

% Calculate initial residuals
fprintf('Calculate initial residual...');
rho = zeros(siz);

rho = rho(:);
res = rho;

fprintf('...done\n');

% Iterations
%---------------
rhs = reshape(rhs, siz); 
res = reshape(res, siz); 
rho = reshape(rho, siz); 
r = rhs - res;
rr_0 = r(:)'*r(:);
rr = 0;

if numel(siz) == 3
    best_rho = zeros(siz(1),siz(2),siz(3),maxit);
else
    best_rho = zeros(siz(1),siz(2),maxit);
end

residuals = zeros(maxit,1);
% Run iteration
fprintf('Iterating...\n');
for it = 1:maxit,
    rr_1 = rr;
    rr = r(:)'*r(:);
    if (it == 1),
        p = r;
    else        
        beta = rr/rr_1;
        p =  r + beta*p;    
    end
    
    q = E'*(E*p);
    
    % CG magnitude and direction
    q = reshape(q, siz);      
    alpha = rr/(p(:)'*q(:)); 
    rho = rho + alpha*p;
    rho1 = reshape(rho,siz);
    r = r - alpha*q;
 
    clear q;
    fprintf('Iteration %d, rho = %12.8e\n', it, rr/rr_0);drawnow;
    
    normalized_rho = rho1;
    
    if numel(siz) == 3
        best_rho(:,:,:,it) = normalized_rho;
        residuals(it) = rr/rr_0;
    else
        best_rho(:,:,it) = normalized_rho;
        residuals(it) = rr/rr_0;
    end
    
    if (rr/rr_0 < limit)
       break;
    end
    
end

fprintf('...done\n');

