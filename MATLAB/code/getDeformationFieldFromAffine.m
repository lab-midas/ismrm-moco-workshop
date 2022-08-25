function def=getDeformationFieldFromAffine(img,affine)

%% Generate a deformation field using an affine transformation
% Grids that contain the pixel position are created
[gridY gridX]=meshgrid(1:size(img,2),1:size(img,1));
% We create a vector that contains [x y 1]
positions=[gridX(:)';gridY(:)'; ones(numel(img),1)'];
% and apply the transformation to it
def=affine * positions;
% We then reshape the updated position into a deformation field
def=reshape(def(1:2,:)', [size(img,1) size(img,2) 2]);
def = double(def);

end