function res = mtimes(a,b)

% a = encoding operator, 
% b = full_k_data -> (Ny,Nx,Nc) when applying EH
% b = full_image_data -> (Ny,Nx) when applying E

mask = a.mask;
dcf = a.dcf;
kpos = a.kpos;
csm = a.b1;
siz = a.siz;
ncoils = a.ncoils;
adjoint = a.adjoint;
mdir = a.mdir;

if a.adjoint % EH operation

    res = zeros(a.siz(1),a.siz(2)); % result of the EH*b operation
    
    Nms = numel(a.Mf);
    
    for mc = 1:Nms % for each motion state

        % Sampling k-space at this motion state
        b_mc = b(:,mask{mc},:);

        [b_total_coils] = GRPE_2D_nufft(b_mc,kpos{mc},1:numel(mask{mc}),dcf{mc},siz,size(dcf{mc}),csm,ncoils,adjoint);

        b_total_coils = sum(b_total_coils,3) ./ a.coil_rss;
        b_total_coils(a.coil_rss==0) = 0;
        b_total_coils(isnan(b_total_coils)) = 0;

        % Apply motion 
        if mdir == 1
            bs = matrix_interpolation(b_total_coils,a.Mf{mc}');
            % Normalize due to discrete interpolants
            motion_norm = matrix_interpolation(ones(size(bs)),a.Mf{mc}');
            bs = bs./motion_norm;
            bs(isnan(bs)) = 0; bs(isinf(bs)) = 0;
        elseif mdir == 2
            bs = matrix_interpolation(b_total_coils,a.Mf{mc}');
        end

    res = res + bs;
        
    end
    
else % E operation
    res = zeros(a.Ksiz(1),a.Ksiz(2),a.ncoils);
    Nms = numel(a.Mf);
    
    for mc = 1:Nms

        % Apply motion 
        if mdir == 1
            b_mc = matrix_interpolation(b,a.Mf{mc});
        elseif mdir == 2
            b_mc = matrix_interpolation(b,a.Mf{mc}');
            % Normalize due to discrete interpolation
            motion_norm = matrix_interpolation(ones(size(b)),a.Mf{mc}');
            b_mc = b_mc./motion_norm;
            b_mc(isnan(b_mc)) = 0; b_mc(isinf(b_mc)) = 0;
        end

        % Applying intensity correction
        b_mc = b_mc ./ a.coil_rss;
        b_mc(a.coil_rss==0) = 0;
        b_mc(isnan(b_mc)) = 0;             

        % Fourier transform
        [b_total_coils] = GRPE_2D_nufft(b_mc,kpos{mc},1:numel(mask{mc}),dcf{mc},siz,size(dcf{mc}),csm,ncoils,adjoint);

        % Store kspace in corresponding indexes
        res(:,mask{mc},:) = b_total_coils;
    end    
end