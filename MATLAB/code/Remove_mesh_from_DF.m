function [DF_meshless] = Remove_mesh_from_DF(DF)
% DFs by default have point coordinates imbue in them. This function
% removes them


if ndims(DF) == 5

    [ymax,xmax,zmax,~,nb] = size(DF);
    [gridX,gridY,gridZ]=meshgrid(1:xmax,1:ymax,1:zmax);
    DF_meshless = DF;
    if nb> 1
        for b = 1:nb
            DF_meshless(:,:,:,1,b) = DF(:,:,:,1,b) - gridY;
            DF_meshless(:,:,:,2,b) = DF(:,:,:,2,b) - gridX;
            DF_meshless(:,:,:,3,b) = DF(:,:,:,3,b) - gridZ;
        end

    else
            DF_meshless(:,:,:,1) = DF(:,:,:,1) - gridY;
            DF_meshless(:,:,:,2) = DF(:,:,:,2) - gridX;
            DF_meshless(:,:,:,3) = DF(:,:,:,3) - gridZ;
    end
    
elseif ndims(DF) == 4
    
    [ymax,xmax,~,nb] = size(DF);
    [gridX,gridY]=meshgrid(1:xmax,1:ymax);
    DF_meshless = DF;
    if nb> 1
        for b = 1:nb
            DF_meshless(:,:,1,b) = DF(:,:,1,b) - gridY;
            DF_meshless(:,:,2,b) = DF(:,:,2,b) - gridX;
        end

    else
            DF_meshless(:,:,1) = DF(:,:,1) - gridY;
            DF_meshless(:,:,2) = DF(:,:,2) - gridX;
    end

end