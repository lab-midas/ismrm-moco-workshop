import numpy as np
#from gpuNUFFT import NUFFTOp
from merlintf.complex import *
from merlintf.keras.layers.data_consistency import itSENSE, DCPM
from merlintf.keras.layers.mri import MulticoilForwardOp, MulticoilAdjointOp
from mri.operators import NonCartesianFFT
from utils.motioncomp import *
import tensorflow as tf
from scipy.sparse import vstack


def rss(coil_img):
    # root sum-of-squares coil combination
    return np.sqrt(np.sum(np.abs(coil_img)**2, -1))


def minmaxscale(x, scale):
    # x     to be scaled image
    # scale [min, max]
    return ((x-np.amin(x)) * (scale[1]-scale[0]))/(np.amax(x) - np.amin(x))


def maxscale(img):
    return img/np.amax(np.abs(img))


def squeeze_batch_dim(x):
    if np.shape(x)[0] == 1:
        return x[0, ...]
    else:
        return x

# Cartesian 2D operators
def mriAdjointOp(kspace, mask, smaps):
    return np.sum(ifft2c(kspace * mask)*np.conj(smaps), axis=-1)

def mriForwardOp(image, mask, smaps):
    return fft2c(smaps * image[:,:,np.newaxis]) * mask

def fft2c(image, axes=(0,1)):
    return np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(image, axes=axes), norm='ortho', axes=axes), axes=axes)

def ifft2c(kspace, axes=(0,1)):
    return np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(kspace, axes=axes), norm='ortho', axes=axes), axes=axes)

# Define Batchelor's motion operator
# motions is now a vertical stack of sparse motion matrices
def BatchForwardOp(image, masks, smaps, motions, use_optox=False):
    Nx = np.shape(image)[0]
    Ny = np.shape(image)[1]
    Nc = np.shape(smaps)[2]
    Nt = np.shape(masks)[-1]

    kspace_out = np.zeros((Nx,Ny,Nc,Nt)) + 1j * np.zeros((Nx,Ny,Nc,Nt))
    for t in range(Nt):
        if use_optox:
            im_aux = apply_sparse_motion(image,get_sparse_motion_matrix(motions[:,:,:,t]),0)
        else:
            im_aux = apply_sparse_motion(image,motions[t*Nx*Ny:(t+1)*Nx*Ny,:],0)
        kspace_out[:,:,:,t] = mriForwardOp(im_aux, masks[:,:,:,t], smaps)
    return np.sum(kspace_out,3)

def BatchAdjointOp(kspace, masks, smaps, motions, use_optox=False):
    Nx = np.shape(kspace)[0]
    Ny = np.shape(kspace)[1]
    Nc = np.shape(smaps)[2]
    Nt = np.shape(masks)[-1]

    image_out = np.zeros((Nx,Ny,Nt)) + 1j * np.zeros((Nx,Ny,Nt))
    #im_aux = np.zeros((Nx,Ny,Nc))
    for t in range(Nt):
        im_aux = mriAdjointOp(kspace, masks[:,:,:,t], smaps)
        if use_optox:
            image_out[:,:,t] = apply_sparse_motion(im_aux,get_sparse_motion_matrix(motions[:,:,:,t]),1)
        else:
            image_out[:,:,t] = apply_sparse_motion(im_aux,motions[t*Nx*Ny:(t+1)*Nx*Ny,:],1)
    return np.sum(image_out,2)


def BatchGPUNUFFTForwardOp(image, traj, csm, dcf, motions, nufft=None, use_optox=False):
    Nx = np.shape(image)[0]
    Ny = np.shape(image)[1]
    NSpokes = np.shape(traj)[0]
    Nc = np.shape(csm)[0]
    Nt = np.shape(motions)[-1]
    mcomp = True if nufft is None else False
    kspace_out = np.zeros((Nc, NSpokes, Nt)) + 1j * np.zeros((Nc, NSpokes, Nt))
    for t in range(Nt):
        if use_optox:
            im_aux = apply_sparse_motion(image, get_sparse_motion_matrix(motions[:, :, :, t]), 0)
        else:
            im_aux = apply_sparse_motion(image, motions[t * Nx * Ny:(t + 1) * Nx * Ny, :], 0)
        if mcomp:
            nufft = NonCartesianFFT(samples=traj[..., t], shape=[Nx, Nx], n_coils=Nc, density_comp=dcf[..., t],
                                smaps=csm, implementation='gpuNUFFT')
        kspace_out[:, :, t] = nufft.op(im_aux)
    return np.sum(kspace_out, 2)

