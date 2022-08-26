function hImgAxes = imagine(varargin)
% IMAGINE IMAGe visualization, analysis and evaluation engINE
%
%   IMAGINE starts the IMAGINE user interface without initial data
%
%   IMAGINE(DATA) Starts the IMAGINE user interface with one (DATA is 3D)
%   or multiple panels (DATA is 4D).
%
%   IMAGINE(DATA, TITLE) Same functionality as above, however supplying a
%   caption for the data.
%
%   IMAGINE(DATA1, DATA2, ...) Starts the IMAGINE user interface with
%   multiple panels, where each input can be either a 3D- or 4D-array. No
%   captions can be supplied with this call.
%
%   IMAGINE(DATA1, TITLE1, DATA2, TITLE2, ...) Starts the IMAGINE user
%   interface with multiple panels, where each DATA input can be either a
%   3D- or 4D-array. Furthermore, captions for each input data array must
%   be supplied (data and titles must be supplied in pairs).
%
%   HA = IMAGINE(...) Starts the IMAGINE user interface and returns the
%   handles to the N axes created during startup. Thus, further plots can
%   be overlaid to the imagine axes such as quiver plots. You can use the
%   same comfortable zooming and windowing functions that imagine offers
%   in conjunction with a variety of MATLAB visualization features.
%   N depends on the number of input arguments and their dimension (just
%   like in during normal startup.
%   NOTE: Using this syntax, changing the amount of image panels
%   during run-time of imagine is not allowed (otherwise the handles HA
%   would become invalid).
%
% Example:
%
% 1. IMAGINE(DATA);
% where DATA is a numeric or logical 3D-array starts IMAGINE with one panel
% displaying DATA. If DATA is a 4D-array, the data is split in N 3D-arrays,
% where N = size(DATA, 4) and displayed in a sufficient number of panels.
%
% 2. IMAGINE(DATA, 'Titel');
% Same functionality as above, however, supplying a title for the data
% which is displayed in the GUI. If DATA is a 4D-array, the titles are
% extended by a running index.
%
% 3. HA = IMAGINE(DATA);
%    hold(HA(1), 'on';
%    quiver(quiverdata_x, quiverdata_y, ...);
% Overlays a quiver plot to the first axis in the IMAGINE UI.
%
% For more information about the IMAGINE functions refer to the user's
% guide file in the documentation folder supplied with the code.
%
% Copyright 2012-2013 Christian Wuerslin, University of Tuebingen and
% University of Stuttgart, Germany.
% Contact: christian.wuerslin@med.uni-tuebingen.de



% =========================================================================
% *** FUNCTION imagine
% ***
% *** Main GUI function. Creates the figure and all its contents and
% *** registers the callbacks.
% ***
% =========================================================================

% -------------------------------------------------------------------------
% Control the figure's appearence
SAp.sTITLE            = 'IMAGINE 1.4';        % Title of the figure
SAp.iICONSIZE         = 24;                   % Size if the icons
SAp.iICONPADDING      = SAp.iICONSIZE/2;      % Padding between icons
SAp.iMENUBARHEIGHT    = SAp.iICONSIZE*2;      % Height of the menubar
SAp.iTITLEBARHEIGHT   = 24;                   % Height of the titles (above each image)
SAp.iDISABLED_SCALE   = 0.2;                  % Brightness of disabled buttons (decrease to make darker)
SAp.iINACTIVE_SCALE   = 0.5;                  % Brightness of inactive buttons (toggle buttons and radio groups)
SAp.iTOOLBARWIDTH     = SAp.iICONSIZE*2;      % Width of the toolbar
SAp.iCOLORBARHEIGHT   = 12;                   % Height of the colorbar
SAp.iCOLORBARPADDING  = 80;                   % The space on the left and right of the colorbar for the min/max values
SAp.iEVALBARHEIGHT    = 24;                   % Height of the evaluation bar
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Sensitivity parameters that control mouse moving operations
SPref.dWINDOWSENSITIVITY    = 0.005;   % Defines mouse sensitivity for windowing operation
SPref.dZOOMSENSITIVITY      = 0.02;    % Defines mouse sensitivity for zooming operation
SPref.dROTATION_THRESHOLD   = 50;      % Defines the number of pixels the cursor has to move to rotate an image
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set some paths. Add the evalfunction path to the MATLAB path
SPref.sMFILEPATH    = fileparts(mfilename('fullpath'));                             % This is the path of this m-file
SPref.sICONPATH     = [SPref.sMFILEPATH, filesep, 'icons', filesep, '24', filesep]; % That's where the icons are
SPref.sSaveFilename = [SPref.sMFILEPATH, filesep, 'imagineSave.mat'];               % A .mat-file to save the GUI settings
addpath([SPref.sMFILEPATH, filesep, 'EvalFunctions']);                              % Add the path of the eval functions to the matlab path
addpath([SPref.sMFILEPATH, filesep, 'colormaps']);                              % Add the path of the custom colormaps
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create some default values
SState.dBGColor        = [0.15 0.25 0.35];
SState.iLastSeries     = 0;
SState.iStartSeries    = 1;
SState.sTool           = 'cursor_arrow';
SState.sPath           = [SPref.sMFILEPATH, filesep];
SState.sEvalLineFcn    = 'fEvalLineFWHM';
SState.sEvalROIFcn     = 'fEvalROIMean';
SState.iROIState       = 0;
SState.dROILineX       = [];
SState.dROILineY       = [];
SState.iPanels         = [1, 1];
SState.lShowColorbar   = true;
SState.lShowEvalbar    = true;

SData                  = [];    % A struct for hoding the data (image data + visualization parameters)
SImg                   = [];    % A struct for the image component handles
SLines                 = [];    % A struct for the line component handles
SMouse                 = [];    % A Struct to hold parameters of the mouse operations
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Get saved options from file
iPosition = [100 100 1000 600];
if exist(SPref.sSaveFilename, 'file')
    load(SPref.sSaveFilename);
    SState.sPath           = SSaveVar.sPath;
    SState.sEvalLineFcn    = SSaveVar.sEvalLineFcn;
    SState.sEvalROIFcn     = SSaveVar.sEvalROIFcn;
    SState.dBGColor        = SSaveVar.dBGColor;
    SState.lShowColorbar   = SSaveVar.lShowColorbar;
    SState.lShowEvalbar    = SSaveVar.lShowEvalbar;
    iPosition              = SSaveVar.iPosition;
        
    clear SSaveVar; % <- no one needs you anymore! :((
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% This is the definition of the menubar. If a radiobutton-like
% functionality is to implemented, the GroupIndex parameter of all
% icons within the group has to be set to the same positive integer
% value. Normal Buttons have group index -1, toggel switches have group
% index 0.
SPref.SMenubarItems = struct( ...
    'Name',        {'folder_open', 'save', 'spacer', 'doc_import', 'doc_delete', 'exchange', 'spacer', 'grid', 'colormap',            'colorbar',              'eval', 'reset', 'link', 'spacer', 'cogs'},...%, 'eye'}, ...
    'GroupIndex',  {           -1,     -1,       -1,           -1,           -1,         -1,       -1,     -1,         -1,                     0,                   0,      -1,      0,       -1,     -1},...%,    -1}, ...
    'Enabled',     {            1,      0,        0,            1,            0,          0,        1,      1,          1,                     1,                   1,       1,      1,        0,      1},...%,     1}, ...
    'Active',      {            0,      0,        0,            0,            0,          0,        0,      0,          0,  SState.lShowColorbar, SState.lShowEvalbar,       0,      1,        0,      0});%,     0});
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% The buttons in the toolbar. Toolbar behaves like a radiobutton group.
SPref.csToolbarItems =  {'cursor_arrow', 'rotate', 'line', 'roi', 'tag'};
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create the figure. Mouse scroll wheel is supported since Version 7.4 (I think).
try
    hF = figure(...
        'Position'             , iPosition, ...
        'Units'                , 'pixels', ...
        'Color'                , SState.dBGColor, ...
        'ResizeFcn'            , @fResizeFigure, ...
        'DockControls'         , 'off', ...
        'MenuBar'              , 'none', ...
        'Name'                 , SAp.sTITLE, ...
        'NumberTitle'          , 'off', ...
        'KeyPressFcn'          , @fKeyPressFcn, ...
        'CloseRequestFcn'      , @fCloseGUI, ...
        'WindowButtonDownFcn'  , @fWindowButtonDownFcn, ...
        'WindowButtonMotionFcn', @fWindowMouseHoverFcn, ...
        'WindowScrollWheelFcn' , @fWindowScrollWheelFcn);
