function [best_rho,residuals] = Conjugate_Gradient_reg_warm_start(m,E,x_prior,lambda,maxit,limit,x0)
%
% Uses conjugate gradient iteration to solve:
%   (E^H*E + R^H*R * lambda) rho = E^H*m + lambda*R
%
%  INPUT ARGUMENTS:
%   - m                 : measured data [k,coil]
%   - E                 : encoding operator
%   - x_prior           : regularization operator
%   - lambda            : regularization strenght
%   - maxit             : maximum number of iterations of CG
%   - limit             : residual limit
%   - x0                : initial guess for warm start
%
%  OUTPUT:
%   - rho               : reconstruction result


% Form right hand side:
fprintf('Forming right hand side...');

rhs = E'*m + lambda*x_prior;
siz = size(rhs);


% Calculate initial residuals
fprintf('Calculate initial residual...');
if nargin > 6
    rho = (E'*(E*x0)) + (lambda*x0);
    warm_start = 1;
else
    rho = zeros(siz);
    warm_start = 0;
end

rho = rho(:);
res = rho;

fprintf('...done\n');

% Iterations
%---------------
rhs = reshape(rhs, siz); 
res = reshape(res, siz); 
rho = reshape(rho, siz); 

r0 = rhs - res;
rr_0 = r0(:)'*r0(:);
rr = 0;

d1 = r0;
z1 = (E'*(E*d1)) + (lambda*d1);
c1 = (r0(:)'*r0(:)) / (d1(:)'*z1(:));

x1 = x0 + c1*d1;
r1 = r0 - c1*z1;


r_m1 = r1;
r_m2 = r0;
d = d1;
x = x1;

% Init some output variables
residuals = zeros(maxit,1);
if numel(siz) == 4 
    best_rho = single(zeros(siz(1),siz(2),siz(3),siz(4),maxit));
    best_rho(:,:,:,:,1) = single(x1);
elseif numel(siz) == 3
    best_rho = single(zeros(siz(1),siz(2),siz(3),maxit));
    best_rho(:,:,:,1) = single(x1);
else
    best_rho = single(zeros(siz(1),siz(2),maxit));
    best_rho(:,:,1) = single(x1);
end

it = 1;
rr = (r1(:)'*r1(:));
residuals(1) = rr/rr_0;
fprintf('Iteration %d, rho = %12.8e\n', it, residuals(it));drawnow;

it = 2;
% Run iteration

fprintf('Iterating...\n');
for it = 2:maxit
    
    d = r_m1 + ( (r_m1(:)'*r_m1(:))/((r_m2(:)'*r_m2(:))) * d );
    z = (E'*(E*d)) + (lambda*d);
    c = (r_m1(:)'*r_m1(:)) / (d(:)'*z(:));
    
    x = x + c*d;
    r = r_m1 - c*z;
    
    r_m2 = r_m1;
    r_m1 = r;
    
    rr = (r(:)'*r(:));
    
    if numel(siz) == 4 
        best_rho(:,:,:,:,it) = single(x);
        residuals(it) = rr/rr_0;
    elseif numel(siz) == 3
        best_rho(:,:,:,it) = single(x);
        residuals(it) = rr/rr_0;
    else
        best_rho(:,:,it) = single(x);
        residuals(it) = rr/rr_0;
    end
    
    fprintf('Iteration %d, rho = %12.8e\n', it, residuals(it));drawnow;
    
    if (rr/rr_0 < limit)
       break;
    end
    
end


fprintf('...done\n');