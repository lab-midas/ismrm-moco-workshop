% (c) Gastao Cruz, 2022, University of Michigan
% (c) Gastao Cruz, 2013-2022, King's College London

%% This script runs a demo of a motion corrected reconstruction, as initially proposed in:

% Batchelor PG, Atkinson D, Irarrazaval P, Hill DL, Hajnal J, Larkman D.
% Matrix description of general motion correction applied to multishot images.
% Magnetic Resonance in Medicine: An Official Journal of the International
% Society for Magnetic Resonance in Medicine. 2005 Nov;54(5):1273-80.

%% This code was initially developed as part of the following studies:

% Cruz G, Atkinson D, Henningsson M, Botnar RM, Prieto C. Highly efficient
% nonrigid motion‐corrected 3D whole‐heart coronary vessel wall imaging.
% Magnetic resonance in medicine. 2017 May;77(5):1894-908.

% Cruz G, Atkinson D, Buerger C, Schaeffter T, Prieto C. Accelerated motion 
% corrected three‐dimensional abdominal MRI using total variation regularized
% SENSE reconstruction. Magnetic resonance in medicine. 2016 Apr;75(4):1484-98.

%% This demo does not consider the problem of motion estimation. Motion for the 
%% in-vivo case at the end was estimated via image registration with NiftyReg:
%% http://cmictig.cs.ucl.ac.uk/wiki/index.php/NiftyReg
%% More advanced methods registration methods can also be used, like LAPNet:
%% https://github.com/lab-midas/lapnet

%% A more complete demo on motion artefacts, motion estimation and motion correction
%% can be found in the python code and associated google colab.

%% You may want to download a newer version of imagine.m, or use any other image viewer (or even just good old imshow).

%% If you have any questions/ suggestions, get in touch with us via
%% glimadac@med.umich.edu and/or thomas.kuestner@med.uni-tuebingen.de 

clear classes
load('brain.mat');
load('smaps.mat');
addpath(genpath('./'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0 Apply affine transformation to image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% affine parameters
Tx = -10;
Ty = 70;
rot = pi/4;
Scx = 0.7;
Scy = 1.3;
Shx = 0;
Shy = 0;

% apply affine transform
[brain_affine,~] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);

%% Compare images: brain_affine is a warped version of brain, determined 
%% by the translation, rotation and scaling parameters above
imagine(abs(cat(4,brain,brain_affine)))



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1 Simulate a simple motion corrupted acquisition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = -10;
Ty = 70;
rot = pi/4;
Scx = 0.7;
Scy = 1.3;
Shx = 0;
Shy = 0;

% apply affine transform
[brain_affine,~] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);

% k-space of the original brain
k1 = Image2K(brain);

% k-space of the moving brain
k2 = Image2K(brain_affine);

% motion corrupted k-space
k_motion = zeros(size(k1));
k_motion(:,1:2:end) = k1(:,1:2:end);
k_motion(:,2:2:end) = k2(:,2:2:end);

% reconstruct (motion corrupted) image
brain_motion_artefacts = K2Image(k_motion);

