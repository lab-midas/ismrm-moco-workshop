function [new,intrpMat]=spline_mat_interp(a,dof,use_intrpMat)
%splineinterp performs cubic spline interpolation on image "a" using
%deformation field "dof". 
%the 3rd argument (use_intrpMat) determines if a N^2xN^2 interpolation
%matrix will be created. This matrix holds information about the dof and
%interpolation type. The actual interpolation may be done later on simply
%by matrix multiplication. see matrix_interpolation.m

% Default
if nargin <= 2
    use_intrpMat = 0;
end

% Number of dimensions of the image
ndims = numel(size(a));

if ndims == 2
% Initializing a couple of useful grids and the output image.
[ymax,xmax] = size(a);
X=dof(:,:,1);Y=dof(:,:,2);
I=floor(X)-1;U=X-floor(X);
J=floor(Y)-1;V=Y-floor(Y);
new=zeros(ymax,xmax);
top=numel(a);

if use_intrpMat
    % W holds the 16 coefficients for each point
    W = zeros(ymax,xmax,16);
    % P holds the 16 interpolation locations for each point
    P = zeros(ymax,xmax,16);
end

% Create the image
for l=0:3 % Iterating horizontal neighbours
    for m=0:3 % Iterating vertical neighbours
        p=I+l+size(a,1)*(J-1+m);
        Bx = B(l,U); Bx((I+l)<1)=0; Bx((I+l)>ymax)=0; % Cubic splines
        By = B(m,V); By((J+m)<1)=0; By((J+m)>xmax)=0; % Cubic splines
        % Doesn't matter where I redirected the points that leave the FOV, as long as I null them.
        p(p<1)=1;p(p>top)=top; 
        new=new+Bx.*By.*a(p);
        if use_intrpMat
            W(:,:,(m+1)+4*(l+1-1)) = Bx.*By;
            P(:,:,(m+1)+4*(l+1-1)) = p;
        end
    end
end

if use_intrpMat
    % Creating Y indexes (Ys)
    Ys = 16*ones(1,ymax*xmax);
    sum = cumsum(Ys);
    Ys  = zeros(1, sum(end));
    Ys(sum(1:end-1)+1) = 1;
    Ys(1)= 1;
    Ys  = cumsum(Ys);
    % Creating X indexes (Xs)
    Xs = permute(P,[3 1 2]);
    Xs = Xs(:);
    % Vectorizing the weights 
    Vs = permute(W,[3 1 2]);
    Vs = Vs(:);   
    % Summons the interpolation matrix.
    intrpMat = sparse(Ys,Xs,Vs,ymax*xmax,ymax*xmax);
else
    intrpMat = -1;
end

elseif ndims == 3
disp('You are running cubic splines for 3D and are likely to run out of memory. Do yourself a favor and Ctrl-C.');
dof = single(dof);
% Initializing a couple of useful grids and the output image.
[ymax,xmax,zmax] = size(a);
X=dof(:,:,:,1);Y=dof(:,:,:,2);Z=dof(:,:,:,3);
I=floor(X)-1;U=X-floor(X);
J=floor(Y)-1;V=Y-floor(Y);
K=floor(Z)-1;T=Z-floor(Z);
new=zeros(ymax,xmax,zmax);
top=numel(a);    
    
if use_intrpMat
    % W holds the 64 coefficients for each point
    W = single(zeros(ymax,xmax,zmax,64));
    % P holds the 64 interpolation locations for each point
    P = single(zeros(ymax,xmax,zmax,64));
end    

% Create the image
for l=0:3 % Iterating horizontal neighbours
%     if l==1;disp('This is bold. You will crash and burn.');end;
    for m=0:3 % Iterating vertical neighbours
%         if m==3;disp('Well... no turning back now.');end;
        for n=0:3 % Iterating depth (z) neighbours
            p=I+l+ymax*(J-1+m)+ymax*xmax*(K-1+n);
            Bx = B(l,U); Bx((I+l)<1)=0; Bx((I+l)>ymax)=0; % Cubic splines
            By = B(m,V); By((J+m)<1)=0; By((J+m)>xmax)=0; % Cubic splines
            Bz = B(n,T); Bz((K+n)<1)=0; Bz((K+n)>zmax)=0; % Cubic splines
            % Doesn't matter where I redirected the points that leave the FOV, as long as I null them.
            p(p<1)=1;p(p>top)=top; 
            new=new+Bx.*By.*Bz.*a(p);
            if use_intrpMat
                W(:,:,:,(n+1)+4*(m+1-1)+16*(l+1-1)) = single(Bx.*By.*Bz);
                P(:,:,:,(n+1)+4*(m+1-1)+16*(l+1-1)) = single(p);
            end
        end
    end
end    

% Need to free up some space
clear I J K U V T X Y Z Bx By Bz ndims a l m n top dof; 

if use_intrpMat
    % Creating Y indexes (Ys)
    Ys = 64*ones(1,ymax*xmax*zmax);
    sum = cumsum(Ys);
    Ys  = zeros(1, sum(end));
    Ys(sum(1:end-1)+1) = 1;
    Ys(1)= 1;
    Ys  = double(cumsum(Ys));
    % Creating X indexes (Xs)
    Xs = permute(P,[4 1 2 3]);
    Xs = double(Xs(:));
    % Vectorizing the weights 
    Vs = permute(W,[4 1 2 3]);
    Vs = double(Vs(:));   
    % Summons the interpolation matrix.
    intrpMat = sparse(Ys,Xs,Vs,ymax*xmax*zmax,ymax*xmax*zmax);
else
    intrpMat = -1;
end    
disp('Hm... you actually made it through. Good for you.');    
end

end

% --- Cubic spline interpolants ---
function y=B(a,u)
if(a==0);y=(u.*((2-u).*u-1))/2;end
if(a==1);y=(u.^2.*(3*u-5)+2)/2;end
if(a==2);y=(u.*((4-3*u).*u+1))/2;end
if(a==3);y=((u-1).*u.^2)/2;end

% y = y/sum(y(:)); % test
end

% These are interpolants for cubic B-splines to smooth out deformation
% fields.
% function w = B(l,u) 
%     if l == 0
%         w = (1-u).^3/6;
%     elseif l == 1
%         w = (3*u.^3-6*u.^2+4)/6;
%     elseif l == 2
%         w = (-3*u.^3+3*u.^2+3*u+1)/6;
%     elseif l == 3
%         w = u.^3/6;
%     end
% end
