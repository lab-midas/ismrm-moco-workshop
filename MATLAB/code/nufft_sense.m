function [b_total_coils] = nufft_sense(b_bin,kpos,mask,dcf,siz,Ksiz,csm,ncoils,adjoint,dcf_both_ways,FT)

precision = 1E-4; % NUFFT precision
% precision = 'double';

% FT = NUFFT(kpos(:,1) + 1i*kpos(:,2), 1, 1, 0, [siz(1),siz(2)], 2);

if nargin < 10
    dcf_both_ways = 1;
end

if adjoint

    b_total_coils = zeros(siz(1),siz(2),ncoils);

    % parfor turned off. can modify the operators to allow parfor
    for coil = 1:ncoils % size(b,5) == nc; number of coils
            b_bin_coil = b_bin(:,:,coil); % data from bin and coil
            
            if dcf_both_ways
                b_bin_coil = b_bin_coil(:,mask).*sqrt(dcf); % shots and DCF
            else
                b_bin_coil = b_bin_coil(:,mask).*dcf; % shots and DCF
            end
                
            %b_k2im = nufft3_type1(double(a.kpos{bin}), double(b_bin_coil(:)), a.siz, +1,precision); % NUFFT
%             b_k2im = nufft2_type1(double(kpos), double(b_bin_coil(:)), siz, +1, precision); % 2D_NUFFT
            b_k2im = FT'*double(b_bin_coil);
%             b_k2im = reshape(b_k2im,[siz(1) siz(2)]); % reshape
            
            
            b_total_coils(:,:,coil) = b_k2im.*conj(csm(:,:,coil)); % summing coil weighted in image domain
    end

%     res = b_total_coils;



else
    
    b_total_coils = zeros(Ksiz(1),Ksiz(2),ncoils);
    
        % parfor turned off. can modify the operators to allow parfor
        for coil = 1:ncoils % size(b,5) == nc; number of coils
            
            % Quick fix for the regrid_kdata function
            if ndims(b_bin)==2
                b_bin_coil = b_bin.*csm(:,:,coil); % coil weight
            elseif ndims(b_bin)==3
                b_bin_coil = b_bin(:,:,coil).*csm(:,:,coil); % coil weight
            end
                
            %b_im2k = nufft3_type2(double(a.kpos{bin}),double(b_bin_coil(:)),-1,precision); % NUFFT
%             b_im2k = nufft2_type2(double(kpos), double(b_bin_coil), -1, precision); % 2D_NUFFT
            b_im2k = FT*double(b_bin_coil);
            
            b_im2k = reshape(b_im2k,[Ksiz(1) Ksiz(2)]); % reshape
            
            
            if dcf_both_ways
                b_total_coils(:,:,coil) = b_im2k.*sqrt(dcf);
            else
                b_total_coils(:,:,coil) = b_im2k;
            end
        end
end