catch %#ok<CTCH> Old MATLAB version: try again without mouse wheel!
%     fprintf(1, 'Warning: Old MATLAB version doesn''t support scroll wheel!\n');
    hF = figure(...
        'Position'             , iPosition, ...
        'Units'                , 'pixels', ...
        'Color'                , SState.dBGColor, ...
        'ResizeFcn'            , @fResizeFigure, ...
        'DockControls'         , 'off', ...
        'MenuBar'              , 'none', ...
        'Name'                 , SAp.sTITLE, ...
        'NumberTitle'          , 'off', ...
        'KeyPressFcn'          , @fKeyPressFcn, ...
        'CloseRequestFcn'      , @fCloseGUI, ...
        'WindowButtonDownFcn'  , @fWindowButtonDownFcn, ...
        'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
end
colormap(gray(256));
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Created object handles for the menubar. The bar itself is a uipanel. In
% the uipanel there are several axes that hold the images for the buttons.
% The callbacks that provide the functionality of the menubar buttos are
% registered the the image components. Finally, add a text element at the
% right end of the bar.
SPanels.hMenu = uipanel(... % Create the panel
    'Parent'                , hF , ...
    'BackgroundColor'       , 'k', ...
    'BorderWidth'           , 0  , ...
    'Units'                 , 'pixels');

SAxes.hMenu = zeros(length(SPref.SMenubarItems), 1);
SImg .hMenu = zeros(length(SPref.SMenubarItems), 1);
iStartPos = SAp.iTOOLBARWIDTH - SAp.iICONSIZE;
for iI = 1:length(SPref.SMenubarItems)
    iStartPos = iStartPos + SAp.iICONPADDING + SAp.iICONSIZE;
    if strcmp(SPref.SMenubarItems(iI).Name, 'spacer'), continue, end; % Skip the spacers
    
    iImage = imread([SPref.sICONPATH, SPref.SMenubarItems(iI).Name, '.png']); % icon file name (.png) has to be equal to icon name
    dImage = double(iImage(:,:,1));
    dImage = dImage./max(dImage(:));
    SUData = SPref.SMenubarItems(iI);
    SUData.dImg = repmat(dImage, [1 1 3]);
    SAxes.hMenu(iI) = axes(... % Create the Axes
        'Parent'    , SPanels.hMenu, ...
        'Units'     , 'pixels', ...
        'Position'  , [iStartPos SAp.iICONPADDING SAp.iICONSIZE SAp.iICONSIZE]);
    SImg.hMenu(iI) = image(SUData.dImg, ... % Create the images, here we don't need the handles.
        'Parent'        , SAxes.hMenu(iI), ...
        'ButtonDownFcn' , @fMenubarClick, ...
        'UserData'      , SUData);
    set(SAxes.hMenu(iI), 'UserData', SPref.SMenubarItems(iI).Name); % to identify the origin in function  fMenubarClick
    axis(SAxes.hMenu(iI), 'off');
end
SAxes.hMenu = SAxes.hMenu(SAxes.hMenu > 0); % array is to long if spacers are used -> crop the handles array
SImg .hMenu = SImg .hMenu(SImg .hMenu > 0); % array is to long if spacers are used -> crop the handles array
STexts.hStatus = uicontrol(... % Create the text element
    'Style'                 ,'Text', ...
    'Parent'                , SPanels.hMenu, ...
    'FontSize'              , 12, ...
    'FontWeight'            , 'bold', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'HorizontalAlignment'   , 'right', ...
    'Units', 'pixels'       , ...
    'Position'              , [0 SAp.iICONPADDING,  300, 22]);

clear iStartPos iPosition
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Created object handles for the toolbar. Again, the toolbar consists of a
% uipanel, and several axes containing images. 
SPanels.hTools = uipanel('Parent', hF, ... % Create the toolbar
    'BackgroundColor', 'k', ...
    'BorderWidth', 0, ...
    'Units', 'pixels');

SUData = [];
SAxes.hTools = zeros(length(SPref.csToolbarItems), 1);
for iI = 1:length(SPref.csToolbarItems)
    iImage = imread([SPref.sICONPATH, SPref.csToolbarItems{iI}, '.png']);  % icon file name (.png) has to be equal to tool name
    dImage = double(iImage(:,:,1));
    dImage = dImage./max(dImage(:));
    SUData.sName = SPref.csToolbarItems{iI};
    SUData.dImg = repmat(dImage, [1 1 3]);
    SAxes.hTools(iI) = axes(... % Create the axes
        'Parent'    , SPanels.hTools, ...
        'Units'     , 'pixels', ...
        'Position'  , [0 0 SAp.iICONSIZE SAp.iICONSIZE]);
    SImg.hTools(iI) = image(SUData.dImg, ... % Create the images
        'Parent'          , SAxes.hTools(iI), ...
        'ButtonDownFcn'   , @fToolbarClick, ...
        'UserData'        , SUData);
    axis(SAxes.hTools(iI), 'off');
end

clear iI iImage dImage SUData
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Parse Inputs and determine and create the initial amount of panels
SState.iPanels = fParseInputs(varargin);
fCreatePanels(SState.iPanels);
fFillPanels();
clear varargin; % <- no one needs you anymore! :((
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% If output axes handles is requested, disable ability to change the number
% of axes.
if nargout
    hImgAxes = SAxes.hImg;
    hGridImg = findobj(findobj(SPanels.hMenu, 'UserData', 'grid'), 'Type', 'image');
    SGridUData = get(hGridImg, 'UserData');
    SGridUData.Enabled = false;
    set(hGridImg, 'UserData', SGridUData);
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Update the figure components
fUpdateActivation(); % Acitvate/deactivate some buttons according to the gui state
fResizeFigure(hF, []); % Call the resize function to allign all the gui elements
drawnow expose

% -------------------------------------------------------------------------
% The 'end' of the IMAGINE main function. The real end is, of course, after
% all the nested functions. Using the nested functions, shared varaiables
% (the variables of the IMAGINE function) can be used which makes the usage
% of the 'guidata' commands obsolete.
% =========================================================================



    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fCloseGUI (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Closes the figure and saves the settings
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCloseGUI(hObject, eventdata) %#ok<*INUSD> eventdata is repeatedly unused
        % -----------------------------------------------------------------
        % Save the settings
        try %#ok<TRYNC>
            SSaveVar.sPath          = SState.sPath;
            SSaveVar.sEvalLineFcn   = SState.sEvalLineFcn;
            SSaveVar.sEvalROIFcn    = SState.sEvalROIFcn;
            SSaveVar.dBGColor       = SState.dBGColor;
            SSaveVar.lShowColorbar  = SState.lShowColorbar;
            SSaveVar.lShowEvalbar   = SState.lShowEvalbar;
            SSaveVar.iPosition      = get(hObject, 'Position');
            save(SPref.sSaveFilename, 'SSaveVar');
        end
        % -----------------------------------------------------------------
        
        delete(hObject); % Bye-bye figure
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCloseGUI
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fResizeFigure (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Re-arranges all the GUI elements after a figure resize
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fResizeFigure(hObject, eventdata)
        % -----------------------------------------------------------------
        % The resize callback is called very early, therefore we have to check
        % if the GUI elements were already created and return if not
        if ~isfield(SPanels, 'hImgFrame'), return, end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Get figure dimensions
        dFigureSize   = get(hF, 'Position');
        dFigureWidth  = dFigureSize(3);
        dFigureHeight = dFigureSize(4);
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Arrange the panels and all their contents
        dDrawPanelWidth  = (dFigureWidth  - SAp.iTOOLBARWIDTH)      / SState.iPanels(2);
        dDrawPanelHeight = (dFigureHeight - SAp.iMENUBARHEIGHT - 1) / SState.iPanels(1);
        for iM = 1:SState.iPanels(1)
            for iN = 1:SState.iPanels(2)
                iLinInd = (iM - 1).*SState.iPanels(2) + iN;
                iSeriesInd = iLinInd + SState.iStartSeries - 1;
                dWidth  = dDrawPanelWidth  - 1 - (iN == SState.iPanels(2));
                dHeight = dDrawPanelHeight - 1;
                set(SPanels.hImgFrame(iLinInd),  'Position', ...
                    [(iN - 1).*dDrawPanelWidth + 2 + SAp.iTOOLBARWIDTH, ...
                    (SState.iPanels(1) - iM).*dDrawPanelHeight + 2, dWidth, dHeight]);
                set(STexts.hImg1(iLinInd), 'Position', [10, dHeight - SAp.iTITLEBARHEIGHT + 2, dWidth - 85, 20]);
                set(STexts.hImg2(iLinInd), 'Position', [dWidth - 80, dHeight - SAp.iTITLEBARHEIGHT + 2, 70, 20]);
                if SState.lShowColorbar && dWidth > 2*SAp.iCOLORBARPADDING && iSeriesInd > 0 && iSeriesInd <= length(SData), 
                    set(SAxes.hColorbar(iLinInd), 'Position', [SAp.iCOLORBARPADDING, dHeight - SAp.iCOLORBARHEIGHT - SAp.iTITLEBARHEIGHT + 4, dWidth - 2*SAp.iCOLORBARPADDING, SAp.iCOLORBARHEIGHT - 3]);
                    set(SPanels.hImg(iLinInd), 'Position', [1, 1, dWidth, dHeight - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT]);
                    set(SImg.hColorbar(iLinInd), 'Visible', 'on');
                    set(STexts.hColorbarMin(iLinInd), 'Position', [5, dHeight - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT + 1, SAp.iCOLORBARPADDING - 10, 12]);
                    set(STexts.hColorbarMax(iLinInd), 'Position', [dWidth - SAp.iCOLORBARPADDING + 5, dHeight - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT + 1, SAp.iCOLORBARPADDING - 10, 12]);
                    set(STexts.hColorbarMin(iLinInd), 'Visible', 'on');
                    set(STexts.hColorbarMax(iLinInd), 'Visible', 'on');
                else
                    set(SPanels.hImg(iLinInd), 'Position', [1, 1, dWidth, dHeight - SAp.iTITLEBARHEIGHT]);
                    set(SImg.hColorbar(iLinInd), 'Visible', 'off');
                    set(STexts.hColorbarMin(iLinInd), 'Visible', 'off');
                    set(STexts.hColorbarMax(iLinInd), 'Visible', 'off');
                end
                if SState.lShowEvalbar
                    dPos = get(SPanels.hImg(iLinInd), 'Position');
                    dPos(2) = dPos(2) + SAp.iEVALBARHEIGHT;
                    dPos(4) = dPos(4) - SAp.iEVALBARHEIGHT;
                    set(SPanels.hImg(iLinInd), 'Position', dPos);
                    set(STexts.hEval, 'Visible', 'on', 'Position', [5, 1, dWidth - 100, 20]);
                    set(STexts.hVal, 'Visible', 'on', 'Position', [dWidth - 95, 1, 90, 20]);
                else
                    set(STexts.hEval, 'Visible', 'off');
                    set(STexts.hVal, 'Visible', 'off');
                end
                dDrawSize = get(SAxes.hImg(iLinInd), 'Position');
                if iSeriesInd <= length(SData)
                    set(SAxes.hImg(iLinInd), ...
                        'Position', [SData(iSeriesInd).dDrawCenter(1)*(dWidth)  - dDrawSize(3)/2, ...
                        SData(iSeriesInd).dDrawCenter(2)*(dHeight  - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT) - dDrawSize(4)/2, ...
                        dDrawSize(3), ...
                        dDrawSize(4)]);
                end
            end
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Arrange the menubar
        dPos = get(SAxes.hMenu(end), 'Position');
        dTextWidth = max([dFigureWidth - dPos(1) - dPos(3) - 5, 1]);
        set(SPanels.hMenu, 'Position', [1, dFigureHeight - SAp.iMENUBARHEIGHT + 1, dFigureWidth, SAp.iMENUBARHEIGHT]);
        set(STexts.hStatus, 'Position', [dFigureWidth - dTextWidth - 5, SAp.iICONPADDING, dTextWidth, 22]);
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Arrange the toolbar
        set(SPanels.hTools, 'Position', [1, 1, SAp.iTOOLBARWIDTH, dFigureHeight - SAp.iMENUBARHEIGHT]);
        iStartPos = dFigureHeight - SAp.iMENUBARHEIGHT - SAp.iICONPADDING - SAp.iICONSIZE;
        for i = 1:length(SAxes.hTools) % Unfortunately we have to rearrange all the icons to keep them on top :(
            set(SAxes.hTools(i), 'Position', [SAp.iICONPADDING, iStartPos, SAp.iICONSIZE, SAp.iICONSIZE]);
            iStartPos = iStartPos - SAp.iICONSIZE - SAp.iICONPADDING;
        end
        % -----------------------------------------------------------------

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fResizeFigure
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fMenubarClick (nested in imagine)
    % * * 
    % * * Common callback for all buttons in the menubar
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMenubarClick(hObject, eventdata)
        % -----------------------------------------------------------------
        % Get the source's (pressed buttton) data and exit if disabled
        SUData = get(hObject, 'UserData');
        if ~SUData.Enabled, return, end;
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Distinguish the idfferent button types (normal, toggle, radio)
        switch SUData.GroupIndex
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % NORMAL pushbuttons
            case -1

                switch(SUData.Name)
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % LOAD new FILES using file dialog
                    case 'folder_open'
                        [csFilenames, sPath] = uigetfile( ...
                            {'*.jpg;*.jpeg; *.JPG; *.JPEG', 'JPEG-Image (*.jpg)'; ...
                                '*.tif;*.tiff; *.TIF; *.TIFF;', 'TIFF-Image (*.tif)'; ...
                                '*.gif; *.GIF', 'Gif-Image (*.gif)'; ...
                                '*.bmp; *.BMP', 'Bitmaps (*.bmp)'; ...
                                '*.png; *.PNG', 'Portable Network Graphics (*.png)'; ...
                                '*.*', 'All Files'}, ...
                            'OpenLocation'  , SState.sPath, ...
                            'Multiselect'   , 'on');
                        if isnumeric(sPath), return, end;   % Dialog aborted
                        
                        SState.sPath = sPath;
                        SNewData = fLoadFiles(csFilenames);
                        SData = [SData, SNewData];
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Determine the NUMBER OF PANELS and their LAYOUT
                    case 'grid'
                        iPanels = fGridSelect(4, 4);
                        if ~sum(iPanels), return, end   % Dialog aborted
                        
                        fCreatePanels(iPanels); % also updates the SState.iPanels
                        fFillPanels();
                        fUpdateActivation();
                        fResizeFigure(hF, []);
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Select the COLORMAP
                    case 'colormap'
                        fColormapSelect(hF, STexts.hStatus);
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % IMPORT workspace (base) VARIABLE(S)
                    case 'doc_import'
                        csVars = fGetWorkspaceVar();
                        if isempty(csVars), return, end   % Dialog aborted
                        
                        for i = 1:length(csVars)
                            dVar = evalin('base', csVars{i});
                            fAddImageToData(dVar, csVars{i}, 'workspace');
                        end
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % DELETE DATA from structure
                    case 'doc_delete'
                        iSeriesInd = find([SData.lActive]); % Get indices of selected axes
                        iSeriesInd = iSeriesInd(iSeriesInd >= SState.iStartSeries);
                        SData(iSeriesInd) = []; % Delete the visible active data
                        fFillPanels();
                        fUpdateActivation(); % To make sure panels without data are not selected
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % SAVE panel data to file(s)
                    case 'save'
                        [sFilename, sPath] = uiputfile( ...
                               {'*.jpg', 'JPEG-Image (*.jpg)'; ...
                                '*.tif', 'TIFF-Image (*.tif)'; ...
                                '*.gif', 'Gif-Image (*.gif)'; ...
                                '*.bmp', 'Bitmaps (*.bmp)'; ...
                                '*.png', 'Portable Network Graphics (*.png)'}, ...
                                'Save selected series to files', ...
                                [SState.sPath, filesep, '%SeriesName%_%ImageNumber%']);
                        if isnumeric(sPath), return, end;   % Dialog aborted
                        
                        SState.sPath = sPath;
                        fSaveToFiles(sFilename, sPath);
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                        
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % EXCHANGE SERIES
                    case 'exchange'
                        iSeriesInd = find([SData.lActive]); % Get indices of selected axes
                        SData1 = SData(iSeriesInd(1));
                        SData(iSeriesInd(1)) = SData(iSeriesInd(2)); % Exchange the data
                        SData(iSeriesInd(2)) = SData1;
                        fFillPanels();
                        fUpdateActivation(); % To make sure panels without data are not selected
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % RESET the view (zoom/window/center)
                    case 'reset' % Reset the view properties of all data
                        for i = 1:length(SData)
                            SData(i).dZoomFactor = 1;
                            SData(i).dWindowCenter = 0.5;
                            SData(i).dWindowWidth = 1;
                            SData(i).dDrawCenter = [0.5 0.5];
                        end
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Bring up the PREFERENCES dialog
                    case 'cogs'
                        SDefaults.sEvalLineFcn = SState.sEvalLineFcn;
                        SDefaults.sEvalROIFcn  = SState.sEvalROIFcn;
                        SDefaults.dBGColor     = SState.dBGColor;
                        SSettings = fSettings(SDefaults);
                        if isempty(SSettings), return, end; % Dialog aborted

                        SState.sEvalLineFcn = SSettings.sEvalLineFcn;
                        SState.sEvalROIFcn  = SSettings.sEvalROIFcn;
                        SState.dBGColor     = SSettings.dBGColor;
                        set(hF, 'Color', SState.dBGColor);
                        fUpdateActivation(); % Updates the hImgFrame color
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    otherwise
                end
            % End of NORMAL buttons
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % TOGGLE buttons: Invert the state
            case 0
                SUData.Active = ~SUData.Active;
                set(hObject, 'UserData', SUData);
                fUpdateActivation();
                SState.lShowColorbar = fIsOn('colorbar');
                SState.lShowEvalbar = fIsOn('eval');
                fResizeFigure(hF, []);
            % End of TOGGLE buttons
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % RADIO buttons: Disable all other buttons in the same group
            otherwise
                for i = 1:length(SAxes.hMenu)
                    hI = findobj(SAxes.hMenu(i), 'Type', 'image');
                    SThisUData = get(hI, 'UserData');
                    if SThisUData.GroupIndex == SUData.GroupIndex
                        SThisUData.Active = strcmp(SThisUData.Tag, SUData.Tag);
                        set(hI, 'UserData', SThisUData);
                    end
                end
                fUpdateActivation();
            % End of RADIO buttons
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fMenubarClick
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fToolbarClick (nested in imagine)
    % * * 
    % * * Handle the radiobutton behaviour of the toolbar
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fToolbarClick(hObject, eventdata)
        SUData = get(hObject, 'UserData');
        if strcmp(SState.sTool, SUData.sName), return, end %If no tool-change, exit and do nothing

        % -----------------------------------------------------------------
        % Try to delete the lines of the ROI and line eval tools
        if isfield(SLines, 'hEval')
            try delete(SLines.hEval); end %#ok<TRYNC>
            SLines = rmfield(SLines, 'hEval');
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Reset the ROI painting state machine and Mouse callbacks
        SState.iROIState = 0;
        set(gcf, 'WindowButtonDownFcn'  , @fWindowButtonDownFcn);
        set(gcf, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
        set(gcf, 'WindowButtonUpFcn'    , '');
        % -----------------------------------------------------------------

        SState.sTool = SUData.sName; % Set active tool
        fUpdateActivation();
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fToolbarClick
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowMouseHoverFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * The standard mouse move callback. Displays cursor coordinates and
    % * * intensity value of corresponding pixel. The ROI tool is the only
    % * * tool that requires special actions when the mouse is moved
    % * * without a button pressed.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowMouseHoverFcn(hObject, eventdata)
        if ~isfield(SPanels, 'hImgFrame'), return, end; % Return if called during GUI startup
        
        iAxisInd = fGetPanel();
        if iAxisInd
            % -------------------------------------------------------------
            % Cusoris over a panel -> show coordinates and intensity
            iSeriesInd = SState.iStartSeries + iAxisInd - 1;
            iPos = uint16(get(SAxes.hImg(iAxisInd), 'CurrentPoint')); % Get cursor poition in axis coordinate system
            dImg = SData(iSeriesInd).dImg(:,:,SData(iSeriesInd).iActiveImage);
            if iPos(1, 1) > 0 && iPos(1, 2) > 0 && iPos(1, 1) <= size(dImg, 2) && iPos(1, 2) <= size(dImg, 1)
                dVal = dImg(iPos(1, 2), iPos(1, 1));
                if (dVal < 0.01) && (dVal > 0)
                    set(STexts.hStatus, 'Visible', 'on', 'String', sprintf('X =%4u, Y =%4u; Val: %1.1E', iPos(1, 1), iPos(1, 2), dVal));
                else
                    set(STexts.hStatus, 'Visible', 'on', 'String', sprintf('X =%4u, Y =%4u; Val: %3.2f', iPos(1, 1), iPos(1, 2), dVal));
                end
            else
                set(STexts.hStatus, 'Visible', 'off');
            end
            % -------------------------------------------------------------
            
            % -------------------------------------------------------------
            % If eval bar is active, show the values for all panels
            if SState.lShowEvalbar
                for i = 1:length(SPanels.hImgFrame)
                    iSeriesInd = SState.iStartSeries + i - 1;
                    if (iSeriesInd < 1) || (iSeriesInd > length(SData)), continue, end
                    dImg = SData(iSeriesInd).dImg(:,:,SData(iSeriesInd).iActiveImage);
                    if iPos(1, 1) > 0 && iPos(1, 2) > 0 && iPos(1, 1) <= size(dImg, 2) && iPos(1, 2) <= size(dImg, 1)
                        dVal = dImg(iPos(1, 2), iPos(1, 1));
                        if (dVal < 0.01) && (dVal > 0)
                            set(STexts.hVal(i), 'Visible', 'on', 'String', sprintf('%1.1E', dVal));
                        else
                            set(STexts.hVal(i), 'Visible', 'on', 'String', sprintf('%3.2f', dVal));
                        end
                    else
                        set(STexts.hVal(i), 'Visible', 'off');
                    end
                end
            end
            % -------------------------------------------------------------

            % -------------------------------------------------------------
            % Handle special case of ROI drawing (update the lines)
            if strcmp(SState.sTool, 'roi') && SState.iROIState == 1 % ROI drawing in progress
                dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                dROILineX = [SState.dROILineX; dPos(1, 1)]; % Draw a line to the cursor position
                dROILineY = [SState.dROILineY; dPos(1, 2)];
                set(SLines.hEval, 'XData', dROILineX, 'YData', dROILineY);
            end
            % -------------------------------------------------------------
        else
            % -------------------------------------------------------------
            % Cursor is not over a panel -> Check if tooltip has to be
            % shown
            iCursorPos = get(hF, 'CurrentPoint');
            sID = [];
            
            % -------------------------------------------------------------
            % Check if cursor is over a tool
            for i = 1:length(SAxes.hTools);
                dPos = get(SAxes.hTools(i), 'Position');
                if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                        (iCursorPos(2) >= dPos(2)) && (iCursorPos(2) < dPos(2) + dPos(4)))
                    sID = SPref.csToolbarItems{i};
                end
            end
            % -------------------------------------------------------------
            
            % -------------------------------------------------------------
            % Check of cursor is over a menubar item
            dFigureSize = get(hObject, 'Position');
            iCursorPos(2) = iCursorPos(2) - (dFigureSize(4) - SAp.iMENUBARHEIGHT);
            for i = 1:length(SAxes.hMenu)
                dPos = get(SAxes.hMenu(i), 'Position');
                if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                        (iCursorPos(2) >= dPos(2)) && (iCursorPos(2) < dPos(2) + dPos(4)))
                    sID = get(SAxes.hMenu(i), 'UserData');
                end
            end
            % -------------------------------------------------------------
            
            % -------------------------------------------------------------
            % Get the corresponding tooltip
            if ~isempty(sID)
                sTooltip = '';
                switch sID
                    case 'folder_open'      , sTooltip = 'Open File';
                    case 'doc_import'       , sTooltip = 'Import Workspace Variable';
                    case 'doc_delete'       , sTooltip = 'Delete Selected Panel Data';
                    case 'grid'             , sTooltip = 'Change Panel Layout';
                    case 'colormap'         , sTooltip = 'Change Colormap';
                    case 'colorbar'         , sTooltip = 'Show/Hide Colorbars';
                    case 'eval'             , sTooltip = 'Show/Hide Evaluation Bar';
                    case 'exchange'         , sTooltip = 'Exchange Panel Data';
                    case 'reset'            , sTooltip = 'Reset Zoom/Adjustment';
                    case 'link'             , sTooltip = 'Link Panels';
                    case 'cogs'             , sTooltip = 'Preferences';
                    case 'cursor_arrow'     , sTooltip = 'Move, Zoom, Adjust Brightness/Contrast';
                    case 'rotate'           , sTooltip = 'Rotate';
                    case 'line'             , sTooltip = 'Line Evaluation';
                    case 'roi'              , sTooltip = 'ROI Evaluation';
                    case 'tag'              , sTooltip = 'Rename';
                end
                set(STexts.hStatus, 'Visible', 'on', 'String', sTooltip);
            else
                set(STexts.hStatus, 'Visible', 'off');
            end
            % -------------------------------------------------------------
        end

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowMouseHoverFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowButtonDownFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Starting callback for mouse button actions.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowButtonDownFcn(hObject, eventdata)
        iPanelInd = fGetPanel();
        if ~iPanelInd, return, end % Exit if Event didn't occurr in a panel

        % -----------------------------------------------------------------
        % Save starting parameters
        SMouse.iStartAxis       = iPanelInd;
        SMouse.iStartPos        = get(hObject, 'CurrentPoint');
        dPos = get(SAxes.hImg(iPanelInd), 'CurrentPoint');
        SMouse.dAxesStartPos    = [dPos(1, 1), dPos(1, 2)];
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Backup the display settings of all data
        SMouse.dDrawCenter   = reshape([SData.dDrawCenter], [2, length(SData)]);
        SMouse.dZoomFactor   = [SData.dZoomFactor];
        SMouse.dWindowCenter = [SData.dWindowCenter];
        SMouse.dWindowWidth  = [SData.dWindowWidth];
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Delete existing line objects
        if isfield(SLines, 'hEval')
            try delete(SLines.hEval); end %#ok<TRYNC>
            SLines = rmfield(SLines, 'hEval');
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Activate the callbacks for drag operations
        set(hObject, 'WindowButtonUpFcn', @fWindowButtonUpFcn);
        set(hObject, 'WindowButtonMotionFcn', @fWindowMouseMoveFcn);
        % -----------------------------------------------------------------

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowButtonDownFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowMouseMoveFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Callback for mouse movement while button is pressed.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =    
    function fWindowMouseMoveFcn(hObject, eventdata)
        % -----------------------------------------------------------------
        % Get some frequently used values
        lLinked   = fIsOn('link'); % Determines whether axes are linked
        iD        = get(hF, 'CurrentPoint') - SMouse.iStartPos; % Mouse distance travelled since button down
        dPanelPos = get(SPanels.hImg(SMouse.iStartAxis), 'Position');
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Tool-specific code
        switch SState.sTool

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The NORMAL CURSOR: select, move, zoom, window
            case 'cursor_arrow'
                switch get(hF, 'SelectionType')

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Normal, left mouse button -> MOVE operation
                    case 'normal' 
                        dD = double(iD)./dPanelPos(3:4); % Scale mouse movement to panel size (since DrawCenter is a relative value)
                        for i = 1:length(SData)
                            if (~lLinked) && (i ~= SMouse.iStartAxis + SState.iStartSeries - 1), continue, end % Skip if axes not linked and current figure not active

                            iAxisInd = i - SState.iStartSeries + 1;
                            dNewPos = SMouse.dDrawCenter(:, i)' + dD; % Calculate new draw center relative to saved one
                            SData(i).dDrawCenter = dNewPos; % Save DrawCenter data

                            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels

                            dPos = get(SAxes.hImg(iAxisInd), 'Position');
                            set(SAxes.hImg(iAxisInd), 'Position', [dPanelPos(3)*(dNewPos(1)) - dPos(3)/2, dPanelPos(4)*(dNewPos(2)) - dPos(4)/2, dPos(3), dPos(4)]);
                        end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Shift key or right mouse button -> ZOOM operation
                    case 'alt'
                        fZoom(iD, dPanelPos);

                    case 'extend' % Control key or middle mouse button -> WINDOW operation
                        fWindow(iD);
                end
            % end of the NORMAL CURSOR
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The ROTATION tool
            case 'rotate'
                
                switch get(hObject, 'SelectionType')
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Normal, left mouse button -> ROTATION operation
                    case 'normal'
                        if ~any(abs(iD) > SPref.dROTATION_THRESHOLD), return, end   % Only proceed if action required
                        
                        for i = 1:length(SData)
                            if ~lLinked && i ~= iMouseStartAxis + iStartSeries - 1, continue, end % Skip if axes not linked and current figure not active
                            
                            if iD(1) > SPref.dROTATION_THRESHOLD % Moved mouse to left
                                set(hF, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                                SData(i).iActiveImage = uint16(SMouse.dAxesStartPos(1, 1));
                                SData(i).iImg = flipdim(permute(SData(i).iImg, [1 3 2]), 2);
                                SData(i).dImg = flipdim(permute(SData(i).dImg, [1 3 2]), 2); % Don't forget to rotate the original images as well
                            end
                            if iD(1) < -SPref.dROTATION_THRESHOLD % Moved mouse to right
                                set(hF, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                                SData(i).iActiveImage = uint16(size(SData(i).dImg, 2) - SMouse.dAxesStartPos(1, 1) + 1);
                                SData(i).iImg = flipdim(permute(SData(i).iImg, [1 3 2]), 3);
                                SData(i).dImg = flipdim(permute(SData(i).dImg, [1 3 2]), 3); % Don't forget to rotate the original images as well
                            end
                            if iD(2) > SPref.dROTATION_THRESHOLD
                                set(hF, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                                SData(i).iActiveImage = uint16(size(SData(i).dImg, 1) - SMouse.dAxesStartPos(1, 2) + 1);
                                SData(i).iImg = flipdim(permute(SData(i).iImg, [3 2 1]), 3);
                                SData(i).dImg = flipdim(permute(SData(i).dImg, [3 2 1]), 3); % Don't forget to rotate the original images as well
                            end
                            if iD(2) < -SPref.dROTATION_THRESHOLD
                                set(hF, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                                SData(i).iActiveImage = uint16(SMouse.dAxesStartPos(1, 2));
                                SData(i).iImg = flipdim(permute(SData(i).iImg, [3 2 1]), 1);
                                SData(i).dImg = flipdim(permute(SData(i).dImg, [3 2 1]), 1); % Don't forget to rotate the original images as well
                            end
                            
                            % - - - - - - - - - - - - - - - - - - - - - - -
                            % Limit active image range to image
                            % dimensions
                            if SData(i).iActiveImage < 1, SData(i).iActiveImage = 1; end
                            if SData(i).iActiveImage > size(SData(i).iImg, 3), SData(i).iActiveImage = size(SData(i).iImg, 3); end
                            fFillPanels();
                            % - - - - - - - - - - - - - - - - - - - - - - -
                            
                        end
                    % ROTATION operation
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Shift key or right mouse button -> zoom operation
                    case 'alt'
                        fZoom(iD, dPanelPos);
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Control key or middle mouse button -> window operation
                    case 'extend'
                        fWindow(iD);
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                end
            % of the rotate tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The LINE EVALUATION tool
            case 'line'
                dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                if ~isfield(SLines, 'hEval') % Make sure line object exists
                    for i = 1:length(SPanels.hImg)
                        SLines.hEval(i) = line([SMouse.dAxesStartPos(1, 1), dPos(1, 1)], [SMouse.dAxesStartPos(1, 2), dPos(1, 2)], ...
                            'Parent'        , SAxes.hImg(i), ...
                            'Color'         , SState.iColormap(i,:), ...
                            'LineStyle'     , '-.');
                    end
                else
                    set(SLines.hEval, 'XData', [SMouse.dAxesStartPos(1, 1), dPos(1, 1)], 'YData', [SMouse.dAxesStartPos(1, 2), dPos(1, 2)]);
                end
                fWindowMouseHoverFcn(hF, []); % Update the position display by triggering the mouse hover callback
            % end of the LINE EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            otherwise

        end
        % end of the TOOL switch statement
        % -----------------------------------------------------------------

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowButtonUpFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * End of mouse operations.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowButtonUpFcn(hObject, eventdata)
        iCursorPos = get(hF, 'CurrentPoint');

        % -----------------------------------------------------------------
        % Stop the operation by disabling the corresponding callbacks
        set(hF, 'WindowButtonMotionFcn'    ,@fWindowMouseHoverFcn);
        set(hF, 'WindowButtonUpFcn'        ,'');
        set(STexts.hStatus, 'Visible', 'off');
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Tool-specific code
        switch SState.sTool
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The NORMAL CURSOR: select, move, zoom, window
            % In this function, only the select case has to be handled
            case 'cursor_arrow'
                if ~sum(abs(iCursorPos - SMouse.iStartPos)) % Proceed only if mouse was moved
                    
                    switch get(hF, 'SelectionType')
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        % NORMAL selection: Select only current series
                        case 'normal'
                            iN = fGetNActiveVisibleSeries();
                            for iSeries = 1:length(SData)
                                if SMouse.iStartAxis + SState.iStartSeries - 1 == iSeries
                                    SData(iSeries).lActive = ~SData(iSeries).lActive || iN > 1;
                                else
                                    SData(iSeries).lActive = false;
                                end
                            end
                            SState.iLastSeries = SMouse.iStartAxis + SState.iStartSeries - 1; % The lastAxis is needed for the shift-click operation
                        % end of normal selection
                        % - - - - - - - - - - - - - - - - - - - - - - - - -

                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        %  Shift key or right mouse button: Select ALL axes
                        %  between last selected axis and current axis
                        case 'extend'
                            iSeriesInd = SMouse.iStartAxis + SState.iStartSeries - 1;
                            if sum([SData.lActive] == true) == 0
                                % If no panel active, only select the current axis
                                SData(iSeriesInd).lActive = true;
                                SState.iLastSeries = iSeriesInd;
                            else
                                if SState.iLastSeries ~= iSeriesInd
                                    iSortedInd = sort([SState.iLastSeries, iSeriesInd], 'ascend');
                                    for i = 1:length(SData)
                                        SData(i).lActive = (i >= iSortedInd(1)) && (i <= iSortedInd(2));
                                    end
                                end
                            end
                        % end of shift key/right mouse button
                        % - - - - - - - - - - - - - - - - - - - - - - - - -

                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Cntl key or middle mouse button: ADD/REMOVE axis
                        % from selection
                        case 'alt'
                            iSeriesInd = SMouse.iStartAxis + SState.iStartSeries - 1;
                            SData(iSeriesInd).lActive = ~SData(iSeriesInd).lActive;
                            SState.iLastSeries = iSeriesInd;
                        % end of alt/middle mouse buttton
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    end
                end
            % end of the NORMAL CURSOR
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The LINE EVALUATION tool
            case 'line'
                dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                dXEnd = dPos(1,1);
                dYEnd = dPos(1,2);
                dXStart = SMouse.dAxesStartPos(1,1);
                dYStart = SMouse.dAxesStartPos(1,2);
                iDist = round(sqrt((dXStart - dXEnd).^2 + (dYStart - dYEnd).^2));
                
                if ~iDist, return, end % In case of a misclick
                
                SEvalData = struct('sName', '<no data>', 'dLineData', cell(length(SPanels.hImg), 1));
                for i = 1:length(SPanels.hImg)
                    iSeriesInd = i + SState.iStartSeries - 1;
                    if iSeriesInd <= length(SData)
                        SEvalData(i).sName     = SData(iSeriesInd).sName;
                        SEvalData(i).dLineData = improfile(SData(iSeriesInd).dImg(:, :, SData(iSeriesInd).iActiveImage), [dXStart dXEnd], [dYStart, dYEnd], round(iDist), 'bicubic');
                    end
                end
                sSelectionType = get(hObject, 'SelectionType'); %#ok<NASGU> Can be used in eval functions
                eval([SState.sEvalLineFcn, '(SEvalData, sSelectionType, STexts.hEval);']);
            % End of the LINE EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The ROI EVALUATION tool
            case 'roi'
                dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                switch get(hF, 'SelectionType')
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % NORMAL selection: Add point to roi
                    case 'normal'
                        if ~SState.iROIState % This is the first polygon point
                            SState.dROILineX = dPos(1, 1);
                            SState.dROILineY = dPos(1, 2);
                            for i = 1:length(SPanels.hImg)
                                SLines.hEval(i) = line(SState.dROILineX, SState.dROILineY, ...
                                    'Parent'    , SAxes.hImg(i), ...
                                    'Color'     , SState.iColormap(i,:),...
                                    'LineStyle' , '--');
                            end
                            SState.iROIState = 1;
                            set(hF, 'WindowButtonDownFcn'  , ''); % Disable the button down function
                            set(hF, 'WindowButtonUpFcn'    ,@fWindowButtonUpFcn); % But keep the button up function
                        else % Add point to existing polygone
                            SState.dROILineX = [SState.dROILineX; dPos(1, 1)];
                            SState.dROILineY = [SState.dROILineY; dPos(1, 2)];
                            set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                            set(hF, 'WindowButtonUpFcn', @fWindowButtonUpFcn); % Keep the button up function
                        end
                    % End of NORMAL selection
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Right mouse button/shift key: UNDO last point, quit
                    % if is no point remains
                    case 'alt'
                        if ~SState.iROIState, return, end    % Only perform action if painting in progress

                        if length(SState.dROILineX) > 1
                            SState.dROILineX = SState.dROILineX(1:end-1); % Delete last point
                            SState.dROILineY = SState.dROILineY(1:end-1);
                            dROILineX = [SState.dROILineX; dPos(1, 1)]; % But draw line to current cursor position
                            dROILineY = [SState.dROILineY; dPos(1, 2)];
                            set(SLines.hEval, 'XData', dROILineX, 'YData', dROILineY);
                            set(hF, 'WindowButtonUpFcn', @fWindowButtonUpFcn); % Keep the button up function
                        else % Abort drawing ROI
                            SState.iROIState = 0;
                            delete(SLines.hEval);
                            SLines = rmfield(SLines, 'hEval');
                            set(hF, 'WindowButtonDownFcn', @fWindowButtonDownFcn); % Disable the button down function
                        end
                    % End of right click/shift-click
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - - 

                    % Middle mouse button/double-click/cntl-click: CLOSE
                    % POLYGONE and quit roi action
                    case {'extend', 'open'} % Middle mouse button or double-click -> 
                        if ~SState.iROIState, return, end    % Only perform action if painting in progress

                        SState.dROILineX = [SState.dROILineX; SState.dROILineX(1)]; % Close line
                        SState.dROILineY = [SState.dROILineY; SState.dROILineY(1)];
                        set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);

                        SEvalData = struct('sName', '<no data>', 'dData', cell(length(SPanels.hImg), 1)); % Prepare data for evaluation function
                        for i = 1:length(SPanels.hImg)
                            iSeriesInd = i + SState.iStartSeries - 1;
                            if iSeriesInd <= length(SData)
                                lMask = poly2mask(SState.dROILineX, SState.dROILineY, size(SData(iSeriesInd).iImg, 1), size(SData(iSeriesInd).iImg, 2));
                                SEvalData(i).sName = SData(iSeriesInd).sName;
                                dImg = SData(iSeriesInd).dImg(:,:,SData(iSeriesInd).iActiveImage);
                                SEvalData(i).dData = dImg(lMask);
                                SEvalData(i).lMask = lMask;
                            end
                        end
                        eval([SState.sEvalROIFcn, '(SEvalData, STexts.hEval);']);

                        SState.iROIState = 0;
                        set(hF, 'WindowButtonDownFcn', @fWindowButtonDownFcn);
                    % End of middle mouse button/double-click/cntl-click
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                end
            % End of the ROI EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The TAG tool: Rename the data
            case 'tag'
                iAxisInd = fGetPanel();
                if ~iAxisInd, return, end % quit if not over a panel
                
                iSeriesInd = SState.iStartSeries + iAxisInd - 1;
                sName = SData(iSeriesInd).sName;
                sString = inputdlg('Change Series Name:', sprintf('Change %s', sName), 1, {sName});
                if isempty(sString), return, end
                SData(iSeriesInd).sName = sString{1};
                set(STexts.hImg1(iAxisInd), 'String', ['[', int2str(iSeriesInd), ']: ', sString{1}]);
            % End of the TAG tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            otherwise

        end
        % end of the tool switch-statement
        % -----------------------------------------------------------------

        fUpdateActivation();
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowButtonUpFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

	
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowScrollWheelFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Handle the mouse scroll wheel.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowScrollWheelFcn(hObject, eventdata) %#ok<INUSL> % Don't use ~ for the sake of backwards compatibility
        % -----------------------------------------------------------------
        % Determine the axis and return of not over any
        iAxisInd = fGetPanel();
        if ~iAxisInd, return, end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Loopover all data (visible or not)
        for iSeriesInd = 1:length(SData)
            if (~fIsOn('link')) && (iSeriesInd ~= iAxisInd + SState.iStartSeries - 1), continue, end % Skip if axes not linked and mouse not over this panel

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new image index and make sure it's not out of bounds
            iNewImgInd = SData(iSeriesInd).iActiveImage + eventdata.VerticalScrollCount;
            iNewImgInd = max([iNewImgInd, 1]);
            iNewImgInd = min([iNewImgInd, size(SData(iSeriesInd).iImg, 3)]);
            SData(iSeriesInd).iActiveImage = iNewImgInd;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Update corresponding axes if necessary (visible)
            iAxisInd = iSeriesInd - SState.iStartSeries + 1;
            if (iAxisInd) > 0 && (iAxisInd <= length(SPanels.hImgFrame))
                set(SImg.hImg(iAxisInd), 'CData', SData(iSeriesInd).iImg(:,:,iNewImgInd));
                set(STexts.hImg2(iAxisInd), 'String', sprintf('%u/%u', iNewImgInd, size(SData(iSeriesInd).iImg, 3)));
            end
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        end
        % -----------------------------------------------------------------

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowScrollWheelFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fKeyPressFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Callback for keyboard actions.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fKeyPressFcn(hObject, eventdata) %#ok<INUSL> % Don't use ~ for the sake of backwards compatibility
        
        hA = 0;
        
        % -----------------------------------------------------------------
        % Get the modifier (shift, cntl, alt) keys and determine whether
        % the control key was presed
        csModifier = eventdata.Modifier;
        lControl = false;
        for i = 1:length(csModifier)
            if strcmp(csModifier{i}, 'control'), lControl = true; end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Start button evaluation
        if lControl
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % If key combination involves the control key, menubar actions
            % are called. Simply get the handle of the corresponding button
            % axes and call the menubar callback with the handle argument.
            switch eventdata.Key
                case 'o', hA = findobj(SPanels.hMenu, 'UserData', 'folder_open');   % Open files
                case 'i', hA = findobj(SPanels.hMenu, 'UserData', 'doc_import');    % Import WS variable
                case 'x', hA = findobj(SPanels.hMenu, 'UserData', 'exchange');      % Exchange
                case '0', hA = findobj(SPanels.hMenu, 'UserData', 'reset');         % Reset view
                case 'l', hA = findobj(SPanels.hMenu, 'UserData', 'link');          % Link panels
                case 'p', hA = findobj(SPanels.hMenu, 'UserData', 'cogs');          % Preferences
            end % Callback is called at the end of the function.
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
        else
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % If control key not pressed
            switch eventdata.Key
                case 'delete', hA = findobj(SPanels.hMenu, 'UserData', 'doc_delete');

                case {'numpad1', 'leftarrow'} % Image up
                    fChangeImage(-1);

                case {'numpad2', 'rightarrow'} % Image down
                    fChangeImage(1);

                case {'numpad4', 'uparrow'} % Series up
                    SState.iStartSeries = max([1 SState.iStartSeries - 1]);
                    fFillPanels();
                    fUpdateActivation();

                case {'numpad5', 'downarrow'} % Series down
                    SState.iStartSeries = min([SState.iStartSeries + 1 length(SData)]);
                    fFillPanels();
                    fUpdateActivation();

                case 'm' % Switch to arrow tool
                    SState.sTool = 'cursor_arrow';
                    fUpdateActivation();

                case 'l' % Switch to line tool
                    SState.sTool = 'line';
                    fUpdateActivation();

                case 'r' % Switch to rotate tool
                    SState.sTool = 'rotate';
                    fUpdateActivation();

                case 'o' % Switch to roi tool
                    SState.sTool = 'roi';
                    fUpdateActivation();

                case 't' % Switch to tag tool
                    SState.sTool = 'tag';
                    fUpdateActivation();

                otherwise
                    return
                    
            end % switch
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % If action is a menubar item, call the menubar callback with the
        % corresponding axes handle as argument
        if hA
            hI = findobj(hA, 'Type', 'image');
            fMenubarClick(hI, []);
        end
        % -----------------------------------------------------------------
        
        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fKeyPressFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fChangeImage (nested in imagine)
    % * * 
    % * * Change image index of all series (if linked) or all selected
    % * * series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fChangeImage(iCnt)
        % -----------------------------------------------------------------
        % Loopover all data (visible or not)
        for iSeriesInd = 1:length(SData)
            if (~fIsOn('link')) && (~SData(iSeriesInd).lActive), continue, end % Skip if axes not linked and current figure not active
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new image index and make sure it's not out of bounds
            iNewImgInd = SData(iSeriesInd).iActiveImage + iCnt;
            iNewImgInd = max([iNewImgInd, 1]);
            iNewImgInd = min([iNewImgInd, size(SData(iSeriesInd).iImg, 3)]);
            SData(iSeriesInd).iActiveImage = iNewImgInd;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Update corresponding axes if necessary (visible)
            iAxisInd = iSeriesInd - SState.iStartSeries + 1;
            if (iAxisInd) > 0 && (iAxisInd <= length(SPanels.hImgFrame))         % Update Corresponding Axis
                set(SImg.hImg(iAxisInd), 'CData', SData(iSeriesInd).iImg(:,:,iNewImgInd));
                set(STexts.hImg2(iAxisInd), 'String', sprintf('%u/%u', iNewImgInd, size(SData(iSeriesInd).iImg, 3)));
            end
        end
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fChangeImage
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fSaveToFiles (nested in imagine)
    % * * 
    % * * Save image data of selected panels to file(s)
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =    
    function fSaveToFiles(sFilename, sPath)
        
        for iSeriesInd = 1:length(SData)
            if ~SData(iSeriesInd).lActive, continue, end
            
            sSeriesFilename = strrep(sFilename, '%SeriesName%', SData(iSeriesInd).sName);
            dImg = double(SData(iSeriesInd).iImg);
            dWinMin = 255*SData(iSeriesInd).dWindowCenter - max([255*SData(iSeriesInd).dWindowWidth/2, 1]);
            dWinMax = 255*SData(iSeriesInd).dWindowCenter + max([255*SData(iSeriesInd).dWindowWidth/2, 1]);

            dImg = dImg - dWinMin;
            dImg(dImg < 0) = 0;
            dImg = dImg.*255./dWinMax;
            dImg(dImg > 255) = 255;
            for iImgInd = 1:size(SData(iSeriesInd).iImg, 3)
                sImgFilename = strrep(sSeriesFilename, '%ImageNumber%', sprintf('%03u', iImgInd));
                imwrite(uint8(dImg(:,:,iImgInd)), [sPath, filesep, sImgFilename]);
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fSaveToFiles
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fLoadFiles (nested in imagine)
    % * * 
    % * * Load image files from disk and sort into series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =    
    function SNewData = fLoadFiles(csFilenames)
        if ~iscell(csFilenames)
            csFilenames = {csFilenames};
        end
        iInd = strfind(csFilenames{1}, '.');

        sExt = csFilenames{1}(iInd(end) + 1:end);

        switch lower(sExt)
            case {'jpg', 'jpeg', 'tif', 'tiff', 'gif', 'bmp', 'png'}
                SNewData = [];
                for i = 1:length(csFilenames)
                    try
                        iImg = imread([SState.sPath, csFilenames{i}]);
                    catch %#ok<CTCH>
                        disp(['Error when loading "', SState.sPath, csFilenames{i}, '": File extenstion and type do not match']);
                        continue;
                    end
                    iImg = iImg(:,:,1);
                    iInd = fServesSizeCriterion(size(iImg), SNewData);
                    if iInd
                        iImg = cat(3, SNewData(iInd).iImg, iImg);
                        SNewData(iInd).dImg = iImg;
                    else
                        iLength = length(SNewData) + 1;
                        SNewData(iLength).dImg = iImg;
                        SNewData(iLength).sOrigin = 'Image File';
                        SNewData(iLength).sName = [SState.sPath, csFilenames{i}];
                    end
                end

            otherwise

        end
        for i = 1:length(SNewData)
            [iImg, dScale] = fIm2uint8(SNewData(i).dImg);
            SNewData(i).dScale = dScale;
            SNewData(i).iImg = iImg;
            SNewData(i).dWindowCenter = 0.5;
            SNewData(i).dWindowWidth  = 1;
            SNewData(i).dZoomFactor = 1;
            SNewData(i).dDrawCenter = [0.5 0.5];
            SNewData(i).iActiveImage = 1;
            SNewData(i).lActive = false;
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fLoadFiles
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fFillPanels (nested in imagine)
    % * *
    % * * Display the current data in all panels.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fFillPanels
        iSeriesInd = SState.iStartSeries;
        for i = 1:length(SPanels.hImgFrame)
            if iSeriesInd <= length(SData)
                iImg = SData(iSeriesInd).iImg(:,:,SData(iSeriesInd).iActiveImage);
                set(SImg.hImg(i), 'CData', iImg);
                dXDim = size(iImg, 2);
                dYDim = size(iImg, 1);
                dPos = get(SPanels.hImg(i), 'Position');
                set(SAxes.hImg(i), 'Position', [SData(iSeriesInd).dDrawCenter(1)*dPos(3) - ...
                    dXDim.*SData(iSeriesInd).dZoomFactor/2, ...
                    SData(iSeriesInd).dDrawCenter(2)*dPos(4) - dYDim.*SData(iSeriesInd).dZoomFactor/2, ...
                    dXDim.*SData(iSeriesInd).dZoomFactor, ...
                    dYDim.*SData(iSeriesInd).dZoomFactor], ...
                    'XLim'    , [0.5 dXDim + 0.5], ...
                    'YLim'    , [0.5 dYDim + 0.5]);
                set(STexts.hImg1(i), 'String', ['[', int2str(iSeriesInd), ']: ', SData(iSeriesInd).sName]);
                set(STexts.hImg2(i), 'String', sprintf('%u/%u', SData(iSeriesInd).iActiveImage, size(SData(iSeriesInd).iImg, 3)));
                iWinMin = round(255*SData(iSeriesInd).dWindowCenter - 255*SData(iSeriesInd).dWindowWidth/2);
                iWinMax = round(255*SData(iSeriesInd).dWindowCenter + 255*SData(iSeriesInd).dWindowWidth/2);
                set(SAxes.hImg(i), 'CLim', [iWinMin iWinMax]);
                set(SPanels.hImg(i), 'Visible', 'on');
            else
                set(SPanels.hImg(i), 'Visible', 'off');
                set(STexts.hImg1(i), 'String', '<no data>');
                set(STexts.hImg2(i), 'String', '');
            end
            iSeriesInd = iSeriesInd + 1;
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fFillPanels
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fCreatePanels (nested in imagine)
    % * *
    % * * Create the panels and its child object.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCreatePanels(iSize)
        % -----------------------------------------------------------------
        % Delete panels and their handles if necessary
        if isfield(SPanels, 'hImgFrame')
            delete(SPanels.hImgFrame); % Deletes hImgFrame and its children
            SPanels = rmfield(SPanels, {'hImgFrame', 'hImg'});
            STexts  = rmfield(STexts,  {'hImg1', 'hImg2', 'hColorbarMin', 'hColorbarMax','hEval', 'hVal'});
            SAxes   = rmfield(SAxes,   {'hImg', 'hColorbar'});
            SImg    = rmfield(SImg,    {'hImg', 'hColorbar'});
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % For each panel create panels, axis, image and text objects
        for i = 1:(iSize(1)*iSize(2));
            SPanels.hImgFrame(i) = uipanel(...
                'Parent'                , hF, ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'BorderWidth'           , 0, ...
                'BorderType'            , 'line', ...
                'Units'                 , 'pixels');
            STexts.hImg1(i) = uicontrol(...
                'Style'                 , 'text', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'left', ...
                'FontSize'              , 12, ...
                'FontName'              , 'FixedWidth', ...
                'String'                , '');
            STexts.hImg2(i) = uicontrol(...
                'Style'                 , 'text', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'right', ...
                'FontSize'              , 12, ...
                'FontName'              , 'FixedWidth', ...
                'String'                , '');
            SPanels.hImg(i) = uipanel(...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , 'k', ...
                'BorderWidth'           , 0, ...
                'Units'                 , 'pixels');
            SAxes.hImg(i) = axes(...
                'Parent'                , SPanels.hImg(i), ...
                'Units'                 , 'pixels', ...
                'Position'              , [10 10 10 10]);
            SImg.hImg(i) = image(zeros(1, 'uint8'), ...
                'Parent'                , SAxes.hImg(i), ...
                'CDataMapping'          , 'scaled');
            SAxes.hColorbar(i) = axes(...
                'Parent'                , SPanels.hImgFrame(i), ...
                'Units'                 , 'pixels', ...
                'Position'              , [10 30 20 128]);
            SImg.hColorbar(i) = image(uint8(0:255), ...
                'Parent'                , SAxes.hColorbar(i));
            STexts.hColorbarMin(i) = uicontrol(...
                'Style'                 , 'text', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'right', ...
                'FontSize'              , 8, ...
                'FontName'              , 'FixedWidth', ...
                'String'                , 'Min');
            STexts.hColorbarMax(i) = uicontrol(...
                'Style'                 , 'text', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'left', ...
                'FontSize'              , 8, ...
                'FontName'              , 'FixedWidth', ...
                'String'                , 'Max');
            STexts.hEval(i) = uicontrol(...
                'Style'                 , 'text', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'left', ...
                'FontSize'              , 12, ...
                'FontName'              , 'FixedWidth', ...
                'String'                , '');
            STexts.hVal(i) = uicontrol(...
                'Style'                 , 'text', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dBGColor*0.6, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'right', ...
                'FontSize'              , 12, ...
                'FontName'              , 'FixedWidth', ...
                'String'                , '');
            axis(SAxes.hImg(i), 'off');
            axis(SAxes.hColorbar(i), 'off');
            
            iDataInd = i + SState.iStartSeries - 1;
            if (iDataInd > 0) && (iDataInd <= length(SData))
                dRealCenter = (SData(iDataInd).dScale(2) - SData(iDataInd).dScale(1)).* SData(iDataInd).dWindowCenter - SData(iDataInd).dScale(1);
                dRealWidth  = (SData(iDataInd).dScale(2) - SData(iDataInd).dScale(1)).* SData(iDataInd).dWindowWidth;

                dMin = dRealCenter - dRealWidth./2;
                if (abs(dMin) < 0.01) && (dMin ~= 0), set(STexts.hColorbarMin(i), 'String', sprintf('%1.1E', dMin));
                else                                  set(STexts.hColorbarMin(i), 'String', sprintf('%4.0f', dMin)); end

                dMax = dRealCenter + dRealWidth./2;
                if (abs(dMax) < 0.01) && (dMax ~= 0), set(STexts.hColorbarMax(i), 'String', sprintf('%1.1E', dMax));
                else                                  set(STexts.hColorbarMax(i), 'String', sprintf('%4.0f', dMax)); end
            end
            
        end % of loop over pannels
        % -----------------------------------------------------------------
  
        SState.iColormap = lines(i);
        SState.iPanels   = iSize;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCreatePanels
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fUpdateActivation (nested in imagine)
    % * *
    % * * Set the activation and availability of some switches according to
    % * * the GUI state.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fUpdateActivation

        % -----------------------------------------------------------------
        % Update states of some menubar buttons according to panel selection
        hA = findobj(SPanels.hMenu, 'UserData', 'save');
        hI = findobj(hA, 'Type', 'image');
        SUData = get(hI, 'UserData');
        SUData.Enabled = fGetNActiveVisibleSeries() > 0;
        set(hI, 'UserData', SUData);
        
        hA = findobj(SPanels.hMenu, 'UserData', 'doc_delete');
        hI = findobj(hA, 'Type', 'image');
        SUData = get(hI, 'UserData');
        SUData.Enabled = fGetNActiveVisibleSeries() > 0;
        set(hI, 'UserData', SUData);
        
        hA = findobj(SPanels.hMenu, 'UserData', 'exchange');
        hI = findobj(hA, 'Type', 'image');
        lEnabled = fGetNActiveVisibleSeries() == 2;
        SUData = get(hI, 'UserData');
        SUData.Enabled = lEnabled;
        set(hI, 'UserData', SUData);
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Treat the menubar items
        for i = 1:length(SAxes.hMenu)
            SUData = get(SImg.hMenu(i), 'UserData');
            if SUData.GroupIndex == -1 % Normal Buttons
                if SUData.Enabled
                    set(SImg.hMenu(i), 'CData', SUData.dImg);
                else
                    set(SImg.hMenu(i), 'CData', SUData.dImg.*SAp.iDISABLED_SCALE);
                end
            else %  Toggle Buttons
                if SUData.Enabled
                    if SUData.Active
                        set(SImg.hMenu(i), 'CData', SUData.dImg);
                    else
                        set(SImg.hMenu(i), 'CData', SUData.dImg.*SAp.iINACTIVE_SCALE);
                    end
                else
                    set(SImg.hMenu(i), 'CData', SUData.dImg.*SAp.iDISABLED_SCALE);
                end
            end
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Treat the toolbar items (radiogroup)
        for i = 1:length(SAxes.hTools)
            hI = findobj(SAxes.hTools(i), 'Type', 'image');
            SUData = get(hI, 'UserData');
            if strcmp(SUData.sName, SState.sTool);
                set(SImg.hTools(i), 'CData', SUData.dImg);
            else
                set(SImg.hTools(i), 'CData', SUData.dImg.*SAp.iINACTIVE_SCALE);
            end
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Treat the panels
        for i = 1:length(SPanels.hImgFrame)
            iSeriesInd = i + SState.iStartSeries - 1;
            if iSeriesInd > length(SData)
                set([SPanels.hImgFrame(i), STexts.hImg1(i), STexts.hImg2(i)], 'BackgroundColor', SState.dBGColor*0.6);
                continue
            end
            
            if SData(iSeriesInd).lActive
                set([SPanels.hImgFrame(i), STexts.hImg1(i), STexts.hImg2(i), STexts.hColorbarMin(i), STexts.hColorbarMax(i), STexts.hEval(i)], 'BackgroundColor', SState.dBGColor);
            else
                set([SPanels.hImgFrame(i), STexts.hImg1(i), STexts.hImg2(i), STexts.hColorbarMin(i), STexts.hColorbarMax(i), STexts.hEval(i)], 'BackgroundColor', SState.dBGColor*0.6);
            end
        end
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fUpdateActivation
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetNActiveVisibleSeries (nested in imagine)
    % * *
    % * * Returns the number of visible active series.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iNActiveSeries = fGetNActiveVisibleSeries()
        if isempty(SData)
            iNActiveSeries = 0;
        else
            iStartInd = SState.iStartSeries;
            iEndInd = min([iStartInd + length(SPanels.hImgFrame) - 1, length(SData)]);
            lActiveSeries = [SData(iStartInd:iEndInd).lActive];
            iNActiveSeries = sum(lActiveSeries == true);
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetNActiveVisibleSeries
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fParseInputs (nested in imagine)
    % * *
    % * * Parse the varargin input variable. It can be either pairs of
    % * * data/captions or just data. Data can be either 2D, 3D or 4D.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iPanels = fParseInputs(cInput)        
        if isempty(cInput)
            iPanels = [1, 1];
            return
        end

        sMode = 'DataOnly';
        if length(cInput) > 1
            if ischar(cInput{2}), sMode = 'DataName'; end % Input is given in pairs of data and title
        end

        switch sMode
            case 'DataOnly'
                for i = 1:length(cInput)
                    fAddImageToData(cInput{i}, sprintf('User Input %02u', i), 'startup');
                end

            case 'DataName'
                for i = 1:floor(length(cInput)/2)
                    if ~ischar(cInput{i * 2}), error('Input data must be pairs of image and name'); end
                    fAddImageToData(cInput{i * 2 - 1}, cInput{i * 2}, 'startup');
                end
        end

        iNumImages = length(SData);
        dRoot = sqrt(iNumImages);
        iPanelsN = ceil(dRoot);
        iPanelsM = ceil(dRoot);
        while iPanelsN*iPanelsM >= iNumImages
            iPanelsN = iPanelsN - 1;
        end
        iPanelsN = iPanelsN + 1;
        iPanelsN = min([4, iPanelsN]);
        iPanelsM = min([4, iPanelsM]);
        iPanels = [iPanelsN, iPanelsM];
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fParseInputs
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fAddImageToData (nested in imagine)
    % * *
    % * * Add image data to the global SDATA variable. Can handle 2D, 3D or
    % * * 4D data.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fAddImageToData(dImage, sName, sOrigin)
        if islogical(dImage), dImage = ones(size(dImage)).*dImage; end
        if ~isreal(dImage), dImage = abs(dImage); end
        dImage = double(dImage);
        iInd = length(SData) + 1;
        for i = 1:size(dImage, 4)
            SData(iInd).dImg = dImage(:,:,:,i);
            [iImg, dScale] = fIm2uint8(dImage(:,:,:,i));
            SData(iInd).iImg = iImg;
            SData(iInd).dScale = dScale;
            SData(iInd).sOrigin = sOrigin;
            SData(iInd).dWindowCenter = 0.5;
            SData(iInd).dWindowWidth  = 1;
            SData(iInd).dZoomFactor = 1;
            SData(iInd).dDrawCenter = [0.5 0.5];
            SData(iInd).iActiveImage = 1;
            SData(iInd).lActive = false;
            if size(dImage, 4) > 1
                SData(iInd).sName = sprintf([sName, '_%02u'], i);
            else
                SData(iInd).sName = sName;
            end
            iInd = iInd + 1;
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fAddImageToData
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fIm2uint8 (nested in imagine)
    % * *
    % * * Converts an input image to uint8 and scales to full dynamic range
    % * * [0..255]. Also returns the original dynamic range in the
    % * * additional output argument dScale.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function [iFOut, dScale] = fIm2uint8(dFIn)
        % FIM2UINT8 convert data to uint8 format and scale for full dynamic range
        dFOut = double(dFIn);
        dScale(1) = min(dFOut(:));
        dScale(2) = max(dFOut(:));
        dFOut = dFOut - dScale(1);
        dFOut = dFOut./max(dFOut(:)).*255;
        iFOut = uint8(round(dFOut));
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fIm2uint8
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetPanel (nested in imagine)
    % * *
    % * * Determine the panelnumber under the mouse cursor. Returns 0 if
    % * * not over a panel at all.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iPanelInd = fGetPanel()
        iCursorPos = get(hF, 'CurrentPoint');
        iPanelInd = uint8(0);
        for i = 1:min([length(SPanels.hImgFrame), length(SData) - SState.iStartSeries + 1])
            dPos = get(SPanels.hImgFrame(i), 'Position');
            if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                    (iCursorPos(2) >= dPos(2)) && (iCursorPos(2) < dPos(2) + dPos(4)))
                iPanelInd = uint8(i);
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetPanel
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fServesSizeCriterion (nested in imagine)
    % * *
    % * * Determines, whether the data structure contains an image series
    % * * with the same x- and y-dimensions as iSize
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iInd = fServesSizeCriterion(iSize, SNewData)
        iInd = 0;
        for i = 1:length(SNewData)
            if (iSize(1) == size(SNewData(i).iImg, 1)) && ...
                    (iSize(2) == size(SNewData(i).iImg, 2))
                iInd = i;
                return;
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fServesSizeCriterion
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fZoom (nested in imagine)
    % * *
    % * * Zoom images
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fZoom(iD, dPanelPos)
        for i = 1:length(SData)
            if (~fIsOn('link')) && i ~= (SMouse.iStartAxis + SState.iStartSeries - 1), continue, end % Skip if axes not linked and current figure not active
            
            iAxisInd = i - SState.iStartSeries + 1;
                        
            dZoomFactor = max([0.25, SMouse.dZoomFactor(i).*exp(SPref.dZOOMSENSITIVITY.*iD(2))]);
            dZoomFactor = min([dZoomFactor, 100]);
            
            dStaticCoordinate = SMouse.dAxesStartPos - 0.5;
            dStaticCoordinate(2) = size(SData(i).iImg, 1) - dStaticCoordinate(2);
            iFramePos = get(SPanels.hImgFrame(SMouse.iStartAxis), 'Position');
            dStaticPoint = SMouse.iStartPos - iFramePos(1:2);
            if SState.lShowEvalbar, dStaticPoint(2) = dStaticPoint(2) - SAp.iEVALBARHEIGHT; end;
            
            dStartPoint = dStaticPoint - (dStaticCoordinate).*dZoomFactor + [1.5 1.5];
            dEndPoint   = dStaticPoint + ([size(SData(i).iImg, 2), size(SData(i).iImg, 1)] - dStaticCoordinate).*dZoomFactor + [1.5 1.5];
            
            SData(i).dDrawCenter = (dEndPoint + dStartPoint)./(2.*dPanelPos(3:4)); % Save Draw Center
            SData(i).dZoomFactor = dZoomFactor; % Save ZoomFactor data
            
            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels

            dImageWidth  = double(size(SData(i).iImg, 2)).*dZoomFactor;
            dImageHeight = double(size(SData(i).iImg, 1)).*dZoomFactor;
            set(SAxes.hImg(iAxisInd), 'Position', [dPanelPos(3).*SData(i).dDrawCenter(1) - dImageWidth/2, ...
                dPanelPos(4).*SData(i).dDrawCenter(2) - dImageHeight/2, ...
                dImageWidth, dImageHeight]);
            if iAxisInd == SMouse.iStartAxis % Show zooming information for the starting axis
                set(STexts.hStatus, 'Visible', 'on', 'String', sprintf('Zoom: %3.1fx', dZoomFactor));
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fZoom
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fWindow (nested in imagine)
    % * *
    % * * Window an image (that is radiology slang for
    % * * "adjust contrast and brightness")
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindow(iD)
        for i = 1:length(SData)
            if (~fIsOn('link')) && (i ~= SMouse.iStartAxis + SState.iStartSeries - 1), continue, end % Skip if axes not linked and current figure not active

            SData(i).dWindowWidth = max([0.001 SMouse.dWindowWidth(i).*exp(SPref.dWINDOWSENSITIVITY*(-iD(2)))]);
            SData(i).dWindowCenter = SMouse.dWindowCenter(i) + SPref.dWINDOWSENSITIVITY*iD(1);
            iAxisInd = i - SState.iStartSeries + 1;
            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels)

            iWinMin = round(255*SData(i).dWindowCenter - max([255*SData(i).dWindowWidth/2, 1]));
            iWinMax = round(255*SData(i).dWindowCenter + max([255*SData(i).dWindowWidth/2, 1]));
            set(SAxes.hImg(iAxisInd), 'CLim', [iWinMin iWinMax]);
            
            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels
            
            dRealCenter = (SData(i).dScale(2) - SData(i).dScale(1)).* SData(i).dWindowCenter - SData(i).dScale(1);
            dRealWidth  = (SData(i).dScale(2) - SData(i).dScale(1)).* SData(i).dWindowWidth;
            
            dMin = dRealCenter - dRealWidth./2;
            if (abs(dMin) < 0.01) && (dMin ~= 0), set(STexts.hColorbarMin(iAxisInd), 'String', sprintf('%1.1E', dMin));
            else                                  set(STexts.hColorbarMin(iAxisInd), 'String', sprintf('%4.0f', dMin)); end
            
            dMax = dRealCenter + dRealWidth./2;
            if (abs(dMax) < 0.01) && (dMax ~= 0), set(STexts.hColorbarMax(iAxisInd), 'String', sprintf('%1.1E', dMax));
            else                                  set(STexts.hColorbarMax(iAxisInd), 'String', sprintf('%4.0f', dMax)); end
            
        
            if iAxisInd == SMouse.iStartAxis % Show windowing information for the starting axes
                set(STexts.hStatus, 'Visible', 'on', 'String', sprintf('C: %4.0f, W: %4.0f', dRealCenter, dRealWidth));
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindow
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fIsOn (nested in imagine)
    % * *
    % * * Determine whether togglebutton is active
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function lOn = fIsOn(sTag)
        hA = findobj(SPanels.hMenu, 'UserData', sTag);
        hI = findobj(hA, 'Type', 'image');
        SUData = get(hI, 'UserData');
        lOn = SUData.Active;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fIsOn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


end
% =========================================================================
% *** END FUNCTION imagine (and its nested functions)
% =========================================================================




% #########################################################################
% ***
% ***   Helper GUIS and their callbacks
% ***
% #########################################################################


% =========================================================================
% *** FUNCTION fGridSelect
% ***
% *** Creates a tiny GUI to select the GUI layout, i.e. the number of
% *** panels and the grid dimensions.
% ***
% =========================================================================
function iSizeOut = fGridSelect(iM, iN)

iAXESSIZE = 30;
iSizeOut = [0 0];

% -------------------------------------------------------------------------
% Create a new figure at the current mouse pointer position
iPos = get(0, 'PointerLocation');
iHeight = iAXESSIZE*iM;
iWidth  = iAXESSIZE*iN;
hGridFig = figure(...
    'Position'             , [iPos(1), iPos(2) - iHeight, iWidth, iHeight], ...
    'Units'                , 'pixels', ...
    'Color'                , [0.5 0.5 0.5], ...
    'DockControls'         , 'off', ...
    'WindowStyle'          , 'modal', ...
    'Name'                 , '', ...
    'WindowButtonMotionFcn', @fMouseMoveFcn, ...
    'WindowButtonDownFcn'  , 'uiresume(gcbf)', ... % continues the execution of this function after the uiwait when the mousebutton is pressed
    'NumberTitle'          , 'off', ...
    'Resize'               , 'off');

colormap gray
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create MxN axes/images for the visualization
hA = zeros(iM, iN);
hI = zeros(iM, iN);
for iI = 1:iM
    for iJ = 1:iN
        hA(iI, iJ) = axes(...
            'Units'     , 'pixels', ...
            'Position'  , [(iJ - 1)*iAXESSIZE + 2, (iM - iI)*iAXESSIZE + 2, iAXESSIZE-2, iAXESSIZE-2], ...
            'Parent'    , hGridFig, ...
            'Color'     , 'w', ...
            'XLim'      , [0.5 1.5], ...
            'YLim'      , [0.5 1.5], ...
            'CLim'      , [0 1]);
        
        hI(iI, iJ) = image(ones(1), ...
            'Parent'        ,  hA(iI, iJ), ...
            'CDataMapping'  , 'scaled');
        
        axis(hA(iI, iJ), 'off');
    end
end
set(hA, 'CLim', [0 1]);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Handle GUI interaction
uiwait(hGridFig); % Wait until the uiresume function is called (happens when mouse button is pressed, see creation of the figure above)
try % Button was pressed, return the amount of selected panels
    delete(hGridFig); % close the figure
catch %#ok<CTCH> % if figure could not be deleted (dialog aborted), return [0 0]
    iSizeOut = [0 0];
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fMouseMoveFcn (nested in fGridSelect)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMouseMoveFcn(hObject, eventdata)
        dCursorPos = get(hGridFig, 'CurrentPoint'); % The mouse pointer
        dPos       = get(hGridFig, 'Position');     % The figure dimensions

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Determine over which axes the mouse pointer is located
        i = ceil((dPos(4) - dCursorPos(2))/iAXESSIZE);
        j = ceil(dCursorPos(1)/iAXESSIZE);
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Update the axes's colors to visualize the current selection
        for n = 1:size(hA, 1)
            for m = 1:size(hA, 2)
                if (i >= n) && (j >= m)
                    set(hI(n, m), 'CData', 0);
                else
                    set(hI(n, m), 'CData', 1);
                end
            end
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        iSizeOut = [i, j]; % Update output variable
        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGridMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

end
% =========================================================================
% *** END FUNCTION fGridSelect (and its nested functions)
% =========================================================================



% =========================================================================
% *** FUNCTION fColormapSelect
% ***
% *** Creates a tiny GUI to select the colormap.
% ***
% =========================================================================
function fColormapSelect(hF, hText)

iWIDTH = 128;
iBARHEIGHT = 32;

% -------------------------------------------------------------------------
% List the MATLAB built-in colormaps
csColormaps = {'gray', 'bone', 'copper', 'pink', 'hot', 'jet', 'hsv', 'spring', 'summer', 'autumn', 'winter', 'cool'};
iNColormaps = length(csColormaps);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Add custom colormaps (if any)
sColormapPath = [fileparts(mfilename('fullpath')), filesep, 'colormaps'];
SDir = dir([sColormapPath, filesep, '*.m']);
for iI = 1:length(SDir)
    iNColormaps = iNColormaps + 1;
    [sPath, sName] = fileparts(SDir(iI).name);
    csColormaps{iNColormaps} = sName;
end
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
% Create a new figure at the current mouse pointer position
iPos = get(0, 'PointerLocation');
iHeight = iNColormaps.*iBARHEIGHT;
hColormapFig = figure(...
    'Position'             , [iPos(1), iPos(2) - iHeight, iWIDTH, iHeight], ...
    'Units'                , 'pixels', ...
    'DockControls'         , 'off', ...
    'WindowStyle'          , 'modal', ...
    'Name'                 , '', ...
    'WindowButtonMotionFcn', @fColormapMouseMoveFcn, ...
    'WindowButtonDownFcn'  , 'uiresume(gcbf)', ... % continues the execution of this function after the uiwait when the mousebutton is pressed
    'NumberTitle'          , 'off', ...
    'Resize'               , 'off');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Make the true-color image with the colormaps
dImg = zeros(iNColormaps, iWIDTH, 3);
dLine = zeros(iWIDTH, 3);
for iI = 1:iNColormaps
    eval(['dLine = ', csColormaps{iI}, '(iWIDTH);']);
    dImg(iI, :, :) = permute(dLine, [3, 1, 2]);
end

% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create axes and image for selection
hA = axes(...
    'Units'     , 'pixels', ...
    'Position'  , [1, 1, iWIDTH, iHeight], ...
    'Parent'    , hColormapFig, ...
    'Color'     , 'w', ...
    'XLim'      , [0.5 128.5], ...
    'YLim'      , [0.5 length(csColormaps) + 0.5]);

hI = image(dImg, 'Parent',  hA);

axis(hA, 'off');
set(hA, 'CLim', [0 1]);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Handle GUI interaction
iLastInd = 0;
uiwait(hColormapFig); % Wait until the uiresume function is called (happens when mouse button is pressed, see creation of the figure above)
try % Button was pressed, return the amount of selected panels
    delete(hColormapFig); % close the figure
catch %#ok<CTCH> % if figure could not be deleted (dialog aborted), return [0 0]
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fColormapMouseMoveFcn (nested in fColormapSelect)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fColormapMouseMoveFcn(hObject, eventdata)
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Determine over which colormap the mouse pointer is located
        dPos = get(hA, 'CurrentPoint');
        iInd = round(dPos(1, 2));
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Update the figure's colormap if desired
        if iInd ~= iLastInd
            dColormap = zeros(256, 3);
            eval(['dColormap = ', csColormaps{iInd}, '(256);']);
            set(hF, 'Colormap', dColormap);
            if exist('hText', 'var')
                set(hText, 'String', csColormaps{iInd});
            end
            iLastInd = iInd;
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fColormapMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

end
% =========================================================================
% *** END FUNCTION fColormapSelect (and its nested functions)
% =========================================================================



% =========================================================================
% *** FUNCTION fGetWorkspaceVar
% ***
% *** Lets the user select one or multiple variables from the base
% *** workspace for import into imagine
% ***
% =========================================================================
function csVarOut = fGetWorkspaceVar()

iFIGUREWIDTH = 300;
iFIGUREHEIGHT = 400;
iBUTTONHEIGHT = 24;

csVarOut = {};
iPos = get(0, 'ScreenSize');

% -------------------------------------------------------------------------
% Create figure and GUI elements
hF = figure( ...
    'Position'              , [(iPos(3) - iFIGUREWIDTH)/2, (iPos(4) - iFIGUREHEIGHT)/2, iFIGUREWIDTH, iFIGUREHEIGHT], ...
    'Units'                 , 'pixels', ...
    'DockControls'          , 'off', ...
    'WindowStyle'           , 'modal', ...
    'Name'                  , 'Load workspace variable...', ...
    'NumberTitle'           , 'off', ...
    'Resize'                , 'off');

csVars = evalin('base', 'who');
hList = uicontrol(hF, ...
    'Style'                 , 'listbox', ...
    'Units'                 , 'pixels', ...
    'Position'              , [1 iBUTTONHEIGHT + 1 iFIGUREWIDTH iFIGUREHEIGHT - iBUTTONHEIGHT], ...
    'ForegroundColor'       , 'w' , ...
    'BackgroundColor'       , 'k', ...
    'HitTest'               , 'on', ...
    'String'                , csVars, ...
    'Min'                   , 0, ...
    'Max'                   , 2, ...
    'Callback'              , @fMouseActionFcn);

hButOK = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'ForegroundColor'       , 'w', ...
    'BackgroundColor'       , 'k', ...
    'Callback'              , @fMouseActionFcn, ...
    'HitTest'               , 'on', ...
    'String'                , 'OK');

hButCancel = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [iFIGUREWIDTH/2 + 1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'ForegroundColor'       , 'w', ...
    'BackgroundColor'       , 'k', ...
    'Callback'              , @fMouseActionFcn, ...
    'HitTest'               , 'on', ...
    'String'                , 'Cancel');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set default action and enable gui interaction
sAction = 'Cancel';
uiwait(hF);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% uiresume was triggered (in fMouseActionFcn) -> return
try
    if strcmp(sAction, 'OK')
        iList = get(hList, 'Value');
        csVarOut = cell(length(iList), 1);
        for iI = 1:length(iList)
            csVarOut(iI) = csVars(iList(iI));
        end
    end
    close(hF);
catch %#ok<CTCH>
    csVarOut = {};
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fMouseActionFcn (nested in fGetWorkspaceVar)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMouseActionFcn(hObject, eventdata)
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % React on action depending on its source component
        switch(hObject)
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Click in LISBOX: return if double-clicked
            case hList
                if strcmp(get(hF, 'SelectionType'), 'open')
                    sAction = 'OK';
                    uiresume(hF);
                end
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % OK button
            case hButOK
                sAction = 'OK';
                uiresume(hF);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % CANCEL button
            case hButCancel
                sAction = 'Cancel';
                uiresume(hF);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            otherwise

        end
        % End of switch statement
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGridMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
end
% =========================================================================
% *** END FUNCTION fGetWorkspaceVar (and its nested functions)
% =========================================================================



% =========================================================================
% *** FUNCTION fSettings
% ***
% *** Brings up a settings dialog
% ***
% =========================================================================
function SSettings = fSettings(SDefaults)

iFIGUREWIDTH = 500;
iFIGUREHEIGHT = 150;
iBUTTONHEIGHT = 24;

SSettings = [];
iPos = get(0, 'ScreenSize');

% -------------------------------------------------------------------------
% Create figure and GUI elements
hF = figure( ...
    'Position'              , [(iPos(3) - iFIGUREWIDTH)/2, (iPos(4) - iFIGUREHEIGHT)/2, iFIGUREWIDTH, iFIGUREHEIGHT], ...
    'Units'                 , 'pixels', ...
    'DockControls'          , 'off', ...
    'WindowStyle'           , 'modal', ...
    'Name'                  , 'Preferences', ...
    'NumberTitle'           , 'off', ...
    'Color'                 , 'k', ...
    'Resize'                , 'off');

hButOK = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'ForegroundColor'       , 'w', ...
    'BackgroundColor'       , 'k', ...
    'Callback'              , @fMouseButtonFcn, ...
    'HitTest'               , 'on', ...
    'String'                , 'OK');

hButCancel = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [iFIGUREWIDTH/2 + 1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'ForegroundColor'       , 'w', ...
    'BackgroundColor'       , 'k', ...
    'Callback'              , @fMouseButtonFcn, ...
    'HitTest'               , 'on', ...
    'String'                , 'Cancel');

hT = zeros(2, 1);
hE = zeros(2, 1);
hB = zeros(2, 1);
for iI = 1:2
    hT(iI) = uicontrol(hF, ...
        'Style'             , 'text', ...
        'Units'             , 'pixels', ...
        'Position'          , [1 iFIGUREHEIGHT - 20 - (iBUTTONHEIGHT + 2)*iI 150 iBUTTONHEIGHT], ...
        'ForegroundColor'   , 'w', ...
        'BackgroundColor'   , 'k');

    hE(iI) = uicontrol(hF, ...
        'Style'             , 'edit', ...
        'Units'             , 'pixels', ...
        'Position'          , [160 iFIGUREHEIGHT - 16 - (iBUTTONHEIGHT + 2)*iI 200 iBUTTONHEIGHT], ...
        'ForegroundColor'   , 'w', ...
        'BackgroundColor'   , 'k', ...
        'HorizontalAlign'   , 'left');

    hB(iI) = uicontrol(hF, ...
        'Style'             , 'pushbutton', ...
        'Units'             , 'pixels', ...
        'Position'          , [370 iFIGUREHEIGHT - 16 - (iBUTTONHEIGHT + 2)*iI 100 iBUTTONHEIGHT], ...
        'ForegroundColor'   , 'w', ...
        'BackgroundColor'   , 'k', ...
        'HorizontalAlign'   , 'left', ...
        'Callback'          , @fMouseButtonFcn, ...
        'String'            , 'Browse...');
end

set(hT(1), 'String', 'Line eval function:');
set(hT(2), 'String', 'ROI eval function:');
set(hE(1), 'String', SDefaults.sEvalLineFcn);
set(hE(2), 'String', SDefaults.sEvalROIFcn);

uicontrol(hF, ...
    'Style'             , 'text', ...
    'Units'             , 'pixels', ...
    'Position'          , [1 iFIGUREHEIGHT - 20 - (iBUTTONHEIGHT + 2)*3 150 iBUTTONHEIGHT], ...
    'ForegroundColor'   , 'w', ...
    'BackgroundColor'   , 'k', ...
    'String'            , 'Background Color:');

hBColor = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [370 iFIGUREHEIGHT - 16 - (iBUTTONHEIGHT + 2)*3 100 iBUTTONHEIGHT], ...
    'ForegroundColor'       , 'w', ...
    'BackgroundColor'       , 'k', ...
    'HorizontalAlign'       , 'left', ...
    'Callback'              , @fMouseButtonFcn, ...
    'String'                , 'Pick Color...');

hP = uipanel( ...
    'Parent'                , hF, ...
    'Units'                 , 'pixels', ...
    'BorderWidth'           , 0, ...
    'Position'              , [160 iFIGUREHEIGHT - 16 - (iBUTTONHEIGHT + 2)*3 200 iBUTTONHEIGHT], ...
    'BackgroundColor'       , SDefaults.dBGColor);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Make the GUI wait for user input
sAction = 'Cancel';
uiwait(hF);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% uiresume was called in fMouseButtonFcn -> continue execution
try
    if strcmp(sAction, 'OK')
        SSettings.sEvalLineFcn = get(hE(1), 'String');
        SSettings.sEvalROIFcn = get(hE(2), 'String');
        SSettings.dBGColor = get(hP, 'BackgroundColor');
    end
    close(hF);
catch %#ok<CTCH>
    SSettings = [];
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fMouseButtonFcn (nested in fSettings)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMouseButtonFcn(hObject, eventdata)

        switch(hObject)
            case {hB(1), hB(2)} % The browse buttons
                [sFilename, sPath] = uigetfile( ...
                    {'*.m', 'm-File (*.m)'}, ...
                    'OpenLocation'      , [fileparts(mfilename('fullpath')), filesep, 'EvalFunctions']);
                if isnumeric(sPath), return, end;   % Dialog aborted

                iInd = strfind(sFilename, '.');     % Crop file extension
                sFilename = sFilename(1:iInd(end)-1);
                if hObject == hB(1)
                    set(hE(1), 'String', sFilename);
                else
                    set(hE(2), 'String', sFilename);
                end

            case hButOK
                sAction = 'OK';
                uiresume(hF);

            case hButCancel
                sAction = 'Cancel';
                uiresume(hF);

            case hBColor
                dBGColor = uisetcolor(get(hP, 'BackgroundColor'));
                set(hP, 'BackgroundColor', dBGColor);

            otherwise
                return

        end
    end
	
end
% =========================================================================
% *** END FUNCTION fSettings (and its nested functions)
% =========================================================================