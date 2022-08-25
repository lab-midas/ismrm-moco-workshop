function fEvalROIMean(SData, hTexts)
%FEVALROIMEAN Example ROI evaluation function calculating mean and std.
%   Data is provided in struct SDATA containing fields sName and dData.
%   HTEXTS provides handles to uicontrol text elements in the imagine GUI
%   which can be used to ouput the results

% -------------------------------------------------------------------------
% Prepare table-like output in the console window
fprintf(1, '\nImage           |     mean     |    std\n');
fprintf(1,   '----------------+--------------+-------------\n');
% -------------------------------------------------------------------------

sName = char(ones(length(SData), 15)*32); % Initialize with blanks

% -------------------------------------------------------------------------
% Loop over the data
for iI = 1:length(SData)
    
    if isempty(SData(iI).dData), continue, end % Skip if empty
    
    % - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
    % Make sure all names have same length
    iLength = length(SData(iI).sName);
    iLength = min(iLength, 15);
    sName(iI, 1:iLength) = SData(iI).sName(1:iLength);
    % - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -

    % - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
    % Caluculate values and ouput to console.
    dMean = mean(SData(iI).dData(:));
    dStd = std(SData(iI).dData(:));
    fprintf(1, '%s |    % 3.2f    |   % 3.2f\n', sName(iI, :), dMean, dStd);
    % - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -

    % - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
    % If text handles supplied, ouput to the text elements in the main GUI.
    if nargin > 1, set(hTexts(iI), 'String', sprintf('Mean=%3.2f; STD=%3.2f\n', dMean, dStd)); end
    % - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
    
end % FOR loop
% -------------------------------------------------------------------------


% =========================================================================
% *** END OF FUNCTION fEvalROIMean
% =========================================================================