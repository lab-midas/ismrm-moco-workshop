function [kpos_GC] = get_GC_kpos(n_FE,n_spokes,RadProfOrder)

% K-space values along each radial spoke
%             delta_kr = 1/size(Data,1);
            delta_kr = 1/n_FE;
            rad_pos(:,1) = -0.5:delta_kr:0.5-delta_kr;
%             rad_pos = rad_pos/(AcqVoxelSize(1)./RecVoxelSize(1));
            % Determine number of radial lines
%             n_spokes = size(Data,2);
            
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
            kpos_GC = zeros(n_FE, n_spokes, 1, 3);
            
            kpos_GC(:,:,1,1:2) = CalcTraj_2d_radial(rad_pos, RadialAngles, isalternated);

end