def BatchGPUNUFFTAdjointOp(kspace, traj, csm, dcf, motions, nufft=None, use_optox=False):
    Nx = np.shape(csm)[1]
    Ny = np.shape(csm)[2]
    Nt = np.shape(motions)[-1]
    mcomp = True if nufft is None else False
    image_out = np.zeros((Nx, Ny, Nt)) + 1j * np.zeros((Nx, Ny, Nt))
    for t in range(Nt):
        if mcomp:
            nufft = NonCartesianFFT(samples=traj[..., t], shape=[Nx, Nx], n_coils=Nc, density_comp=dcf[..., t],
                                    smaps=csm, implementation='gpuNUFFT')
        im_aux = nufft.adj_op(kspace)
        if use_optox:
            image_out[:, :, t] = apply_sparse_motion(im_aux, get_sparse_motion_matrix(motions[:, :, :, t]), 1)
        else:
            image_out[:, :, t] = apply_sparse_motion(im_aux, motions[t * Nx * Ny:(t + 1) * Nx * Ny, :], 1)
    return np.sum(image_out, 2)


class BatchelorFwd(tf.keras.layers.Layer):
    def __init__(self):
        super().__init__()
        self.op = BatchForwardOp

    def call(self, image, mask, smaps, flow):
        flow = squeeze_batch_dim(flow.numpy())
        flowlist = []
        for t in range(np.shape(flow)[-1]):
            flowlist.append(get_sparse_motion_matrix(flow[:, :, :, t]))
        smm = vstack(flowlist)
        return numpy2tensor(self.op(squeeze_batch_dim(image.numpy()), squeeze_batch_dim(mask.numpy()), squeeze_batch_dim(smaps.numpy()),
                                    smm, use_optox=True), add_batch_dim=True, add_channel_dim=False)


class BatchelorAdj(tf.keras.layers.Layer):
    def __init__(self):
        super().__init__()
        self.op = BatchAdjointOp

    def call(self, kspace, mask, smaps, flow):
        flow = squeeze_batch_dim(flow.numpy())
        flowlist = []
        for t in range(np.shape(flow)[-1]):
            flowlist.append(get_sparse_motion_matrix(flow[:, :, :, t]))
        smm = vstack(flowlist)
        return numpy2tensor(self.op(squeeze_batch_dim(kspace.numpy()), squeeze_batch_dim(mask.numpy()), squeeze_batch_dim(smaps.numpy()),
                                    smm, use_optox=True), add_batch_dim=True, add_channel_dim=False)

# Non-Cartesian 2D operators
class GPUNUFFTOp():
    def __init__(self, traj, csm, dcf, nRead):
        self.traj = traj
        self.csm = csm
        self.dcf = dcf
        self.nufft = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf,
                                smaps=csm, implementation='gpuNUFFT')

    def forward(self, image):
        return self.nufft.op(image)

    def adjoint(self, kspace):
        return self.nufft.adj_op(kspace)

    def set_nufft(self, nufft):
        self.nufft = nufft


class GPUNUFFTFwd(tf.keras.layers.Layer):
    def __init__(self, nRead, traj, csm, dcf):
        super().__init__()
        self.op = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf,
                                smaps=csm, implementation='gpuNUFFT')

    def call(self, x, traj, csm, dcf):
        return numpy2tensor(self.op.op(np.squeeze(x.numpy())), add_batch_dim=True, add_channel_dim=False)


class GPUNUFFTAdj(tf.keras.layers.Layer):
    def __init__(self, nRead, traj, csm, dcf):
        super().__init__()
        self.op = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf, smaps=csm,
                              implementation='gpuNUFFT')

    def call(self, x, traj, csm, dcf):
        return numpy2tensor(self.op.adj_op(np.squeeze(x.numpy())), add_batch_dim=True, add_channel_dim=False)


