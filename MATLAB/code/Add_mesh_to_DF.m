function [DF_meshless] = Add_mesh_to_DF(DF,type)
% DFs by default have point coordinates imbue in them. This function
% removes them

if type == 3 % 3D motion field

    [ymax,xmax,zmax,~,nb] = size(DF);
    [gridX,gridY,gridZ]=meshgrid(1:ymax,1:xmax,1:zmax);
    DF_meshless = DF;
    for b = 1:nb
        DF_meshless(:,:,:,1,b) = DF(:,:,:,1,b) + gridY;
        DF_meshless(:,:,:,2,b) = DF(:,:,:,2,b) + gridX;
        DF_meshless(:,:,:,3,b) = DF(:,:,:,3,b) + gridZ;
    end
    
elseif type == 2 % 2D motion field
    [ymax,xmax,~,nb] = size(DF);
    [gridX,gridY]=meshgrid(1:ymax,1:xmax);
    DF_meshless = DF;
    for b = 1:nb
        DF_meshless(:,:,1,b) = DF(:,:,1,b) + gridY;
        DF_meshless(:,:,2,b) = DF(:,:,2,b) + gridX;
    end
     
end

