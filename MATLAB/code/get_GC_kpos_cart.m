function [kpos_GC] = get_GC_kpos_cart(n_FE,n_spokes,RadProfOrder)

% randomized partial fourier trajectory except every readout also samples
% the central line
if strcmpi(RadProfOrder, 'Cart')
    delta_kr = 1/(n_FE);
    central_kaux = -0.5:delta_kr:0.5-delta_kr;
%     pe_rdn = randi(n_spokes,1,n_spokes);
    pe_pos = linspace(-0.5,0.05,n_spokes);
    
    for qqq = 1:n_spokes
%         clear kaux1
%         kaux1(:,2) = zeros(numel(central_kaux),1);
%         kaux1(:,1) = central_kaux;
%         kaux2(:,2) = repmat(pe_pos(pe_rdn(qqq)),[numel(central_kaux),1]);
%         kaux2(:,1) = central_kaux;
        
        kt(:,1) = central_kaux;
        kt(:,2) = repmat(pe_pos(qqq),[numel(central_kaux),1]);
        
%         kt = cat(1,kaux1,kaux2);
        
        kpos_GC(:,qqq,1,1:2) = permute(kt,[1 4 3 2]);
    end
end

