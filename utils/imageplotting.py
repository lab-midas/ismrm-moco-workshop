import matplotlib.pyplot as plt
import numpy as np
import medutils
from utils.mri import minmaxscale, maxscale


def plot_quiver(ax, flow, spacing, scale=1, margin=0, **kwargs):
    """Plots less dense quiver field.

    Args:
        ax: Matplotlib axis
        flow: motion vectors
        spacing: space (px) between each arrow in grid
        margin: width (px) of enclosing region without arrows
        kwargs: quiver kwargs (default: angles="xy", scale_units="xy")
    """
    h, w, *_ = flow.shape

    nx = int((w - 2 * margin) / spacing)
    ny = int((h - 2 * margin) / spacing)

    x = np.linspace(margin, w - margin - 1, nx, dtype=np.int64)
    y = np.linspace(margin, h - margin - 1, ny, dtype=np.int64)

    flow = flow[np.ix_(y, x)]
    u = scale * flow[:, :, 0]
    v = scale * flow[:, :, 1]

    kwargs = {**dict(angles="xy", scale_units="xy"), **kwargs}
    ax.quiver(x, y, u, v, **kwargs)

    ax.set_ylim(sorted(ax.get_ylim(), reverse=True))
    ax.set_aspect("equal")


def plot(img, flow=None, permorder=(2, 0, 1), title='', spacing=4, scale=5, figsize=None, **kwargs):
    # img        ndarray, list: to be plotted image or list of 2D images
    #            2D: single 2D image
    #            3D: third dimension is plotted side-by-side
    # flow       ndarray, list: to be plotted flow or list of 2D flows
    #            2D: [x, y, flowDir]
    #            3D: [x, y, slices, flowDir]
    #            flowDir being the x and y components of the flow
    # permorder  (rank > 2): move any dimension in the side-by-side plotting order
    # title      string, list of strings: plotting title
    # spacing    space (px) between each arrow in grid
    # scale      scale factor for flow vectors
    # figsize    figure size (width, height)
    # kwargs     quiver kwargs (default: angles="xy", scale_units="xy")

    if isinstance(img, list):
        img = [np.abs(x) for x in img]
        img = [maxscale(x) for x in img]
        img = np.stack(img, -1)

    if np.iscomplex(img).any():
        img = np.abs(img)

    Nmax = 8
    M = int(np.ceil(np.shape(img)[-1] / Nmax))
    if M > 1:
        N = int(Nmax)
    else:
        N = int(np.shape(img)[-1])

    if flow is None:
        if len(np.shape(img)) == 3:
            figsize = (40, 20) if figsize is None else figsize
            medutils.visualization.imshow(medutils.visualization.plot_array(np.transpose(img, permorder), M=M, N=N),
                                          title=title, figsize=figsize)
        else:
            figsize = (10, 10) if figsize is None else figsize
            medutils.visualization.imshow(img, title=title, figsize=figsize)
    else:
        if isinstance(flow, list):
            flow = np.stack(flow, -1)
        figsize = (10, 10) if figsize is None else figsize
        fig, axs = plt.subplots(M, N, figsize=(M * figsize[0], N * figsize[1]))
        # nvec = 20  # Number of vectors to be displayed along each image dimension
        # nl, nc, nd = img.shape
        # step = max(nl//nvec, nc//nvec)

        # y, x = np.mgrid[:nl:step, :nc:step]
        # u, v = flow[..., 0, :], flow[..., 1, :]
        # u_ = u[::step, ::step, :]
        # v_ = v[::step, ::step, :]
        for idx, ax in enumerate(axs):
            ax.imshow(img[..., idx], cmap='gray')
            if np.sum(flow[..., idx] > 0):
                plot_quiver(ax, flow[..., idx], spacing=spacing, scale=scale, color='y', **kwargs)
            # ax.quiver(x, y, u_[..., idx], v_[..., idx], color='y', units='dots',
            #     angles='xy', scale_units='xy', lw=3)
            ax.set_axis_off()
            if isinstance(title, list):
                ax.set_title(title[idx])
        plt.show()