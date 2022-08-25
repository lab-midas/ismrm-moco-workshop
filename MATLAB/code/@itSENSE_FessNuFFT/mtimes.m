function [res,res_rss] = mtimes(a,b)
% precision = 1E-2; % NUFFT precision
% a = encoding operator, 
% b = full_k_data -> (Ny,Nx,Nt,Nc) when applying EH
% b = full_image_data -> (Ny,Nx,Nt) when applying E

if a.adjoint % EH operation

    res = zeros(a.siz(1),a.siz(2),a.nbins); % result of the EH*b operation
    for bin = 1:a.nbins % iterating thru bins
%         b_total_coils = zeros(a.siz(1),a.siz(2),a.ncoils); % init
        b_bin = squeeze(b(:,:,bin,:));
        mask = a.mask{bin};
        dcf = a.dcf{bin};
        kpos = a.kpos{bin};
        csm = a.b1;
        siz = a.siz;
        ncoils = a.ncoils;
        adjoint = a.adjoint;
        Ksiz = a.Ksiz;
        
%         [b_total_coils] = GRPE_2D_nufft(b_bin,kpos,mask,dcf,siz,Ksiz,csm,ncoils,adjoint);
        FT = NUFFT(kpos(:,1) + 1i*kpos(:,2), 1, 1, 0, [size(csm,1) size(csm,2)], 2);
        [b_total_coils] = nufft_sense(b_bin,kpos,mask,dcf,siz,size(dcf),csm,ncoils,adjoint,1,FT);


        % Applying intensity correction
        b_total_coils_rss = sqrt(sum(b_total_coils.*conj(b_total_coils),3)) ./ a.coil_rss;
        b_total_coils_rss(a.coil_rss==0) = 0;
        b_total_coils_rss(isnan(b_total_coils_rss)) = 0;

        
        b_total_coils = sum(b_total_coils,3) ./ a.coil_rss;
        b_total_coils(a.coil_rss==0) = 0;
        b_total_coils(isnan(b_total_coils)) = 0;
        res(:,:,bin) = b_total_coils; % storing bins in a single matrix
    end  
    

else % E operation
    res = zeros(a.Ksiz(1),a.Ksiz(2),a.nbins,a.ncoils);
    
    for bin = 1:a.nbins % iterating thru bins
        
        mask = a.mask{bin};
        dcf = a.dcf{bin};
        kpos = a.kpos{bin};
        csm = a.b1;
        siz = a.siz;
        ncoils = a.ncoils;
        adjoint = a.adjoint;
        Ksiz = a.Ksiz;
        
        % Applying intensity correction
        b_bin = b(:,:,bin) ./ a.coil_rss;
        b_bin(a.coil_rss==0) = 0;
        b_bin(isnan(b_bin)) = 0; 
        
%         [b_total_coils] = GRPE_2D_nufft(b_bin,kpos,mask,dcf,siz,Ksiz,csm,ncoils,adjoint);
        FT = NUFFT(kpos(:,1) + 1i*kpos(:,2), 1, 1, 0, [size(csm,1) size(csm,2)], 2);
        [b_total_coils] = nufft_sense(b_bin,kpos,mask,dcf,siz,size(dcf),csm,ncoils,adjoint,1,FT);


        res(:,mask,bin,:) = permute(b_total_coils(:,mask,:),[1 2 4 3]);
    end
           
    res_rss = 0; % for compleness
    

end