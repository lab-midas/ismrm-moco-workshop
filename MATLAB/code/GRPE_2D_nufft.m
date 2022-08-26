function [b_total_coils] = GRPE_2D_nufft(b_bin,kpos,mask,dcf,siz,Ksiz,csm,ncoils,adjoint,dcf_both_ways)

precision = 1E-4; % NUFFT precision
% precision = 'double';


if nargin < 10
    dcf_both_ways = 1;
end

if max(abs(kpos(:))) > 0.5
    kpos(:,1) = Normalize(kpos(:,1),-0.5,0.5);
    kpos(:,2) = Normalize(kpos(:,2),-0.5,0.5);
end

if adjoint

    b_total_coils = zeros(siz(1),siz(2),ncoils);

    parfor coil = 1:ncoils % size(b,5) == nc; number of coils
            b_bin_coil = b_bin(:,:,coil); % data from bin and coil
            
            if dcf_both_ways
                b_bin_coil = b_bin_coil(:,mask).*sqrt(dcf); % shots and DCF
            else
                b_bin_coil = b_bin_coil(:,mask).*dcf; % shots and DCF
            end
                
            %b_k2im = nufft3_type1(double(a.kpos{bin}), double(b_bin_coil(:)), a.siz, +1,precision); % NUFFT
            b_k2im = nufft2_type1(double(kpos), double(b_bin_coil(:)), siz, +1, precision); % 2D_NUFFT
            b_k2im = reshape(b_k2im,[siz(1) siz(2)]); % reshape
            
            b_total_coils(:,:,coil) = b_k2im.*conj(csm(:,:,coil)); % summing coil weighted in image domain
    end

else
    
    b_total_coils = zeros(Ksiz(1),Ksiz(2),ncoils);
    
        parfor coil = 1:ncoils % size(b,5) == nc; number of coils
            
            % Quick fix for the regrid_kdata function
            if ndims(b_bin)==2
                b_bin_coil = b_bin.*csm(:,:,coil); % coil weight
            elseif ndims(b_bin)==3
                b_bin_coil = b_bin(:,:,coil).*csm(:,:,coil); % coil weight
            end

            b_im2k = nufft2_type2(double(kpos), double(b_bin_coil), -1, precision); % 2D_NUFFT

            b_im2k = reshape(b_im2k,[Ksiz(1) numel(mask)]); % reshape

            if dcf_both_ways
                b_total_coils(:,mask,coil) = b_im2k.*sqrt(dcf);
            else
                b_total_coils(:,mask,coil) = b_im2k;
            end
            
        end
end



