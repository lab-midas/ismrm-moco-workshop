import numpy as np

def generate_mask(R, nPE, nFE, nRef=20, mode='regular'):
  # R     desired acceleration factor
  # nPE   amount of phase-encoding lines
  # nFE   amount of frequency-encoding lines
  # nRef  amount of fully-sampled center lines
  # mode  'regular': Parallel-Imaging-like/regular undersampling, 'random': Compressed-Sensing-like/random undersampling
  if mode == 'random':
    mask = np.random.choice([1, 0],(nPE), p=[1/R, 1-1/R])
    mask[nPE//2-nRef//2:nPE//2+nRef//2] = 1
  elif mode == 'regular':
    mask = np.zeros(nPE)
    mask[::R] = 1
    mask[nPE//2-nRef//2:nPE//2+nRef//2] = 1
  else:
    raise ValueError(f'Mode {mode} not defined')

  Reff = nPE/np.sum(mask)
  print(f'Reff={Reff}')

  mask = mask.reshape(1, nPE).repeat(nFE, axis=0)

  return mask[:,:,np.newaxis]