class BatchelorGPUNUFFTFwd(tf.keras.layers.Layer):
    def __init__(self, nRead, traj, csm, dcf):
        super().__init__()
        self.Nx = nRead
        self.Ny = nRead
        self.Nc = np.shape(csm)[0]
        if len(np.shape(traj)) == 3:
            self.Nt = np.shape(traj)[2]
        else:
            self.Nt = 1
        self.NSpokes = np.shape(traj)[0]
        if self.Nt > 1:
            self.nufft = None
        else:
            self.nufft = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf,
                                smaps=csm, implementation='gpuNUFFT')
        self.op = BatchGPUNUFFTForwardOp

    def call(self, image, traj, csm, dcf, flow):
        flow = squeeze_batch_dim(flow.numpy())
        flowlist = []
        for t in range(np.shape(flow)[-1]):
            flowlist.append(get_sparse_motion_matrix(flow[:, :, :, t]))
        smm = vstack(flowlist)
        return numpy2tensor(self.op(squeeze_batch_dim(image.numpy()), squeeze_batch_dim(traj.numpy()), squeeze_batch_dim(csm.numpy()),
                                    squeeze_batch_dim(dcf.numpy()), smm, self.nufft, use_optox=True), add_batch_dim=True, add_channel_dim=False)


class BatchelorGPUNUFFTAdj(tf.keras.layers.Layer):
    def __init__(self, nRead, traj, csm, dcf):
        super().__init__()
        self.Nx = nRead
        self.Ny = nRead
        self.Nc = np.shape(csm)[0]
        if len(np.shape(traj)) == 3:
            self.Nt = np.shape(traj)[2]
        else:
            self.Nt = 1
        self.NSpokes = np.shape(traj)[0]
        if self.Nt > 1:
            self.nufft = None
        else:
            self.nufft = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf,
                                  smaps=csm, implementation='gpuNUFFT')
        self.op = BatchGPUNUFFTAdjointOp

    def call(self, kspace, traj, csm, dcf, flow):
        flow = squeeze_batch_dim(flow.numpy())
        flowlist = []
        for t in range(np.shape(flow)[-1]):
            flowlist.append(get_sparse_motion_matrix(flow[:, :, :, t]))
        smm = vstack(flowlist)
        return numpy2tensor(self.op(squeeze_batch_dim(kspace.numpy()), squeeze_batch_dim(traj.numpy()), squeeze_batch_dim(csm.numpy()),
                    squeeze_batch_dim(dcf.numpy()), smm, self.nufft, use_optox=True), add_batch_dim=True,
            add_channel_dim=False)


