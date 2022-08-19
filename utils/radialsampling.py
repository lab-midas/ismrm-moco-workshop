import numpy as np
#import scipy.io as sio
#import optopy.gpunufft as op
#import pysap
from mri.operators import NonCartesianFFT


def get_kpos(n_FE, n_spokes, RadProfOrder, start_angle):
    # n_FE = number of points along each radial spoke
    # n_spokes = number of radial spokes
    # RadProfOrder = string with either "GC" for golden angle or "GC_23deg" for tiny golden angle
    # start_angle = if you want to rotate the trajectory by some amount you can change the start_angle.
    #
    # Ouput is kpos containing k-space positions along x and y normalized from -0.5 to +0.5.

    # K - space values along each radial spoke
    # delta_kr = 1 / size(Data, 1);
    delta_kr = 1 / n_FE
    rad_pos = np.arange(-0.5, 0.5, delta_kr)  # :0.5 - delta_kr

    # Angles of different radial spokes
    if RadProfOrder == 'golden':  # golden angle
        RadialAngles = np.arange(0, n_spokes) * (np.pi / 180) * (180 * 0.618034)
        isalternated = 0

    elif RadProfOrder == 'tinygolden':  # Andreia Gaspar 02 / 08 / 2016 tiny golden angle
        RadialAngles = np.arange(0, n_spokes) * (np.pi / 180) * (180 * 0.1312674636)
        isalternated = 0

    else:  # linear order
        RadialAngles = np.arange(0, n_spokes) * (np.pi / n_spokes)
        # Flag indicating that each even radial line is sampled from +k_max to - k_max and each odd line is acquired from -k_max to + k_max
        isalternated = 1

    RadialAngles = RadialAngles + start_angle * np.pi / 180

    # Kpos has to be the same size as the FE, PE and SE dimension of MR.Data

    kpos = CalcTraj_2d_radial(rad_pos, RadialAngles, isalternated)

    return np.transpose(kpos, (2, 1, 0))  # tranpose to: _, num_spokes, num_readout


def CalcTraj_2d_radial(rad_pos, rad_angles, isalternated):
    # Calculate k - space trajectory for a 2D radial acquisition

    # rad_pos: K - space points along radial spokes
    # rad_angles: Angle values for each of the radial lines
    # isalternated: Flag indicating that each even radial line is sampled from +k_max to - k_max and each odd line is acquired from -k_max to + k_max

    rad_pos = np.asarray(rad_pos, dtype=np.float32)
    rad_angles = np.asarray(rad_angles, dtype=np.float32)
    kpos = np.zeros((np.shape(rad_pos)[0], np.shape(rad_angles)[0], 2))

    if isalternated:
        # Radius from -k_max to + k_max
        kpos[:, :, :][:, 0:-1:2, :][:, :, 0] = rad_pos[:, np.newaxis] * np.sin(rad_angles[0:-1:2])[:,
                                                                        np.newaxis].transpose()
        kpos[:, :, :][:, 0:-1:2, :][:, :, 1] = rad_pos[:, np.newaxis] * np.cos(rad_angles[0:-1:2])[:,
                                                                        np.newaxis].transpose()

        # Radius from +k_max to - k_max
        kpos[:, :, :][:, 1:-1:2, :][:, :, 0] = -rad_pos[:, np.newaxis] * np.sin(rad_angles[1:-1:2])[:,
                                                                         np.newaxis].transpose()
        kpos[:, :, :][:, 1:-1:2, :][:, :, 1] = -rad_pos[:, np.newaxis] * np.cos(rad_angles[1:-1:2])[:,
                                                                         np.newaxis].transpose()

    else:
        kpos[:, :, 1] = rad_pos[:, np.newaxis] * np.sin(rad_angles)[:, np.newaxis].transpose()
        kpos[:, :, 0] = rad_pos[:, np.newaxis] * np.cos(rad_angles)[:, np.newaxis].transpose()

    return kpos


def generateRadialTrajectory(Nread, Nspokes=1, kmax=0.5):
    """ Generate a radial trajectory
    :param Nread: number of readout steps
    :param Nspokes: number of spokes
    :param kmax: maximum k-space sampling frequency
    :return: complex-valued trajectory
    """
    tmp_trajectory = np.linspace(-1, 1, num=Nread, endpoint=False) * kmax
    trajectory = np.zeros((2, Nread, Nspokes))
    for n in range(Nspokes):
        phi = (np.mod(Nspokes, 2) + 1) * np.pi * n / Nspokes
        kx = np.cos(phi) * tmp_trajectory
        ky = np.sin(phi) * tmp_trajectory
        trajectory[0, :, n] = kx
        trajectory[1, :, n] = ky
    return trajectory
    # return trajectory[0] + 1j*trajectory[1]


def calc_radial_dcf(kpos, lens):
    """ This is suboptimal... Room for (a lot of) improvement. """
    dcf = []
    num_phases, _, num_spokes, num_readout = kpos.shape
    # num_readout, num_spokes, _ = kpos.shape
    # num_phases = 1
    for idx_bin in range(num_phases):
        dcf_idx = compute_radial_dcf(kpos[idx_bin])
        # print(np.max(dcf_idx), lens[idx_bin])
        dcf_idx = dcf_idx * num_readout * np.pi  # dirty hack... / (lens[idx_bin]) * 2 * np.pi # * num_readout #* 2.5 # correct with nyu trick?
        dcf.append(dcf_idx)
    dcf = np.ascontiguousarray(dcf)

    return dcf  # / np.max(dcf)


