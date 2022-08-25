function dColormap = OptimalColor(iNBins)
%OPTIMALCOLORS Example custom colormap for use with imagine
%  DCOLORMAP = OPTIMALCOLOR(INBINS) returns a double colormap array of size
%  (INBINS, 3). Use this template to implement you own custom colormaps.
%  Imagine will interpret all m-files in this folder as potential colormap-
%  generating functions an list them using the filename.

% -------------------------------------------------------------------------
% Process input
if ~nargin, iNBins = 256; end
iNBins = uint16(iNBins);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create look-up tables (pairs of x- and y-vectors) for the three colors
dYRed = [0; 0.471; 0.471; 0.518; 0.518;   1;   1];
dXRed = [1;    31;    88;   100;   205; 254; 256];

dYGrn = [0;  0;   1;   1];
dXGrn = [1; 30; 132; 256];

dYBlu = [0;  0;   1;   1];
dXBlu = [1; 79; 181; 256];
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Interpolate and concatenate vectors to the final colormap
dRedInt = interp1(dXRed, dYRed, linspace(1, 255, iNBins)');
dGrnInt = interp1(dXGrn, dYGrn, linspace(1, 255, iNBins)');
dBluInt = interp1(dXBlu, dYBlu, linspace(1, 255, iNBins)');

dColormap = [dRedInt, dGrnInt, dBluInt];
% -------------------------------------------------------------------------

% =========================================================================
% *** END OF FUNCTION OptimalColor
% =========================================================================