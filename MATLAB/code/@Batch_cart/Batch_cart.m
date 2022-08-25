function  res = Batch_cart(At,csm,MF)

res.adjoint = 0; % flag
res.At = At; % sampled points
res.coils = csm; % coils
res.motion_fields = MF; % motion fields
res.nbins = numel(MF); % number of motion states
res.ncoils = size(csm,3); % size(coils)
res.siz =[size(csm,1) size(csm,2)]; % size in image space
res.coil_rss = sqrt(sum(csm.*conj(csm),3)); % intensity correction
res = class(res,'Batch_cart');

