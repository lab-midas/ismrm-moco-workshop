function [MC,recon_its] = cine_motion_correction(kIN,kpp,dcf_aux,csm,cbins,ref_bin,Motion_fields)

% kIN = [nFE,nPE,nC] matrix of the k-space data
% kpp = [nFE,nPE,1,3] matrix of 3D k-space positions (only 2D needed here)

    kpp = squeeze(kpp(:,:,:,1:2));
    [siz(1), siz(2), Nc] = size(csm);
    Nphases = numel(cbins);
 
    disp('Preparing recon params...');
    % Prepare the sampling, trajectory, dcf and motion field for each state
    for bbb = 1:Nphases
        shots = cbins{bbb};
        [iM] = get_sparse_mot(csm(:,:,1),Motion_fields{ref_bin}(:,:,:,bbb));
        Mf{bbb} = iM;
        mask_E{bbb} = shots;
        dcf_E{bbb} = dcf_aux(:,shots);
        kp_aux = kpp(:,shots,:);
        kp_E{bbb} = reshape(kp_aux,[size(kp_aux,1)*size(kp_aux,2) 2]);
    end
    
    % pre-weighting each (motion) data subset by sqrt(dcf) before recon
    b_kIN = kIN(:,mask_E{1},:) .* sqrt(repmat(single(dcf_E{1}),[1 1 Nc]));
    mask_E2{1} = 1:numel(mask_E{1});
    for qqq = 2:Nphases
        aux = kIN(:,mask_E{qqq},:) .* sqrt(repmat(single(dcf_E{qqq}),[1 1 Nc]));
        mask_E2{qqq} = size(b_kIN,2)+1:size(b_kIN,2)+numel(mask_E{qqq});
        b_kIN = cat(2,b_kIN,aux);
    end
    
    % create recon operator and run CG
    Ksiz = [size(b_kIN,1) size(b_kIN,2)];
    MC_E = Batch_recon_FessNuFFT(mask_E2,csm,kp_E,dcf_E,Mf,Ksiz,2);  
    CG_its = 5; res_limit = 1E-4;
    [recon_its,residuals] = Conjugate_Gradient(permute(b_kIN,[1 2 4 3]),MC_E,CG_its,res_limit);

    clear cphase
    % Chose iteration
    it = find(residuals<res_limit);
    if ~isempty(it)
        MC = recon_its(:,:,it(1));
    else
        [~,it] = min(residuals(:));
        MC(:,:,:) = recon_its(:,:,it);
    end
end
    
    
    
    
