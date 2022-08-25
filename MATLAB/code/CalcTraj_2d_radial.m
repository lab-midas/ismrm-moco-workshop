function kpos = CalcTraj_2d_radial(rad_pos, rad_angles, isalternated)
% Calculate k-space trajectory for a 2D radial acquisition

% rad_pos:      K-space points along radial spokes
% rad_angles:   Angle values for each of the radial lines
% isalternated: Flag indicating that each even radial line is
%                sampled from +k_max to -k_max and each odd line
%                is acquired from -k_max to + k_max


rad_pos = double(rad_pos(:));
rad_angles = double(rad_angles(:));
kpos = zeros(size(rad_pos,1), size(rad_angles,1), 2);

if isalternated
    % Radius from -k_max to +k_max
    kpos(:,(1:2:end),1) = rad_pos*sin(rad_angles(1:2:end))';
    kpos(:,(1:2:end),2) = rad_pos*cos(rad_angles(1:2:end))';

    % Radius from +k_max to -k_max
    kpos(:,(2:2:end),1) = -rad_pos*sin(rad_angles(2:2:end))';
    kpos(:,(2:2:end),2) = -rad_pos*cos(rad_angles(2:2:end))';

else
    kpos(:,:,1) = rad_pos*sin(rad_angles)';
    kpos(:,:,2) = rad_pos*cos(rad_angles)';
end


end