def iterativeSENSE(kspace, smap=None, mask=None, noisy=None, dcf=None, flow=None,
                     fwdop=MulticoilForwardOp, adjop=MulticoilAdjointOp,
                     add_batch_dim=True, max_iter=10, tol=1e-12, weight_init=1.0, weight_scale=1.0, use_optox=False):
    # kspace        raw k-space data as [X, Y, coils] which will be converted to:
    #               Cartesian + no-motion compensation: [batch, coils, X, Y] or [batch, coils, X, Y, Z] or [batch, coils, time, X, Y] or [batch, coils, time, X, Y, Z] (numpy array)
    #               Cartesian + motion-compensation / non-Cartesian + no-motion/motion-comp.: [batch, X, Y, coils]
    # smap          coil sensitivity maps with same shape as kspace (or singleton dimension for time) (numpy array)
    # mask          subsampling including/excluding soft-weights with same shape as kspace (no-motion-comp) and shape: X, Y, coils, T (motion-comp) (numpy array)
    # noisy         initialiaztion for reconstructed image, if None it is created from A^H(kspace) (numpy array)
    # dcf           density compensation function (only non-Cartesian) (numpy array)
    # flow          flow field (numpy array)
    # fwdop         forward operator A
    # adjop         adjoint operator A^H
    # add_batch_dim automatically append batch dimension for GPU execution
    # max_iter      maximum number of iterations for CG/iterative SENSE
    # tol           tolerance for stopping condition for CG/iterative SENSE
    # weight_init   initial weighting for lambda regularization parameter
    # weight_scale  scaling factor for lambda regularization parameter
    # return:       reconstructed image (numpy array)

    if dcf is not None:
        bradial = True
    else:
        bradial = False

    if flow is not None:
        motioncomp = True
    else:
        motioncomp = False

    if bradial:
        Nx, Nspokes = np.shape(kspace)
        Ny = Nx
        Nc = 1
    else:
        Nx, Ny, Nc = np.shape(kspace)
    if motioncomp:
        Nt = np.shape(flow)[-1]
    else:
        Nt = 1
    # Forward and Adjoint operators
    A = fwdop
    AH = adjop

    if use_optox:
        if type(kspace).__module__ == np.__name__:
            if not bradial and not motioncomp:
                kspace = np.transpose(kspace, (2, 0, 1))
            kspace = numpy2tensor(kspace, add_batch_dim=add_batch_dim, add_channel_dim=False)
        if smap is not None and type(smap).__module__ == np.__name__:
            if not bradial and not motioncomp:
                smap = np.transpose(smap, (2, 0, 1))
            smap = numpy2tensor(smap, add_batch_dim=add_batch_dim, add_channel_dim=False)
        if mask is not None and type(mask).__module__ == np.__name__:
            mask = numpy2tensor(mask, add_batch_dim=add_batch_dim, add_channel_dim=False, dtype=tf.float32)
        else:
            if motioncomp:
                mask = tf.ones([Nx, Ny, Nc, Nt], dtype=tf.float32)
            else:
                mask = tf.ones(tf.shape(kspace), dtype=tf.float32)
        if dcf is not None and type(dcf).__module__ == np.__name__:
            dcf = numpy2tensor(dcf, add_batch_dim=add_batch_dim, add_channel_dim=False)
        if flow is not None and type(flow).__module__ == np.__name__:
            flow = numpy2tensor(flow, add_batch_dim=add_batch_dim, add_channel_dim=False, dtype=tf.float32)

        if noisy is None:
            if bradial:
                if motioncomp:
                    noisy = AH(kspace, mask, smap, dcf, flow)
                else:
                    noisy = AH(kspace, mask, smap, dcf)
            else:
                if motioncomp:
                    noisy = AH(kspace, mask, smap, flow)
                else:
                    noisy = AH(kspace, mask, smap)
        elif noisy is not None and type(noisy).__module__ == np.__name__:
            noisy = numpy2tensor(noisy, add_batch_dim=add_batch_dim, add_channel_dim=False)

        model = DCPM(A, AH, weight_init=weight_init, weight_scale=weight_scale, max_iter=max_iter, tol=tol)
        if bradial:  # non-Cartesian
            if motioncomp:
                return np.squeeze(model([noisy, kspace, smap, mask, dcf, flow]).numpy())
            else:
                return np.squeeze(model([noisy, kspace, smap, mask, dcf]).numpy())
        else:  # Cartesian
            if motioncomp:
                return np.squeeze(model([noisy, kspace, mask, smap, flow]).numpy())
            else:
                return np.squeeze(model([noisy, kspace, mask, smap]).numpy())
    else:
        if not bradial and not motioncomp:
            kspace = np.transpose(kspace, (2, 0, 1))

        if smap is not None:
            if not bradial and not motioncomp:
                smap = np.transpose(smap, (2, 0, 1))

        if mask is None:
            if motioncomp:
                mask = tf.ones([Nx, Ny, Nc, Nt], dtype=tf.float32)
            else:
                mask = tf.ones(tf.shape(kspace), dtype=tf.float32)

        if noisy is None:
            if bradial:
                if motioncomp:
                    noisy = AH(kspace, mask, smap, dcf, flow)
                else:
                    noisy = AH(kspace, mask, smap, dcf)
            else:
                if motioncomp:
                    noisy = AH(kspace, mask, smap, flow)
                else:
                    noisy = AH(kspace, mask, smap)

        if bradial:  # non-Cartesian
            if motioncomp:
                return np.squeeze(conjugate_gradient([noisy, kspace, smap, mask, dcf, flow], A, AH, max_iter, tol).numpy())
            else:
                return np.squeeze(conjugate_gradient([noisy, kspace, smap, mask, dcf], A, AH, max_iter, tol).numpy())
        else:  # Cartesian
            if motioncomp:
                return np.squeeze(conjugate_gradient([noisy, kspace, mask, smap, flow], A, AH, max_iter, tol).numpy())
            else:
                return np.squeeze(conjugate_gradient([noisy, kspace, mask, smap], A, AH, max_iter, tol).numpy())

# Conjugate gradient solver for linear inverse problem
def conjugate_gradient(inputs, A, AH, max_iter=10, tol=1e-12):
    #x0 = inputs[0]
    y = inputs[1]
    constants = inputs[2:]

    #xk = x0
    rhs = AH(y, *constants)
    def M(p):
        return AH(A(p, *constants), *constants)

    x = np.zeros_like(rhs)
    i, r, p = 0, rhs, rhs
    rTr = np.real(np.sum(np.conj(r) * r))
    num_iter = 0
    while (num_iter < max_iter) and (rTr > tol):
        Ap = M(p)
        alpha = rTr / np.real(np.sum(np.conj(p) * Ap))
        x = x + p * alpha
        r = r - Ap * alpha
        rTrNew = np.real(np.sum(np.conj(r) * r))
        beta = rTrNew / rTr
        rTr = rTrNew
        p = r + p * beta

    return x