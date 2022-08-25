function [outputImage,affineMatrix] = affine_from_values(inputImage, ...
    translationX, translationY, rotation,Sx,Sy,Shx,Shy)
%% function affine_from_values
% Inputs:
% - a 2D image
% - the coeficients for the affine matrix
% Note rotation is in radians
% Return a transformed image and the affine matrix.

x = size(inputImage,1)/2;
y = size(inputImage,2)/2;
 
% Rotation about the conventional direction
rotation = -rotation;
% Scaling in the intuitive sense
Sx = 1/Sx;
Sy = 1/Sy;

% translation from origin to point (x,y)     
P1 = [1, 0, -x; ...
      0, 1, -y; ...
      0, 0, 1];         
% translation back to the origin from point (x,y)
P2 = [1, 0, x; ...
      0, 1, y; ...
      0, 0, 1];
    
% final translation of the image  
% T = [1, 0, translationY; ...
%      0, 1, -translationX; ...
%      0, 0, 1];
T = [0, 0, translationX; ...
     0, 0, -translationY; ...
     0, 0, 0];
 
% rotation matrix 
R = [cos(rotation), -sin(rotation), 0; ...
     sin(rotation), cos(rotation), 0; ...
     0, 0, 1];
 
% scalling matrix 
Sc = [Sy, 0, 0; ...
      0, Sx, 0; ...
      0, 0, 1];
  
% shearing matrix  
Sh = [1, Shx, 0; ...
      -Shy, 1, 0; ...
      0, 0, 1];
  
% Final affinity transmutation matrix magic thingie. Every operation is performed about the center of the image.  
affineMatrix = (P2*Sh*Sc*R*P1) + T;
             
outputImage = apply_DF_lin_interp(inputImage, ...
    getDeformationFieldFromAffine(inputImage, affineMatrix));

% outputImage = splineinterp(inputImage, ...
%    getDeformationFieldFromAffine(inputImage, affineMatrix));

end