def compute_radial_dcf(Kpos):
    angles = np.degrees(np.arctan2(Kpos[1, ..., 0], Kpos[0, ..., 0])) + 180  # previously [1,...] [0,....]
    dcf = np.linspace(-0.5, 0.5, Kpos.shape[-1])
    dcf = np.tile(np.abs(dcf), [Kpos.shape[1], 1])

    idx = np.argsort(angles)
    sorted_angles = angles[idx]

    last_angle = sorted_angles[-1]
    first_angle = sorted_angles[0]

    angle_n = np.insert(sorted_angles[:-1], 0, last_angle - 360)
    angle_p = np.append(sorted_angles[1:], first_angle + 360)

    delta_p = np.abs(angle_p - sorted_angles)
    delta_n = np.abs(angle_n - sorted_angles)

    sorted_diff = 0.5 * np.radians(delta_p + delta_n)
    # dcf = np.maximum(dcf, 1e-9)
    dcf[idx] *= 0.5 * sorted_diff[:, np.newaxis] / np.pi

    return dcf.reshape((1, *dcf.shape))


def prepare_radial(acc, nRead, nSlices=1):
    """
    :param acc:         acceleration factor
    :param nRead:       number of readout steps
    :param nSlices:     number of slices
    :return:            radial trajectory, density compensation function
    """
    nyquist_spokes = np.round(np.pi / 2 * nRead)

    if acc > 1:
        n_spokes = int(np.round(nyquist_spokes / acc))
    else:
        n_spokes = int(nyquist_spokes)
    startangle = 0
    kpos = get_kpos(nRead, n_spokes, 'golden', startangle)
    dcf = compute_radial_dcf(kpos)
    dcf = dcf * nRead * np.pi

    kpos = np.tile(kpos.reshape(1, -1, nRead * n_spokes), (nSlices, 1, 1))
    dcf = np.tile(dcf.reshape(1, 1, nRead * n_spokes) / np.max(dcf), (nSlices, 1, 1))

    kpos = np.transpose(kpos[0, ...], (1, 0))
    #mask_rad = convert_locations_to_mask(kpos, (nRead, nRead))
    dcf = np.transpose(dcf[0, ...], (1, 0))
    return kpos, dcf


def subsample_radial(img_cart, smaps=None, acc=1, cphases=[0]):
    # return radial subsampled image

    # zero-pad to quadratic FOV
    maxsize = np.amax(np.shape(img_cart)[0:2])
    img_cart = zpad(img_cart, (maxsize, maxsize, np.shape(img_cart)[2], np.shape(img_cart)[3])).astype(np.complex64)

    nyquist_spokes = np.round(np.pi / 2 * maxsize)

    if acc > 1:
        n_spokes = int(np.round(nyquist_spokes / acc))
    else:
        n_spokes = int(nyquist_spokes)

    golden_angle = 180 * 0.618034
    if len(np.shape(img_cart) == 4):
        img_cart = img_cart[:, :, :, np.newaxis, :]

    nRO, _, nSlices, n_phases_img, ncoils = np.shape(img_cart)
    n_phases = len(cphases)
    if np.any(np.asarray(cphases) > n_phases_img):
        raise ValueError

    img = np.transpose(img_cart, (3, 4, 2, 0, 1)).copy().view()  # phase must be first to be c-contiguous

    startangle = 0
    img_rad = []
    if smaps is None:
        csm = np.ones((1, maxsize, maxsize))
    for ipha in cphases:  # range(n_phases):
        kpos = get_kpos(maxsize, n_spokes, 'golden', startangle)
        # kpos = generateRadialTrajectory(int(maxsize), int(n_spokes))
        # kpos_idx = np.transpose(kpos_idx,(0,2,1))

        # kpos_idx = kpos_idx[np.newaxis, :, :, :]  # phases x 2 x nSpokes x nRO -> required input of dcf
        # kpos.append(kpos_idx)

        dcf = compute_radial_dcf(kpos)
        dcf = dcf * nRO * np.pi

        kpos = np.tile(kpos.reshape(1, -1, maxsize * n_spokes), (nSlices, 1, 1))
        dcf = np.tile(dcf.reshape(1, 1, maxsize * n_spokes) / np.max(dcf), (nSlices, 1, 1))

        # nufft = op.GpuNufft(img_dim=maxsize, osf=1, kernel_width=3, sector_width=5)
        # nufft.setDcf(dcf.astype(np.float32))  # nBatch x 1 x nRO * nSpokes
        # nufft.setTraj(kpos.astype(np.float32))  # nBatch x 2 x nRO * nSpokes
        # nufft.setCsm(csm.astype(np.complex64))  # nCoils x nRO x nRO
        # out = nufft.adjoint(nufft.forward(img[ipha, ...].astype(np.complex64)))
        nufft = NonCartesianFFT(samples=kpos, shape=np.shape(img), n_coils=np.shape(csm)[0], density_comp=dcf,
                                smaps=csm)
        out = nufft.op(img)
        img_rad.append(out)

        startangle += golden_angle

    img_rad = np.transpose(np.ascontiguousarray(img_rad), (2, 3, 1, 0))  # nRO x nRO x nSlices x cPhases
    return img_rad