%% Compare images: brain_motion_artefacts contains a superposition of 
%% aliased views of brain and brain_affine. The motion artefacts that appear
%% are in fact the undersampling artefacts of each motion state (brain and
%% brain_affine) that fail to cancel out.
imagine(abs(cat(4,brain,brain_affine,brain_motion_artefacts)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2 Use Batchelor's motion model with translation and Cartesian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = -40;
rot = 0;
Scx = 1;
Scy = 1;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain,0,0,0,1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% setting up recon params
[Ny, Nx] = size(brain);
csm = ones([Ny Nx 8]);
% motion field params for recon
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
% sampling masks
At1 = zeros(size(brain));
At1(:,1:2:end) = 1;
At2 = zeros(size(brain));
At2(:,2:2:end) = 1;
At{1} = At1; At{2} = At2;

% The current implementation of Batchelor's reconstruction creates sparse motion matrices
% assuming the underlying motion fields include a mesh grid of coordinates for x and y. You
% may add/remove the mesh grid using "Add_mesh_to_DF.m" or "Remove_mesh_from_DF.m"

% Forward model with motion
E_motion_yes = Batch_cart(At,csm,motion_fields);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_cart(At,csm,id_mot);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% Zero-fill motion corrupted
motion_corrupted = E_motion_no'*motion_kspace;
% Zero-fill motion corrected
motion_corrected = E_motion_yes'*motion_kspace;

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_yes,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: SENSE_its is just a zero-fill recon (no CSM info)
%% MoCo's 1st iteration is the naive "image-based" motion correction, which
%% produces residual aliasing; however, the ideal image can be recovered
%% with the iterative reconstruction. Incidentally, if the motion is along Tx
%% then we have a special case where the motion and fourier operators commute
%% and the naive solution (iteration zero) actually gives the correct solution.
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3 Use Batchelor's motion model with rotation and Cartesian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = 0;
rot = pi/2;
Scx = 1;
Scy = 1;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain,0,0,0,1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% setting up recon params
[Ny, Nx] = size(brain);
csm = ones([Ny Nx 8]);
% motion field params for recon
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
% sampling masks
At1 = zeros(size(brain));
At1(:,1:2:end) = 1;
At2 = zeros(size(brain));
At2(:,2:2:end) = 1;
At{1} = At1; At{2} = At2;

% Forward model with motion
E_motion_yes = Batch_cart(At,csm,motion_fields);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_cart(At,csm,id_mot);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% Zero-fill motion corrupted
motion_corrupted = E_motion_no'*motion_kspace;
% Zero-fill motion corrected
motion_corrected = E_motion_yes'*motion_kspace;

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_yes,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: In this case, Batchelor's recon does correct for motion, 
%% but additional aliasing is introduced. This is because any motion more complex
%% than translation (e.g. rotation) will open gaps in k-space. This is a 
%% fundamental limitation of retrospective motion correction.
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4 Use Batchelor's motion model with rotation and Cartesian and CSM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = 0;
rot = pi/2;
Scx = 1;
Scy = 1;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain,0,0,0,1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% setting up recon params
[Ny, Nx] = size(brain);
csm = smaps;
% motion field params for recon
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
% sampling masks
At1 = zeros(size(brain));
At1(:,1:2:end) = 1;
At2 = zeros(size(brain));
At2(:,2:2:end) = 1;
At{1} = At1; At{2} = At2;

% Forward model with motion
E_motion_yes = Batch_cart(At,csm,motion_fields);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_cart(At,csm,id_mot);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% Zero-fill motion corrupted
motion_corrupted = E_motion_no'*motion_kspace;
% Zero-fill motion corrected
motion_corrected = E_motion_yes'*motion_kspace;

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_yes,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: Combining SENSE with Batch allows Parallel Imaging to fill
%% in the k-space gaps created during the motion correction process. In this 
%% example SENSE_its still has motion artefacts, however both motion states
%% could be reconstructed separately to produce alias free images 
%% (in distinct motion states).
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5 Use Batchelor's motion model with affine motion and (undersampled) radial and (CSM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = -30;
rot = pi/4;
Scx = 0.7;
Scy = 1.3;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain, 0, 0, 0, 1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);

% other recon inputs
Nfe = Ny;
Npe = round(Nx/3);
[kpos] = get_GC_kpos(Nfe,Npe,'GC');
dcf = voronoi_dcf_2D(kpos);
dcf(:,1) = dcf(:,2); dcf(:,end) = dcf(:,end-1);
kpos = double(squeeze(kpos(:,:,:,1:2)));
Ksiz = size(dcf);

csm = smaps;
Nc = size(csm,3);
coil_rss = sqrt(sum(csm.*conj(csm),3));
mdir = 1;
%
mask{1} = 1:2:Npe;
mask{2} = 2:2:Npe;
%
kp1 = kpos(:,mask{1},:);
kpos_all{1} = reshape(kp1,[size(kp1,1)*size(kp1,2) size(kp1,3)]);
kp2 = kpos(:,mask{2},:);
kpos_all{2} = reshape(kp2,[size(kp2,1)*size(kp2,2) size(kp2,3)]);
%
dcf_all{1} = dcf(:,mask{1});
dcf_all{2} = dcf(:,mask{2});
%
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;

% Forward model with motion 
E_motion_yes = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,motion_fields,Ksiz,mdir);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,id_mot,Ksiz,mdir);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_yes,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: In this example SENSE_its helps reduce some aliasing due 
%% to undersampling, but considerable artefacts remain due to motion and 
%% undersampling. Batchelor's recon removes most artefacts related to the 
%% combined effect of motion and undersampling.
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6 Use Batchelor's motion model with added noise: Cartesian, scaling, undersampled 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = 0;
rot = 0;
Scx = 1.5;
Scy = 1;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain,0,0,0,1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% setting up recon params
[Ny, Nx] = size(brain);
csm = smaps;
% motion field params for recon
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
% sampling masks
At1 = zeros(size(brain));
At1(:,1:4:end) = 1;
At2 = zeros(size(brain));
At2(:,2:4:end) = 1;
At2(:,4:4:end) = 1;
At{1} = At1; At{2} = At2;

