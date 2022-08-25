function [kpos] = create_cart_kpos(n_FE,n_spokes,RadProfOrder)

% randomized partial fourier trajectory except every readout also samples
% the central line
if strcmpi(RadProfOrder, 'cart')
    delta_kr = 1/(n_FE);
    kaux = -0.5:delta_kr:0.5-delta_kr;
%     pe_rdn = randi(n_spokes,1,n_spokes);
    pe_pos = linspace(-0.5,0,n_spokes);
    
    for qqq = 1:n_spokes
        clear kaux1

        kaux1(:,1) = kaux;
        kaux1(:,2) = repmat(pe_pos(qqq),[1 numel(kaux)]);

        kpos(:,qqq,1,1) = kaux1(:,1);
        kpos(:,qqq,1,2) = kaux1(:,2);
    end

else 
    delta_kr = 1/(n_FE);
    rad_pos(:,1) = -0.5:delta_kr:0.5-delta_kr;
    % Angles of different radial spokes
    if strcmpi(RadProfOrder, 'GC') % golden angle
    %                 if isempty(RadialAngles)
            RadialAngles = (0:n_spokes-1)'*(pi/180)*(180*0.618034);
    %                 end
        isalternated = 0;

    elseif strcmpi(RadProfOrder, 'GC_23deg') %Andreia Gaspar 02/08/2016 tiny golden angle
    %                 if isempty(RadialAngles)
            RadialAngles = (0:n_spokes-1)'*(pi/180)*(180*0.1312674636);
    %                 end
        isalternated = 0;
    %                 isalternated = 1; % test
    else % linear order
    %                 if isempty(RadialAngles)
            RadialAngles = (0:n_spokes-1)'*(pi/n_spokes);
    %                 end

        % Flag indicating that each even radial line is
        % sampled from +k_max to -k_max and each odd line
        % is acquired from -k_max to + k_max
        isalternated = 1;
    end

    % Kpos has to be the same size as the FE, PE and SE
    % dimension of MR.Data
    kpos = zeros(n_FE, n_spokes, 1, 2);

    kpos(:,:,1,1:2) = CalcTraj_2d_radial(rad_pos, RadialAngles, isalternated);
end


