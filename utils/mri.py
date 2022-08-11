import numpy as np


def rss(coil_img):
  # root sum-of-squares coil combination
  return np.sqrt(np.sum(np.abs(coil_img)**2, -1))


def minmaxscale(x, scale):
  # x     to be scaled image
  # scale [min, max]
  return ((x-np.amin(x)) * (scale[1]-scale[0]))/(np.amax(x) - np.amin(x))


# Cartesian 2D operators
def mriAdjointOp(kspace, smaps, mask):
  return np.sum(ifft2c(kspace * mask)*np.conj(smaps), axis=-1)

def mriForwardOp(image, smaps, mask):
  return fft2c(smaps * image[:,:,np.newaxis]) * mask

def fft2c(image, axes=(0,1)):
  return np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(image, axes=axes), norm='ortho', axes=axes), axes=axes)

def ifft2c(kspace, axes=(0,1)):
  return np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(kspace, axes=axes), norm='ortho', axes=axes), axes=axes)