function CINE = cine_SENSE_recon(kIN,kpp,csm,cbins)

% kIN = [nFE,nPE,nC] matrix of the k-space data
% kpp = [nFE,nPE,1,3] matrix of 3D k-space positions (only 2D needed here)

    [siz(1), siz(2), Nc] = size(csm);
    Nphases = numel(cbins);
    CINE = zeros(siz(1),siz(2),Nphases);

    b_kpos = cell(1,Nphases);
    b_dcf = cell(1,Nphases);

    % = 0 -> fast (approximate) analytic dcf
    % = 1 -> slower (generally more accurate) voronoi dcf
    quick_dcf = 0;

    % Recon
    for bbb = 1:Nphases
        b_Nt = numel(cbins{bbb});

        b_kIN = squeeze(kIN(:,cbins{bbb},:,:));
        b_Ksiz = [size(b_kIN,1) size(b_kIN,2)];

        b_kp = double(squeeze(kpp(:,cbins{bbb},:,1:2)));
        b_kpos{bbb} = reshape(b_kp,[size(b_kp,1)*size(b_kp,2) size(b_kp,3)]);

        if quick_dcf
            %quick dcf
            b_dcf_aux = 2*pi/size(b_kp,2) * abs(squeeze(b_kp(:,1,2))) *  (1/Ksiz(1))^2;
            b_dcf_aux = repmat(b_dcf_aux(:),[1 size(b_kp,2)]);
            b_dcf{bbb} = b_dcf_aux;
            else
            b_dcf_aux = voronoi_dcf_2D(reshape(b_kp,[size(b_kp,1) size(b_kp,2) 1 2]));
            % edge dcf can have errors
            b_dcf_aux(1,:) = b_dcf_aux(2,:); b_dcf_aux(end,:) = b_dcf_aux(end-1,:);
            % Get kcentre pos
            [~,kc] = min(abs(b_kp(:,:,2))); kc = kc(1);
            % Central dcf can have errors too
            b_dcf_aux(kc,:) = b_dcf_aux(kc+1,:); b_dcf_aux(kc,:) = min(b_dcf_aux(kc,:));
            b_dcf{bbb} = b_dcf_aux;
        end


        maskb{1} = 1:b_Nt;

        % Pre-weight by sqrt of dcf. 
        b_kIN = b_kIN .* sqrt(repmat(single(b_dcf_aux),[1 1 Nc]));

        nbins = 1; % can recon multiple bins simutaneously if needed
        E = itSENSE_FessNuFFT(maskb,csm,b_kpos(bbb),b_dcf(bbb),b_Ksiz,nbins);
        CG_its = 5; res_limit = 1E-4;
        
        [recon_its,residuals] = Conjugate_Gradient(permute(b_kIN,[1 2 4 3]),E,CG_its,res_limit);
%         [nav_it,residuals] = itSENSE(permute(b_kIN,[1 2 4 3]),E,maxit,min_residual,verbose);

        clear cphase
        % Chose iteration
        it = find(residuals<res_limit);
        if ~isempty(it)
            cphase = recon_its(:,:,it(1));
        else
            [~,it] = min(residuals(:));
            cphase(:,:,:) = recon_its(:,:,it);
        end

        
        CINE(:,:,bbb) = cphase;
    end

end

