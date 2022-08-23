import numpy as np
#from gpuNUFFT import NUFFTOp
from merlintf.complex import *
from mri.operators import NonCartesianFFT


def rss(coil_img):
  # root sum-of-squares coil combination
  return np.sqrt(np.sum(np.abs(coil_img)**2, -1))


def minmaxscale(x, scale):
  # x     to be scaled image
  # scale [min, max]
  return ((x-np.amin(x)) * (scale[1]-scale[0]))/(np.amax(x) - np.amin(x))


def maxscale(img):
  return img/np.amax(np.abs(img))


# Cartesian 2D operators
def mriAdjointOp(kspace, smaps, mask):
  return np.sum(ifft2c(kspace * mask)*np.conj(smaps), axis=-1)

def mriForwardOp(image, smaps, mask):
  return fft2c(smaps * image[:,:,np.newaxis]) * mask

def fft2c(image, axes=(0,1)):
  return np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(image, axes=axes), norm='ortho', axes=axes), axes=axes)

def ifft2c(kspace, axes=(0,1)):
  return np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(kspace, axes=axes), norm='ortho', axes=axes), axes=axes)


# Non-Cartesian 2D operators
class GPUNUFFTFwd(tf.keras.layers.Layer):
    def __init__(self, nRead, csm, traj, dcf):
      super().__init__()
      self.op = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf,
                                smaps=csm, implementation='gpuNUFFT')

    def call(self, x, csm, traj, dcf):
      return numpy2tensor(self.op.op(np.squeeze(x.numpy())), add_batch_dim=True, add_channel_dim=False)


class GPUNUFFTAdj(tf.keras.layers.Layer):
  def __init__(self, nRead, csm, traj, dcf):
    super().__init__()
    self.op = NonCartesianFFT(samples=traj, shape=[nRead, nRead], n_coils=np.shape(csm)[0], density_comp=dcf, smaps=csm,
                              implementation='gpuNUFFT')

  def call(self, x, csm, traj, dcf):
    return numpy2tensor(self.op.adj_op(x), add_batch_dim=True, add_channel_dim=False)


# Define Batchelor's motion operator
def BatchForwardOp(image,smaps,masks,motions):
  Nx = np.shape(image)[0]
  Ny = np.shape(image)[1]
  Nc = np.shape(smaps)[2]
  Nt = np.shape(masks)[2]

  kspace_out = np.zeros((Nx,Ny,Nc,Nt)) + 1j * np.zeros((Nx,Ny,Nc,Nt))
  for t in range(Nt):
    im_aux = apply_sparse_motion(image,get_sparse_motion_matrix(motions[:,:,:,t]),0)
    kspace_out[:,:,:,t] = mriForwardOp(im_aux, smaps, masks[:,:,t][:,:,np.newaxis])
  return np.sum(kspace_out,3)


def BatchAdjointOp(kspace,smaps,masks,motions):
  Nx = np.shape(kspace)[0]
  Ny = np.shape(kspace)[1]
  Nc = np.shape(smaps)[2]
  Nt = np.shape(masks)[2]

  image_out = np.zeros((Nx,Ny,Nt)) + 1j * np.zeros((Nx,Ny,Nt))
  im_aux = np.zeros((Nx,Ny,Nc))
  for t in range(Nt):
    im_aux = mriAdjointOp(kspace, smaps, masks[:,:,t][:,:,np.newaxis])
    image_out[:,:,t] = apply_sparse_motion(im_aux,get_sparse_motion_matrix(motions[:,:,:,t]),1)
  return np.sum(image_out,2)