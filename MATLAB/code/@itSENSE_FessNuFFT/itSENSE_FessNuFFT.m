function  res = itSENSE_FessNuFFT(mask,b1,kpos,dcf,Ksiz,nbins)

%res = Cruz_E_GRPE(mask,b1)
%
%
%	Implementation of parallel MRI encoding matrix for dynamic MRI data
%	
%	input:
%			mask : angular shots belonging to each bin.
%           b1 : coil sensitivity maps (Ny,Nx,Nz,Nc).
%           kpos: k-space positions of each point (GRPE is not cartesian)
%           in cell format.
%           DCF: weights for each of these points (for nufft) in cell
%           format.
%           siz: [Ymax Xmax], size of the image domain.
%           Ksiz: [N_fe N_ang], size of the k domain: number of
%           frequenc encodings  and number of angular encodings 
%           (angular encodings == shots).
%           nbins and ncoils: number of bins and coils
%           rss_flag: 0 or 1, determines if a rss recon will be performed.
%
%	output: the operator

if nargin<10
    rss_flag = 0;
end

res.adjoint = 0;
res.mask = mask;
res.b1 = b1;
res.kpos = kpos;
res.dcf = dcf;
res.siz = [size(b1,1) size(b1,2)];
res.Ksiz = Ksiz;
res.nbins = nbins;
res.ncoils = size(b1,3);
res.coil_rss = sqrt(sum(b1.*conj(b1),3));
res = class(res,'itSENSE_FessNuFFT');

