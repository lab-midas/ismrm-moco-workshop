function fEvalLineFWHM(SData, sSelectionType, hTexts)
%FEVALLINEFWHM Example line evaluation function calculating the FWHM.
%   Data is provided in struct SDATA containing fields sName and dData.
%   SSELECTIONTYPE represents imagine's slection type (modifier keys or
%   mouse buttons used) to enable different behaviour of the calculations
%   (e.g. avaraging). HTEXTS provides handles to uicontrol text elements in
%   the imagine GUI which can be used to ouput the results

iINTERPOLATIONFACTOR = 10; % For a more precise calculation ot the FWHM

if nargin < 2, sSelectionType = 'normal'; end

% -------------------------------------------------------------------------
% Check for presence of plot figure and create if necessary. This is
% optional.
hFEval = findobj('Type', 'figure', '-and', 'Name', 'Line Profile');
if isempty(hFEval)
    hFEval = figure(...
        'Units'                , 'centimeters', ...
        'Position'             , [1 1 20, 10], ...
        'Name'                 , 'Line Profile', ...
        'NumberTitle'          , 'off', ...
        'WindowStyle'          , 'normal');
    movegui(hFEval, 'center');
    axes('Parent'              , hFEval, ...
        'Box'                  , 'on', ...
        'ColorOrder'           , lines(length(SData)));
    set(get(gca, 'XLabel'), 'String', 'x [pixels]');
    set(get(gca, 'YLabel'), 'String', 'Intensity');
else
    figure(hFEval);
    hL = findobj(gca, 'Type', 'line');
    delete(hL);
    hold off
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Prepare table-like output in the console window
fprintf(1, '\nImage           |     FWHM [px]\n');
fprintf(1, '----------------+-----------------\n');

sName = char(ones(length(SData), 15)*32); % Initialize with blanks (32)

csLegend = {};

% -------------------------------------------------------------------------
% Loop over the line profiles
for iI = 1:length(SData)
    
    if isempty(SData(iI).dLineData), continue, end % Skip if empty
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Interpolation for better FWHM calculation
    dData = SData(iI).dLineData;
    iBins = (length(dData) - 1).*iINTERPOLATIONFACTOR + 1;
    dDataInt = interp1(dData, linspace(1, length(dData), iBins), 'cubic*');
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Plot the line profile and add name to legend
    plot(dData); hold all
    csLegend{iI} = SData(iI).sName;
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Make sure all names have same length (for table output
    iLength = length(SData(iI).sName);
    iLength = min(iLength, 15);
    sName(iI, 1:iLength) = SData(iI).sName(1:iLength);
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Calculate FWHM
    [dMax, iMaxPos] = max(dDataInt);
    dMin = min(dDataInt);
    dDiff5 = dDataInt(iMaxPos:-1:1) - 0.5*(dMax + dMin);
    iLowerHalfPos = iMaxPos - find(dDiff5 < 1, 1, 'first') + 1;
    dDiff5 = dDataInt(iMaxPos:end) - 0.5*(dMax + dMin);
    iUpperHalfPos = find(dDiff5 < 1, 1, 'first') + iMaxPos - 1;

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Print name and FWHM
    dFWHM = double(iUpperHalfPos - iLowerHalfPos)./double(iINTERPOLATIONFACTOR);
    if isempty(dFWHM), dFWHM = nan; end
    fprintf(1, '%s |    % 3.2f \n', sName(iI, :), dFWHM);
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if nargin > 2, set(hTexts(iI), 'String', sprintf('FWHM = %3.2f', dFWHM)); end
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
end % FOR loop
% -------------------------------------------------------------------------

legend(csLegend); % Show legend

% =========================================================================
% *** END OF FUNCTION fEvalLineFWHM
% =========================================================================