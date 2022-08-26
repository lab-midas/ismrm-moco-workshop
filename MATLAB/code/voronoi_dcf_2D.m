function dcf = voronoi_dcf_2D(Kpos)
% Calculates sample density compensation function using Voronoi method method.
% Points at the edge of k-space are assigned the weight of their nearest
% neighbour
%
% Input:
%
% Kpos: Matrix containing the 3D k-space locations (size [m p 1 2])
% 
% Output:
%
% dcf: Density compensation weights (size [m p])
%

d = size(Kpos);

kx = Kpos(:,:,:,1);
ky = Kpos(:,:,:,2);

% Round trajectory to make almost matching points actually match;
kx = 1e-15*round(kx*1e15);
ky = 1e-15*round(ky*1e15);

Kpos = [kx(:), ky(:)];

[Kpos_unique,index] = unique(Kpos,'rows','first');  

[v, c] = voronoin(Kpos_unique);

v_cell = cellfun(@(x)  v(x',:), c, 'UniformOutput',0);


% 
% for i = 1:length(c)
%     if all(c{i}~=1)   % If at least one of the indices is 1,
%         % then it is an open region and we can't
%         % patch that.
%         patch(v(c{i},1),v(c{i},2),i); % use color i.
%     end
% end
% 
% hold on
% plot(kx(:),ky(:),'.')

dcf = zeros(1,numel(v_cell));

for ii = 1:numel(v_cell)


	dcf(ii) = polyarea(v_cell{ii}(:,1), v_cell{ii}(:,2));


end

dcf_mean = mean(dcf(~isnan(dcf)));
dcf_std = mean(dcf(~isnan(dcf)));

dcf(dcf > (dcf_mean + 5*dcf_std)) = NaN;

% Fill in values for duplicated trajectory points (and weight by number
% of duplicates)

dcf_all_points = zeros(size(Kpos,1),1);
dcf_all_points(index) = dcf;

repeatedIndex = setdiff(1:size(Kpos,1),index);  %# Finds indices of repeats

while ~isempty(repeatedIndex)
    
    [Lia] = ismember(Kpos, Kpos(repeatedIndex(1),:),'rows');
    
    f = find(Lia,1,'first');
    dcf_all_points(Lia) = dcf_all_points(f)/sum(Lia);
    
    repeatedIndex = repeatedIndex(~ismember(repeatedIndex, find(Lia)));
    
    
end

% Find edge points, which will have NaN area

nan_points = find(isnan(dcf_all_points));


dcf_not_nan = dcf_all_points(~isnan(dcf_all_points));
Kpos_not_nan = Kpos(~isnan(dcf_all_points),:);

for ii = nan_points'
    coords = Kpos(ii,:);
    [~, closest] = min(vnorm(repmat(coords, [size(Kpos_not_nan,1),1]) - Kpos_not_nan, 2));
    dcf_all_points(ii) = dcf_not_nan(closest);
end

dcf = dcf_all_points;
dcf = dcf*numel(dcf);
dcf = reshape(dcf, d(1:2));