% Forward model with motion
E_motion_yes = Batch_cart(At,csm,motion_fields);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_cart(At,csm,id_mot);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% Add white gaussian noise
max_s = max(abs(motion_kspace(:)));
noisestd = 2E-3;
motion_kspace = motion_kspace + noisestd*max_s*randn(size(motion_kspace)) + 1i*noisestd*max_s*randn(size(motion_kspace));

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_yes,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: This is an interesting case where motion state 1 has 25%
%% of the data and motion state 2 has 50% of the data. This causes SENSE to 
%% converge to a solution where the image is predominantly in motion state 2.
%% Noise propagation through Batchelor's reconstruction has a similar
%% behaviour to Parallel Imaging (and produces similar g-factors)
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7 Use Batchelor's motion model with motion errors: fully sampled and noise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = 0;
rot = 0;
Scx = 1.5;
Scy = 1;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain,0,0,0,1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);

% error_motion
er_factor = 0.90; % 10% error
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx*er_factor,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
error_mot = get_sparse_mot(brain,DF);


% setting up recon params
[Ny, Nx] = size(brain);
csm = smaps;
% motion field params for recon
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
% sampling masks
At1 = zeros(size(brain));
At1(:,1:2:end) = 1;
At2 = zeros(size(brain));
At2(:,2:2:end) = 1;
At{1} = At1; At{2} = At2;

% Forward model with motion
E_motion_yes = Batch_cart(At,csm,motion_fields);

% motion field params for recon
motion_error{1} = sparse_id;
motion_error{2} = error_mot;
% Forward model with motion
E_motion_error = Batch_cart(At,csm,motion_error);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_cart(At,csm,id_mot);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% Add white gaussian noise
max_s = max(abs(motion_kspace(:)));
noisestd = 2E-3;
motion_kspace = motion_kspace + noisestd*max_s*randn(size(motion_kspace)) + 1i*noisestd*max_s*randn(size(motion_kspace));

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_error,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: Motion errors propagate linearly through Batchelor's reconstruction:
%% the original motion artefacts are corrected for, but new (smaller)
%% motion artefacts are introduced due to errors in the motion model
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8 Use Batchelor's motion model with motion errors (3 states), radial and undersampled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 0;
Ty = 00;
rot = pi/6;
Scx = 1;
Scy = 1.2;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain, 0, 0, 0, 1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% error motion
er_factor = 0.90; % 10% error
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot*er_factor,Scx,Scy*er_factor,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
error_mot = get_sparse_mot(brain,DF);

% affine parameters
Tx = 0;
Ty = 0;
rot = -pi/8;
Scx = 0.7;
Scy = 1;
Shx = 0;
Shy = 0;

% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot2 = get_sparse_mot(brain,DF);
% error motion
er_factor = 0.90; % 10% error
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot*er_factor,Scx*er_factor,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
error_mot2 = get_sparse_mot(brain,DF);

% other recon inputs
Nfe = Ny;
Npe = round(Nx/2);
[kpos] = get_GC_kpos(Nfe,Npe,'GC');
dcf = voronoi_dcf_2D(kpos);
dcf(:,1) = dcf(:,2); dcf(:,end) = dcf(:,end-1);
kpos = double(squeeze(kpos(:,:,:,1:2)));
Ksiz = size(dcf);

csm = smaps;
Nc = size(csm,3);
coil_rss = sqrt(sum(csm.*conj(csm),3));
mdir = 1;
%
mask{1} = 1:3:Npe;
mask{2} = 2:3:Npe;
mask{3} = 3:3:Npe;
%
kp1 = kpos(:,mask{1},:);
kpos_all{1} = reshape(kp1,[size(kp1,1)*size(kp1,2) size(kp1,3)]);
kp2 = kpos(:,mask{2},:);
kpos_all{2} = reshape(kp2,[size(kp2,1)*size(kp2,2) size(kp2,3)]);
kp3 = kpos(:,mask{3},:);
kpos_all{3} = reshape(kp3,[size(kp3,1)*size(kp3,2) size(kp3,3)]);
%
dcf_all{1} = dcf(:,mask{1});
dcf_all{2} = dcf(:,mask{2});
dcf_all{3} = dcf(:,mask{3});
%
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
motion_fields{3} = sparse_mot2;
%
motion_error{1} = sparse_id;
motion_error{2} = error_mot;
motion_error{3} = error_mot2;

% Forward model with motion
E_motion_yes = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,motion_fields,Ksiz,mdir);

% Forward model with errors
E_motion_error = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,motion_error,Ksiz,mdir);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
id_mot{3} = sparse_id;
E_motion_no = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,id_mot,Ksiz,mdir);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

