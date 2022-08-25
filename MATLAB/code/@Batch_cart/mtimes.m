function [res] = mtimes(a,b)

% a = encoding operator, 
% b = full_k_data : (Ny,Nx,Nc) -> (Ny,Nx) when applying EH
% b = full_image_data : (Ny,Nx) -> (Ny,Nx,Nc) when applying E

if a.adjoint % EH operation
    res = zeros(a.siz(1),a.siz(2)); % result of the EH*b operation
    %res_with_coils = zeros(a.siz(1),a.siz(2),a.ncoils);
    coil_rss = a.coil_rss; 
    for bin = 1:a.nbins % iterating thru bins
        res_coils = zeros(a.siz(1),a.siz(2),a.ncoils); % init
        Bin_At = double(a.At{bin});
        coils = a.coils;
        current_mf = a.motion_fields;
        
        parfor coil = 1:a.ncoils % number of coils
            % Sampling -> FFT -> Coil
            res_coils(:,:,coil) = K2Image(b(:,:,coil).*Bin_At).*conj(coils(:,:,coil)); 
        end
        
        % Coil intensity normalization
        res_bin = sum(res_coils,3)./coil_rss;
        res_bin(coil_rss==0) = 0;
        res_bin(isnan(res_bin)) = 0;
        
        % Apply motion
        res_bin = matrix_interpolation(res_bin,current_mf{bin}');
        % Correct for discrete interpolation
        motion_norm = matrix_interpolation(ones(size(res_bin)),current_mf{bin}');
        res_bin = res_bin./motion_norm;
        res_bin(isnan(res_bin)) = 0; res_bin(isinf(res_bin)) = 0;
            
        res = res + res_bin;

    end  
    
else % E operation
    res = zeros(a.siz(1),a.siz(2),a.ncoils);
    coil_rss = a.coil_rss;
    b_bin = b;
    
    for bin = 1:a.nbins % iterating thru bins
        
        % Apply motion (and coil normalization)
        current_mf = a.motion_fields;
        warped_b = matrix_interpolation(b_bin,current_mf{bin})./coil_rss;
        warped_b(coil_rss==0) = 0;
        warped_b(isnan(warped_b)) = 0;
        
        Bin_At = double(a.At{bin});
        coils = a.coils;
        for coil = 1:a.ncoils % number of coils
            res(:,:,coil) = Image2K(warped_b.*coils(:,:,coil)).*Bin_At + res(:,:,coil).*~Bin_At;
        end
        
    end

end
