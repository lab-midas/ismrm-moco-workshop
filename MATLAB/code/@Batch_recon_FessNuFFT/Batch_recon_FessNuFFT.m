function  res = Batch_recon_FessNuFFT(mask,b1,kpos,dcf,Mf,Ksiz,mdir)

%	Implementation of Batchelor's reconstruction
%	
%	input:
%			mask : angular shots belonging to each bin.
%           b1 : coil sensitivity maps (Ny,Nx,Nz,Nc).
%           kpos: k-space positions of each point (GRPE is not cartesian)
%           in cell format.
%           DCF: weights for each of these points (for nufft) in cell
%           format.
%           Mf: is a set of sparse motion matrices.
%           siz: [Ymax Xmax], size of the image domain.
%           Ksiz: [N_fe N_ang], size of the k domain: number of
%           frequenc encodings  and number of angular encodings 
%           (angular encodings == shots).
%           ncols: number of coils...
%           rss_flag: 0 or 1, determines if a rss recon will be performed.
%           mdir: 1 or 2, determines if estimated motion was forward
%           (option 1, from one motion state to all) or inverse (option 2,
%           from all states into one).
%

res.adjoint = 0;
res.mask = mask;
res.b1 = b1;
res.kpos = kpos;
res.dcf = dcf;
res.Mf = Mf;
res.siz = [size(b1,1) size(b1,2)];
res.Ksiz = Ksiz;
res.ncoils = size(b1,3);
res.coil_rss = sqrt(sum(b1.*conj(b1),3));
res.mdir = mdir;
% res.FT = NUFFT(kpos(:,1) + 1i*kpos(:,2), 1, 1, 0, [size(b1,1) size(b1,2)], 2);
res = class(res,'Batch_recon_FessNuFFT');