CG_its = 5; res_limit = 1E-4;
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_error,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: With the radial trajectory, errors in the motion model 
%% lead to more incoherent errors: some residual overlap of aliased images, 
%% blurring and localized noise amplification.
imagine(abs(cat(4,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 9 Use Batchelor's motion model with regularization to help  
%% with undersampling and added noise.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear motion_fields id_mot
% affine parameters
Tx = 0;
Ty = 0;
rot = 0;
Scx = 1.5;
Scy = 1;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain,0,0,0,1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% setting up recon params
[Ny, Nx] = size(brain);
csm = smaps;
% motion field params for recon
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
% sampling masks
At1 = zeros(size(brain));
At1(:,1:6:end) = 1;
At2 = zeros(size(brain));
At2(:,5:6:end) = 1;
At{1} = At1; At{2} = At2;

% Forward model with motion
E_motion_yes = Batch_cart(At,csm,motion_fields);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
E_motion_no = Batch_cart(At,csm,id_mot);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% Add white gaussian noise
max_s = max(abs(motion_kspace(:)));
noisestd = 4E-3;
motion_kspace = motion_kspace + noisestd*max_s*randn(size(motion_kspace)) + 1i*noisestd*max_s*randn(size(motion_kspace));

% low resolution prior
x_prior = imgaussfilt(abs(brain),11,'FilterSize',11);

CG_its = 5; res_limit = 1E-4; lambda = 0.05;
[MoCoReg_its,MocoReg_res] = Conjugate_Gradient_reg_warm_start(motion_kspace,E_motion_yes,x_prior,lambda,CG_its,res_limit,x_prior);
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_yes,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: In this example we have 3x undersampling with noise and 
%% a big undersampling gap near the center of k-space, causing substantial
%% aliasing even when motion is corrected for. Using a prior as regularization
%% significantly improves the reconstruction
imagine(abs(cat(4,MoCoReg_its,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 10 Use Batchelor's motion model with motion errors (3 states), 
%% radial, undersampled and regularized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% affine parameters
Tx = 4;
Ty = -8;
rot = -pi/8;
Scx = 1.3;
Scy = 0.8;
Shx = 0;
Shy = 0;

% Identity motion
[~,aff_mat1] = affine_from_values(brain, 0, 0, 0, 1,1,0,0);
DF_Id = getDeformationFieldFromAffine(brain, aff_mat1);
sparse_id = get_sparse_mot(brain,DF_Id);
% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot = get_sparse_mot(brain,DF);
% error motion
er_factor = 1.10; % 20% error
[~,aff_mat] = affine_from_values(brain, Tx*er_factor, Ty*er_factor, rot*er_factor,Scx*er_factor,Scy*er_factor,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
error_mot = get_sparse_mot(brain,DF);

% affine parameters
Tx = -2;
Ty = -5;
rot = -pi/9;
Scx = 1.2;
Scy = 1.1;
Shx = 0;
Shy = 0;

% affine motion
[~,aff_mat] = affine_from_values(brain, Tx, Ty, rot,Scx,Scy,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
sparse_mot2 = get_sparse_mot(brain,DF);
% error motion
er_factor = 1.10; % 10% error
[~,aff_mat] = affine_from_values(brain, Tx*er_factor, Ty*er_factor, rot*er_factor,Scx*er_factor,Scy*er_factor,Shx,Shy);
DF = getDeformationFieldFromAffine(brain, aff_mat);
error_mot2 = get_sparse_mot(brain,DF);

% other recon inputs
Nfe = Ny;
Npe = round(Nx/3);
[kpos] = get_GC_kpos(Nfe,Npe,'GC');
dcf = voronoi_dcf_2D(kpos);
dcf(:,1) = dcf(:,2); dcf(:,end) = dcf(:,end-1);
kpos = double(squeeze(kpos(:,:,:,1:2)));
Ksiz = size(dcf);

csm = smaps;
Nc = size(csm,3);
coil_rss = sqrt(sum(csm.*conj(csm),3));
mdir = 1;
%
mask{1} = 1:3:Npe;
mask{2} = 2:3:Npe;
mask{3} = 3:3:Npe;
%
kp1 = kpos(:,mask{1},:);
kpos_all{1} = reshape(kp1,[size(kp1,1)*size(kp1,2) size(kp1,3)]);
kp2 = kpos(:,mask{2},:);
kpos_all{2} = reshape(kp2,[size(kp2,1)*size(kp2,2) size(kp2,3)]);
kp3 = kpos(:,mask{3},:);
kpos_all{3} = reshape(kp3,[size(kp3,1)*size(kp3,2) size(kp3,3)]);
%
dcf_all{1} = dcf(:,mask{1});
dcf_all{2} = dcf(:,mask{2});
dcf_all{3} = dcf(:,mask{3});
%
motion_fields{1} = sparse_id;
motion_fields{2} = sparse_mot;
motion_fields{3} = sparse_mot2;
%
motion_error{1} = sparse_id;
motion_error{2} = error_mot;
motion_error{3} = error_mot2;

% Forward model with motion
E_motion_yes = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,motion_fields,Ksiz,mdir);

% Forward model with errors
E_motion_error = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,motion_error,Ksiz,mdir);

% Forward model without motion
id_mot{1} = sparse_id;
id_mot{2} = sparse_id;
id_mot{3} = sparse_id;
E_motion_no = Batch_recon_FessNuFFT(mask,csm,kpos_all,dcf_all,id_mot,Ksiz,mdir);

% Motion corrupted acquisition
motion_kspace = E_motion_yes*brain;

% low resolution prior
x_prior = imgaussfilt(abs(brain),11,'FilterSize',11);

CG_its = 5; res_limit = 1E-4; lambda = 0.05;
[MoCoReg_its,MocoReg_res] = Conjugate_Gradient_reg_warm_start(motion_kspace,E_motion_yes,x_prior,lambda,CG_its,res_limit,x_prior);
[MoCo_its,Moco_res] = Conjugate_Gradient(motion_kspace,E_motion_error,CG_its,res_limit);
[SENSE_its,SENSE_res] = Conjugate_Gradient(motion_kspace,E_motion_no,CG_its,res_limit);

%% Compare images: Motion and undersampling artefacts are present in the 
%% SENSE recon. Residual aliasing is visible in the non-regularized Batch
%% recon due to undersampling, motion errors and noise. These artefacts
%% are substantially reduced with regularization.
imagine(abs(cat(4,MoCoReg_its,MoCo_its,SENSE_its)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 11 Experiment with in-vivo cine  data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% In-vivo dataset is available at
%% https://drive.google.com/file/d/1XJ-myPNOlKR96POjs_rEc9aVvL5D7-ku/view?usp=sharing

%% Contains in-vivo k-space, coil sensitivities and cardiac motion fields between 30 cardiac phases

% Cine data with 20 heartbeats
cine_data = load('cine_in_vivo');

% Perform cardiac phase binning with R = 4
R = 5;
cbins = get_cardiac_phases(cine_data.nPE,cine_data.RM,cine_data.ECG,cine_data.nPhases,R);

% Reconstruct a cine using iterative SENSE
itSENSE_cine = cine_SENSE_recon(cine_data.kIN,cine_data.kpp,cine_data.csm,cbins);

% Reconstruct a specific phase using a motion corrected reconstruction
target_phase = 20;
MC_phase = cine_motion_correction(cine_data.kIN,cine_data.kpp,cine_data.dcf_aux,cine_data.csm,cbins,target_phase,cine_data.Motion_fields);

%% Compare images: in this example we are using motion correction to improve
%% the condition of the reconstruction, by using all the acquired data to 
%% reconstruct a cardiac phase, resulting in increased image quality
imagine(cat(3,itSENSE_cine(:,:,target_phase),MC_phase))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 12 Further exercises to perform on numerical and/or in-vivo data:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% 1. Evaluate the performance of both reconstructions in the presence of
% noise, different degrees of undersampling, model errors (coils and/or
% motion), etc.

% 2. Implement a motion corrected reconstruction using nearest neighbour or
% cubic spline interpolations (current implementation uses linear). Evaluate
% the performance of the recon, particularly in the presence of large scalings.
% Notice how the motion matrix reduces to a permutation matrix in the case
% of nearest neighbour interpolation.

% 3. Inspect the convergence of the motion corrected reconstruction without
% normalizing the interpolants when the tranpose motion is applied (i.e.
% set the "motion_norm" variable inside "mtimes.m" to identity). Experiment 
% with different interpolation strategies, rotations, scalings and shearings.

% 4. Combine both itSENSE recon and the motion correction recon with 
% compressed sensing and evalute their performances as in "1.".

% 5. Evaluate the performance of all the previous exercises in terms of 
% SNR, SSIM, RMSE, etc

% 6. Simulate a case with through-plane motion and observe the performance
% of a (in-plane) motion corrected reconstruction.

% 7. Evaluate the g-factor of the motion corrected reconstruction for 
% different types of motion and sampling.

% 8. Motion correction can be combined with soft-weighting to alleviate the
% inherent noise amplification. With soft-weighting, the sampling matrices
% are real-valued [0,1] and each k-space data can partially belong to 
% multiple motion states. Implement such a soft-weighted motion corrected 
% reconstruction and evaluate its' performance.

% 9. The current implementation assumes the object is acquired during a 
% steady state. Contrast resolved reconstructions can be easily solved
% using low rank subspace forward models. Combine a low rank constrained
% reconstruction with motion correction to enable contrast resolved motion
% correction.

% 10. Plenty of other parameters can go into the forward model. For example,
% B0 and B1 can vary with motion. Implement a variant of the motion
% corrected reconstruction that accounts for B0 and B1 variations due to
% motion.
















