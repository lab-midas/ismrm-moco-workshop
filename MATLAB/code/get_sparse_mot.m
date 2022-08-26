function [interpolationMatrix] = get_sparse_mot(old,deformationField)
%% Builds a N^2 by N^2 resampling matrix and the resampled image (new) as a
%% function of the derformationField and the interpolation scheme (bilinear
%% in this case).

% Number of dimensions of the image
ndims = numel(size(old));

if ndims == 2
[ymax,xmax] = size(old);

% floor and ceil value for each pixel are extracted
floorGridX=floor(deformationField(:,:,1));
floorGridY=floor(deformationField(:,:,2));
ceilGridX=ceil(deformationField(:,:,1));
ceilGridY=ceil(deformationField(:,:,2));

% We here compute the relative position of each pixel
wx=deformationField(:,:,1)-floorGridX;
wy=deformationField(:,:,2)-floorGridY;

% We compute the weight that will be applied to each intensity
w1=(1-wx).*(1-wy);
w2=wx.*(1-wy);
w3=(1-wx).*wy;
w4=wx.*wy;

% Killing off the coefficients of points that leave the FOV.
% This is just a safe-guard.
w1(floorGridX<1 | floorGridX>size(old,1)) = 0; w1(floorGridY<1 | floorGridY>size(old,2)) = 0;
w1(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w1(ceilGridY<1 | ceilGridY>size(old,2)) = 0;

w2(floorGridX<1 | floorGridX>size(old,1)) = 0; w2(floorGridY<1 | floorGridY>size(old,2)) = 0;
w2(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w2(ceilGridY<1 | ceilGridY>size(old,2)) = 0;

w3(floorGridX<1 | floorGridX>size(old,1)) = 0; w3(floorGridY<1 | floorGridY>size(old,2)) = 0;
w3(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w3(ceilGridY<1 | ceilGridY>size(old,2)) = 0;

w4(floorGridX<1 | floorGridX>size(old,1)) = 0; w4(floorGridY<1 | floorGridY>size(old,2)) = 0;
w4(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w4(ceilGridY<1 | ceilGridY>size(old,2)) = 0;

% Cheap boundary conditions were the intensity at the border is replicated
% However, because the weights above are being nulled, this will make the
% point disappear.
floorGridX(floorGridX<1)=1;
floorGridY(floorGridY<1)=1;
ceilGridX(ceilGridX<1)=1;
ceilGridY(ceilGridY<1)=1;
floorGridX(floorGridX>size(old,1))=xmax;
floorGridY(floorGridY>size(old,2))=ymax;
ceilGridX(ceilGridX>size(old,1))=xmax;
ceilGridY(ceilGridY>size(old,2))=ymax;

% We here compute the index in 1D of each pixel
P(:,:,1) = floorGridX+size(old,1)*(floorGridY-1);
P(:,:,2) = ceilGridX+size(old,1)*(floorGridY-1);
P(:,:,3) = floorGridX+size(old,1)*(ceilGridY-1);
P(:,:,4) = ceilGridX+size(old,1)*(ceilGridY-1);
% Storing weights in a double matrix
W(:,:,1) = w1;
W(:,:,2) = w2;
W(:,:,3) = w3;
W(:,:,4) = w4;

% Vectorizing Y indexes
Ys = 4*ones(1,ymax*xmax);
CS = cumsum(Ys);
Ys  = zeros(1, CS(end));
Ys(CS(1:end-1)+1) = 1;
Ys(1)= 1;
Ys  =  double(cumsum(Ys));
% Vectorizing X indexes
Xs = permute(P,[3 1 2]);
Xs = double(Xs(:));
% Vectorizing the weights 
Vs = permute(W,[3 1 2]);
Vs = double(Vs(:));
% Summons the interpolation matrix
interpolationMatrix = sparse(Ys,Xs,Vs,ymax*xmax,ymax*xmax);

% Using tighter precisions in 3D.
elseif ndims == 3
[ymax,xmax,zmax] = size(old);
deformationField = double(deformationField);    
% floor and ceil value for each pixel are extracted
floorGridX=double(floor(deformationField(:,:,:,1)));
floorGridY=double(floor(deformationField(:,:,:,2)));
floorGridZ=double(floor(deformationField(:,:,:,3)));
ceilGridX=double(ceil(deformationField(:,:,:,1)));
ceilGridY=double(ceil(deformationField(:,:,:,2)));
ceilGridZ=double(ceil(deformationField(:,:,:,3)));

% We here compute the relative position of each pixel
wx=deformationField(:,:,:,1)-floorGridX;
wy=deformationField(:,:,:,2)-floorGridY;
wz=deformationField(:,:,:,3)-floorGridZ;

% We compute the weight that will be applied to each intensity
w1=(1-wx).*(1-wy).*(1-wz);
w2=wx.*(1-wy).*(1-wz);
w3=(1-wx).*wy.*(1-wz);
w4=wx.*wy.*(1-wz);    
w5=(1-wx).*(1-wy).*wz;
w6=wx.*(1-wy).*wz;     
w7=(1-wx).*wy.*wz;    
w8=wx.*wy.*wz;    
    
% Killing off the coefficients of points that leave the FOV.
% This is just a safe-guard.
% Killing off the coefficients of points that leave the FOV.
w1(floorGridX<1 | floorGridX>size(old,1)) = 0; w1(floorGridY<1 | floorGridY>size(old,2)) = 0; w1(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w1(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w1(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w1(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;
w2(floorGridX<1 | floorGridX>size(old,1)) = 0; w2(floorGridY<1 | floorGridY>size(old,2)) = 0; w2(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w2(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w2(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w2(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;
w3(floorGridX<1 | floorGridX>size(old,1)) = 0; w3(floorGridY<1 | floorGridY>size(old,2)) = 0; w3(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w3(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w3(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w3(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;
w4(floorGridX<1 | floorGridX>size(old,1)) = 0; w4(floorGridY<1 | floorGridY>size(old,2)) = 0; w4(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w4(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w4(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w4(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;   
w5(floorGridX<1 | floorGridX>size(old,1)) = 0; w5(floorGridY<1 | floorGridY>size(old,2)) = 0; w5(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w5(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w5(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w5(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;
w6(floorGridX<1 | floorGridX>size(old,1)) = 0; w6(floorGridY<1 | floorGridY>size(old,2)) = 0; w6(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w6(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w6(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w6(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;
w7(floorGridX<1 | floorGridX>size(old,1)) = 0; w7(floorGridY<1 | floorGridY>size(old,2)) = 0; w7(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w7(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w7(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w7(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;
w8(floorGridX<1 | floorGridX>size(old,1)) = 0; w8(floorGridY<1 | floorGridY>size(old,2)) = 0; w8(floorGridZ<1 | floorGridZ>size(old,3)) = 0;
w8(ceilGridX<1 | ceilGridX>size(old,1)) = 0; w8(ceilGridY<1 | ceilGridY>size(old,2)) = 0; w8(ceilGridZ<1 | ceilGridZ>size(old,3)) = 0;       
    
% Current boundary condition is NaN. This means that points that leave the
% FOV disapear altogether.
floorGridX(floorGridX<1)=1;
floorGridY(floorGridY<1)=1;
floorGridZ(floorGridZ<1)=1;
ceilGridX(ceilGridX<1)=1;
ceilGridY(ceilGridY<1)=1;
ceilGridZ(ceilGridZ<1)=1;
floorGridX(floorGridX>size(old,1))=ymax;
floorGridY(floorGridY>size(old,2))=xmax;
floorGridZ(floorGridZ>size(old,3))=zmax;
ceilGridX(ceilGridX>size(old,1))=ymax;
ceilGridY(ceilGridY>size(old,2))=xmax;    
ceilGridZ(ceilGridZ>size(old,3))=zmax;    
    
P = double(zeros(ymax,xmax,zmax,8));
W = double(zeros(ymax,xmax,zmax,8));
% We here compute the index in 1D of each pixel
P(:,:,:,1) = floorGridX+ymax*(floorGridY-1)+ymax*xmax*(floorGridZ-1);
P(:,:,:,2) = ceilGridX+ymax*(floorGridY-1)+ymax*xmax*(floorGridZ-1);
P(:,:,:,3) = floorGridX+ymax*(ceilGridY-1)+ymax*xmax*(floorGridZ-1);
P(:,:,:,4) = ceilGridX+ymax*(ceilGridY-1)+ymax*xmax*(floorGridZ-1);
P(:,:,:,5) = floorGridX+ymax*(floorGridY-1)+ymax*xmax*(ceilGridZ-1);
P(:,:,:,6) = ceilGridX+ymax*(floorGridY-1)+ymax*xmax*(ceilGridZ-1);
P(:,:,:,7) = floorGridX+ymax*(ceilGridY-1)+ymax*xmax*(ceilGridZ-1);
P(:,:,:,8) = ceilGridX+ymax*(ceilGridY-1)+ymax*xmax*(ceilGridZ-1);

% Storing weights in a double matrix
W(:,:,:,1) = w1;
W(:,:,:,2) = w2;
W(:,:,:,3) = w3;
W(:,:,:,4) = w4;
W(:,:,:,5) = w5;
W(:,:,:,6) = w6;
W(:,:,:,7) = w7;
W(:,:,:,8) = w8;

% Vectorizing Y indexes
Ys = double(8*ones(ymax*xmax*zmax,1));
CS = cumsum(Ys);
Ys  = zeros(1, CS(end));
Ys(CS(1:end-1)+1) = 1;
Ys(1)= 1;
Ys  = cumsum(Ys);
% Vectorizing X indexes
Xs = permute(P,[4 1 2 3]);
Xs = double(Xs(:));
% Vectorizing the weights 
Vs = permute(W,[4 1 2 3]);
Vs = double(Vs(:));
% Summons the interpolation matrix
interpolationMatrix = sparse(Ys,Xs,Vs,ymax*xmax*zmax,ymax*xmax*zmax);

end

end

