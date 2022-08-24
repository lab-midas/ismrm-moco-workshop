import numpy as np
from scipy.sparse import csr_matrix
import math

#####################
# Auxiliary functions
#####################

def bound_index(x,Nx):
  # restrict coordinate x to matrix limit [0,Nx-1]
  if x<0:
    x = 0
  if x>(Nx-1):
    x = Nx-1
  return x

def bound_weight(w,x,y,Nx,Ny):
  # null weights outside the FOV
  if x<0 or x> (Nx-1) or y<0 or y> (Ny-1):
    w = 0
  return w  

def lin_index(x,y,Nx):
  # get 1D linear index from 2D index
  return int(x + Nx*y)

#####################
# Key function !!!
#####################

# get_sparse_motion_matrix takes a [Nx,Ny,2] flow field (i.e no underlying mesh)
# and creates the corresponding [Nx*Ny Nx*Ny] sparse motion matrix

def get_sparse_motion_matrix (flow_field):
# creates a sparse motion matrix corresponding to the motion in the flow field 
# assuming linear interpolation
  Ny = np.shape(flow_field)[1]
  Nx = np.shape(flow_field)[0]
  sparse_mot = csr_matrix((Ny*Nx,Ny*Nx))

  for y in range(np.shape(flow_field)[1]):
    for x in range(np.shape(flow_field)[0]):
      # cartesian interpolant coordinates
      ux = flow_field[x,y,0]
      uy = flow_field[x,y,1]
      y1 = math.floor(y+uy)
      y2 = math.floor(y+uy+1)
      x1 = math.floor(x+ux)
      x2 = math.floor(x+ux+1)
      # interpolants for linear interpolation
      wx = ux-math.floor(ux)
      wy = uy-math.floor(uy)
      w11 = bound_weight((1-wx)*(1-wy),x1,y1,Nx,Ny)
      w12 = bound_weight((1-wx)*wy,x1,y2,Nx,Ny)
      w21 = bound_weight(wx*(1-wy),x2,y1,Nx,Ny)
      w22 = bound_weight(wx*wy,x2,y2,Nx,Ny)
      # avoiding out of FOV issues
      y1 = bound_index(y1,Ny)
      y2 = bound_index(y2,Ny)
      x1 = bound_index(x1,Nx)
      x2 = bound_index(x2,Nx)
      # loading sparse matrix indexes
      li = int(lin_index(x,y,Nx))
      x1y1 = int(lin_index(x1,y1,Nx))
      x1y2 = int(lin_index(x1,y2,Nx))
      x2y1 = int(lin_index(x2,y1,Nx))
      x2y2 = int(lin_index(x2,y2,Nx))
      # assigning weights to sparse matrix
      if w11 != 0:
        sparse_mot[li,x1y1] = w11
      if w12 != 0:
        sparse_mot[li,x1y2] = w12
      if w21 != 0:
        sparse_mot[li,x2y1] = w21
      if w22 != 0:
        sparse_mot[li,x2y2] = w22

  return sparse_mot

#####################
# Key function !!!
#####################

# apply_sparse_motion takes a [Nx,Ny] image and a [Nx*Ny,Nx*Ny] spr_mat and applies
# the corresponding motion. adj_flag determines if the forward or transpose motion
# is applied (tranpose should be a good approximation of the inverse)
def apply_sparse_motion(img,spr_mat,adj_flag):
    # applies a motion field via the sparse representation
    Ny = np.shape(img)[1]
    Nx = np.shape(img)[0]
    img = np.reshape(img,(Nx*Ny,1),order='F')
    # flag == 1 means we apply transpose (i.e. inverse) motion
    if adj_flag == 1:
        spr_mat = spr_mat.transpose()
    # apply motion
    img_r = spr_mat * np.real(img)
    img_i = spr_mat * np.imag(img)
    # apply correction pertaining to errors in discrete interpolations with large jacobians
    m_norm = np.ones((Nx*Ny,1))
    m_norm = spr_mat * m_norm
    np.seterr(divide='ignore', invalid='ignore')
    img_r = np.divide(img_r,m_norm)
    img_i = np.divide(img_i,m_norm)
    # mind nans
    img_r = np.nan_to_num(img_r)
    img_i = np.nan_to_num(img_i)
    img = np.vectorize(complex)(img_r[:,0], img_i[:,0])
    img = np.reshape(img,(Nx,Ny),order='F')
    return img


if __name__ == "__main__":
    #######################
    ## MAIN for simple test
    #######################

    ### test small flow field
    q = np.zeros((2,3,2))
    # 1st pixel moves along x
    q[0,0,0] = 0.8
    q[0,0,1] = 0
    # 2nd pixel moves along y
    q[1,0,0] = 0
    q[1,0,1] = 0.2
    # 3rd pixel moves outside FOV
    q[0,1,0] = -10
    q[0,1,1] = -10
    # 4th pixel moves diag
    q[1,1,0] = -0.5
    q[1,1,1] = 0.5
    # 5th pixel does not move
    q[0,2,0] = 0
    q[0,2,1] = 0
    # 6th pixel moves backwards diagonally
    q[1,2,0] = -0.5
    q[1,2,1] = -1.2


    ### test small image
    w = np.zeros((2,3))
    w[0,0] = 1
    w[0,1] = 2
    w[0,2] = 3
    w[1,0] = 10
    w[1,1] = 20
    w[1,2] = 30

    asd = get_sparse_motion_matrix (q)
    imi = apply_sparse_motion(w,asd,1)
    asd2 = asd.transpose()

    print(type(q))
    print(q[:,:,0])
    print(q[:,:,1])
    print(type(asd))
    print(asd2.toarray()[:,:])
    print(type(w))
    print(w)
    print(type(imi))
    print(imi)