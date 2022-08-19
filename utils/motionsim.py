import numpy as np
from utils.mri import mriForwardOp
import SimpleITK as sitk


def simulate_motion(img_cc, smaps, mask, p):
    # img_cc      motion-free coil-combined image
    # smaps       coil sensitivity maps
    # mask        k-space sampling mask
    # p           a) affine motion parameters (constant over time), 1x6
    #             b) affine motion course (time-dependent or time-constant), nPE x 6
    #             np.abs(p[:, :5]) > 0 = mask_motion; time points of phase-encoding steps
    #             at which motion parameters > 0 are defined, i.e. motion is happening

    kspace = mriForwardOp(img_cc, smaps, mask)
    p = np.asarray(p)
    tmp = np.unique(p, axis=0)
    if len(np.shape(p)) == 1:
        mask_motion = np.ones_like(kspace)
    else:
        mask_motion = np.abs(np.sum(p[:, :5], axis=1)) > 0
        mask_motion = np.tile(mask_motion[np.newaxis, :, np.newaxis], (np.shape(kspace)[0], 1, np.shape(kspace)[2]))

    if len(np.shape(p)) == 1 or np.shape(tmp[~np.all(tmp == 0, axis=1)])[0] == 1:  # constant motion over time
        if len(np.shape(p)) != 1:
            p = np.squeeze(tmp[~np.all(tmp == 0, axis=1)])
        kspace_motion = mriForwardOp(transform_img(img_cc, p), smaps, mask)
        return kspace * ( 1 -mask_motion) + kspace_motion * mask_motion, mask_motion
    else:  # time-dependent motion
        kspace_aff = np.zeros_like(kspace)
        for ky in np.arange(np.shape(img_cc)[1]):
            kspace_aff[:, ky, :] = mriForwardOp(transform_img(img_cc, p[ky, :]), smaps, mask)[:, ky, :]
        return kspace_aff, mask_motion


def transform_img(img, p):
    # img      input image to be transformed
    # p        affine transformation parameters
    #          3D (rank(img) == 3): t_x, t_y, t_z, \phi [°], \theta [°], \psi [°], G_{xy}, G_{xz}, G_{yz}, S_x, S_y, S_z
    #          2D (rank(img) == 2): t_x, t_y, \phi [°], G_{xy}, S_x, S_y
    # return   transformed image

    dim = len(np.shape(img))
    p = np.asarray(p, dtype='float')
    if dim == 2:  # 2D
        trans = affine_translate(p[0:2], dim)
        rotate = affine_rotate(p[2], dim, tuple(np.asarray(np.shape(img))/2))
        shear = affine_shear(p[3], dim)
        scale = affine_scale(p[4:], dim)
    else:
        trans = affine_translate(p[0:4], dim)
        rotate = affine_rotate(p[4:7], dim, tuple(np.asarray(np.shape(img))/2))
        shear = affine_shear(p[7:6], dim)
        scale = affine_scale(p[6:], dim)

    affine = sitk.CompositeTransform([trans, rotate, shear, scale])
    return resample(img, affine)


def affine_translate(p_trans, dim=2):
    transform = sitk.AffineTransform(dim)
    transform.SetTranslation(p_trans)
    return transform


def affine_scale(p_scale, dim=2):
    transform = sitk.AffineTransform(dim)
    matrix = np.array(transform.GetMatrix()).reshape((dim,dim))
    matrix[0,0] = p_scale[0]
    matrix[1,1] = p_scale[1]
    if dim == 3:
      matrix[2,2] = p_scale[2]
    transform.SetMatrix(matrix.ravel())
    return transform


def affine_rotate(p_rotate, dim=2, center=(0, 0)):
    #parameters = np.array(transform.GetParameters())
    transform = sitk.AffineTransform(dim)
    transform.SetCenter(center)
    matrix = np.array(transform.GetMatrix()).reshape((dim,dim))
    if dim == 2:
        radians = -np.pi * np.asarray(p_rotate) / 180.
        rotation = np.array([[np.cos(radians), -np.sin(radians)],[np.sin(radians), np.cos(radians)]])
        new_matrix = np.dot(rotation, matrix)
    else:
        phi = np.pi * np.asarray(p_rotate)[0] / 180.
        theta = np.pi * np.asarray(p_rotate)[1] / 180.
        psi = np.pi * np.asarray(p_rotate)[2] / 180.
        Rx = [[1,       0,          0],
            [0,   np.cos(phi),  np.sin(phi)],
            [0,  -np.sin(phi),  np.cos(phi)]]

        Ry = [[np.cos(theta),   0,   np.sin(theta)],
            [0,       1,       0],
            [-np.sin(theta),   0,   np.cos(theta)]]

        Rz = [[np.cos(psi),   np.sin(psi),   0],
            [-np.sin(psi),   np.cos(psi),   0],
            [0,           0,       1]]
        new_matrix = np.linalg.multi_dot([Rx, Ry, Rz, matrix])
    transform.SetMatrix(new_matrix.ravel())
    return transform


def affine_shear(p_shear, dim=2):
    transform = sitk.AffineTransform(dim)
    matrix = np.array(transform.GetMatrix()).reshape((dim,dim))
    p_shear = np.asarray(p_shear)
    if dim == 2:
        matrix[0,1] = p_shear
    else:
        matrix[0,1] = p_shear[0]
        matrix[0,2] = p_shear[1]
        matrix[1,2] = p_shear[2]
    transform.SetMatrix(matrix.ravel())
    return transform


def resample(image, transform, interpolator=sitk.sitkLinear, default_value=0.0):
    # Output image Origin, Spacing, Size, Direction are taken from the reference
    # image in this call to Resample
    if np.iscomplex(image).any():
        image = np.abs(image)
    imgin = sitk.GetImageFromArray(image)
    #interpolator = sitk.sitkCosineWindowedSinc
    #interpolator = sitk.sitkLinear
    imgres = sitk.GetArrayFromImage(sitk.Resample(image1=imgin, transform=transform, interpolator=interpolator, defaultPixelValue=default_value))
    if not np.shape(imgres) == np.shape(image):
        imgres = crop(imgres, np.shape(image))
    return imgres


# centered cropping
def crop(x, s):
    # x: input data
    # s: desired size
    if type(s) is not np.ndarray:
        s = np.asarray(s, dtype='f')

    if type(x) is not np.ndarray:
        x = np.asarray(x, dtype='f')

    m = np.asarray(np.shape(x), dtype='f')
    if len(m) < len(s):
        m = [m, np.ones(1, len(s) - len(m))]

    if np.sum(m == s) == len(m):
        return x

    idx = list()
    for n in range(np.size(s)):
        if np.remainder(s[n], 2) == 0:
            idx.append(list(np.arange(np.floor(m[n] / 2) + 1 + np.ceil(-s[n] / 2) - 1, np.floor(m[n] / 2) + np.ceil(s[n] / 2), dtype=np.int)))
        else:
            idx.append(list(np.arange(np.floor(m[n] / 2) + np.ceil(-s[n] / 2) - 1, np.floor(m[n] / 2) + np.ceil(s[n] / 2) - 1), dtype=np.int))

    index_arrays = np.ix_(*idx)
    return x[index_arrays]