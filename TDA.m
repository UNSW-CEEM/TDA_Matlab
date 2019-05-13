
%% Info
% Copyright (C) 2017, Navid Haghdadi, n.haghdadi@unsw.edu.au

% TDA is open source software for assessing existing and proposed new tariffs.
% It offers a range of analyses as described in this document to assist energy
% market stakeholders and the wider community to analyse the impact of different
% tariffs on different user groups. TDA is free software and you can redistribute
% it and/or modify it under the terms of the GNU General Public License as published
% by the Free Software Foundation version 3. For more information about GPL 3 please
% refer to: https://www.gnu.org/licenses/gpl-3.0.en.html.

% --- Main function of the TDA
function TDA


%% ****************** GUI Initialising ***********************

warning('off','all')

% Global Variable h, main handle of the data
global h

h=[];

% If Windows, it will find the folder and work properly
if ispc
    h.FolderSel=1;
    h.FilesPath='';
    
    % If Mac we need to allocate the TDA folder
else
    
    choice = questdlg('Welcome to TDA! As you are a Mac user, you should first browse the TDA folder in your computer:', ...
        'Browse folder','Browse folder','Browse folder');
    
    % Handle response
    switch choice
        case 'Browse folder'
            % Get the folder
            h.FilesPath=uigetdir;
            h.FolderSel=1;
    end
end

% Loading the tariff list (original) and the new tariff list (modified by user)
if ispc
    TariffList1=load('Data\AllTariffs.mat','AllTariffs');   % Download original tariffs
    try
        TariffList2=load('Data\AllTariffs_New.mat','AllTariffs');   % Download new tariffs
    catch
        TariffList2.AllTariffs=[];
    end
else
    TariffList1=load([h.FilesPath,'/Data/AllTariffs.mat'],'AllTariffs');   % Download original tariffs
    try
        TariffList2=load([h.FilesPath,'/Data/AllTariffs_New.mat'],'AllTariffs');   % Download new tariffs
    catch
        TariffList2.AllTariffs=[];
    end
end
% Combining all tariffs
AllTariffsList=[TariffList1.AllTariffs,TariffList2.AllTariffs];

% Removing the original tariffs which has been deleted by user
AllTariffsList(:,~cell2mat({AllTariffsList.Show}))=[];

% Assign the tariffs in to the handle
h.TariffList.AllTariffs=AllTariffsList;

% List of all options for 4 figures
% 1- Load selection figure
h.ListofLoadSelectFigures={'Annual Average Profile', 'Daily Profile(s)','Daily Profile interquartile Range','Daily kWh Histogram','Average Load Duration Curve','Average Peak Day Profile','Monthly Average kWh','Seasonal Daily Pattern'};
% 2- Single variabl figure
h.ListofSingVarFigs={'Average Annual Profile','Daily kWh Histogram','Monthly Average kWh','Seasonal Daily Pattern','Monthly Peak Time','Average Load Duration Curve','Bill Distribution','Bill Box Plot'};
% 3- Dual Variable figures
h.ListofDualVarFigs={'Annual kWh';'Average Demand at ''N'' Network Peaks';'Average Demand at ''N'' Network Monthly Peaks';'Average Demand at Top ''N'' Peaks';'Average Demand at Top ''N'' Monthly Peaks';'Average Daily kWh';'Average Daily Peak';'Bill ($/year)';'Unitised Bill (kW)'}; % Options for plotting in Dual variable figure
% 4- Single case figures
h.ListofSingCaseFigs={'Bill Components'; 'Bill Component Pie Chart';'Daily Profile interquartile Range'}; % Options for plotting in Single case figure

% Number of peaks to be considered
h.ListofTopPeaks=num2cell([1:150]');

% AllDiagrams is the variable which contains all cases (up to 10 case)
h.AllDiagrams=[]; % Container Of all cases (up to 10 cases)

% Load, are not set yet.
h.status.LoadSet=0;

% Import Settings
if ispc
    load('Data\Settings.mat');
else
    load([h.FilesPath,'/Data/Settings.mat']);
end
% Loading the previous settings saved by the user including:
% Synthetic Network load
h.SyntheticNetwork=SyntheticNetwork;
% Peak time method (based on whole load, filtered load or synthetic network)
h.PeakTimeMethod=PeakTimeMethod;
% Option for ask to name a new case
h.AskForCaseName=AskForCaseName;
% Option for Confirm before exiting
h.Confirm.BeforeExit=Confirm.BeforeExit;
% Option for Confirm before deleting Case
h.Confirm.BeforeDeleting.Case=Confirm.BeforeDeleting.Case;
% Option for Confirm before deleting Load
h.Confirm.BeforeDeleting.Load=Confirm.BeforeDeleting.Load;
% Option for Confirm before deleting Tariff
h.Confirm.BeforeDeleting.Tariff=Confirm.BeforeDeleting.Tariff;
% Option for Confirm before deleting Project
h.Confirm.BeforeDeleting.Project=Confirm.BeforeDeleting.Project;


%% ****************** GUI Elements ***********************

%% GUI Elements: Main Figure
h.MainFigure = figure('Name','TDA (CEEM, UNSW)','NumberTitle','off', ...
    'HandleVisibility','on', ...
    'Toolbar','none','Menubar','none',...
    'Position',[20 50 1200 730 ],...
    'CloseRequestFcn',@closeGUI);

% Set Icon
% warning('off', ...
% 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
% jframe=get(h.MainFigure,'javaframe');
% jIcon=javax.swing.ImageIcon('UNSWLogo_small.png');
% jframe.setFigureIcon(jIcon);

% UNSW and CEEM Logos
h.CEEMAxes = axes('Parent', h.MainFigure, ...
    'HandleVisibility','callback', ...
    'Units', 'normalized', 'Position',[.01 0.88 0.17 0.12], 'FontSize',8,'Box','on');  % Axes for ceem logo
CEEMIm = imread('CEEMLogo.png');
image(h.CEEMAxes,CEEMIm)
axis(h.CEEMAxes, 'off')
axis(h.CEEMAxes, 'image')

h.UNSWAxes = axes('Parent', h.MainFigure, ...
    'HandleVisibility','callback', ...
    'Units', 'normalized', 'Position',[.2 0.88 0.1 0.1], 'FontSize',8,'Box','on'); %Axes for UNSW logo

UNSWIm = imread('UNSWLogo.png');
image(h.UNSWAxes,UNSWIm)
axis(h.UNSWAxes, 'off')
axis(h.UNSWAxes, 'image')

%% GUI Elements: Menus
% 1- Project Menu
h.menuProject = uimenu('Label','Project','Parent',h.MainFigure);
% Load project
h.LoadProjMenu=uimenu(h.menuProject,'Label','Load Project');
% update the list of projects based on available projects
updatePrjList
% save and save as puttons
uimenu(h.menuProject,'Label','Save Project','Accelerator','S','Callback', ...
    @SaveProj_CB);
uimenu(h.menuProject,'Label','Save Project As','Callback', ...
    @SaveProjAs_CB);
% delete projects
h.menuProject_del=uimenu(h.menuProject,'Label','Delete Project');
% update the list of projects for delete
updatePrjList_del
% restart the tool
uimenu(h.menuProject,'Label','Restart Tool','Separator','on','Callback',...
    @RestartTool);

% 2- Load Menu
h.menuLoad = uimenu('Label','Load','Parent',h.MainFigure);
% import load
uimenu(h.menuLoad,'Label','Import Load Data', ...
    'Callback',@ImpNewLoad_CB);
% delete load
h.menuLoad_del=uimenu(h.menuLoad,'Label','Delete Load Data');
updateLoadList_del
% restart load
uimenu(h.menuLoad,'Label','Restore Original Load Data', 'Callback',@RestoreLoad);
% Maximum Allowed Missing Data (%)
h.menuLoad_Miss=uimenu(h.menuLoad,'Label','Maximum Allowed Missing Data (%)','Separator','On');
h.MissingDataOptions={'0%','1%','2%','5%','10%','20%','30%'};

% Check only the one which has been selected
for n=1:7
    h.menuLoad_Miss_Opt{n,1}=uimenu(h.menuLoad_Miss,'Label',h.MissingDataOptions{1,n},...
        'checked','Off','Callback',{@ChenageCheckedMiss,n});
end
h.menuLoad_Miss_Opt{4,1}.Checked='On';


% Down sampling the data
h.menuLoad_DownSam=uimenu(h.menuLoad,'Label','Down-sample Users (Random Selection)');
h.DownSamOptions={'100% (full data)','50%','20%','10%','5%','2%','1%'};

for n=1:7
    h.menuLoad_DownSam_Opt{n,1}=uimenu(h.menuLoad_DownSam,'Label',h.DownSamOptions{1,n},...
        'checked','Off','Callback',{@ChenageCheckedDownSam,n});
end

h.menuLoad_DownSam_Opt{1,1}.Checked='On';

% Options for Network load
h.menuLoad_PT=uimenu(h.menuLoad,'Label','Network Load',...
    'Separator','On');
% based on the Aggregation of Whole Load Data
h.menuLoad_PT1=uimenu(h.menuLoad_PT,'Label','Aggregation of Whole Load Data',...
    'checked','Off','Callback',{@PeakTimeNew,1});
% based on the Aggregation of Filtered Load Data
h.menuLoad_PT2=uimenu(h.menuLoad_PT,'Label','Aggregation of Filtered Load Data',...
    'checked','Off','Callback',{@PeakTimeNew,2});
% based on the Synthetic Network Load
h.menuLoad_PT3=uimenu(h.menuLoad_PT,'Label','Synthetic Network Load',...
    'checked','Off','Callback',{@PeakTimeNew,3});
% Create New Synthetic Network Load
h.menuLoad_PT4=uimenu(h.menuLoad_PT,'Label','Create New Synthetic Network Load',...
    'Separator','on','Callback',{@PeakTimeNew,4});
% Plot Network Load Pattern
h.menuLoad_PT4=uimenu(h.menuLoad_PT,'Label','Plot Network Load Pattern','Separator','on');
% Plot Network Load which is based on: Based on Whole Dataset
uimenu(h.menuLoad_PT4,'Label','Based on Whole Dataset',...
    'Callback',{@PlotNetworkLoad,1});
% Plot Network Load which is based on: Based on Filtered Dataset
uimenu(h.menuLoad_PT4,'Label','Based on Filtered Dataset',...
    'Callback',{@PlotNetworkLoad,2});
% Plot Network Load which is based on: Synethetic Network Load
uimenu(h.menuLoad_PT4,'Label','Synethetic Network Load',...
    'Callback',{@PlotNetworkLoad,3});

% See what is the method for the network peak and check the option
if h.PeakTimeMethod==1
    h.menuLoad_PT1.Checked='On';
elseif h.PeakTimeMethod==2
    h.menuLoad_PT2.Checked='On';
else
    h.menuLoad_PT3.Checked='On';
end

% 3- Tariff Menu
h.menuTariff = uimenu('Label','Tariff','Parent',h.MainFigure);
% Create New Tariff
h.MenuTariff_cre=uimenu(h.menuTariff,'Label','Create New Tariff');
% Different options for the tariff:
uimenu(h.MenuTariff_cre,'Label','Flat rate','Callback',{@CreateTar,'FR'});
uimenu(h.MenuTariff_cre,'Label','Flat rate Seasonal','Callback',{@CreateTar,'FRSeas'});
uimenu(h.MenuTariff_cre,'Label','Block','Callback',{@CreateTar,'Block'});
uimenu(h.MenuTariff_cre,'Label','Block Quarterly','Callback',{@CreateTar,'Block_Quarterly'});
uimenu(h.MenuTariff_cre,'Label','Time of Use','Callback',{@CreateTar,'TOU'});
uimenu(h.MenuTariff_cre,'Label','Time of Use Seasonal','Callback',{@CreateTar,'TOUSeas'});
uimenu(h.MenuTariff_cre,'Label','Demand Charge','Callback',{@CreateTar,'Demand'});
uimenu(h.MenuTariff_cre,'Label','Demand Charge + TOU','Callback',{@CreateTar,'Demand_TOU'});

% Help file of the tariffs
uimenu(h.menuTariff,'Label','Tariff Info','Callback',@HelpTariff);
% Reset the tariff
uimenu(h.menuTariff,'Label','Reset Tariffs','Callback',@ResTar);

% 4- Export Menu
h.menuExport = uimenu('Label','Export','Parent',h.MainFigure);
% Export current figure showing on the panel
uimenu(h.menuExport,'Label','Export Figure','Callback',@ExpCurFig,'Accelerator','E');
% Copy current figure showing on the panel
uimenu(h.menuExport,'Label','Copy Figure','Callback',@CopyCurFig,'Accelerator','C');
% Copy the data of the figure showing on the panel
uimenu(h.menuExport,'Label','Copy Data','Callback',@CopyCurData,'Accelerator','D');
% Export the result of the cases
h.menuExpRes=uimenu(h.menuExport,'Label','Export Results');
% Export all cases
h.menuExport_all=uimenu(h.menuExpRes,'Label','All Cases','Callback',@Exp_AllCases_CB);
% Exporting menu for individual cases will appear when they are being added

% 5- Preferences Menu (specifying the preferences for some options)
h.menuPref.M = uimenu('Label','Preferences','Parent',h.MainFigure);
if h.AskForCaseName
    AskForCaseName_C='On';
else
    AskForCaseName_C='Off';
end
% Ask To Name New Case
h.menuPref.AskForCaseName=uimenu(h.menuPref.M,'Label','Ask To Name New Case','checked',AskForCaseName_C,'Callback',@AskForCaseName_Callback);
% Check the previously set preference
if h.Confirm.BeforeExit
    ConfirmBeforeExit_C='On';
else
    ConfirmBeforeExit_C='Off';
end
% Confirm Before Exiting Tool
h.menuPref.Confirm.BeforeExit=uimenu(h.menuPref.M,'Label','Confirm Before Exiting Tool','checked',ConfirmBeforeExit_C,'Callback',@ConfirmBeforeExit_Callback);
% Confirm Before Deleting
h.menuPref.Confirms = uimenu(h.menuPref.M,'Label','Confirm Before Deleting');

% Confirm Before Deleting Case
% Check the previously set preference
if h.Confirm.BeforeDeleting.Case
    ConfirmBeforeDeletingCase_C='On';
else
    ConfirmBeforeDeletingCase_C='Off';
end

h.menuPref.Confirm.BeforeDeleting.Case=uimenu(h.menuPref.Confirms,'Label','Case','checked',ConfirmBeforeDeletingCase_C,'Callback',@ConfirmBeforeDeletingCase_Callback);

% Confirm Before Deleting Load
% Check the previously set preference
if h.Confirm.BeforeDeleting.Load
    ConfirmBeforeDeletingLoad_C='On';
else
    ConfirmBeforeDeletingLoad_C='Off';
end

h.menuPref.Confirm.BeforeDeleting.Load=uimenu(h.menuPref.Confirms,'Label','Load','checked',ConfirmBeforeDeletingLoad_C,'Callback',@ConfirmBeforeDeletingLoad_Callback);

% Confirm Before Deleting Project
% Check the previously set preference
if h.Confirm.BeforeDeleting.Project
    ConfirmBeforeDeletingProject_C='On';
else
    ConfirmBeforeDeletingProject_C='Off';
end

h.menuPref.Confirm.BeforeDeleting.Project=uimenu(h.menuPref.Confirms,'Label','Project','checked',ConfirmBeforeDeletingProject_C,'Callback',@ConfirmBeforeDeletingProject_Callback);

% Confirm Before Deleting Tariff
% Check the previously set preference
if h.Confirm.BeforeDeleting.Tariff
    ConfirmBeforeDeletingTariff_C='On';
else
    ConfirmBeforeDeletingTariff_C='Off';
end

h.menuPref.Confirm.BeforeDeleting.Tariff=uimenu(h.menuPref.Confirms,'Label','Tariff','checked',ConfirmBeforeDeletingTariff_C,'Callback',@ConfirmBeforeDeletingTariff_Callback);

% 6- Help menu
h.menuHelp = uimenu('Label','Help','Parent',h.MainFigure);

h.menuHelp_About=uimenu(h.menuHelp,'Label','About');

uimenu(h.menuHelp_About,'Label','CEEM','Callback',@About_CEEM_Callback);
uimenu(h.menuHelp_About,'Label','ResearchGate','Callback',@About_RG_Callback);
uimenu(h.menuHelp_About,'Label','GitHub','Callback',@About_GH_Callback);

uimenu(h.menuHelp,'Label','User''s Guide','Callback',@UserGuide_Callback);
uimenu(h.menuHelp,'Label','Check for Update','Callback',@Update_Callback);
uimenu(h.menuHelp,'Label','Feedback','Callback',@Feedback_Callback);
uimenu(h.menuHelp,'Label','Subscribe','Callback',@Subscribe_Callback);


%  Project name Text
if  isfield(h,'ProjectName')
else
    h.ProjectName='Undefined';
end

h.ProjectText = uicontrol(h.MainFigure,'Style','Text',...
    'String',['Project Name: ',h.ProjectName], ...
    'FontUnits','normalized',...
    'Value',1,...
    'Units', 'normalized', 'Position',[.75 .95 .25 .03],'TooltipString','Save project if you want to work on this later');

% Functions of the menu options

% Check what missing % is selected
    function ChenageCheckedMiss(src,evnt,n2)
        for n3=1:size(h.menuLoad_Miss_Opt,1)
            h.menuLoad_Miss_Opt{n3,1}.Checked='Off';
        end
        h.menuLoad_Miss_Opt{n2,1}.Checked='On';
    end

% Check what downsampling option is selected
    function ChenageCheckedDownSam(src,evnt,n2)
        for n3=1:size(h.menuLoad_DownSam_Opt,1)
            h.menuLoad_DownSam_Opt{n3,1}.Checked='Off';
        end
        h.menuLoad_DownSam_Opt{n2,1}.Checked='On';
    end

% Check what option is selected:
    function AskForCaseName_Callback(src,evnt)
        
        if  strcmpi(h.menuPref.AskForCaseName.Checked,'On')
            AskForCaseName=0;
            h.AskForCaseName=0;
            h.menuPref.AskForCaseName.Checked='Off';
        else
            AskForCaseName=1;
            h.AskForCaseName=1;
            h.menuPref.AskForCaseName.Checked='On';
        end
        if ispc
            save('Data\Settings','AskForCaseName','-append');
        else
            save([h.FilesPath,'/Data/Settings'],'AskForCaseName','-append');
        end
    end

% Check what option is selected:
    function ConfirmBeforeExit_Callback(src,evnt)
        if  strcmpi(h.menuPref.Confirm.BeforeExit.Checked,'On')
            Confirm.BeforeExit=0;
            h.Confirm.BeforeExit=0;
            h.menuPref.Confirm.BeforeExit.Checked='Off';
        else
            Confirm.BeforeExit=1;
            h.Confirm.BeforeExit=1;
            h.menuPref.Confirm.BeforeExit.Checked='On';
        end
        if ispc
            save('Data\Settings','Confirm','-append');
        else
            save([h.FilesPath,'/Data/Settings'],'Confirm','-append');
        end
    end

% Check what option is selected:
    function ConfirmBeforeDeletingCase_Callback(src,evnt)
        if  strcmpi(h.menuPref.Confirm.BeforeDeleting.Case.Checked,'On')
            Confirm.BeforeDeleting.Case=0;
            h.Confirm.BeforeDeleting.Case=0;
            h.menuPref.Confirm.BeforeDeleting.Case.Checked='Off';
        else
            Confirm.BeforeDeleting.Case=1;
            h.Confirm.BeforeDeleting.Case=1;
            h.menuPref.Confirm.BeforeDeleting.Case.Checked='On';
        end
        if ispc
            save('Data\Settings','Confirm','-append');
        else
            save([h.FilesPath,'/Data/Settings'],'Confirm','-append');
        end
    end

% Check what option is selected:
    function ConfirmBeforeDeletingProject_Callback(src,evnt)
        if  strcmpi(h.menuPref.Confirm.BeforeDeleting.Project.Checked,'On')
            Confirm.BeforeDeleting.Project=0;
            h.Confirm.BeforeDeleting.Project=0;
            h.menuPref.Confirm.BeforeDeleting.Project.Checked='Off';
        else
            Confirm.BeforeDeleting.Project=1;
            h.Confirm.BeforeDeleting.Project=1;
            h.menuPref.Confirm.BeforeDeleting.Project.Checked='On';
        end
        if ispc
            save('Data\Settings','Confirm','-append');
        else
            save([h.FilesPath,'/Data/Settings'],'Confirm','-append');
        end
    end

% Check what option is selected:
    function ConfirmBeforeDeletingLoad_Callback(src,evnt)
        if  strcmpi(h.menuPref.Confirm.BeforeDeleting.Load.Checked,'On')
            Confirm.BeforeDeleting.Load=0;
            h.Confirm.BeforeDeleting.Load=0;
            h.menuPref.Confirm.BeforeDeleting.Load.Checked='Off';
        else
            Confirm.BeforeDeleting.Load=1;
            h.Confirm.BeforeDeleting.Load=1;
            h.menuPref.Confirm.BeforeDeleting.Load.Checked='On';
        end
        if ispc
            save('Data\Settings','Confirm','-append');
        else
            save([h.FilesPath,'/Data/Settings'],'Confirm','-append');
        end
    end

% Check what option is selected:
    function ConfirmBeforeDeletingTariff_Callback(src,evnt)
        if  strcmpi(h.menuPref.Confirm.BeforeDeleting.Tariff.Checked,'On')
            Confirm.BeforeDeleting.Tariff=0;
            h.Confirm.BeforeDeleting.Tariff=0;
            h.menuPref.Confirm.BeforeDeleting.Tariff.Checked='Off';
        else
            Confirm.BeforeDeleting.Tariff=1;
            h.Confirm.BeforeDeleting.Tariff=1;
            h.menuPref.Confirm.BeforeDeleting.Tariff.Checked='On';
        end
        if ispc
            save('Data\Settings','Confirm','-append');
        else
            save([h.FilesPath,'/Data/Settings'],'Confirm','-append');
        end
    end

% Peak time set
    function PeakTimeNew(src,evnt,j)
        % if the whole database
        if j==1
            h.menuLoad_PT1.Checked='on';
            h.menuLoad_PT2.Checked='off';
            h.menuLoad_PT3.Checked='off';
            h.PeakTimeMethod=1;
            PeakTimeMethod=h.PeakTimeMethod;
            if ispc
                save('Data\Settings','PeakTimeMethod','-append');
            else
                save([h.FilesPath,'/Data/Settings'],'PeakTimeMethod','-append');
            end
            % if the filtered load
        elseif j==2
            h.menuLoad_PT1.Checked='off';
            h.menuLoad_PT2.Checked='on';
            h.menuLoad_PT3.Checked='off';
            h.PeakTimeMethod=2;
            PeakTimeMethod=h.PeakTimeMethod;
            
            if ispc
                save('Data\Settings','PeakTimeMethod','-append');
            else
                save([h.FilesPath,'/Data/Settings'],'PeakTimeMethod','-append');
                
            end
            % if the synethetic load
        elseif j==3
            
            if ~isfield(h,'SyntheticNetwork')
                DelMsg;msgbox('You have not created any synthetic data yet! Please select "Creat synthetic network load data" to do so!');
            else
                h.menuLoad_PT1.Checked='off';
                h.menuLoad_PT2.Checked='off';
                h.menuLoad_PT3.Checked='on';
                h.PeakTimeMethod=3;
                PeakTimeMethod=h.PeakTimeMethod;
                if ispc
                    save('Data\Settings','PeakTimeMethod','-append');
                else
                    save([h.FilesPath,'/Data/Settings'],'PeakTimeMethod','-append');
                end
            end
            
            % create a new synthetic load
        elseif j==4
            
            choice = questdlg(['Please refer to instructions, section 5.3 (CREATING NEW LOAD DATA) and put the network load data in required format before importing.You can also open the sample file and see the required format or paste in your data into this file and save as a new load file and then load the file when creating the new load data.'], ...
                'Create synthetic network load data', ...
                'Create now','Open sample file','Cancel','Cancel');
            % Handle response
            switch choice
                case 'Create now'
                    % locate the file
                    [h.NewFile_FileName_NL,h.NewFile_PathName_NL,FilterIndex] = uigetfile({'*.xlsx';'*.xls'},'Upload synthetic network load file');
                    
                    if FilterIndex
                        DelMsg;msgbox('Loading Data..Please wait!');
                        % read the file
                        newNload_rawdata=readtable([h.NewFile_PathName_NL,h.NewFile_FileName_NL]);
                        
                        if size(newNload_rawdata,2)<2
                            DelMsg;msgbox('There was a problem in the file. Please make sure you followed the required data format described in the instruction and try again!');
                        else
                            % check the file has corret data
                            if numel(unique(floor(datenum(newNload_rawdata{:,1}))))>366
                                
                                DelMsg;msgbox('The network load profile should be only one year data. Please make sure you followed the required data format described in the instruction and try again!');
                                
                            else
                                % create the synthetic laod
                                h.SyntheticNetwork=table;
                                h.SyntheticNetwork.TimeStamp=newNload_rawdata{:,1};
                                h.SyntheticNetwork.Load=newNload_rawdata{:,2};
                                SyntheticNetwork=h.SyntheticNetwork;
                                if ispc
                                    save('Data\Settings.mat','SyntheticNetwork','-append');
                                else
                                    save([h.FilesPath,'/Data/Settings.mat'],'SyntheticNetwork','-append');
                                end
                                DelMsg
                                choice = questdlg(['The new synthetic load data has been successfully saved! You can plot the netowrk load and monthly peak values.'], ...
                                    'Saved!', ...
                                    'Plot Network Load','OK','OK');
                                % Handle response
                                switch choice
                                    case 'Plot Network Load'
                                        PlotNetworkLoad(src,evnt,3)
                                    case 'OK'
                                        DelMsg
                                end
                            end
                        end
                    end
                    % open the sample file
                case 'Open sample file'
                    if ispc
                        copyfile('Data\SampleNLoad_BU.xlsx','SampleNetwork.xlsx');
                        winopen('SampleNetwork.xlsx')
                    else
                        copyfile([h.FilesPath,'/Data/SampleNLoad_BU.xlsx'],[h.FilesPath,'/SampleNetwork.xlsx']);
                        system(['open ',h.FilesPath,'/SampleNetwork.xlsx'])
                    end
            end
        end
    end

% plot the netwoke load
    function PlotNetworkLoad(src,evnt,k)
        GTG=0;
        % based on the whole dataset
        if k==1
            if h.status.LoadSet
                LoadNo=find(strcmp(h.AllLoads(:,1),h.CurrentLoad_Name));
                PeakLoadForPlot=table;
                PeakLoadForPlot.TimeStamp=h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end);
                PeakLoadForPlot.Load=h.AllLoads{LoadNo,2}.Load.NetworkLoad(2:end);
                NetworkLaodName=h.CurrentLoad_Name;
                NetworkLaodName=strrep(NetworkLaodName,'_',' ');
                GTG=1;
            else
                DelMsg;msgbox('No load has been set yet!')
            end
            % based on the filtered dataset
        elseif k==2
            if h.status.LoadSet
                
                LoadNo=find(strcmp(h.AllLoads(:,1),h.CurrentLoad_Name));
                PeakLoadForPlot=table;
                PeakLoadForPlot.TimeStamp=h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end);
                PeakLoadForPlot.Load=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo)),2);
                NetworkLaodName=[h.CurrentLoad_Name,'_Filtered'];
                NetworkLaodName=strrep(NetworkLaodName,'_',' ');
                GTG=1;
            else
                
                DelMsg;msgbox('No load has been set yet!')
            end
            % synthetic network load
        else
            GTG=1;
            PeakLoadForPlot= h.SyntheticNetwork;
            NetworkLaodName='Synthetic Network Load';
            NetworkLaodName=strrep(NetworkLaodName,'_',' ');
        end
        % plot the monthly peaks of the load
        if GTG
            figure;
            plot(PeakLoadForPlot.TimeStamp,PeakLoadForPlot.Load)
            grid on
            xlabel('Time')
            ylabel('Power')
            title('Network load')
            for i=1:12
                newtemp1= PeakLoadForPlot.Load(PeakLoadForPlot.TimeStamp.Month==i);
                newtemp2= PeakLoadForPlot.TimeStamp(PeakLoadForPlot.TimeStamp.Month==i);
                newtemp1(isnan(newtemp1))=0;
                hold on
                [ind1,ind2]=max(newtemp1);
                plot(newtemp2(ind2),ind1,'MarkerSize',10,'Marker','o',...
                    'LineStyle','none',...
                    'Color',[1 0 0]);
            end
            legend('Network load','Monthly peak')
            title(['Network load pattern (',NetworkLaodName,')'])
        end
    end

% update the list of project
    function updatePrjList(str,evnt)
        child_handles = allchild(h.LoadProjMenu);
        try
            delete(child_handles)
        end
        if ispc
            ListofPrj=dir('Prj_*');
        else
            ListofPrj=dir([h.FilesPath,'/Prj_*']);
        end
        
        
        h.PrjList=struct2cell(ListofPrj);
        for i=1:size(h.PrjList,2)
            h.PrjList{1,i}=h.PrjList{1,i}(5:end-4);
        end
        for i=1:size(h.PrjList,2)
            h.PrjSubList{1,i}= uimenu(h.LoadProjMenu,'Label',[h.PrjList{1,i}],'Callback',{@LoadPrjLis,i});
        end
    end
% update the list of projects for delet
    function updatePrjList_del(str,evnt)
        child_handles = allchild(h.menuProject_del);
        try
            delete(child_handles)
        end
        if ispc
            ListofPrj=dir('Prj_*');
        else
            ListofPrj=dir([h.FilesPath,'/Prj_*']);
            
        end
        h.PrjList=struct2cell(ListofPrj);
        for i=1:size(h.PrjList,2)
            h.PrjList{1,i}=h.PrjList{1,i}(5:end-4);
        end
        uimenu(h.menuProject_del,'Label','Delete All','Callback',{@DelPrjLis,-1});
        
        for i=1:size(h.PrjList,2)
            uimenu(h.menuProject_del,'Label',[h.PrjList{1,i}],'Callback',{@DelPrjLis,i});
        end
    end
% update the list of loads for delete
    function updateLoadList_del(str,evnt)
        child_handles = allchild(h.menuLoad_del);
        try
            delete(child_handles)
        end
        
        if ispc
            ListofLoads=dir('Data\LoadData_*');
        else
            ListofLoads=dir([h.FilesPath,'/Data/LoadData_*']);
        end
        h.LoadList=struct2cell(ListofLoads);
        for i=1:size(h.LoadList,2)
            h.LoadList{1,i}=h.LoadList{1,i}(10:end-4);
        end
        h.SelectLoad_Pup.Value=1;
        
        h.SelectLoad_Pup.String=h.LoadList(1,:);
        for i=1:size(h.LoadList,2)
            uimenu(h.menuLoad_del,'Label',[h.LoadList{1,i}],'Callback',{@DelLoadLis,i});
        end
    end



%% GUI Elements: Load Panel
% creat the panel for all options and axes
h.LoadPanel = uipanel('Parent',h.MainFigure,'Title','Select Load:',...
    'Units', 'normalized', 'Position',[0.01 .01 0.3 .85],...
    'FontWeight','bold',...
    'FontSize',10);

% Select load
h.SelectLoad_Pup_text = uicontrol(h.LoadPanel,'Style','Text',...
    'String','Select:', ...
    'FontUnits','normalized',...
    'Value',1,...
    'Units', 'normalized', 'Position',[.01 .95 .15 .03],...
    'HorizontalAlignment','left');

h.SelectLoad_Pup = uicontrol(h.LoadPanel,'Style','popupmenu',...
    'String','N/A', ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.14 .955 .4 .03]);

h.SetLoad=uicontrol(h.LoadPanel, ...
    'Style','pushbutton', 'String','Set',...
    'Units', 'normalized', 'Position',[.88 .949 .1 .0369],...
    'FontWeight','bold',...
    'FontUnits','normalized',...
    'Callback', @SetLoad_CB);

h.Line1 = uipanel('Parent',h.LoadPanel,...
    'Units', 'normalized', 'Position',[0.02 .935 0.96 .005],...
    'BackgroundColor','black','FontSize',10);

% Select user group based on demographic info
h.LoadDemog_text1 = uicontrol(h.LoadPanel,'Style','Text',...
    'String','Select user group based on demographic info:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontUnits','normalized',...
    'Value',1,...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .90 0.96 .03]);
% create all the demographic options buttons but invisible until the load
% with demographic info is loaded
for k=1:10
    h.Demo_Pup_text{k,1}= uicontrol(h.LoadPanel,'Style','Text',...
        'String','N/A', ...
        'Value',1,...
        'Units', 'normalized', 'Position',[.01 .9-k*0.05 .42 .03],...
        'FontWeight','bold',...
        'FontUnits','normalized',...
        'TooltipString','Filter users group based on this item.',...
        'Visible','off',...
        'HorizontalAlignment','left');
    h.Demo_Pup {k,1}= uicontrol(h.LoadPanel,'Style','popupmenu',...
        'String','N/A', ...
        'Value',1,'BackgroundColor','white',...
        'Visible','off',...
        'FontUnits','normalized',...
        'Units', 'normalized', 'Position',[.47 .905-k*0.05 .4 .03],...
        'Callback', @FilterDemo);
end

h.Demo1_Pup_text_noDemo= uicontrol(h.LoadPanel,'Style','Text',...
    'String','Warning: No demographic info exist!', ...
    'TooltipString','Please refer to instruction for importing demographic data along with your load data',...
    'Value',1,...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.01 .8 .95 .04],...
    'Visible','off',...
    'HorizontalAlignment','left');
%         'FontWeight','bold',...

h.Line2 = uipanel('Parent',h.LoadPanel,...
    'Units', 'normalized', 'Position',[0.02 .385 0.96 .005],...
    'BackgroundColor','black','FontSize',10);
% Create the load axes
h.LoadAxes = axes('Parent', h.LoadPanel, ...
    'HandleVisibility','callback', ...
    'Units', 'normalized', 'Position',[.15 0.08 0.75 0.25],...
    'FontUnits','normalized',...
    'FontSize',8,'Box','on');

% Number of selected users
h.LoadFig_TotNum = uicontrol(h.LoadPanel,'Style','Text',...
    'String','No. of users: N/A', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.02 .34 .35 .035]);

% selecting different options to show on the load axes
h.LoadFig_Pup_text = uicontrol(h.LoadPanel,'Style','Text',...
    'String','Show:', ...
    'Value',1,...
    'FontUnits','normalized',...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.4 .34 .15 .03]);

h.LoadFig_Pup = uicontrol(h.LoadPanel,'Style','popupmenu',...
    'String',h.ListofLoadSelectFigures, ...
    'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.55 .345 .4 .03],...
    'Callback', @update_LoadSelec_Fig);

%% GUI Elements: Diagram Panel
% creat the panel for all options and axes
h.DiagramPanel = uipanel('Parent',h.MainFigure,...
    'Units', 'normalized', 'Position',[0.315 .3+0.035 0.68 .65-0.035],...
    'FontSize',10);
% creta the tabs
h.tabg_Diag = uitabgroup('Parent',h.DiagramPanel,'Tag','Loadtabs', ...
    'Units','normalized','Position',[0 0 0.7 1]);

% Tab 1: single variable figures:
h.tab1 = uitab('parent',h.tabg_Diag, 'title', 'Single Variable Graphs');
h.SingVarDiag = uipanel('Parent',h.tab1, ...
    'Position',[.0 .0 1 1]);

% Axes
h.SingVarAxis = axes('Parent', h.SingVarDiag, ...
    'HandleVisibility','callback', ...
    'Units', 'normalized', 'Position',[.15 0.25 0.81 0.65],...
    'FontSize',8,'Box','on');

h.SingVar_FigType_Text= uicontrol(h.SingVarDiag,'Style','Text',...
    'String','Select Figure:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .03 .15 .045]);

h.SingVar_FigType_PUP= uicontrol(h.SingVarDiag,'Style','popupmenu',...
    'String',h.ListofSingVarFigs, ...
    'FontUnits','normalized',...
    'Value',1,'BackgroundColor','white',...
    'Units', 'normalized', 'Position',[.16 .035 .25 .04],...
    'Callback', {@update_SingVar,1});

% Tab 1: Dual variable figures:
h.tab2 = uitab('parent',h.tabg_Diag, 'title', 'Dual Variable Graphs');
h.DualVarDiag = uipanel('Parent',h.tab2, ...
    'Position',[.0 .0 1 1]);

h.DualVarAxis = axes('Parent', h.DualVarDiag, ...
    'HandleVisibility','callback', ...
    'Units', 'normalized', 'Position',[.15 0.25 0.81 0.65],...
    'FontSize',8,'Box','on');
% Variable to show in X axes
h.DualVar_FigType_Text_x= uicontrol(h.DualVarDiag,'Style','Text',...
    'String','X axis:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.03 .09 .08 .045]);

h.DualVar_FigX= uicontrol(h.DualVarDiag,'Style','popupmenu',...
    'String',h.ListofDualVarFigs, ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.12 .095 .25 .045],...
    'Callback', {@update_DualVar,1});
% Variable to show in Y axes
h.DualVar_FigType_Text_y= uicontrol(h.DualVarDiag,'Style','Text',...
    'String','Y axis:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.03 .02 .08 .045]);

h.DualVar_FigY= uicontrol(h.DualVarDiag,'Style','popupmenu',...
    'String',h.ListofDualVarFigs, ...
    'Value',8,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.12 .025 .25 .04],...
    'Callback', {@update_DualVar,1});

% if number of peaks needed create the "N" for both X axes:
h.DualVar_XTopPeak_Text= uicontrol(h.DualVarDiag,'Style','Text',...
    'String','N=', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Visible','off',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.39 .09 .04 .045]);

h.DualVar_XTopPeak_PB= uicontrol(h.DualVarDiag,'Style','popupmenu',...
    'String',h.ListofTopPeaks, ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Visible','off',...
    'Units', 'normalized', 'Position',[.44 .095 .07 .045],...
    'Callback', {@update_DualVar,1});
% If one day limit was needed
h.DualVar_XOnePeakPerDay= uicontrol(h.DualVarDiag,'Style','Check',...
    'String','One Peak/Day', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Visible','off',...
    'Units', 'normalized', 'Position',[.53 .09 .3 .045],'Callback',{@update_DualVar,1});

% if number of peaks needed create the "N" for both Y axes:
h.DualVar_YTopPeak_Text= uicontrol(h.DualVarDiag,'Style','Text',...
    'String','N=', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Visible','off',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.39 .02 .04 .045]);

h.DualVar_YTopPeak_PB= uicontrol(h.DualVarDiag,'Style','popupmenu',...
    'String',h.ListofTopPeaks, ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Visible','off',...
    'Units', 'normalized', 'Position',[.44 .025 .07 .045],...
    'Callback', {@update_DualVar,1});
% If one day limit was needed
h.DualVar_YOnePeakPerDay= uicontrol(h.DualVarDiag,'Style','Check',...
    'String','One Peak/Day', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Visible','off',...
    'Units', 'normalized', 'Position',[.53 .02 .3 .045],'Callback',{@update_DualVar,1});

% Seasons panel:
h.SeasonsPanel = uipanel('Parent',h.DualVarDiag, ...
    'Position',[.75 .01 0.245 0.15],'Title','Seasons','Visible','on');
% Summer
h.DualVar_Seasons{1,1}= uicontrol(h.SeasonsPanel,'Style','Check',...
    'String','Summer', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Visible','on',...
    'Value',1,...
    'Units', 'normalized', 'Position',[0.05 0.1 .48 .35],'Callback',{@update_DualVar,1});
% Autumn
h.DualVar_Seasons{2,1}= uicontrol(h.SeasonsPanel,'Style','Check',...
    'String','Autumn', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Visible','on',...
    'Value',1,...
    'Units', 'normalized', 'Position',[0.55 0.52 .48 .35],'Callback',{@update_DualVar,1});
% Winter
h.DualVar_Seasons{3,1}= uicontrol(h.SeasonsPanel,'Style','Check',...
    'String','Winter', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Visible','on',...
    'Value',1,...
    'Units', 'normalized', 'Position',[0.55 0.1 .48 .35],'Callback',{@update_DualVar,1});
% Spring
h.DualVar_Seasons{4,1}= uicontrol(h.SeasonsPanel,'Style','Check',...
    'String','Spring', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Visible','on',...
    'Value',1,...
    'Units', 'normalized', 'Position',[0.05 0.52 .48 .35],'Callback',{@update_DualVar,1});

% Tab 3: single case figures:
h.tab3 = uitab('parent',h.tabg_Diag, 'title', 'Single Case Graphs');
h.SingCaseDiag = uipanel('Parent',h.tab3, ...
    'Position',[.0 .0 1 1]);

h.SingCaseAxis = axes('Parent', h.SingCaseDiag, ...
    'HandleVisibility','callback', ...
    'Units', 'normalized', 'Position',[.15 0.25 0.81 0.65],...
    'FontSize',8,'Box','on');

h.SingCase_SelectCase_Text= uicontrol(h.SingCaseDiag,'Style','Text',...
    'String','Select Case: ', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.03 .1 .15 .045]);
h.SingCase_List= uicontrol(h.SingCaseDiag,'Style','popupmenu',...
    'String',{'N/A'}, ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.19 .105 .25 .045],...
    'Callback', {@update_SingCase,1});
% Select Figure:
h.SingCase_SelectFig_Text= uicontrol(h.SingCaseDiag,'Style','Text',...
    'String','Select Figure: ', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.03 .03 .15 .045]);

h.SingCase_Fig= uicontrol(h.SingCaseDiag,'Style','popupmenu',...
    'String',h.ListofSingCaseFigs, ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.19 .035 .25 .04],...
    'Callback', {@update_SingCase,1});
% Sort by:
h.SingCase_OptionFig_Text= uicontrol(h.SingCaseDiag,'Style','Text',...
    'String','Sort by: ', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Visible','Off',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.47 .03 .15 .045]);
h.SingCase_OptionFig= uicontrol(h.SingCaseDiag,'Style','popupmenu',...
    'String','', ...
    'Value',1,'BackgroundColor','white',...
    'Visible','Off',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.63 .035 .25 .04],...
    'Callback', {@update_SingCase,1});

%% GUI Elements: List if cases

h.ListofCases_Text = uicontrol(h.DiagramPanel,'Style','Text',...
    'String','List of cases:', ...
    'Value',1,...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.707 .91 .15 .05]);

h.ListofCases_Delete_all=uicontrol(h.DiagramPanel, ...
    'Style','pushbutton', 'String','X',...
    'FontUnits','normalized',...
    'Visible','On',...
    'TooltipString',['Delete all cases'],...
    'Units', 'normalized', 'Position',[0.96 .92 .02 .0369],...
    'Callback', {@DeleteCase_Diag,0});


for k=1:10
    h.ListofCases_CB{k,1} = uicontrol(h.DiagramPanel,'Style','checkbox',...
        'String',['C. ',num2str(k)], ...
        'HorizontalAlignment','left',...
        'FontUnits','normalized',...
        'TooltipString',['Hide/Unhide Case ',num2str(k)],...
        'Value', 1,...
        'Visible','Off',...
        'Callback', @HideUnhideCase_Diag,...
        'Units', 'normalized', 'Position',[.70+floor((k-1)/5)*0.15 .9-(rem(k-1,5))*0.05-0.05 .15 .04]);
    %
    h.ListofCases_Show{k,1}=uicontrol(h.DiagramPanel, ...
        'Style','pushbutton', 'String','?',...
        'FontUnits','normalized',...
        'Visible','Off',...
        'Units', 'normalized', 'Position',[.76+floor((k-1)/5)*0.15 .9-(rem(k-1,5))*0.05-0.05 .02 .0369],...
        'TooltipString',['Show Case ',num2str(k),' in load and tariff selection panels'],...
        'Callback', {@ShowCase_Diag,k});
    
    h.ListofCases_Export{k,1}=uicontrol(h.DiagramPanel, ...
        'Style','pushbutton', 'String','Exp',...
        'FontUnits','normalized',...
        'Visible','Off',...
        'Units', 'normalized', 'Position',[.78+floor((k-1)/5)*0.15 .9-(rem(k-1,5))*0.05-0.05 .03 .0369],...
        'TooltipString',['Export the results of Case ',num2str(k)],...
        'Callback', {@Exp_Case_CB,k});
    h.ListofCases_Delete{k,1}=uicontrol(h.DiagramPanel, ...
        'Style','pushbutton', 'String','X',...
        'FontUnits','normalized',...
        'Visible','Off',...
        'TooltipString',['Delete Case ',num2str(k)],...
        'Units', 'normalized', 'Position',[.81+floor((k-1)/5)*0.15 .9-(rem(k-1,5))*0.05-0.05 .02 .0369],...
        'Callback', {@DeleteCase_Diag,k});
    
end

h.LineBetweencases = uipanel('Parent',h.DiagramPanel,...
    'Units', 'normalized', 'Position',[0.84 .65 0.002 .25]);



%% GUI Elements: Info Load Panel

h.Info_Diag = uitabgroup('Parent',h.DiagramPanel,'Tag','Loadtabs', ...
    'Units','normalized','Position',[.71 0 0.29 0.6]);
h.tabi1 = uitab('parent',h.Info_Diag, 'title', 'Load Info');
% 1- Load info tab
h.InfoLoadPanel = uipanel('Parent',h.tabi1, ...
    'Position',[.0 .0 1 1]);
% all the options text and info:
h.InfoLoadPan{1,1} = uicontrol(h.InfoLoadPanel,'Style','Text',...
    'String','Case ', ...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .9 .9 .08]);

h.InfoLoadPan{2,1}  = uicontrol(h.InfoLoadPanel,'Style','Text',...
    'String','No. of users:', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .8 .53 .08]);

h.InfoLoadPan{3,1}  = uicontrol(h.InfoLoadPanel,'Style','Text',...
    'String','Database: ', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .7 .8 .08]);

h.InfoLoadPan{15,1} = uicontrol(h.InfoLoadPanel,'Style','Text',...
    'String','Network Load: ', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .6 .9 .08]);

% 2- Tariff info tab
h.tabi2 = uitab('parent',h.Info_Diag, 'title', 'Tariff Info');
h.InfoTariffPanel = uipanel('Parent',h.tabi2, ...
    'Position',[.0 .0 1 1]);
% all the options text and info:
h.InfoLoadPan{5,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','Case ', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.03 .9 .8 .08]);

h.InfoLoadPan{6,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','Name:', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .8 .9 .08]);

h.InfoLoadPan{7,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','Type:', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .72 .7 .08]);

h.InfoLoadPan{8,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','State:', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .64 .4 .08]);

h.InfoLoadPan{14,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','Tariff Component:', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.35 .64 .6 .08]);

h.InfoLoadPan{10,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','Daily Charge ($/day):', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .56 .8 .08]);

h.InfoLoadPan{11,1} = uicontrol(h.InfoTariffPanel,'Style','Text',...
    'String','Energy Cost ($/kWh):', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.03 .48 .8 .08]);

h.InfoLoadPan{12,1}=uitable(h.InfoTariffPanel,'Units', 'normalized','Position',[.03 .05 .90 .44]);


% 3- Demog info tab
h.tabi3 = uitab('parent',h.Info_Diag, 'title', 'Demog Info');
h.InfoDemogPanel = uipanel('Parent',h.tabi3, ...
    'Position',[.0 .0 1 1]);

% all the options text and info:
h.InfoLoadPan{4,1}  = uicontrol(h.InfoDemogPanel,'Style','Text',...
    'String','Demographic Information:', ...
    'FontWeight','bold',...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.09 .815 .8 .08]);
% Statistical analysis button
h.InfoLoadPan_Dem_SA_all=uicontrol(h.InfoDemogPanel, ...
    'Style','pushbutton', 'String','S',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.02 .84 .05 .05],...
    'TooltipString',['Statistical Analaysis'],...
    'Callback', {@SA_CB,0});

% all the demog info
for kk1=1:10
    
    h.InfoLoadPan_Dem{kk1,1} = uicontrol(h.InfoDemogPanel,'Style','Text',...
        'String','', ...
        'FontUnits','normalized',...
        'Value',1,...
        'HorizontalAlignment','left',...
        'Units', 'normalized', 'Position',[.09 .9-kk1*0.07-0.1 .9 .08]);
    
    h.InfoLoadPan_Dem_SA{kk1,1}=uicontrol(h.InfoDemogPanel, ...
        'Style','pushbutton', 'String','S',...
        'FontUnits','normalized',...
        'Visible','Off',...
        'Units', 'normalized', 'Position',[.02 .9-kk1*0.07-0.07 .05 .05],...
        'TooltipString',['Statistical Analaysis'],...
        'Callback', {@SA_CB,kk1});
end


h.InfoLoadPan{13,1} = uicontrol(h.InfoDemogPanel,'Style','Text',...
    'String','Case ', ...
    'FontUnits','normalized',...
    'Value',1,...
    'HorizontalAlignment','left',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.03 .9 .8 .08]);


%% GUI Elements: Tariff Panel
% Creating the uicontrols in tariff panel

% Panel
h.TariffPanel = uipanel('Parent',h.MainFigure,'Title','Select Tariff:',...
    'Units', 'normalized', 'Position',[0.315 .01 0.68 .28+0.035],...
    'FontWeight','bold',...
    'FontSize',10);
% 'BackgroundColor',color.back,

% List of Tariff filters, Text and Pop-up menu  (Type - State - Provider - Year)

% Type
h.TariffType_Text= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Type:', ...
    'HorizontalAlignment','left',...
    'FontWeight','bold',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.01 .84 .1 .11/1.125]);
h.TariffType_Pup= uicontrol(h.TariffPanel,'Style','popupmenu',...
    'String','N/A', ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.1 .845 .15 .1/1.125],...
    'Callback', @UpdateTariffList);
% State
h.TariffState_Text= uicontrol(h.TariffPanel,'Style','Text',...
    'String','State:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .67 .1 .11/1.125]);
h.TariffState_Pup= uicontrol(h.TariffPanel,'Style','popupmenu',...
    'String','N/A', ...
    'FontUnits','normalized',...
    'Value',1,'BackgroundColor','white',...
    'Units', 'normalized', 'Position',[.1 .675 .15 .11/1.125],...
    'Callback', @UpdateTariffList);
% Provider
h.TariffProvider_Text= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Provider:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .5 .1 .11/1.125]);
h.TariffProvider_Pup= uicontrol(h.TariffPanel,'Style','popupmenu',...
    'String','N/A', ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.1 .505 .15 .11/1.125],...
    'Callback', @UpdateTariffList);

% Year
h.TariffYear_Text= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Year:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .33 .1 .11/1.125]);
h.TariffYear_Pup= uicontrol(h.TariffPanel,'Style','popupmenu',...
    'String','N/A', ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.1 .335 .15 .11/1.125],...
    'Callback', @UpdateTariffList);

% Sector
h.TariffSector_Text= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Sector:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .17 .1 .11/1.125]);
h.TariffSector_Pup= uicontrol(h.TariffPanel,'Style','popupmenu',...
    'String','N/A', ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.1 .175 .15 .11/1.125],...
    'Callback', @UpdateTariffList);


% List of all tariffs (updated when chaing the filters by @UpdateTariffList)
h.TariffListText= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Tariff:', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.01 .01 .1 .11/1.125]); % [.01 .17 .1 .11/1.125]
h.TariffListPup= uicontrol(h.TariffPanel,'Style','popupmenu',...
    'String','N/A', ...
    'Value',1,'BackgroundColor','white',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.1 .015 .15 .11/1.125],...
    'Callback', @SelecTariff);


% Deleting the tariff
h.TarDelBut=uicontrol(h.TariffPanel, ...
    'Style','pushbutton', 'String','X',...
    'FontUnits','normalized',...
    'Visible','Off',...
    'TooltipString',['Delete this tariff'],...
    'Units', 'normalized', 'Position',[.26 .175 .02 .09],...
    'Callback',@DelCurTar);

h.TarDocBut=uicontrol(h.TariffPanel, ...
    'Style','pushbutton', 'String','i',...
    'FontUnits','normalized',...
    'Visible','Off',...
    'FontWeight','bold',...
    'FontAngle','italic',...
    'TooltipString',['Find info about this tariff'],...
    'Units', 'normalized', 'Position',[.28 .175 .02 .09],...
    'Callback',@DocCurTar);


% When editing some parameters of the tariff, you can also save the
% modified tariff as a new tariff.
h.TariffModifytext_2= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Save the modified tariff as:', ...
    'HorizontalAlignment','right',...
    'Visible','Off',...
    'TooltipString','Please note only this component of the tariff will be changed. To change all components try: Menu > Tariff > Create New Tariff',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.49 .008 .25 .1]);

h.NewTariffName= uicontrol(h.TariffPanel,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'Visible','Off',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.75 .01 .15 .1]);

h.AddTariffPB=uicontrol(h.TariffPanel, ...
    'Style','pushbutton', 'String','Save',...
    'Units', 'normalized', 'Position',[.9 .008 .06 0.1],...
    'Visible','Off',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Callback', @AddTariff);


% List of info of the tariff including name, state, year, etc

% Name
h.SelectTariff_Name= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Name:', ...
    'FontUnits','normalized',...
    'HorizontalAlignment','left',...
    'Units', 'normalized', 'Position',[.30 .9 .05 .1/1.125]);

h.NameSE= uicontrol(h.TariffPanel,'Style','Text',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.35 .9 .2 .1/1.125]);

% Type
h.SelectTariff_Type= uicontrol(h.TariffPanel,'Style','Text',...
    'String','Type:', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.55 .9 .05 .1/1.125]);

h.SelectTariff_Type_Value= uicontrol(h.TariffPanel,'Style','Text',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.62 .9 .15 .1/1.125]);

% State
h.SelectTariff_State= uicontrol(h.TariffPanel,'Style','Text',...
    'String','State:', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.76 .9 .05 .1/1.125]);


h.SelectTariff_State_Value= uicontrol(h.TariffPanel,'Style','Text',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Units', 'normalized', 'Position',[.83 .9 .06 .1/1.125]);

% Component applied


h.tabg_SelTar = uitabgroup('Parent',h.TariffPanel,'Tag','Loadtabs', ...
    'Units','normalized','Position',[0.3 0.1 0.7 0.8]);

% h.tabg_SelTar = uitabgroup('Parent',h.TariffPanel,'Tag','Loadtabs', ...
%     'Units','normalized','Position',[0.3 0.1 0.7 0.8],'SelectionChangedFcn',@TarTabChange);

h.tabg_SelTar_DUOS = uitab('parent',h.tabg_SelTar, 'title', 'DUOS');
h.tabg_SelTar_DUOS_P = uipanel('Parent',h.tabg_SelTar_DUOS, ...
    'Position',[.0 .0 1 1]);

h.tabg_SelTar_TUOS = uitab('parent',h.tabg_SelTar, 'title', 'TUOS');
h.tabg_SelTar_TUOS_P = uipanel('Parent',h.tabg_SelTar_TUOS, ...
    'Position',[.0 .0 1 1]);

h.tabg_SelTar_DTUOS = uitab('parent',h.tabg_SelTar, 'title', 'DUOS+TUOS');
h.tabg_SelTar_DTUOS_P = uipanel('Parent',h.tabg_SelTar_DTUOS, ...
    'Position',[.0 .0 1 1]);

h.tabg_SelTar_NUOS = uitab('parent',h.tabg_SelTar, 'title', 'NUOS');
h.tabg_SelTar_NUOS_P = uipanel('Parent',h.tabg_SelTar_NUOS, ...
    'Position',[.0 .0 1 1]);
h.tabg_SelTar.SelectedTab = h.tabg_SelTar_NUOS;


% DUOS
h.DailyChargeSTR_DUOS= uicontrol(h.tabg_SelTar_DUOS_P,'Style','Text',...
    'String','Daily Charge ($/day):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.01 .82 .18 .13]);

h.DailySE_DUOS= uicontrol(h.tabg_SelTar_DUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'CallBack',@TariffPar_CellEditCallback,...
    'Units', 'normalized', 'Position',[.20 .825 .13 .13]);

h.EnergyCostStr_DUOS= uicontrol(h.tabg_SelTar_DUOS_P,'Style','Text',...
    'String','Energy Charge ($/kWh):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.35 .82 .2 .13]);
h.EnergyCostEdit_DUOS= uicontrol(h.tabg_SelTar_DUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'CallBack',@TariffPar_CellEditCallback,...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.56 .82 .1 .13]);

h.TariffParTable_DUOS=uitable(h.tabg_SelTar_DUOS_P,'Units', 'normalized','Position',[.015 .05 .94 0.7],'CellEditCallback',@TariffPar_CellEditCallback);



% TUOS
h.DailyChargeSTR_TUOS= uicontrol(h.tabg_SelTar_TUOS_P,'Style','Text',...
    'String','Daily Charge ($/day):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.01 .82 .18 .13]);

h.DailySE_TUOS= uicontrol(h.tabg_SelTar_TUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'CallBack',@TariffPar_CellEditCallback,...
    'Units', 'normalized', 'Position',[.20 .825 .13 .13]);

h.EnergyCostStr_TUOS= uicontrol(h.tabg_SelTar_TUOS_P,'Style','Text',...
    'String','Energy Charge ($/kWh):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.35 .82 .2 .13]);
h.EnergyCostEdit_TUOS= uicontrol(h.tabg_SelTar_TUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'CallBack',@TariffPar_CellEditCallback,...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.56 .82 .1 .13]);

h.TariffParTable_TUOS=uitable(h.tabg_SelTar_TUOS_P,'Units', 'normalized','Position',[.015 .05 .94 0.7],'CellEditCallback',@TariffPar_CellEditCallback);


% NUOS
h.DailyChargeSTR_NUOS= uicontrol(h.tabg_SelTar_NUOS_P,'Style','Text',...
    'String','Daily Charge ($/day):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.01 .82 .18 .13]);

h.DailySE_NUOS= uicontrol(h.tabg_SelTar_NUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'CallBack',@TariffPar_CellEditCallback,...
    'Units', 'normalized', 'Position',[.20 .825 .13 .13]);

h.EnergyCostStr_NUOS= uicontrol(h.tabg_SelTar_NUOS_P,'Style','Text',...
    'String','Energy Charge ($/kWh):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.35 .82 .2 .13]);
h.EnergyCostEdit_NUOS= uicontrol(h.tabg_SelTar_NUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'CallBack',@TariffPar_CellEditCallback,...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.56 .82 .1 .13]);

h.TariffParTable_NUOS=uitable(h.tabg_SelTar_NUOS_P,'Units', 'normalized','Position',[.015 .05 .94 0.7],'CellEditCallback',@TariffPar_CellEditCallback);


% DUOS+TUOS
h.DailyChargeSTR_DTUOS= uicontrol(h.tabg_SelTar_DTUOS_P,'Style','Text',...
    'String','Daily Charge ($/day):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.01 .82 .18 .13]);

h.DailySE_DTUOS= uicontrol(h.tabg_SelTar_DTUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'CallBack',@TariffPar_CellEditCallback,...
    'Units', 'normalized', 'Position',[.20 .825 .13 .13]);

h.EnergyCostStr_DTUOS= uicontrol(h.tabg_SelTar_DTUOS_P,'Style','Text',...
    'String','Energy Charge ($/kWh):', ...
    'HorizontalAlignment','left',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.35 .82 .2 .13]);
h.EnergyCostEdit_DTUOS= uicontrol(h.tabg_SelTar_DTUOS_P,'Style','Edit',...
    'String','N/A', ...
    'HorizontalAlignment','left',...
    'CallBack',@TariffPar_CellEditCallback,...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.56 .82 .1 .13]);

h.TariffParTable_DTUOS=uitable(h.tabg_SelTar_DTUOS_P,'Units', 'normalized','Position',[.015 .05 .94 0.7],'CellEditCallback',@TariffPar_CellEditCallback);



h.AddDiag=uicontrol(h.TariffPanel, ...
    'Style','pushbutton', 'String','Add',...
    'Units', 'normalized', 'Position',[.91 .83 .07 .15],...
    'FontUnits','normalized',...
    'FontWeight','bold',...
    'Callback', @AddDiag);

% Before applying the tariff to the load data you can choose to apply GST
% or not.
h.SelectTariff_GST= uicontrol(h.TariffPanel,'Style','Check',...
    'String','Exclude GST', ...
    'HorizontalAlignment','right',...
    'FontUnits','normalized',...
    'Units', 'normalized', 'Position',[.3 .008 .12 .1/1.125]);


%% ********************* Initialisation of parameters ********************

% List of loads (look for loads in the folder and impr the list of them)
if ispc
    ListofFiles=dir('Data\LoadData_*');
else
    ListofFiles=dir([h.FilesPath,'/Data/LoadData_*']);
end
temp=struct2cell(ListofFiles);
temp=strrep(temp(1,:),'.mat','');
temp=strrep(temp(1,:),'LoadData_','');

h.SelectLoad_Pup.String=temp;

h.AllTariffs_Filtered=h.TariffList.AllTariffs;
% update the list of tariffs
% List of tariffs
h.TariffType_Pup.String=['All',unique({h.TariffList.AllTariffs.Type})];
h.TariffState_Pup.String=['All',unique({h.TariffList.AllTariffs.State})];
h.TariffProvider_Pup.String=['All',unique({h.TariffList.AllTariffs.Provider})];

h.TariffYear_Pup.String=['All',unique({h.TariffList.AllTariffs.Year})];

h.TariffSector_Pup.String=['All',unique({h.TariffList.AllTariffs.Sector})];

h.TariffListPup.String={'Select:',h.TariffList.AllTariffs.Name};

h.LoadedLoads.Ini=1;


%% ********************* Callback Functions  *****************************
% Loading the project
    function LoadPrjLis(src,evnt,i)
        DelMsg;msgbox('Loading project.. Please wait.')
        % Load the Prj_* file
        if ispc
            test=load(['Prj_',h.PrjList{1,i},'.mat']);
        else
            test=load([h.FilesPath,'/Prj_',h.PrjList{1,i},'.mat']);
        end
        % check if there is any results saved in this file
        if size(test.ProjData,1)<1
            DelMsg;msgbox(['There is no result saved in this project!'])
        else
            
            % put the results in the AllDiagrams file
            h.AllDiagrams=test.ProjData;
            % loading the load files which have been used in the project
            for j=1:size(h.AllDiagrams,1)
                NewLoadName=h.AllDiagrams{j,1}.SelectedDatabase;
                if ~isfield(h,'AllLoads')
                    LoadNum=1;
                    h.AllLoads={};
                    NewLoadComes=1;
                elseif ~strcmp(h.AllLoads(:,1),NewLoadName)
                    NewLoadComes=1;
                    LoadNum=size(h.AllLoads,1)+1;
                else
                    NewLoadComes=0;
                end
                if NewLoadComes
                    if ispc
                        Temp=load(['Data\LoadData_',NewLoadName,'.mat']);
                    else
                        Temp=load([h.FilesPath,'/Data/LoadData_',NewLoadName,'.mat']);
                    end
                    
                    h.AllLoads{LoadNum,1}=NewLoadName;
                    h.AllLoads{LoadNum,2}=Temp.LoadData;
                    % finding the network load
                    h.AllLoads{LoadNum,2}.Load.NetworkLoad=nan(size(h.AllLoads{LoadNum,2}.Load.kWh,1),1);
                    h.AllLoads{LoadNum,2}.Load.NetworkLoad(2:end,1)=nanmean(h.AllLoads{LoadNum,2}.Load.kWh(2:end,:),2);
                    h.AllLoads{LoadNum,2}.Load.NetworkLoad(isnan(h.AllLoads{LoadNum,2}.Load.NetworkLoad))=0;
                    % finding LDC of network
                    [~,indp2]= sort(h.AllLoads{LoadNum, 2}.Load.NetworkLoad(2:end,1),'descend');
                    Times=h.AllLoads{LoadNum, 2}.Load.TimeStamp(2:end);
                    h.AllLoads{LoadNum,3}.Network_LDC_ind=indp2;
                    [~,Indp5]=unique(floor(datenum(Times(h.AllLoads{LoadNum,3}.Network_LDC_ind))),'stable');
                    h.AllLoads{LoadNum,3}.Network_LDC_ind_Daily=indp2(Indp5);
                end
            end
            
            h.ProjectName=h.PrjList{1,i};
            h.ProjectText.String=['Project Name: ',h.PrjList{1,i}];
            % updating everything based on this project
            update_listofExports(src,evnt);
            update_DualVar(src,evnt,1);
            update_SingVar(src,evnt,1);
            update_SingCase(src,evnt,1);
            UpdateListofCasesPanel(src,evnt);
            ShowCase_Diag(src,evnt,size(h.AllDiagrams,1));
            
            for in=1:size(h.AllDiagrams,1)
                h.SingCase_List.String{in,1}=h.AllDiagrams{in,1}.CaseName;
            end
            
            DelMsg;msgbox([h.PrjList{1,i},' has been loaded.'])
        end
    end

    function DelPrjLis(src,evnt,i)
        % Function for deleteing a project
        if i==-1
            % if confirmation option is selected
            if h.Confirm.BeforeDeleting.Project
                choice = questdlg(['Are you sure you want to delete all projects?'], ...
                    'Deleting all project', ...
                    'Yes','No','No');
                % Handle response
                switch choice
                    case 'Yes'
                        for i=1:size(h.PrjList,2)
                            if ispc
                                delete(['Prj_',h.PrjList{1,i},'.mat'])
                            else
                                delete([h.FilesPath,'/Prj_',h.PrjList{1,i},'.mat'])
                            end
                        end
                        h.ProjectName='Undefined';
                        h.ProjectText.String='Undefined';
                        updatePrjList
                        updatePrjList_del
                        DelMsg;msgbox(['All projects have been deleted!'])
                    case 'No'
                end
                
            else
                for i=1:size(h.PrjList,2)
                    if ispc
                        delete(['Prj_',h.PrjList{1,i},'.mat'])
                    else
                        delete([h.FilesPath,'/Prj_',h.PrjList{1,i},'.mat'])
                    end
                end
                h.ProjectName='Undefined';
                h.ProjectText.String='Undefined';
                updatePrjList
                updatePrjList_del
                DelMsg;msgbox(['All projects have been deleted!'])
            end
        else
            
            if h.Confirm.BeforeDeleting.Project
                choice = questdlg(['Are you sure you want to delete Project ',h.PrjList{1,i},'?'], ...
                    'Deleting project', ...
                    'Yes','No','No');
                % Handle response
                switch choice
                    case 'Yes'
                        if ispc
                            delete(['Prj_',h.PrjList{1,i},'.mat'])
                        else
                            delete([h.FilesPath,'/Prj_',h.PrjList{1,i},'.mat'])
                        end
                        name=h.PrjList{1,i};
                        updatePrjList
                        updatePrjList_del
                        if strcmp(h.ProjectText.String(15:end),name)
                            h.ProjectText.String=['Project Name: Undefined'] ;
                            h.ProjectName='Undefined';
                        end
                        DelMsg;msgbox([name,' has been deleted!'])
                    case 'No'
                end
            else
                if ispc
                    delete(['Prj_',h.PrjList{1,i},'.mat'])
                else
                    delete([h.FilesPath,'/Prj_',h.PrjList{1,i},'.mat'])
                end
                name=h.PrjList{1,i};
                updatePrjList
                updatePrjList_del
                if strcmp(h.ProjectText.String(15:end),name)
                    h.ProjectText.String=['Project Name: Undefined'] ;
                    h.ProjectName='Undefined';
                end
                DelMsg;msgbox([name,' has been deleted!'])
            end
        end
    end

    function DelLoadLis(src,evnt,i)
        % Function for deleting load (ini)
        if h.Confirm.BeforeDeleting.Load
            choice = questdlg(['Are you sure you want to delete Load ',h.LoadList{1,i},'?'], ...
                'Deleting Load data', ...
                'Yes','No','No');
            % Handle response
            switch choice
                case 'Yes'
                    DelLoadLis2(src,evnt,i)
                case 'No'
            end
        else
            DelLoadLis2(src,evnt,i)
        end
    end

    function DelLoadLis2(src,evnt,i)
        % function for deleting load
        OriginalList= {'LoadData_AG300_2010_11_Gross.mat';'LoadData_AG300_2010_11_Net.mat';'LoadData_AG300_2011_12_Gross.mat';'LoadData_AG300_2011_12_Net.mat';'LoadData_AG300_2012_13_Gross.mat';'LoadData_AG300_2012_13_Net.mat';'LoadData_SGSC.mat';'LoadData_SGSC_sample.mat'};
        if ispc
            if numel(find(strcmp(OriginalList,['LoadData_',h.LoadList{1,i},'.mat'])))
                movefile(['Data\LoadData_',h.LoadList{1,i},'.mat'],['Data\Del_LoadData_',h.LoadList{1,i},'.mat'])
            else
                delete(['Data\LoadData_',h.LoadList{1,i},'.mat'])
            end
        else
            if numel(find(strcmp(OriginalList,['LoadData_',h.LoadList{1,i},'.mat'])))
                movefile([h.FilesPath,'/Data/LoadData_',h.LoadList{1,i},'.mat'],[h.FilesPath,'/Data/Del_LoadData_',h.LoadList{1,i},'.mat'])
            else
                delete([h.FilesPath,'/Data/LoadData_',h.LoadList{1,i},'.mat'])
            end
        end
        name=h.LoadList{1,i};
        updateLoadList_del
        DelMsg;msgbox([name,' Data has been deleted!'])
    end

    function UpdateTariffList(src,evnt)
        % when a pupupmenu changes for selecting a new tariff
        if h.TariffType_Pup.Value==1
            indetype=[1:size(h.TariffList.AllTariffs,2)];
        else
            indetype=find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Type},h.TariffType_Pup.String(h.TariffType_Pup.Value))));
        end
        
        if h.TariffState_Pup.Value==1
            indestate=[1:size(h.TariffList.AllTariffs,2)];
        else
            indestate=find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.State},h.TariffState_Pup.String(h.TariffState_Pup.Value))));
        end
        
        if h.TariffProvider_Pup.Value==1
            indeprovider=[1:size(h.TariffList.AllTariffs,2)];
        else
            indeprovider=find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Provider},h.TariffProvider_Pup.String(h.TariffProvider_Pup.Value))));
        end
        
        if h.TariffYear_Pup.Value==1
            indeyear=[1:size(h.TariffList.AllTariffs,2)];
        else
            indeyear=find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Year},h.TariffYear_Pup.String(h.TariffYear_Pup.Value))));
        end
        
        if h.TariffSector_Pup.Value==1
            indesector=[1:size(h.TariffList.AllTariffs,2)];
        else
            indesector=find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Sector},h.TariffSector_Pup.String(h.TariffSector_Pup.Value))));
        end
        
        
        if size(intersect(indetype,intersect(indestate,intersect(indeyear,indeprovider))))>0
            h.AllTariffs_Filtered=h.TariffList.AllTariffs(1,intersect(indetype,intersect(indestate,intersect(indeyear,intersect(indesector,indeprovider)))));
            h.TariffListPup.Value=1;
            h.TarDelBut.Visible='Off';
            h.TarDocBut.Visible='Off';
            h.TariffListPup.String={'Select',h.AllTariffs_Filtered.Name};
        else
            DelMsg;msgbox('There is no Tariff for these criteria! Please change the filter and try again!');
        end
        
    end

    function SelecTariff(src,evnt)
        % function for selecting the tariff
        if h.TariffListPup.Value>1
            h.TarDelBut.Visible='On';
            h.TarDocBut.Visible='On';
            h.TariffModifytext_2.Visible='off';
            h.NewTariffName.Visible='off';
            h.AddTariffPB.Visible='off';
            h.TariffSelected=1;
            % find the selected tariff:
            % assign it as MyTariff
            h.MyTariff=h.TariffList.AllTariffs(find(strcmp({h.TariffList.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value})));
            
            h.SelectTariff_State_Value.String=h.MyTariff.State;
            h.NameSE.String=h.MyTariff.Name;
            try
                h.NameSE.TooltipString=h.MyTariff.Info;
            end
            h.SelectTariff_Type_Value.String=h.MyTariff.Type;
            
            % Check if it has daily parameter and hide/show the option accordingly
            
            if isfield(h.MyTariff.Parameters.DUOS,'Daily')
                h.DailySE_DUOS.Visible='on';
                h.DailySE_DUOS.String=num2str(h.MyTariff.Parameters.DUOS.Daily.Value);
                h.DailyChargeSTR_DUOS.Visible='on';
                
                h.DailySE_TUOS.Visible='on';
                h.DailySE_TUOS.String=num2str(h.MyTariff.Parameters.TUOS.Daily.Value);
                h.DailyChargeSTR_TUOS.Visible='on';
                
                h.DailySE_NUOS.Visible='on';
                h.DailySE_NUOS.String=num2str(h.MyTariff.Parameters.NUOS.Daily.Value);
                h.DailyChargeSTR_NUOS.Visible='on';
                
                h.DailySE_DTUOS.Visible='on';
                h.DailySE_DTUOS.String=num2str(h.MyTariff.Parameters.DTUOS.Daily.Value);
                h.DailyChargeSTR_DTUOS.Visible='on';

            else
                h.DailySE_DUOS.Visible='off';
                h.DailyChargeSTR_DUOS.Visible='off';
                h.DailySE_TUOS.Visible='off';
                h.DailyChargeSTR_TUOS.Visible='off';
                h.DailySE_NUOS.Visible='off';
                h.DailyChargeSTR_NUOS.Visible='off';
                h.DailySE_DTUOS.Visible='off';
                h.DailyChargeSTR_DTUOS.Visible='off';
            end
            
            % check if it has volumetric energy parameter and hide/show the option accordingly
            if isfield(h.MyTariff.Parameters.DUOS,'Energy')
                h.EnergyCostEdit_DUOS.Visible='on';
                h.EnergyCostEdit_DUOS.String=num2str(h.MyTariff.Parameters.DUOS.Energy.Value);
                h.EnergyCostStr_DUOS.Visible='on';
                
                h.EnergyCostEdit_TUOS.Visible='on';
                h.EnergyCostEdit_TUOS.String=num2str(h.MyTariff.Parameters.TUOS.Energy.Value);
                h.EnergyCostStr_TUOS.Visible='on';
                
                h.EnergyCostEdit_NUOS.Visible='on';
                h.EnergyCostEdit_NUOS.String=num2str(h.MyTariff.Parameters.NUOS.Energy.Value);
                h.EnergyCostStr_NUOS.Visible='on';
                
                h.EnergyCostEdit_DTUOS.Visible='on';
                h.EnergyCostEdit_DTUOS.String=num2str(h.MyTariff.Parameters.DTUOS.Energy.Value);
                h.EnergyCostStr_DTUOS.Visible='on';
                
            else
                h.EnergyCostEdit_DUOS.Visible='off';
                h.EnergyCostStr_DUOS.Visible='off';
                
                h.EnergyCostEdit_TUOS.Visible='off';
                h.EnergyCostStr_TUOS.Visible='off';
                
                h.EnergyCostEdit_NUOS.Visible='off';
                h.EnergyCostStr_NUOS.Visible='off';
                
                h.EnergyCostEdit_DTUOS.Visible='off';
                h.EnergyCostStr_DTUOS.Visible='off';
                
            end
            
            % show the table containing all the parameters:
            h.Mytable_DUOS=h.MyTariff.Parameters.DUOS.Other;
            h.Mytable_TUOS=h.MyTariff.Parameters.TUOS.Other;
            h.Mytable_NUOS=h.MyTariff.Parameters.NUOS.Other;
            h.Mytable_DTUOS=h.MyTariff.Parameters.DTUOS.Other;
            
            % put the parameters of the table to the parameters of the tariff
            h.TariffParTable_DUOS.Data=table2cell(h.Mytable_DUOS);
            h.TariffParTable_DUOS.ColumnName=h.Mytable_DUOS.Properties.VariableNames;
            
            h.TariffParTable_TUOS.Data=table2cell(h.Mytable_TUOS);
            h.TariffParTable_TUOS.ColumnName=h.Mytable_TUOS.Properties.VariableNames;
            
            h.TariffParTable_NUOS.Data=table2cell(h.Mytable_NUOS);
            h.TariffParTable_NUOS.ColumnName=h.Mytable_NUOS.Properties.VariableNames;
            
            h.TariffParTable_DTUOS.Data=table2cell(h.Mytable_DTUOS);
            h.TariffParTable_DTUOS.ColumnName=h.Mytable_DTUOS.Properties.VariableNames;
            
            for i=1:size(h.TariffParTable_DUOS.ColumnName,1)
                temp2= h.TariffParTable_DUOS.ColumnName{i,1};
                if strcmp(temp2,'Unit')||strcmp(temp2,'Comment')||strcmp(temp2,'Bound_unit')
                    h.TariffParTable_DUOS.ColumnEditable(1,i)=false;
                    h.TariffParTable_TUOS.ColumnEditable(1,i)=false;
                    h.TariffParTable_NUOS.ColumnEditable(1,i)=false;
                    h.TariffParTable_DTUOS.ColumnEditable(1,i)=false;
                else
                    h.TariffParTable_DUOS.ColumnEditable(1,i)=true;
                    h.TariffParTable_TUOS.ColumnEditable(1,i)=true;
                    h.TariffParTable_NUOS.ColumnEditable(1,i)=true;
                    h.TariffParTable_DTUOS.ColumnEditable(1,i)=true;
                    
                end
            end
            
            h.SthEdited=0;
            
        else
            h.TarDelBut.Visible='Off';
        end
    end

%% ********************* Callback functions*****************************

%% Response to menu options:
% User Guide
    function UserGuide_Callback(src,evnt)
        try
            try
                if(ispc)
                    winopen(['TDA_Instruction.pdf'])
                elseif(ismac)
                    system(['open ',[h.FilesPath,'/TDA_Instruction.pdf']])
                end
            catch
                msgbox('Sorry! There is a problem in opening of the file!')
            end
        catch
            DelMsg;msgbox('There is a problem in opening of the pdf file!')
        end
    end

% Update
    function Update_Callback(src,evnt)
        
        choice = questdlg(['New versions of the software as well as new load an tariff data will become available in the project webcite. Please refer to this website for more information.'], ...
            'Check for update', ...
            'Open Website','Cancel','Cancel');
        % Handle response
        switch choice
            case 'Open Website'
                try
                    web('http://www.ceem.unsw.edu.au/cost-reflective-tariff-design','-browser')
                catch
                    DelMsg;msgbox('There is a problem in opening the webpage! Please refer to http://www.ceem.unsw.edu.au/cost-reflective-tariff-design')
                end
        end
    end

% Feedback
    function Feedback_Callback(src,evnt)
        % --- Executes on button press in Feedback (sending email to the
        % tariffapp@gmail.com
        handles.userinput = inputdlg({'Name','Email','Subject','Message'},...
            'Send Feedback', [1 50; 1 50;1 50; 10 50]);
        if numel(handles.userinput) >0
            
            % for seting up the gmail for sending the email:
            GmailSetup
            myaddress='tariffapp@gmail.com';
            mailbody = cellstr(handles.userinput{4,1}) ;
            mailbody2 = ['Email address: ' handles.userinput{2,1} 10 'Name: ',handles.userinput{1,1} 10 'Message:  '];
            
            mailbody3=mailbody2;
            for kj=1:size(handles.userinput{4,1},1)
                mailbody3=[mailbody3 10 char(mailbody(kj))];
            end
            
            DelMsg;msgbox('Sending.. Please wait!');
            try
                sendmail(myaddress,handles.userinput{3,1},mailbody3);
                h2=1;
            catch exception
                h2=2;
            end
            
            try
                sendmail(handles.userinput{2,1},'Thanks for the feedback!',['Dear ',handles.userinput{1,1},'!',10,10,'Thanks for sending the feedback!',10,10,'We will get back to you shortly!',10,10,'Regards',10,10,'Tariff Design Tool Team!']);
                h3=1;
            catch exception
                h3=2;
            end
            
            if h2==2
                DelMsg;msgbox('There was a problem in sending feedback! Please check your internet connection (or pause your anti-virus) and try again! IF not worked, please send us an email on "n.haghdadi@unsw.edu.au". Sorry for the inconvenience.  ');
            elseif h3==2
                DelMsg;msgbox('Thanks for the feedback! But the email address you provided seem to be not working! Please provide a correct email address if you want us to get back to you!');
            else
                DelMsg;msgbox(['Dear ',handles.userinput{1,1},'! Thanks for sending the feedback! We will get back to you in few days!']);
            end
            
        end
        
    end

% About
    function About_CEEM_Callback(src,evnt)
        try
            web('http://www.ceem.unsw.edu.au/cost-reflective-tariff-design','-browser')
        catch
            DelMsg;msgbox('There is a problem in opening the webpage! Please refer to http://www.ceem.unsw.edu.au/cost-reflective-tariff-design')
        end
    end

    function About_RG_Callback(src,evnt)
        try
            web('https://www.researchgate.net/project/Tariff-Design-and-Analysis-TDA-Tool','-browser')
        catch
            DelMsg;msgbox('There is a problem in opening the webpage! Please refer to https://www.researchgate.net/project/Tariff-Design-and-Analysis-TDA-Tool')
        end
    end

    function About_GH_Callback(src,evnt)
        try
            web('https://github.com/UNSW-CEEM','-browser')
        catch
            DelMsg;msgbox('There is a problem in opening the webpage! Please refer to https://github.com/UNSW-CEEM')
        end
    end

% Subscribe
    function Subscribe_Callback(src,evnt)
        choice = questdlg(['Subscribe to our email list to receive latest news, updates, and discussions by clicking on "Subscribe" or sending an email to n.haghdadi@unsw.edu.au with subject: TDA subscribe.'], ...
            'Subscribe', ...
            'Subscribe','Cancel','Subscribe');
        % Handle response
        switch choice
            case 'Subscribe'
                
                handles.userinput = inputdlg({'Preferred name','Email'},...
                    'Subscribe', [1 50; 1 50]);
                if numel(handles.userinput) >0
                    
                    % for seting up the gmail for sending the email:
                    GmailSetup
                    myaddress='tariffapp@gmail.com';
                    mailbody2 = ['Subscribe: Email address: ' handles.userinput{2,1} 10 'Name: ',handles.userinput{1,1} 10];
                    mailbody3=mailbody2;
                    DelMsg;msgbox('Please wait!');
                    try
                        sendmail(myaddress,'Subscription',mailbody3);
                        h2=1;
                    catch exception
                        
                        h2=2;
                    end
                    
                    try
                        sendmail(handles.userinput{2,1},'Thanks for subscribing in our email list!',['Dear ',handles.userinput{1,1},'!',10,10,'Thanks for subscribing in our email list!',10,10,'Regards',10,10,'Tariff Design Tool Team!']);
                        h3=1;
                    catch exception
                        h3=2;
                        
                    end
                    
                    if h2==2
                        DelMsg;msgbox('There was a problem in your connection! Please check your internet connection (or pause your anti-virus) and try again! If not worked, please send an email to "n.haghdadi@unsw.edu.au" with subject: TDA subscribe. Sorry for the inconvenience.  ');
                    elseif h3==2
                        DelMsg;msgbox('Thanks for subscribing! But the email address you provided seem to be not working! Please provide a correct email address or send an email to "n.haghdadi@unsw.edu.au" with subject: TDA subscribe.!');
                    else
                        DelMsg;msgbox(['Dear ',handles.userinput{1,1},'! Thanks for subscribing! You have been successfully added to our mailing list! For unsubscribe., please send an email to n.haghdadi@unsw.edu.au with the subject: TDA unsubscribe']);
                    end
                end
        end
        
    end

% Saving Project
    function SaveProjAs_CB(src,evnt)
       % Creating the  
        h.SaveProj.F = figure('Name','Save Project as','NumberTitle','off', ...
            'HandleVisibility','on','Resize','off', ...
            'Position',[200,200, 400, 150],...
            'Toolbar','none','Menubar','none'); % Figure to save project
        
        movegui(h.SaveProj.F ,'center')
        h.SaveProj.P=uipanel('Parent',h.SaveProj.F,...
            'Units', 'normalized', 'Position',[0 0 1 1],...
            'FontWeight','bold',...
            'FontSize',10);
        
        h.SaveProj.T1= uicontrol(h.SaveProj.P,'Style','Text',...
            'String','Project Name:', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.01 .75 .3 .17],...
            'HorizontalAlignment','left');
        
        h.SaveProj.T2= uicontrol(h.SaveProj.P,'Style','Edit',...
            'String',['Project_',datestr(now,'yyyymmdd_HHMM')], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.31 .75 .5 .17],...
            'HorizontalAlignment','left');
        
        temp=uicontrol(h.SaveProj.P, ...
            'Style','pushbutton', 'String','Save',...
            'Units', 'normalized', 'Position',[.2 .1 .2 .2],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'Callback', @SaveProj_CB2);
        
        temp=uicontrol(h.SaveProj.P, ...
            'Style','pushbutton', 'String','Cancel',...
            'Units', 'normalized', 'Position',[.6 .1 .2 .2],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'Callback', @SaveProj_CB3);
        
    end
    function SaveProj_CB(src,evnt)
        
        if strcmp(h.ProjectName,'Undefined')
            
            h.SaveProj.F = figure('Name','Save Project as','NumberTitle','off', ...
                'HandleVisibility','on','Resize','off', ...
                'Position',[200,200, 400, 150],...
                'Toolbar','none','Menubar','none'); % Figure to save project
            
            movegui(h.SaveProj.F ,'center')
            h.SaveProj.P=uipanel('Parent',h.SaveProj.F,...
                'Units', 'normalized', 'Position',[0 0 1 1],...
                'FontWeight','bold',...
                'FontSize',10);
            
            h.SaveProj.T1= uicontrol(h.SaveProj.P,'Style','Text',...
                'String','Project Name:', ...
                'FontUnits','normalized',...
                'Value',1,...
                'Units', 'normalized', 'Position',[.01 .75 .3 .17],...
                'HorizontalAlignment','left');
            
            h.SaveProj.T2= uicontrol(h.SaveProj.P,'Style','Edit',...
                'String',['Project_',datestr(now,'yyyymmdd_HHMM')], ...
                'FontUnits','normalized',...
                'Value',1,...
                'Units', 'normalized', 'Position',[.31 .75 .5 .17],...
                'HorizontalAlignment','left');
            
            temp=uicontrol(h.SaveProj.P, ...
                'Style','pushbutton', 'String','Save',...
                'Units', 'normalized', 'Position',[.2 .1 .2 .2],...
                'FontWeight','bold',...
                'FontUnits','normalized',...
                'Callback', @SaveProj_CB2);
            
            temp=uicontrol(h.SaveProj.P, ...
                'Style','pushbutton', 'String','Cancel',...
                'Units', 'normalized', 'Position',[.6 .1 .2 .2],...
                'FontWeight','bold',...
                'FontUnits','normalized',...
                'Callback', @SaveProj_CB3);
        else
            
            DelMsg;msgbox('Saving project.. Please wait!');
            
            ProjData=h.AllDiagrams;
            if ispc
                save(['Prj_',h.ProjectName,'.mat'],'ProjData')
            else
                save([h.FilesPath,'/Prj_',h.ProjectName,'.mat'],'ProjData')
            end
            
            DelMsg;msgbox(['The project is successfully saved.'])
        end
    end


    function SaveProj_CB2(src,evnt)
        
        % check if the name is correct
        
        % put required data in ProjData
        ProjData=h.AllDiagrams;
        name=h.SaveProj.T2.String;
        close(h.SaveProj.F)
        DelMsg;msgbox('Saving project.. Please wait!');
        if ispc
            save(['Prj_',name,'.mat'],'ProjData')
        else
            
            save([h.FilesPath,'/Prj_',name,'.mat'],'ProjData')
            
        end
        updatePrjList
        updatePrjList_del
        
        h.ProjectText.String=['Project Name: ',name];
        h.ProjectName=name;
        DelMsg;msgbox(['Project ',name,' is successfully saved.'])
        
    end


    function SaveProj_CB3(src,evnt)
        
        close(h.SaveProj.F)
        
    end

% Restoring tariffs
    function ResTar(src,evnt)
        % Resetting the tariffs to the main one
        choice = questdlg(['Are you sure you want to Reset tariffs? This will delete all your new tariffs and undo your tariff modifications.'], ...
            'Reset tariff', ...
            'Yes','No','No');
        % Handle response
        switch choice
            case 'Yes'
                if ispc
                    temp2=load('Data\AllTariffs.mat','AllTariffs');
                else
                    temp2=load([h.FilesPath,'/Data/AllTariffs.mat'],'AllTariffs');
                end
                for yh=1:size(temp2.AllTariffs,2)
                    temp2.AllTariffs(1,yh).Show=true;
                end
                AllTariffs=temp2.AllTariffs;
                h.TariffList.AllTariffs=AllTariffs;
                if ispc
                    save('Data\AllTariffs.mat','AllTariffs')
                    delete('Data\AllTariffs_New.mat')
                else
                    save([h.FilesPath,'/Data/AllTariffs.mat'],'AllTariffs')
                    delete([h.FilesPath,'/Data/AllTariffs_New.mat'])
                end
                
                h.TariffListPup.String={'Select:',h.TariffList.AllTariffs.Name};
                h.TariffListPup.Value=1;
                DelMsg;msgbox('The list of tariffs has been successfully reset to the original values.')
        end
    end


    function HelpTariff(src,evnt)
        
        try
            if(ispc)
                winopen('Data\AllTariffs.xlsx')
            else
                system(['open ',[h.FilesPath,'/Data/AllTariffs.xlsx']])
            end
        catch
            msgbox('Sorry! There is a problem in opening of the file!')
        end
    end


    function RestartTool(src,evnt)
        
        closeGUI(src,evnt)
        TDA
        
    end


    function closeGUI(src,evnt)
        %         function to close gui
        
        if h.Confirm.BeforeExit
            if ~strcmp(h.ProjectName,'Undefined')
                choice = questdlg(['Are you sure you want to close the application? You can save the changes you have made to the active project.'], ...
                    'Exiting Tool', ...
                    'Exit','Save and Exit','Cancel','Cancel');
                % Handle response
                switch choice
                    case 'Exit'
                        delete(gcf)
                    case 'Save and Exit'
                        DelMsg;msgbox('Saving project.. Please wait!');
                        ProjData=h.AllDiagrams;
                        if ispc
                            save(['Prj_',h.ProjectName,'.mat'],'ProjData')
                        else
                            save([h.FilesPath,'/Prj_',h.ProjectName,'.mat'],'ProjData')
                        end
                        DelMsg
                        delete(gcf)
                end
            else
                choice = questdlg(['Are you sure you want to close the application? You have no active project and upon closing the tool you will lose the results.'], ...
                    'Exiting Tool', ...
                    'Exit','Cancel','Cancel');
                % Handle response
                switch choice
                    case 'Exit'
                        delete(gcf)
                end
            end
        else
            delete(gcf)
        end
        
    end

%% ********************* Selecting load  *****************************
    function SetLoad_CB(src,evnt)
        % Executes when pressing pushbutton "Set" in load panel
        
        DelMsg;msgbox('Please wait! Loading data..');
        
        % converting the name to acceptable name of the load (by which the load has been saved)
        NewLoadName = h.SelectLoad_Pup.String{h.SelectLoad_Pup.Value};
        % Check if the load data has already been loaded to tool to save time in
        % next selection. Otherwise download the load
        
        if ~isfield(h,'AllLoads')
            LoadNum=1;
            h.AllLoads={};
            NewLoadComes=1;
        elseif ~strcmp(h.AllLoads(:,1),NewLoadName)
            NewLoadComes=1;
            LoadNum=size(h.AllLoads,1)+1;
        else
            NewLoadComes=0;
        end
        
        if NewLoadComes
            
            if ispc
                Temp=load(['Data\LoadData_',h.SelectLoad_Pup.String{h.SelectLoad_Pup.Value},'.mat']);
            else
                Temp=load([h.FilesPath,'/Data/LoadData_',h.SelectLoad_Pup.String{h.SelectLoad_Pup.Value},'.mat']);
            end
            h.AllLoads{LoadNum,1}=NewLoadName;
            h.AllLoads{LoadNum,2}=Temp.LoadData;
            % finding the network load
            h.AllLoads{LoadNum,2}.Load.NetworkLoad=nan(size(h.AllLoads{LoadNum,2}.Load.kWh,1),1);
            h.AllLoads{LoadNum,2}.Load.NetworkLoad(2:end,1)=nanmean(h.AllLoads{LoadNum,2}.Load.kWh(2:end,:),2);
            h.AllLoads{LoadNum,2}.Load.NetworkLoad(isnan(h.AllLoads{LoadNum,2}.Load.NetworkLoad))=0;
            % finding LDC of network
            [~,indp2]= sort(h.AllLoads{LoadNum, 2}.Load.NetworkLoad(2:end,1),'descend');
            Times=h.AllLoads{LoadNum, 2}.Load.TimeStamp(2:end);
            h.AllLoads{LoadNum,3}.Network_LDC_ind=indp2;
            [~,Indp5]=unique(floor(datenum(Times(h.AllLoads{LoadNum,3}.Network_LDC_ind))),'stable');
            h.AllLoads{LoadNum,3}.Network_LDC_ind_Daily=indp2(Indp5);
            
        end
        
        % choose the selected load as the current load:
        h.CurrentLoad_Name=h.SelectLoad_Pup.String{h.SelectLoad_Pup.Value};
        LoadNo=find(strcmp(h.AllLoads(:,1),h.CurrentLoad_Name));
        % filter the loads with more than allowed missing percentage
        
        NanSize=100*sum(isnan(h.AllLoads{LoadNo,2}.Load.kWh(2:end,:)),1)/...
            ( size(h.AllLoads{LoadNo,2}.Load.kWh,1)-1);
        
        for n2=1:size(h.menuLoad_Miss_Opt,1)
            
            if strcmpi(h.menuLoad_Miss_Opt{n2,1}.Checked,'on')
                MissValue= str2num(h.MissingDataOptions{1,n2}(1:end-1));
            end
        end
        % downsample the load
        for n2=1:size(h.menuLoad_DownSam_Opt,1)
            
            if strcmpi(h.menuLoad_DownSam_Opt{n2,1}.Checked,'on')
                if n2==1
                    DownSam_Rnd=1;
                else
                    DownSam_Rnd= str2num(h.DownSamOptions{1,n2}(1:end-1))/100;
                end
            end
        end
        
        h.FilteredID=h.AllLoads{LoadNo,2}.Load.kWh(1,NanSize<=MissValue);
        h.FilteredID=sort(h.FilteredID(1,randsample(size(h.FilteredID,2),floor(DownSam_Rnd*size(h.FilteredID,2)))));
        
        % check if the load has demographic info
        if isfield( h.AllLoads{LoadNo,2},'Demog')
            
            for k1=1:10
                
                h.Demo_Pup_text{k1,1}.Visible='Off';
                h.Demo_Pup{k1,1}.Visible='Off';
            end
            
            for k1=1:size(h.AllLoads{LoadNo,2}.Demog,2)-1
                Demog_Item_Header=h.AllLoads{LoadNo,2}.Demog{1,k1+1};
                Demog_Item_all=h.AllLoads{LoadNo,2}.Demog(2:end,[1,k1+1]);
                Demog_Item_F=Demog_Item_all(ismember(str2double(Demog_Item_all(:,1)),h.FilteredID),2);
                Demog_Item_list=unique(Demog_Item_F);
                h.Demo_Pup_text{k1,1}.String=[Demog_Item_Header,':'];
                h.Demo_Pup_text{k1,1}.TooltipString=Demog_Item_Header;
                h.Demo_Pup_text{k1,1}.Visible='On';
                h.Demo_Pup{k1,1}.String=['All';Demog_Item_list];
                h.Demo_Pup{k1,1}.Visible='On';
                h.Demo_Pup{k1,1}.Value=1;
            end
            h.Demo1_Pup_text_noDemo.Visible='Off';
        else
            h.Demo1_Pup_text_noDemo.Visible='On';
            for k1=1:10
                h.Demo_Pup_text{k1,1}.Visible='Off';
                h.Demo_Pup{k1,1}.Visible='Off';
            end
        end
        
        h.LoadFig_TotNum.String=['No. of users: ',num2str(numel(h.FilteredID))];
        
        % Assign all demog info
        
        DelMsg;msgbox('Please wait! Analysing load data..');
        
        % Analysis of load data (peak time, daily peak ,etc)
        
        NewAnalysis=table;
        NewAnalysis.HomeID=h.AllLoads{LoadNo,2}.Load.kWh(1,:)';
        NewAnalysis.AnnualkWh=nansum(h.AllLoads{LoadNo,2}.Load.kWh(2:end,:),1)';
        NewAnalysis.AverageDailyPeak=nanmean(reshape(max(reshape(h.AllLoads{LoadNo,2}.Load.kWh(2:end,:),48,[])),[],size(h.AllLoads{LoadNo,2}.Load.kWh,2)))';
        
        h.AllLoads{LoadNo,4}=NewAnalysis;
        
        FilterDemo(src,evnt);
        %
        DelMsg
        h.status.LoadSet=1;
        % update load figure
        update_LoadSelec_Fig(src, evnt);
    end
%% ********************* Filter Load based on demographic information  *****************************

    function FilterDemo(src,evnt)
        % is run when a demog filter is changed
        %         h.CurrentLoad.FilteredLoad_Demo=h.CurrentLoad.FilteredLoad;
        %         h.FilteredID_demo=h.FilteredID;
        DemoInfo={};
        LoadNo=find(strcmp(h.AllLoads(:,1),h.CurrentLoad_Name));
        
        %        TempIDDemo=[str2double(h.AllLoads{LoadNo,2}.Demog(2:end,1))];
        %        TempIDDemo=[TempIDDemo(ismember(TempIDDemo,h.FilteredID))];
        h.FilteredID_demo=h.FilteredID;
        if isfield(h.AllLoads{LoadNo,2},'Demog')
            for k1=1:size(h.AllLoads{LoadNo,2}.Demog,2)-1
                Demog_Item_all=h.AllLoads{LoadNo,2}.Demog(2:end,[1,k1+1]);
                %             Demog_Item_F=Demog_Item_all(ismember(str2double(Demog_Item_all(:,1)),h.FilteredID),:);
                switch   h.Demo_Pup{k1,1}.String{h.Demo_Pup{k1,1}.Value}
                    case 'All'
                        
                    otherwise
                        
                        RemoveID=str2double(Demog_Item_all(cellfun(@isempty,regexp(Demog_Item_all(:,2),h.Demo_Pup{k1,1}.String{h.Demo_Pup{k1,1}.Value})),1));
                        h.FilteredID_demo=setdiff(h.FilteredID_demo,RemoveID) ;  % removing the filtered users
                end
                
                DemoInfo{k1,1}=h.Demo_Pup_text{k1,1}.String;
                DemoInfo{k1,2}=h.Demo_Pup{k1,1}.String{h.Demo_Pup{k1,1}.Value};
                h.CurrentLoad_Demo=DemoInfo;
                
            end
        end
        
        h.LoadFig_TotNum.String=['No. of users: ',num2str(numel(h.FilteredID_demo))];
        
        % update analyses
        h.AllLoads_An_F.AverageAnnual=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo)),2);
        h.AllLoads_An_F.AverageAnnual(isnan(h.AllLoads_An_F.AverageAnnual))=0;
        h.AllLoads_An_F.NetworkLDC=sort(nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo)),2),'descend');
        
        for hm=1:12
            h.AllLoads_An_F.MonthAvg(hm,1)=48*nanmean(nanmean(h.AllLoads{LoadNo,2}.Load.kWh(h.AllLoads{LoadNo,2}.Load.TimeStamp.Month==hm,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo))));
        end
        Seas=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp.Month,[12,1,2]),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo)),2);
        h.AllLoads_An_F.SummerDailyPatt=nanmean(reshape(Seas,48,size(Seas,1)/48),2);
        
        Seas=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp.Month,[6,7,8]),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo)),2);
        h.AllLoads_An_F.WinterDailyPatt=nanmean(reshape(Seas,48,size(Seas,1)/48),2);
        
        [~,indp2]= sort(h.AllLoads_An_F.AverageAnnual,'descend');
        Times=h.AllLoads{LoadNo, 2}.Load.TimeStamp(2:end);
        h.AllLoads_An_F.Network_F_LDC_ind=indp2;
        [~,Indp5]=unique(floor(datenum(Times(h.AllLoads_An_F.Network_F_LDC_ind))),'stable');
        h.AllLoads_An_F.Network_F_LDC_ind_Daily=indp2(Indp5);
        if isfield(h.AllLoads{LoadNo,2},'Demog')
            h.AllLoads_An_F.Demog=[h.AllLoads{LoadNo,2}.Demog(1,:);h.AllLoads{LoadNo,2}.Demog(ismember(str2double(h.AllLoads{LoadNo,2}.Demog(:,1)),h.FilteredID_demo),:)];
        end
        h.Cashe=[]; % emptying cashe
        update_LoadSelec_Fig(src,evnt)
        
        
    end
%% ********************* Update all figures in Load Select graph  *****************************
    function update_LoadSelec_Fig(src,evnt)
        % list of figuers
        LoadNo=find(strcmp(h.AllLoads(:,1),h.CurrentLoad_Name));
        
        axes(h.LoadAxes)
        cla(h.LoadAxes)
        hold off
        box(h.LoadAxes,'on');
        
        if h.status.LoadSet==1
            cla(h.LoadAxes,'reset')
            
            switch h.LoadFig_Pup.String{h.LoadFig_Pup.Value}
                
                case 'Annual Average Profile'
                    
                    plot(h.LoadAxes,h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),h.AllLoads_An_F.AverageAnnual,'DisplayName','Selected Users');
                    hold on
                    plot(h.LoadAxes,h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),h.AllLoads{LoadNo,2}.Load.NetworkLoad(2:end),'DisplayName','All');
                    
                    grid(h.LoadAxes,'On');
                    ylabel(h.LoadAxes,'Average Load (kWh)','FontUnits','normalized')
                    legend(h.LoadAxes,'boxoff')
                    lgd=legend ('show');
                    lgd.Location='Northwest';
                    
                    legend(h.LoadAxes,'boxoff')
                case 'Daily Profile(s)'
                    
                    if ~isfield(h.Cashe,'NewDaily')
                        for k2=1:size(h.FilteredID_demo,2)
                            h.Cashe.newDaily(:,k2)=nanmean(reshape(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo(k2))),48,[]),2);
                        end
                    end
                    
                    plot(h.LoadAxes,h.Cashe.newDaily);
                    ylabel(h.LoadAxes,'kWh','FontUnits','normalized')
                    xlabel(h.LoadAxes,'Hour','FontUnits','normalized')
                    xlim(h.LoadAxes,[1,48])
                    grid(h.LoadAxes,'on')
                    legend(h.LoadAxes,'boxoff')
                    set(h.LoadAxes,'XTick',[2:4:48],'XTickLabel',...
                        {'1','3','5','7','9','11','13','15','17','19','21','23'});
                    
                case 'Daily Profile interquartile Range'
                    %                 cla(h.LoadAxes)
                    if ~isfield(h.Cashe,'NewDaily')
                        for k2=1:size(h.FilteredID_demo,2)
                            h.Cashe.newDaily(:,k2)=nanmean(reshape(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.FilteredID_demo(k2))),48,[]),2);
                        end
                    end
                    
                    IQR(:,1)=prctile(h.Cashe.newDaily,25,2);
                    IQR(:,2)=prctile(h.Cashe.newDaily,50,2)-IQR(:,1);
                    IQR(:,3)=prctile(h.Cashe.newDaily,75,2)-IQR(:,2)-IQR(:,1);
                    hold off
                    area1 = area(IQR,'Parent',h.LoadAxes);
                    hold on
                    
                    set(area1(2),'DisplayName','Median',...
                        'EdgeColor',[0.6 0.6 1]);
                    set(area1(3),'DisplayName','75%',...
                        'FaceColor',[0.6 0.6 1],...
                        'LineStyle','none');
                    set(area1(1),'DisplayName','25%','FaceColor',[1 1 1],...
                        'EdgeColor',[1 1 1],'FaceAlpha',0);
                    %                 plot(IQR(:,2)+IQR(:,1),'Parent',h.LoadAxes);
                    xlim(h.LoadAxes,[1,48])
                    ylabel(h.LoadAxes,'kWh','FontUnits','normalized')
                    xlabel(h.LoadAxes,'Hour','FontUnits','normalized')
                    
                    set(h.LoadAxes,'XTick',[2:4:48],'XTickLabel',...
                        {'1','3','5','7','9','11','13','15','17','19','21','23'});
                    
                    % title (h.LoadAxes,'show')
                    lgd = legend(h.LoadAxes,{''},'Location','northwest');
                    title(lgd,'Interquartile Range (25%, 50%, 75%)')
                    legend(h.LoadAxes,'boxoff')
                    grid on
                    
                case 'Daily kWh Histogram'
                    
                    Temp1=histogram(h.LoadAxes,h.AllLoads{LoadNo,4}.AnnualkWh(ismember(h.AllLoads{LoadNo,4}.HomeID,h.FilteredID_demo),1)/365,'DisplayName','Selected Users');
                    Temp1.Normalization = 'probability';
                    Temp1.BinWidth = 2;
                    
                    hold on
                    Temp2=histogram(h.LoadAxes,h.AllLoads{LoadNo,4}.AnnualkWh/365,'DisplayName','All');
                    Temp2.Normalization = 'probability';
                    Temp2.BinWidth = 2;
                    grid(h.LoadAxes,'on')
                    xlabel(h.LoadAxes,'kWh/day');
                    ylabel(h.LoadAxes,'Probability')
                    
                    lgd=legend ('show');
                    lgd.Location='Northeast';
                    legend(h.LoadAxes,'boxoff')
                case 'Average Load Duration Curve'
                    
                    plot(h.LoadAxes,sort(h.AllLoads_An_F.AverageAnnual,'descend'),'LineWidth',2,'DisplayName','Selected Users');
                    hold on
                    plot(h.LoadAxes,sort(h.AllLoads{LoadNo,2}.Load.NetworkLoad(2:end),'descend'),'LineWidth',2,'DisplayName','All');
                    
                    ylabel(h.LoadAxes,'kWh');
                    grid(h.LoadAxes,'On');
                    legend(h.LoadAxes,'boxoff')
                    xlim(h.LoadAxes,[1,size(h.AllLoads_An_F.AverageAnnual,1)])
                    xlabel(h.LoadAxes,'Annual peak number');
                    lgd=legend ('show');
                    lgd.Location='Northeast';
                    
                case 'Average Peak Day Profile'
                    %                     % need to modify probably by looking at the peak
                    %                     times..
                    %
                    [~,ind2]=max(h.AllLoads{LoadNo,2}.Load.NetworkLoad);
                    plot(h.LoadAxes,nanmean(h.AllLoads{LoadNo,2}.Load.kWh(floor(datenum(h.AllLoads{LoadNo,2}.Load.TimeStamp))==floor(datenum(h.AllLoads{LoadNo,2}.Load.TimeStamp(ind2+1))),ismember(h.AllLoads{LoadNo,4}.HomeID,h.FilteredID_demo))'),'LineWidth',2,'DisplayName','Selected Users');
                    
                    hold on
                    plot(h.LoadAxes,nanmean(h.AllLoads{LoadNo,2}.Load.kWh(floor(datenum(h.AllLoads{LoadNo,2}.Load.TimeStamp))==floor(datenum(h.AllLoads{LoadNo,2}.Load.TimeStamp(ind2+1))),:)'),'LineWidth',2,'DisplayName','All');
                    
                    xlabel(h.LoadAxes,['Load profile on network peak day (',datestr(h.AllLoads{LoadNo,2}.Load.TimeStamp(ind2+1),'yyyy mmm dd'),' )']);
                    ylabel(h.LoadAxes,'kWh');
                    grid(h.LoadAxes,'On');
                    lgd=legend ('show');
                    lgd.Location='Northwest';
                    xlim(h.LoadAxes,[1,48]);
                    set(h.LoadAxes,'XTick',[2:4:48],'XTickLabel',...
                        {'1','3','5','7','9','11','13','15','17','19','21','23'});
                    legend(h.LoadAxes,'boxoff')
                case 'Monthly Average kWh'
                    
                    
                    bar(h.AllLoads_An_F.MonthAvg);
                    
                    % Plot properties
                    set(h.LoadAxes,'XTick',[1:12],'XTickLabel',...
                        {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'});
                    xlim([0 13])
                    %           end
                    xlabel('Month')
                    ylabel('kWh/day')
                    grid on
                    box on
                    
                    hold on
                    
                case 'Seasonal Daily Pattern'
                    
                    
                    plot(h.AllLoads_An_F.SummerDailyPatt,'LineWidth',2,'DisplayName','Summer');
                    
                    ylabel(h.LoadAxes,'kWh','FontUnits','normalized')
                    xlabel(h.LoadAxes,'Hour','FontUnits','normalized')
                    xlim(h.LoadAxes,[1,48])
                    grid(h.LoadAxes,'on')
                    legend(h.LoadAxes,'boxoff')
                    set(h.LoadAxes,'XTick',[2:4:48],'XTickLabel',...
                        {'1','3','5','7','9','11','13','15','17','19','21','23'});
                    hold on
                    plot(h.AllLoads_An_F.WinterDailyPatt,'LineWidth',2,'DisplayName','Winter');
                    legend(h.LoadAxes,'boxoff')
                    lgd=legend (h.LoadAxes,'show');
                    lgd.Location='Northwest';
                    box on
                    
                    xlim([1 48])
            end
        else
            
            DelMsg; msgbox('Please set the load data first!')
            
        end
    end

%% ********************* Adding new case *****************************

    function AddDiag(src,evnt)
        % check all conditions..
        
        DelMsg;msgbox('Please wait! Adding new case..')
        
        if isfield(h,'CurrentLoad_Name')&&isfield(h,'MyTariff')
            
            h.TariffTableOK=1;
            %             end
            % Issue: Missing tariff validity check
            % check if the modifed tariff structure is ok:
            if h.TariffTableOK==1
                % check which load is selected
                LoadNo=find(strcmp(h.AllLoads(:,1),h.CurrentLoad_Name));
                % check the number of current cases:
                ADS=size(h.AllDiagrams,1);
                % if less than 10 then we can add one more:
                if ADS<10
                    % if any load is selected:
                    if isfield(h,'CurrentLoad_Name')
                        % Retrieving the load
                        newLoad=table;
                        newLoad.TimeStamp=h.AllLoads{LoadNo, 2}.Load.TimeStamp(2:end);
                        newLoad.Load=h.AllLoads{LoadNo, 2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo, 2}.Load.kWh(1,:),h.FilteredID_demo));
                        
                        if  size(h.AllLoads{LoadNo, 2}.Load.kWh,2)>0
                            
                            % Creating the network load:
                            % if based on whole database
                            if h.PeakTimeMethod==1
                                
                                h.AllDiagrams{ADS+1,1}.PeakTimeBased='Whole Dataset';
                                
                                h.AllDiagrams{ADS+1,1}.PeakTimeAll=h.AllLoads{LoadNo,2}.Load.TimeStamp(h.AllLoads{LoadNo,3}.Network_LDC_ind+1,1);
                                h.AllDiagrams{ADS+1,1}.PeakTimeAll_OnePerDay=h.AllLoads{LoadNo,2}.Load.TimeStamp(h.AllLoads{LoadNo,3}.Network_LDC_ind_Daily+1,1);
                                
                                newLoad.NetworkLoad=h.AllLoads{LoadNo, 2}.Load.NetworkLoad(2:end);
                                
                                % if based on filtered load data
                            elseif h.PeakTimeMethod==2
                                
                                h.AllDiagrams{ADS+1,1}.PeakTimeBased='Filtered Load';
                                h.AllDiagrams{ADS+1,1}.PeakTimeAll=h.AllLoads{LoadNo,2}.Load.TimeStamp(h.AllLoads_An_F.Network_F_LDC_ind+1,1);
                                h.AllDiagrams{ADS+1,1}.PeakTimeAll_OnePerDay=h.AllLoads{LoadNo,2}.Load.TimeStamp(h.AllLoads_An_F.Network_F_LDC_ind_Daily+1,1);
                                %
                                newLoad.NetworkLoad=h.AllLoads_An_F.AverageAnnual;
                                % if based on synthetic load data
                            elseif h.PeakTimeMethod==3
                                % Loading the synthetic network load and
                                % change it to the same year as the load
                                % profile
                                temptime1=h.AllLoads{LoadNo, 2}.Load.TimeStamp(2:end);
                                temptime3=temptime1;
                                temptime2=h.SyntheticNetwork.TimeStamp;
                                temptime1.Year=1999;
                                temptime2.Year=1999;
                                
                                [~,bT,cT]=intersect(temptime1,temptime2);
                                
                                NewSyn=zeros(size(h.AllLoads{LoadNo, 2}.Load(2:end,1)));
                                NewSyn(bT,1)=h.SyntheticNetwork.Load(cT,1);
                                
                                NewSyn(isnan(NewSyn))=0;
                                [~,indp2]= sort(NewSyn,'descend');
                                PeakTimeAll=temptime3(indp2);
                                
                                h.AllDiagrams{ADS+1,1}.PeakTimeBased='Synthetic network load';
                                h.AllDiagrams{ADS+1,1}.PeakTimeAll=PeakTimeAll;
                                [~,Indp5]=unique(floor(datenum(PeakTimeAll)),'stable');
                                h.AllDiagrams{ADS+1,1}.PeakTimeAll_OnePerDay=PeakTimeAll(Indp5);
                                
                                newLoad.NetworkLoad=NewSyn;
                                
                            end
                            
                            % Assigning the tariff
                            h.MyTariff_Com=h.MyTariff;
                            switch h.tabg_SelTar.SelectedTab.Title
                                
                                case 'DUOS'
                                    h.MyTariff_Com.Parameters=h.MyTariff.Parameters.DUOS;
                                    TarCom='DUOS';
                                    
                                case 'TUOS'
                                    h.MyTariff_Com.Parameters=h.MyTariff.Parameters.TUOS;
                                    TarCom='TUOS';
                                    
                                case 'NUOS'
                                    h.MyTariff_Com.Parameters=h.MyTariff.Parameters.NUOS;
                                    TarCom='NUOS';
                                    
                                case 'DTUOS'
                                    h.MyTariff_Com.Parameters=h.MyTariff.Parameters.DTUOS;
                                    TarCom='DTUOS';
                            end
                            
                            % Calculating the bill
                            if strcmp(h.MyTariff_Com.Type,'Demand Charge and TOU')
                            % Separating the bill 
                            TOU_part=h.MyTariff_Com;
                            TOU_part.Parameters.Daily.Value=0;
                           
                            try TOU_part.Parameters.Energy.Value=0;
                            end
                            
                            TOU_part.Parameters.Other= TOU_part.Parameters.Other(strcmp(TOU_part.Parameters.Other.Unit,'$/kWh'),:);
                            TOU_part.Type = 'TOU Seasonal';
                            [Bill2_TOU, Stat_TOU]=BillCalc(TOU_part,newLoad);  
                            
                            Dem_part=h.MyTariff_Com;
                            try Dem_part.Parameters.Energy.Value=0;
                            end
                            Dem_part.Parameters.Other= Dem_part.Parameters.Other(strcmp(Dem_part.Parameters.Other.Unit,'$/kW/Month'),:);
                            Dem_part.Type = 'Demand Charge';
                            [Bill2_Dem, Stat_Dem]=BillCalc(Dem_part,newLoad);  
                           
                            Bill2.Total = Bill2_Dem.Total + Bill2_TOU.Total;
                            Bill2.Components.Names =[ Bill2_Dem.Components.Names([1,3],:); Bill2_TOU.Components.Names(2,:)];
                            Bill2.Components.Value =[ Bill2_Dem.Components.Value([1,3],:); Bill2_TOU.Components.Value(2,:)];
                            Stat=[Stat_Dem,Stat_TOU];
                            Bill2.Unitised=Bill2.Total/(Bill2_Dem.Total/Bill2_Dem.Unitised+Bill2_TOU.Total/Bill2_TOU.Unitised);
                            else
                              [Bill2,Stat]=BillCalc(h.MyTariff_Com,newLoad);  
                            end
                            
                            h.Bill=Bill2;
                            if h.SelectTariff_GST.Value==0
                            else
                                h.Bill.Total= h.Bill.Total.*10/11;
                                h.Bill.Components.Value=h.Bill.Components.Value*10/11;
                            end
                            if  numel(Stat)==0
                                % assigning analyses and data to the
                                % AllDiagrams 
                                h.AllDiagrams{ADS+1,1}.TariffDetail= h.MyTariff_Com;
                                h.AllDiagrams{ADS+1,1}.SelectedDatabase=h.CurrentLoad_Name;
                                h.AllDiagrams{ADS+1,1}.Bill=h.Bill;
                                h.AllDiagrams{ADS+1,1}.TarCom=TarCom;
                                h.AllDiagrams{ADS+1,1}.HomeID=h.AllLoads{LoadNo, 2}.Load.kWh(1,ismember(h.AllLoads{LoadNo, 2}.Load.kWh(1,:),h.FilteredID_demo));
                                
                                Annual_kWh=h.AllLoads{LoadNo,4}.AnnualkWh(ismember(h.AllLoads{LoadNo,4}.HomeID,h.FilteredID_demo),1);
                                
                                % Demand_at_Network_Peak_kWh
                                % if h.DualVar_XOnePeakPerDay.Value==1
                                Demand_at_Network_Peak_kWh= h.AllLoads{LoadNo, 2}.Load.kWh(ismember(h.AllLoads{LoadNo, 2}.Load.TimeStamp,h.AllDiagrams{ADS+1,1}.PeakTimeAll(1)),ismember( h.AllLoads{LoadNo, 2}.Load.kWh(1,:),h.FilteredID_demo))';
                                
                                % Demand_at_Monthly_Network_Peak_kWh:
                                
                                [~,Indp6]=unique(h.AllDiagrams{ADS+1,1}.PeakTimeAll.Month,'stable');
                                PeakTimeAll_Monthly=h.AllDiagrams{ADS+1,1}.PeakTimeAll(Indp6);
                                
                                Demand_at_Monthly_Network_Peak_kWh=nanmean( h.AllLoads{LoadNo, 2}.Load.kWh(ismember(h.AllLoads{LoadNo, 2}.Load.TimeStamp,PeakTimeAll_Monthly),ismember( h.AllLoads{LoadNo, 2}.Load.kWh(1,:),h.FilteredID_demo)),1)';
                                
                                % Annual_Peak_kWh
                                Annual_Peak_kWh=max(h.AllLoads{LoadNo, 2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo, 2}.Load.kWh(1,:),h.FilteredID_demo)))';
                                %   Monthly_Peak_kWh
                                Monthly_Peak_kWh=[];
                                for km=1:12
                                    
                                    Monthly_Peak_kWh(:,km)=max(h.AllLoads{LoadNo, 2}.Load.kWh(h.AllLoads{LoadNo, 2}.Load.TimeStamp.Month==km,ismember(h.AllLoads{LoadNo, 2}.Load.kWh(1,:),h.FilteredID_demo)))';
                                end
                                
                                Monthly_Peak_kWh=mean(Monthly_Peak_kWh,2);
                                % Average_Daily_kWh
                                Average_Daily_kWh=Annual_kWh/floor(size(h.AllLoads{LoadNo, 2}.Load.TimeStamp,1)/48);
                                Average_Daily_Peak_kWh= h.AllLoads{LoadNo,4}.AverageDailyPeak(ismember(h.AllLoads{LoadNo,4}.HomeID,h.FilteredID_demo));
                                
                                % Bill
                                Bill=h.Bill.Total';
                                % Unitised_Bill
                                Unitised_Bill= h.Bill.Unitised';
                                
                                %   h.ListofDualVarFigs={'Annual kWh';'Average Demand at ''N'' Network Peaks';'Average Demand at ''N'' Network Monthly Peaks';'Average Demand at Top ''N'' Peaks';'Average Demand at Top ''N'' Monthly Peaks';'Average Daily kWh';'Bill ($/year)';'Unitised Bill (kW)'}; % Options for plotting in Dual variable figure
                                
                                h.AllDiagrams{ADS+1,1}.Analysis=table(Annual_kWh,Demand_at_Network_Peak_kWh,Demand_at_Monthly_Network_Peak_kWh,Annual_Peak_kWh,Monthly_Peak_kWh,Average_Daily_kWh,Average_Daily_Peak_kWh,Bill,Unitised_Bill,...
                                    'VariableName',{'Annual_kWh','Demand_at_Network_Peak_kWh','Demand_at_Monthly_Network_Peak_kWh','Annual_Peak_kWh','Monthly_Peak_kWh','Average_Daily_kWh','Average_Daily_Peak_kWh','Bill','Unitised_Bill'});                                
                                
                                
                                newTS1= h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end);
                                
                                for mh=1:12
                                    newTS= newTS1(newTS1.Month==mh);
                                    [~,i2]= max(h.AllLoads_An_F.AverageAnnual(newTS1.Month==mh,1));
                                    h.AllDiagrams{ADS+1,1}.MaxTime(mh,1)= newTS.Month(i2);
                                    h.AllDiagrams{ADS+1,1}.MaxTime(mh,2)= newTS.Hour(i2)+newTS.Minute(i2)/60;
                                end
                                
                                if isfield(h.AllLoads_An_F,'Demog')
                                    h.AllDiagrams{ADS+1,1}.Load.Demog= h.AllLoads_An_F.Demog;
                                    h.AllDiagrams{ADS+1,1}.Load.DemogInfo=h.CurrentLoad_Demo;
                                end
                                h.AllDiagrams{size(h.AllDiagrams,1),1}.CaseName=['Case ', num2str(size(h.AllDiagrams,1))];
                                h.AllDiagrams{size(h.AllDiagrams,1),1}.CaseNameMannual=false;
                                
                                if h.AskForCaseName
                                    choice = questdlg(['The analysis is successfully done. Would you like to pick a name for this case, or just call it "Case ',num2str(ADS+1),'"? You can disable this function from Menu: Options > Ask for naming new case.'], ...
                                        'Adding New Case', ...
                                        'Yes','No' ,'No');
                                    % Handle response
                                    switch choice
                                        case 'Yes'
                                            
                                            h.PickName.F = figure('Name','Pick name for Case','NumberTitle','off', ...
                                                'HandleVisibility','on','Resize','off', ...
                                                'Position',[200,200, 400, 150],...
                                                'Toolbar','none','Menubar','none'); % Figure to save project
                                            movegui(h.PickName.F ,'center')
                                            h.PickName.P=uipanel('Parent',h.PickName.F,...
                                                'Units', 'normalized', 'Position',[0 0 1 1],...
                                                'FontWeight','bold',...
                                                'FontSize',10);
                                            
                                            h.PickName.T1= uicontrol(h.PickName.P,'Style','Text',...
                                                'String','Case Name:', ...
                                                'FontUnits','normalized',...
                                                'Value',1,...
                                                'Units', 'normalized', 'Position',[.01 .75 .3 .17],...
                                                'HorizontalAlignment','left');
                                            
                                            h.PickName.T2= uicontrol(h.PickName.P,'Style','Edit',...
                                                'FontUnits','normalized',...
                                                'Value',1,...
                                                'Units', 'normalized', 'Position',[.31 .75 .5 .17],...
                                                'HorizontalAlignment','left');
                                            
                                            uicontrol(h.PickName.P, ...
                                                'Style','pushbutton', 'String','Add',...
                                                'Units', 'normalized', 'Position',[.2 .1 .2 .2],...
                                                'FontWeight','bold',...
                                                'FontUnits','normalized',...
                                                'Callback', @PickName_CB2);
                                            
                                        case 'No'
                                            FinaliseAdd(src,evnt)
                                            
                                        case ''
                                            FinaliseAdd(src,evnt)
                                            
                                            
                                    end
                                else
                                    FinaliseAdd(src,evnt)
                                    
                                end
                            else
                                DelMsg;msgbox('Oops! Something is wrong with the tariff!')
                            end
                        else
                            DelMsg;msgbox('There is no load data!!')
                        end
                    else
                        DelMsg;msgbox('Please load the demand data first!!')
                    end
                else
                    DelMsg;msgbox('You have reached the maximum number of cases! Please delete one case!')
                end
            else
                DelMsg;msgbox('Please check the tariff and try again!')
            end
        else
            DelMsg;msgbox('Please set the load and tariff first!')
        end
    end
    function PickName_CB2(src,evnt)
        
        h.AllDiagrams{size(h.AllDiagrams,1),1}.CaseName=h.PickName.T2.String;
        h.AllDiagrams{size(h.AllDiagrams,1),1}.CaseNameMannual=true;
        FinaliseAdd(src,evnt)
    end

    function FinaliseAdd(src,evnt)
        % Adding the case
        for in=1:size(h.AllDiagrams,1)
            
            h.SingCase_List.String{in,1}=h.AllDiagrams{in,1}.CaseName;
        end
        update_listofExports(src,evnt);
        update_DualVar(src,evnt,1);
        update_SingVar(src,evnt,1);
        update_SingCase(src,evnt,1);
        UpdateListofCasesPanel(src,evnt);
        ShowCase_Diag(src,evnt,size(h.AllDiagrams,1))
        
        DelMsg
    end

%% ********************* Updating the Dual variable graphs *****************************
    function update_DualVar(src,evnt,k)
        if size(h.AllDiagrams,1)>0
            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1;1,1,1,1,1,1,1,1,1,1,1,1];
            
            DelMsg;msgbox(['Please wait!'])
            ReachedPeakLimit=0;
            if k==1
                h.DualVar_XTopPeak_PB.Visible='off';
                h.DualVar_XTopPeak_Text.Visible='off';
                h.DualVar_XOnePeakPerDay.Visible='off';
                h.DualVar_YTopPeak_PB.Visible='off';
                h.DualVar_YTopPeak_Text.Visible='off';
                h.DualVar_YOnePeakPerDay.Visible='off';
                h.SeasonsPanel.Visible='off';
                
                h.AllDiagramsX=h.AllDiagrams;
                h.AllDiagramsY=h.AllDiagrams;
                % What is selected for X axis:
                XSelAx=h.DualVar_FigX.Value;
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% What is selected for X axis:
                switch h.DualVar_FigX.String{h.DualVar_FigX.Value}
                    case 'Annual kWh'
                        h.DatatoPlot.XTitle='Electricity Usage (kWh/year)';
                        
                    case 'Average Demand at ''N'' Network Peaks'
                        h.DatatoPlot.XTitle=['Average Demand at ',h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value} ,' Network Peak(s) (kWh)'];
                        h.DualVar_XTopPeak_PB.Visible='on';
                        h.DualVar_XTopPeak_Text.Visible='on';
                        h.DualVar_XOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            NewPeakTimeAll=h.AllDiagramsX{j,1}.PeakTimeAll;
                            NewPeakTimeAll_OnePerDay=h.AllDiagramsX{j,1}.PeakTimeAll_OnePerDay;
                            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1];
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll(ismember(NewPeakTimeAll.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll_OnePerDay(ismember(NewPeakTimeAll_OnePerDay.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            
                            if h.DualVar_XOnePeakPerDay.Value==0
                                MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(NewPeakTimeAll,1));
                                if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                h.AllDiagramsX{j,1}.Analysis.Demand_at_Network_Peak_kWh=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp,NewPeakTimeAll(1:MaxPeaksNo)),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{j, 1}.HomeID)),1)';
                            else
                                MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(NewPeakTimeAll_OnePerDay,1));
                                if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                h.AllDiagramsX{j,1}.Analysis.Demand_at_Network_Peak_kWh=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp,NewPeakTimeAll_OnePerDay(1:MaxPeaksNo)),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{j, 1}.HomeID)),1)';
                            end
                            
                        end
                        
                    case 'Average Demand at ''N'' Network Monthly Peaks'
                        
                        h.DatatoPlot.XTitle=['Average Demand at ',h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value} ,' Network Monthly Peak(s) (kWh)'];
                        h.DualVar_XTopPeak_PB.Visible='on';
                        h.DualVar_XTopPeak_Text.Visible='on';
                        h.DualVar_XOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            NewPeakTimeAll=h.AllDiagramsX{j,1}.PeakTimeAll;
                            NewPeakTimeAll_OnePerDay=h.AllDiagramsX{j,1}.PeakTimeAll_OnePerDay;
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll(ismember(NewPeakTimeAll.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                    MonthsIndex(3,MonthsIndex(2,:)==ui)=0;
                                end
                            end
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll_OnePerDay(ismember(NewPeakTimeAll_OnePerDay.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            
                            if h.DualVar_XOnePeakPerDay.Value==0
                                NPTM=[];
                                for jM=1:12
                                    if  MonthsIndex(3,jM)==1
                                        NewPeakTimeAll_M=NewPeakTimeAll(NewPeakTimeAll.Month==jM);
                                        MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(NewPeakTimeAll_M,1));
                                        if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                        
                                        NPTM=[NPTM;NewPeakTimeAll_M(1:MaxPeaksNo)];
                                    end
                                end
                                
                            else
                                NPTM=[];
                                for jM=1:12
                                    if  MonthsIndex(3,jM)==1
                                        NewPeakTimeAll_OnePerDay_M=NewPeakTimeAll_OnePerDay(NewPeakTimeAll_OnePerDay.Month==jM);
                                        MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(NewPeakTimeAll_OnePerDay_M,1));
                                        if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                        NPTM=[NPTM;NewPeakTimeAll_OnePerDay_M(1:MaxPeaksNo)];
                                    end
                                end
                            end
                            
                            h.AllDiagramsX{j,1}.Analysis.Demand_at_Monthly_Network_Peak_kWh=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp,NPTM),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{j, 1}.HomeID)),1)';
                            
                        end
                        
                    case 'Average Demand at Top ''N'' Peaks'
                        %                         allAnn=h.AllDiagramsX;
                        %
                        %                         save('temp.mat', 'allAnn')
                        h.DatatoPlot.XTitle=['Average Demand at Top ',h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value} ,' Peak(s) (kWh)'];
                        h.DualVar_XTopPeak_PB.Visible='on';
                        h.DualVar_XTopPeak_Text.Visible='on';
                        h.DualVar_XOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        AllIDS=[];
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            AllIDS=[AllIDS;[repmat(LoadNo,size(h.AllDiagrams{j,1}.HomeID,2),1),h.AllDiagrams{j,1}.HomeID']];
                        end
                        
                        AllIDS=unique(AllIDS,'rows');
                        LoadList=unique(AllIDS(:,1),'stable');
                        for kT=1:size(LoadList,1)
                            TempPeakLoads{kT,1}=table;
                            TempPeakLoads{kT,1}.TimeStamp=h.AllLoads{LoadList(kT),2}.Load.TimeStamp;
                            TempPeakLoads{kT,1}.Load=h.AllLoads{LoadList(kT),2}.Load.kWh(:,ismember(h.AllLoads{LoadList(kT),2}.Load.kWh(1,:),AllIDS(AllIDS(:,1)==LoadList(kT),2)));
                            TempPeakLoads{kT,2}=TempPeakLoads{kT,1}(2:end,:);
                            TempPeakLoads{kT,2}.Load( isnan(TempPeakLoads{kT,2}.Load))=0;
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    TempPeakLoads{kT,2}.Load(ismember(TempPeakLoads{kT,2}.TimeStamp.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=0;
                                end
                            end
                            
                            TempPeakLoads{kT,3}=reshape(max(reshape(TempPeakLoads{kT,2}.Load,48,[])),[],size(TempPeakLoads{kT,2}.Load,2));
                            
                            
                            TempPeakLoads{kT,2}=sort( TempPeakLoads{kT,2}.Load,'descend');
                            TempPeakLoads{kT,3}=sort(TempPeakLoads{kT,3},'descend');
                            
                        end
                        
                        for j=1:size(h.AllDiagrams,1)
                            
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            TempPeakLoads_diag=TempPeakLoads(LoadList==LoadNo,:);
                            [~,~,HI3]=intersect(h.AllDiagrams{j,1}.HomeID,TempPeakLoads_diag{1,1}.Load(1,:),'stable');
                            
                            if h.DualVar_XOnePeakPerDay.Value==0
                                
                                MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(TempPeakLoads_diag{1,2},1));
                                if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                
                                h.AllDiagramsX{j,1}.Analysis.Annual_Peak_kWh=nanmean(TempPeakLoads_diag{1,2}(1:MaxPeaksNo,HI3),1)';
                            else
                                MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(TempPeakLoads_diag{1,3},1));
                                if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                
                                
                                h.AllDiagramsX{j,1}.Analysis.Annual_Peak_kWh=nanmean(TempPeakLoads_diag{1,3}(1:MaxPeaksNo,HI3),1)';
                            end
                            
                        end
                        
                    case 'Average Demand at Top ''N'' Monthly Peaks'
                        
                        h.DatatoPlot.XTitle=['Average Demand at Top ',h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value} ,' Peak(s) (kWh)'];
                        h.DualVar_XTopPeak_PB.Visible='on';
                        h.DualVar_XTopPeak_Text.Visible='on';
                        h.DualVar_XOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        AllIDS=[];
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            AllIDS=[AllIDS;[repmat(LoadNo,size(h.AllDiagrams{j,1}.HomeID,2),1),h.AllDiagrams{j,1}.HomeID']];
                        end
                        
                        AllIDS=unique(AllIDS,'rows');
                        LoadList=unique(AllIDS(:,1),'stable');
                        for kT=1:size(LoadList,1)
                            TempPeakLoads{kT,1}=table;
                            TempPeakLoads{kT,1}.TimeStamp=h.AllLoads{LoadList(kT),2}.Load.TimeStamp;
                            TempPeakLoads{kT,1}.Load=h.AllLoads{LoadList(kT),2}.Load.kWh(:,ismember(h.AllLoads{LoadList(kT),2}.Load.kWh(1,:),AllIDS(AllIDS(:,1)==LoadList(kT),2)));
                            TempPeakLoads{kT,2}=TempPeakLoads{kT,1}(2:end,:);
                            TempPeakLoads{kT,2}.Load( isnan(TempPeakLoads{kT,2}.Load))=0;
                            
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    TempPeakLoads{kT,2}.Load(ismember(TempPeakLoads{kT,2}.TimeStamp.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=0;
                                end
                            end
                            
                            
                            for im=1:12
                                TempPeakLoads{kT,4}{im,1}=TempPeakLoads{kT,2}.Load(TempPeakLoads{kT,2}.TimeStamp.Month==im,:);
                                TempPeakLoads{kT,5}{im,1}=reshape(max(reshape(TempPeakLoads{kT,4}{im,1},48,[])),[],size(TempPeakLoads{kT,4}{im,1},2));
                            end
                            
                            
                            for im=1:12
                                TempPeakLoads{kT,4}{im,1}=sort(TempPeakLoads{kT,4}{im,1},'descend');
                                TempPeakLoads{kT,5}{im,1}=sort(TempPeakLoads{kT,5}{im,1},'descend');
                            end
                        end
                        
                        for j=1:size(h.AllDiagrams,1)
                            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1;1,1,1,1,1,1,1,1,1,1,1,1];
                            
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            TempPeakLoads_diag=TempPeakLoads(LoadList==LoadNo,:);
                            [~,~,HI3]=intersect(h.AllDiagrams{j,1}.HomeID,TempPeakLoads_diag{1,1}.Load(1,:),'stable');
                            
                            
                            % monthly
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    
                                    MonthsIndex(3,MonthsIndex(2,:)==ui)=0;
                                end
                            end
                            
                            
                            if h.DualVar_XOnePeakPerDay.Value==0
                                NPTM=[];
                                for im=1:12
                                    if MonthsIndex(3,im)
                                        MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(TempPeakLoads_diag{1,4}{im,1},1));
                                        if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                        
                                        NPTM=[NPTM;nanmean(TempPeakLoads_diag{1,4}{im,1}(1:MaxPeaksNo,HI3),1)];
                                    end
                                end
                                h.AllDiagramsX{j,1}.Analysis.Monthly_Peak_kWh=nanmean(NPTM,1)';
                                
                                
                            else
                                NPTM=[];
                                for im=1:12
                                    if MonthsIndex(3,im)
                                        MaxPeaksNo=min(str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value}),size(TempPeakLoads_diag{1,5}{im,1},1));
                                        if MaxPeaksNo<str2double(h.DualVar_XTopPeak_PB.String{h.DualVar_XTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                        
                                        NPTM=[NPTM;nanmean(TempPeakLoads_diag{1,5}{im,1}(1:MaxPeaksNo,HI3),1)];
                                    end
                                end
                                h.AllDiagramsX{j,1}.Analysis.Monthly_Peak_kWh=nanmean(NPTM,1)';
                            end
                        end
                        
                    case 'Average Daily kWh'
                        h.DatatoPlot.XTitle='Average Daily usage (kWh)';
                        h.SeasonsPanel.Visible='off';
                        
                    case 'Average Daily Peak'
                        h.SeasonsPanel.Visible='off';
                        h.DatatoPlot.XTitle='Average Daily Peak Demand (kWh)';
                        
                    case 'Bill ($/year)'
                        h.DatatoPlot.XTitle='Bill ($/year)';
                    case 'Unitised Bill (kW)'
                        h.DatatoPlot.XTitle='Unitised Bill (kW)';
                        
                end
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% What is selected for Y axis:
                YSelAx=h.DualVar_FigY.Value;
                % Put what is selected for Y axis:
                switch h.DualVar_FigY.String{h.DualVar_FigY.Value}
                    case 'Annual kWh'
                        h.DatatoPlot.YTitle='Electricity Usage (kWh/year)';
                        
                        
                    case 'Average Demand at ''N'' Network Peaks'
                        h.DatatoPlot.YTitle=['Average Demand at ',h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value} ,' Network Peak(s) (kWh)'];
                        h.DualVar_YTopPeak_PB.Visible='on';
                        h.DualVar_YTopPeak_Text.Visible='on';
                        h.DualVar_YOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            NewPeakTimeAll=h.AllDiagramsY{j,1}.PeakTimeAll;
                            NewPeakTimeAll_OnePerDay=h.AllDiagramsY{j,1}.PeakTimeAll_OnePerDay;
                            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1];
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll(ismember(NewPeakTimeAll.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll_OnePerDay(ismember(NewPeakTimeAll_OnePerDay.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            
                            if h.DualVar_YOnePeakPerDay.Value==0
                                MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(NewPeakTimeAll,1));
                                if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                
                                h.AllDiagramsY{j,1}.Analysis.Demand_at_Network_Peak_kWh=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp,NewPeakTimeAll(1:MaxPeaksNo)),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{j, 1}.HomeID)),1)';
                            else
                                MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(NewPeakTimeAll_OnePerDay,1));
                                if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                
                                h.AllDiagramsY{j,1}.Analysis.Demand_at_Network_Peak_kWh=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp,NewPeakTimeAll_OnePerDay(1:MaxPeaksNo)),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{j, 1}.HomeID)),1)';
                            end
                        end
                        
                    case 'Average Demand at ''N'' Network Monthly Peaks'
                        h.DatatoPlot.YTitle=['Average Demand at ',h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value} ,' Network Monthly Peak(s) (kWh)'];
                        h.DualVar_YTopPeak_PB.Visible='on';
                        h.DualVar_YTopPeak_Text.Visible='on';
                        h.DualVar_YOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            NewPeakTimeAll=h.AllDiagramsY{j,1}.PeakTimeAll;
                            NewPeakTimeAll_OnePerDay=h.AllDiagramsY{j,1}.PeakTimeAll_OnePerDay;
                            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1];
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll(ismember(NewPeakTimeAll.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    NewPeakTimeAll_OnePerDay(ismember(NewPeakTimeAll_OnePerDay.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=[];
                                end
                            end
                            
                            if h.DualVar_YOnePeakPerDay.Value==0
                                NPTM=[];
                                for jM=1:12
                                    if  MonthsIndex(3,jM)==1
                                        NewPeakTimeAll_M=NewPeakTimeAll(NewPeakTimeAll.Month==jM);
                                        MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(NewPeakTimeAll_M,1));
                                        NPTM=[NPTM;NewPeakTimeAll_M(1:MaxPeaksNo)];
                                        
                                        if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                    end
                                end
                                
                            else
                                NPTM=[];
                                for jM=1:12
                                    if  MonthsIndex(3,jM)==1
                                        NewPeakTimeAll_OnePerDay_M=NewPeakTimeAll_OnePerDay(NewPeakTimeAll_OnePerDay.Month==jM);
                                        MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(NewPeakTimeAll_OnePerDay_M,1));
                                        NPTM=[NPTM;NewPeakTimeAll_OnePerDay_M(1:MaxPeaksNo)];
                                        if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                    end
                                end
                            end
                            h.AllDiagramsY{j,1}.Analysis.Demand_at_Monthly_Network_Peak_kWh=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp,NPTM),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{j, 1}.HomeID)),1)';
                        end
                        
                        
                    case 'Average Demand at Top ''N'' Peaks'
                        %
                        h.DatatoPlot.YTitle=['Average Demand at Top ',h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value} ,' Peak(s) (kWh)'];
                        h.DualVar_YTopPeak_PB.Visible='on';
                        h.DualVar_YTopPeak_Text.Visible='on';
                        h.DualVar_YOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        AllIDS=[];
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            AllIDS=[AllIDS;[repmat(LoadNo,size(h.AllDiagrams{j,1}.HomeID,2),1),h.AllDiagrams{j,1}.HomeID']];
                        end
                        AllIDS=unique(AllIDS,'rows');
                        LoadList=unique(AllIDS(:,1),'stable');
                        for kT=1:size(LoadList,1)
                            TempPeakLoads{kT,1}=table;
                            TempPeakLoads{kT,1}.TimeStamp=h.AllLoads{LoadList(kT),2}.Load.TimeStamp;
                            TempPeakLoads{kT,1}.Load=h.AllLoads{LoadList(kT),2}.Load.kWh(:,ismember(h.AllLoads{LoadList(kT),2}.Load.kWh(1,:),AllIDS(AllIDS(:,1)==LoadList(kT),2)));
                            TempPeakLoads{kT,2}=TempPeakLoads{kT,1}(2:end,:);
                            TempPeakLoads{kT,2}.Load( isnan(TempPeakLoads{kT,2}.Load))=0;
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    TempPeakLoads{kT,2}.Load(ismember(TempPeakLoads{kT,2}.TimeStamp.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=0;
                                end
                            end
                            
                            TempPeakLoads{kT,3}=reshape(max(reshape(TempPeakLoads{kT,2}.Load,48,[])),[],size(TempPeakLoads{kT,2}.Load,2));

                            
                            TempPeakLoads{kT,2}=sort( TempPeakLoads{kT,2}.Load,'descend');
                            TempPeakLoads{kT,3}=sort(TempPeakLoads{kT,3},'descend');

                        end
                        
                        for j=1:size(h.AllDiagrams,1)
                            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1;1,1,1,1,1,1,1,1,1,1,1,1];
                            
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            TempPeakLoads_diag=TempPeakLoads(LoadList==LoadNo,:);
                            [~,~,HI3]=intersect(h.AllDiagrams{j,1}.HomeID,TempPeakLoads_diag{1,1}.Load(1,:),'stable');
                            
                            if h.DualVar_YOnePeakPerDay.Value==0
                                MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(TempPeakLoads_diag{1,2},1));
                                if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                h.AllDiagramsY{j,1}.Analysis.Annual_Peak_kWh=nanmean(TempPeakLoads_diag{1,2}(1:MaxPeaksNo,HI3),1)';
                                
                            else
                                MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(TempPeakLoads_diag{1,3},1));
                                if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                    ReachedPeakLimit=1;
                                end
                                
                                h.AllDiagramsY{j,1}.Analysis.Annual_Peak_kWh=nanmean(TempPeakLoads_diag{1,3}(1:MaxPeaksNo,HI3),1)';
                            end
                            
                        end
                        
                    case 'Average Demand at Top ''N'' Monthly Peaks'
                        
                        h.DatatoPlot.YTitle=['Average Demand at Top ',h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value} ,' Peak(s) (kWh)'];
                        h.DualVar_YTopPeak_PB.Visible='on';
                        h.DualVar_YTopPeak_Text.Visible='on';
                        h.DualVar_YOnePeakPerDay.Visible='on';
                        h.SeasonsPanel.Visible='on';
                        
                        AllIDS=[];
                        for j=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            AllIDS=[AllIDS;[repmat(LoadNo,size(h.AllDiagrams{j,1}.HomeID,2),1),h.AllDiagrams{j,1}.HomeID']];
                        end
                        
                        AllIDS=unique(AllIDS,'rows');
                        LoadList=unique(AllIDS(:,1),'stable');
                        for kT=1:size(LoadList,1)
                            TempPeakLoads{kT,1}=table;
                            TempPeakLoads{kT,1}.TimeStamp=h.AllLoads{LoadList(kT),2}.Load.TimeStamp;
                            TempPeakLoads{kT,1}.Load=h.AllLoads{LoadList(kT),2}.Load.kWh(:,ismember(h.AllLoads{LoadList(kT),2}.Load.kWh(1,:),AllIDS(AllIDS(:,1)==LoadList(kT),2)));
                            TempPeakLoads{kT,2}=TempPeakLoads{kT,1}(2:end,:);
                            TempPeakLoads{kT,2}.Load( isnan(TempPeakLoads{kT,2}.Load))=0;
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    TempPeakLoads{kT,2}.Load(ismember(TempPeakLoads{kT,2}.TimeStamp.Month,MonthsIndex(1,MonthsIndex(2,:)==ui)),:)=0;
                                end
                            end
                            
                            
                            for im=1:12
                                TempPeakLoads{kT,4}{im,1}=TempPeakLoads{kT,2}.Load(TempPeakLoads{kT,2}.TimeStamp.Month==im,:);
                                TempPeakLoads{kT,5}{im,1}=reshape(max(reshape(TempPeakLoads{kT,4}{im,1},48,[])),[],size(TempPeakLoads{kT,4}{im,1},2));
                            end

                            for im=1:12
                                TempPeakLoads{kT,4}{im,1}=sort(TempPeakLoads{kT,4}{im,1},'descend');
                                TempPeakLoads{kT,5}{im,1}=sort(TempPeakLoads{kT,5}{im,1},'descend');
                            end
                        end
                        
                        for j=1:size(h.AllDiagrams,1)
                            MonthsIndex=[1,2,3,4,5,6,7,8,9,10,11,12;1,1,2,2,2,3,3,3,4,4,4,1;1,1,1,1,1,1,1,1,1,1,1,1];
                            
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
                            
                            TempPeakLoads_diag=TempPeakLoads(LoadList==LoadNo,:);
                            [~,~,HI3]=intersect(h.AllDiagrams{j,1}.HomeID,TempPeakLoads_diag{1,1}.Load(1,:),'stable');
                            
                            
                            % monthly
                            for ui=1:4
                                if  h.DualVar_Seasons{ui,1}.Value==0
                                    
                                    MonthsIndex(3,MonthsIndex(2,:)==ui)=0;
                                end
                            end
                            
                            
                            if h.DualVar_YOnePeakPerDay.Value==0
                                NPTM=[];
                                for im=1:12
                                    if MonthsIndex(3,im)
                                        MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(TempPeakLoads_diag{1,4}{im,1},1));
                                        if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                        
                                        NPTM=[NPTM;nanmean(TempPeakLoads_diag{1,4}{im,1}(1:MaxPeaksNo,HI3),1)];
                                    end
                                end
                                
                                h.AllDiagramsY{j,1}.Analysis.Monthly_Peak_kWh=nanmean(NPTM,1)';
                                
                                
                            else
                                NPTM=[];
                                for im=1:12
                                    if MonthsIndex(3,im)
                                        MaxPeaksNo=min(str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value}),size(TempPeakLoads_diag{1,5}{im,1},1));
                                        if MaxPeaksNo<str2double(h.DualVar_YTopPeak_PB.String{h.DualVar_YTopPeak_PB.Value})
                                            ReachedPeakLimit=1;
                                        end
                                        NPTM=[NPTM;nanmean(TempPeakLoads_diag{1,5}{im,1}(1:MaxPeaksNo,HI3),1)];
                                    end
                                end
                                h.AllDiagramsY{j,1}.Analysis.Monthly_Peak_kWh=nanmean(NPTM,1)';
                            end
                            
                        end
                          
                    case 'Average Daily kWh'
                        h.DatatoPlot.YTitle='Average Daily usage (kWh)';
                        h.SeasonsPanel.Visible='off';
                      
                    case 'Average Daily Peak'
                        h.SeasonsPanel.Visible='off';
                        
                    case 'Bill ($/year)'
                        h.DatatoPlot.YTitle='Bill ($/year)';
                    case 'Unitised Bill (kW)'
                        h.DatatoPlot.YTitle='Unitised Bill (kW)';
                        
                end
                % Initiating the figure of Dual Var:
                axes(h.DualVarAxis)
                cla(h.DualVarAxis)
                box on
                hold off
                % plotting all diagrams on this figure:
                h.MaxD=0;
                for i=1:size(h.AllDiagrams,1)
                    % putting x and y data:
                    XData1=h.AllDiagramsX{i,1}.Analysis{:,XSelAx};
                    YData1=h.AllDiagramsY{i,1}.Analysis{:,YSelAx};
                    % Calculating the CC:
                    CC=corrcoef(XData1,YData1,'rows','complete');
                    if numel(CC)==1
                        CC=[CC,CC];
                    end
                   % Plotting the scatter
                    h.Plotted_Dual{i,1}=scatter(h.DualVarAxis,XData1,YData1,40,'.','DisplayName',[h.AllDiagrams{i,1}.CaseName,'   CC:',num2str(floor(1000*CC(1,2))/1000)]);
                    hold on
                    h.MaxD=max(h.MaxD,size(XData1,1));
                    
                end
                lgd=legend ('show');
                lgd.Location='Northwest';
                legend(h.DualVarAxis,'boxoff')
                box on
                xlabel(h.DualVarAxis,h.DatatoPlot.XTitle)
                ylabel(h.DualVarAxis,h.DatatoPlot.YTitle)
                grid on
                
                HideUnhideCase_Diag(src,evnt)
            else
                % for copying data to clipboard
                clear DatatoClip*
                DatatoClip=cell(h.MaxD,size(h.AllDiagrams,1));
                for i=1:size(h.AllDiagrams,1)
                    DatatoClip_H{1,2*(i-1)+1}=h.AllDiagrams{i,1}.CaseName;
                    DatatoClip_H{1,2*i}='';
                    DatatoClip_L{1,2*(i-1)+1}=h.DatatoPlot.XTitle;
                    DatatoClip_L{1,2*i}=h.DatatoPlot.YTitle;
                    DatatoClip(1:size(h.AllDiagrams{i,1}.Analysis{:,h.DualVar_FigX.Value},1),2*(i-1)+1)=num2cell(h.AllDiagramsX{i,1}.Analysis{:,h.DualVar_FigX.Value});
                    DatatoClip(1:size(h.AllDiagrams{i,1}.Analysis{:,h.DualVar_FigY.Value},1),2*i)=num2cell(h.AllDiagramsY{i,1}.Analysis{:,h.DualVar_FigY.Value});
                    
                end
                h.Clip_DualVar=[DatatoClip_H;DatatoClip_L;DatatoClip];
                
            end
            DelMsg;
            if ReachedPeakLimit
                
                msgbox('At least one case has less peak times than ''N''! So all available peak times are considered.','','Warn')
            end
            
        else
            
            cla(h.DualVarAxis)
        end
    end

%% ********************* Updating the Single variable graphs *****************************
    function update_SingVar(src,evnt,k)
        
        if size(h.AllDiagrams,1)>0
            DelMsg;msgbox(['Please wait!'])
            if k==1

                axes(h.SingVarAxis)
                cla(h.SingVarAxis)
                hold off
                box(h.SingVarAxis,'on');
                % what variable is selected in single var figure?
            end
            switch h.SingVar_FigType_PUP.String{h.SingVar_FigType_PUP.Value}
                
                case 'Average Annual Profile'
                    
                    if k==1 % updating figure
                        h.maxTS=0;
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            
                            h.Plotted_Sing{i,1}=plot(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2),'DisplayName',h.AllDiagrams{i,1}.CaseName);
                            h.maxTS=max(h.maxTS,size(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),1));
                            
                            hold on
                        end
                        % Plot properties
                        legend ('show')
                        ylabel('Average Load (kWh)')
                        grid on
                        box on
                        datacursormode on
                        title('Average Annual Load Profile')
                        legend(h.SingVarAxis,'boxoff')
                        
                    else  % copying data
                        clear DatatoClip*
                        DatatoClip=cell(h.maxTS,size(h.AllDiagrams,1));
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            DatatoClip_H{1,2*(i-1)+1}=h.AllDiagrams{i,1}.CaseName;
                            DatatoClip_H{1,2*i}='';
                            DatatoClip_L{1,2*(i-1)+1}='TimeStamp';
                            DatatoClip_L{1,2*i}='Load (kWh)';
                            DatatoClip(1:size(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),1),2*(i-1)+1)=cellstr(datestr(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end)));
                            DatatoClip(1:size(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),1),2*i)=num2cell(nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2));
                        end
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;DatatoClip];
                        
                    end
                case 'Daily kWh Histogram'

                    
                    if k==1 % updating figure
                        h.maxBin=0;
                        for i=1:size(h.AllDiagrams,1)
                            h.Plotted_Sing{i,1}=histogram((h.AllDiagrams{i, 1}.Analysis.Annual_kWh)/365,'DisplayName',h.AllDiagrams{i,1}.CaseName);
                            h.Plotted_Sing{i,1}.Normalization = 'probability';
                            h.Plotted_Sing{i,1}.BinWidth = 2;
                            h.dataHist{i,1}=h.Plotted_Sing{i,1}.BinEdges;
                            h.dataHist{i,2}=h.Plotted_Sing{i,1}.BinCounts;
                            h.maxBin=max(h.maxBin,size(h.Plotted_Sing{i,1}.BinEdges,2));
                            hold on
                        end
                        
                        % Plot properties
                        xlabel(h.SingVarAxis,'kWh/day')
                        ylabel(h.SingVarAxis,'Probability')
                        grid on
                        legend (h.SingVarAxis,'show')
                        box on
                        datacursormode on
                        title(h.SingVarAxis,'Daily Energy Distribution')
                        legend(h.SingVarAxis,'boxoff')
                        
                    else
                        
                        clear DatatoClip*
                        DatatoClip=cell(h.maxBin,size(h.AllDiagrams,1));
                        for i=1:size(h.AllDiagrams,1)
                            DatatoClip_H{1,2*(i-1)+1}=h.AllDiagrams{i,1}.CaseName;
                            DatatoClip_H{1,2*i}='';
                            DatatoClip_L{1,2*(i-1)+1}='Edge (kWh/day)';
                            DatatoClip_L{1,2*i}='Count';
                            DatatoClip(1:size(h.dataHist{i,1},2),2*(i-1)+1)=num2cell(h.dataHist{i,1}');
                            DatatoClip(1:size(h.dataHist{i,2},2),2*i)=num2cell(h.dataHist{i,2}');
                        end
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;DatatoClip];
                        
                        
                    end
                    
                case 'Monthly Average kWh'

                    
                    if k==1 % updating figure
                        
                        legind=cell(0);
                        h.MonthAvg=[];
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            
                            for hm=1:12
                                h.MonthAvg(hm,i)=48*nanmean(nanmean(h.AllLoads{LoadNo,2}.Load.kWh(h.AllLoads{LoadNo,2}.Load.TimeStamp.Month==hm,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID))));
                            end
                            legind=[legind;{h.AllDiagrams{i,1}.CaseName}];
                        end
                        
                        h.Plotted_Sing{1,1}=bar(h.MonthAvg);
                        
                        for ij=1: size(h.AllDiagrams,1)
                            set(h.Plotted_Sing{1,1}(ij),'DisplayName',legind{ij,1});
                        end
                        % Plot properties
                        set(h.SingVarAxis,'XTick',[1:12],'XTickLabel',...
                            {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'});
                        xlim([0 13])
                        %           end
                        legend ('show')
                        xlabel('Month')
                        ylabel('Monthly Average Demand (kWh/day)')
                        grid on
                        box on
                        datacursormode on
                        legend(h.SingVarAxis,'boxoff')
                        
                    else
                        clear DatatoClip*
                        for i=1:size(h.AllDiagrams,1)
                            DatatoClip_H{1,i}=h.AllDiagrams{i,1}.CaseName;
                            DatatoClip_L{1,i}='kWh/day';
                            
                        end
                        DatatoClip_H=[{''},DatatoClip_H];
                        DatatoClip_L=[{'Month'},DatatoClip_L];
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;num2cell([[1:12]',h.MonthAvg])];
                        
                        
                    end
                case 'Seasonal Daily Pattern'

                    if k==1 % updating figure
                        
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            
                            Seas=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp.Month,[12,1,2]),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2);
                            Seas2=nanmean(reshape(Seas,48,size(Seas,1)/48),2);
                            
                            h.Plotted_Sing{i,1}=plot(Seas2,'LineWidth',2,'DisplayName',['Summer - ',h.AllDiagrams{i,1}.CaseName]);
                            hold on
                            h.DatatoClip_S(:,i)=Seas2;
                            
                        end

                        % Plot properties
                        xlabel('Hour')
                        ylabel('Daily Average Load (kWh)')
                        grid on
                        box on
                        hold on
                        
                        set(h.SingVarAxis,'XTick',[2:4:48],'XTickLabel',...
                            {'1','3','5','7','9','11','13','15','17','19','21','23'});
                        
                        
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            Seas=nanmean(h.AllLoads{LoadNo,2}.Load.kWh(ismember(h.AllLoads{LoadNo,2}.Load.TimeStamp.Month,[6,7,8]),ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2);
                            Seas2=nanmean(reshape(Seas,48,size(Seas,1)/48),2);
                            h.Plotted_Sing{i,2}=plot([1:48],Seas2,'-.','LineWidth',2,'DisplayName',['Winter - ',h.AllDiagrams{i,1}.CaseName]);
                            h.DatatoClip_W(:,i)=Seas2;
                            hold on
                        end
                        
                        % Plot properties
                        lgd=legend ('show');
                        lgd.Location='Northwest';
                        grid on
                        box on
                        datacursormode on
                        xlim([1,48])
                        legend(h.SingVarAxis,'boxoff')
                    else
                        
                        clear DatatoClip*
                        for i=1:size(h.AllDiagrams,1)
                            DatatoClip_H{1,2*(i-1)+1}=h.AllDiagrams{i,1}.CaseName;
                            DatatoClip_H{1,2*i}='';
                            DatatoClip_L{1,2*(i-1)+1}='Summer';
                            DatatoClip_L{1,2*i}='Winter';
                            DatatoClip(:,2*(i-1)+1)=num2cell(h.DatatoClip_S(:,i));
                            DatatoClip(:,2*i)=num2cell(h.DatatoClip_W(:,i));
                            
                        end
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;DatatoClip];
                        
                    end
                    
                case 'Monthly Peak Time'
                    
                    if k==1 % updating figure
                        
                        clear DatatoClip*
                        
                        for i=1:size(h.AllDiagrams,1)
                            h.Plotted_Sing{i,1}=scatter(h.AllDiagrams{i,1}.MaxTime(:,1),h.AllDiagrams{i,1}.MaxTime(:,2),'DisplayName',h.AllDiagrams{i,1}.CaseName);
                            h.Plotted_Sing{i,1}.LineWidth=3;
                            hold on
                        end
                        
                        % Plot properties
                        set(h.SingVarAxis,'XTick',[1 3 5 7 9 11],'XTickLabel',...
                            {'Jan','Mar','May','Jul','Sep','Nov'});
                        xlabel('Month')
                        xlim([0 13])
                        ylabel('Time of day (Hour)')
                        title('Monthly Peak Time')
                        grid on
                        legend ('show')
                        box on
                        datacursormode on
                        legend(h.SingVarAxis,'boxoff')
                    else
                        clear DatatoClip*
                        for i=1:size(h.AllDiagrams,1)
                            
                            DatatoClip_H{1,2*(i-1)+1}=h.AllDiagrams{i,1}.CaseName;
                            DatatoClip_H{1,2*i}='';
                            DatatoClip_L{1,2*(i-1)+1}='Month';
                            DatatoClip_L{1,2*i}='Time of day (Hour)';
                            DatatoClip(:,2*(i-1)+1)=h.AllDiagrams{i,1}.MaxTime(:,1);
                            DatatoClip(:,2*i)=h.AllDiagrams{i,1}.MaxTime(:,2);
                            
                        end
                        
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;num2cell(DatatoClip)];
                        
                    end
                    
                    
                case 'Average Load Duration Curve'
                    if k==1
                        
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            h.Plotted_Sing{i,1}=plot(h.SingVarAxis,sort(nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2),'descend'),'LineWidth',2,'DisplayName',h.AllDiagrams{i,1}.CaseName);
                            
                            hold on
                            
                        end
                        ylabel(h.SingVarAxis,'kWh');
                        grid(h.SingVarAxis,'On');
                        legend(h.SingVarAxis,'boxoff')
                        xlabel('Annual peak number')
                        title('Average Load Duration Curve')
                        legend ('show')
                        box on
                        datacursormode on
                        legend(h.SingVarAxis,'boxoff')
                        
                    else
                        %
                        
                        clear DatatoClip*
                        for i=1:size(h.AllDiagrams,1)
                            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                            DatatoClip_H{1,i}=h.AllDiagrams{i,1}.CaseName;
                            DatatoClip_L{1,i}='kWh';
                            DatatoClip(:,i)=sort(nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2),'descend');
                        end
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;num2cell(DatatoClip)];
                    end
                    
                case 'Bill Distribution'
                    
                    
                    if k==1 % updating figure
                        h.maxBinB=0;
                        h.dataHist={};
                        for i=1:size(h.AllDiagrams,1)
                            
                            h.Plotted_Sing{i,1}=histogram((h.AllDiagrams{i, 1}.Analysis.Bill),'DisplayName',h.AllDiagrams{i,1}.CaseName);
                            h.Plotted_Sing{i,1}.Normalization = 'probability';
                            h.Plotted_Sing{i,1}.BinWidth = 100;
                            h.dataHist{i,1}=h.Plotted_Sing{i,1}.BinEdges;
                            h.dataHist{i,2}=h.Plotted_Sing{i,1}.BinCounts;
                            h.maxBinB=max(h.maxBinB,size(h.Plotted_Sing{i,1}.BinEdges,2));
                            hold on
                        end
                        % Plot properties
                        xlabel('Bill ($/year)')
                        ylabel('Probability')
                        grid on
                        legend ('show')
                        box on
                        datacursormode on
                        title('Annual Bill')
                        legend(h.SingVarAxis,'boxoff')
                    else
                        
                        clear DatatoClip*
                        DatatoClip=cell(h.maxBinB,size(h.AllDiagrams,1));
                        for i=1:size(h.AllDiagrams,1)
                            DatatoClip_H{1,2*(i-1)+1}=[h.AllDiagrams{i,1}.CaseName];
                            DatatoClip_H{1,2*i}='';
                            DatatoClip_L{1,2*(i-1)+1}='Edge ($/year)';
                            DatatoClip_L{1,2*i}='Count';
                            DatatoClip(1:size(h.dataHist{i,1},2),2*(i-1)+1)=num2cell(h.dataHist{i,1}');
                            DatatoClip(1:size(h.dataHist{i,2},2),2*i)=num2cell(h.dataHist{i,2}');
                        end
                        h.Clip_SingVar=[DatatoClip_H;DatatoClip_L;DatatoClip];
                        
                    end
                    
                    
                case 'Bill Box Plot'

                    if k==1 % updating figure
                        
                        BPdata=[];
                        BPdatagp=[];
                        h.maxuser=0;
                        for i=1:size(h.AllDiagrams,1)
                            BPdata=[BPdata; h.AllDiagrams{i, 1}.Analysis.Bill];
                            BPdatagp=[BPdatagp;repmat(cellstr(h.AllDiagrams{i,1}.CaseName),size(h.AllDiagrams{i, 1}.Analysis.Bill,1),1)];
                            h.maxuser=max(h.maxuser,size(h.AllDiagrams{i, 1}.Analysis.Bill,1));
                        end
                        
                        boxplot(BPdata,BPdatagp);
                        % Plot properties
                        grid on
                        ylabel('Bill ($/year)')
                        xlabel('Case')
                        legend(h.SingVarAxis,'boxoff')
                        
                    else
                        clear DatatoClip*
                        
                        BPdata=[];
                        BPdatagp=[];
                        
                        for i=1:size(h.AllDiagrams,1)
                            BPdata=[BPdata; h.AllDiagrams{i, 1}.Analysis.Bill];
                            BPdatagp=[BPdatagp;repmat(cellstr(h.AllDiagrams{i,1}.CaseName),size(h.AllDiagrams{i, 1}.Analysis.Bill,1),1)];
                        end
                        
                        h.Clip_SingVar=[{'Case', 'Bill ($/year)'};[BPdatagp,num2cell(BPdata)]];
                        
                    end
            end
            
            HideUnhideCase_Diag(src,evnt)
            DelMsg
            
        else
            cla(h.SingVarAxis)
            
        end
    end

%% ********************* Updating the Single Case graphs *****************************

    function update_SingCase(src,evnt,k)
        
        DelMsg;msgbox(['Please wait!'])
        if size(h.AllDiagrams,1)>0
            if k==1
                axes(h.SingCaseAxis)
                cla(h.SingCaseAxis)
                hold off
                box(h.SingCaseAxis,'on');
            end
            switch  h.SingCase_Fig.String{h.SingCase_Fig.Value}
                
                case  'Bill Components'
                    if  k==1
                        h.SingCase_OptionFig.String=[{'Total'};h.AllDiagrams{h.SingCase_List.Value,1}.Bill.Components.Names];
                        h.SingCase_OptionFig_Text.Visible='On';
                        h.SingCase_OptionFig.Visible='On';
                        BillComps=h.AllDiagrams{h.SingCase_List.Value,1}.Bill.Components.Value;
                        BillCompsName=h.AllDiagrams{h.SingCase_List.Value,1}.Bill.Components.Names;
                        h.SingCaseDC=num2cell(BillComps);
                        h.SingCaseDC_h=BillCompsName;
                        
                        switch h.SingCase_OptionFig.Value
                            
                            case 1
                                [~,ind2]=sort(nansum(BillComps,1),'descend');
                            otherwise
                                [~,ind2]=sort(nansum(BillComps(h.SingCase_OptionFig.Value-1,:),1),'descend');
                        end
                        
                        area(h.SingCaseAxis,BillComps(:,ind2)')
                        
                        legend (BillCompsName)
                        title(h.AllDiagrams{h.SingCase_List.Value,1}.CaseName)
                        ylabel('Annual Bill ($/year)')
                        switch h.SingCase_OptionFig.Value
                            
                            case 1
                                xlabel('Users (sorted by total bill)')
                            otherwise
                                [~,ind2]=sort(nansum(BillComps(h.SingCase_OptionFig.Value-1,:),1),'descend');
                                xlabel(['Users (sorted by ',h.AllDiagrams{h.SingCase_List.Value,1}.Bill.Components.Names{h.SingCase_OptionFig.Value-1},')'])
                        end
                        
                        
                        grid on
                        box on
                        xlim([1,size(BillComps,2)])
                        
                    else
                        
                        
                        h.Clip_SingCase=[h.SingCaseDC_h'; h.SingCaseDC'];
                        
                    end
                    
                case 'Bill Component Pie Chart'
                    
                    if  k==1
                        h.SingCase_OptionFig_Text.Visible='Off';
                        h.SingCase_OptionFig.Visible='Off';
                        BillComps=h.AllDiagrams{h.SingCase_List.Value,1}.Bill.Components.Value;
                        BillCompsName=h.AllDiagrams{h.SingCase_List.Value,1}.Bill.Components.Names;
                        AllTog= nansum(BillComps,2);
                        
                        h.SingCaseDC=BillComps;
                        h.SingCaseDC_h=BillCompsName;
                        
                        for i=1:size(BillCompsName,1)
                            LabelThis{1,i}=[BillCompsName{i,1},' (',num2str(floor(1000*AllTog(i)./sum(AllTog))./10),'%)'];
                        end
                        
                        pie(h.SingCaseAxis,nansum(BillComps,2),LabelThis);
                        title(['Average Percentage of Bill Components - Case: ', h.AllDiagrams{h.SingCase_List.Value,1}.CaseName])
                        
                    else
                        
                        tempSC=100*nansum(h.SingCaseDC,2)/nansum(nansum(h.SingCaseDC));
                        for i=1:size(tempSC,1)
                            h.SingCaseDC_2{1,i}=[num2str(round(tempSC(i,1)*10)/10),'%'];
                        end
                        h.Clip_SingCase=[h.SingCaseDC_h'; h.SingCaseDC_2];
                        
                    end
                    
                case 'Daily Profile interquartile Range'
                    
                    if k==1
                        %    cla(h.LoadAxes)
                        h.SingCase_OptionFig_Text.Visible='Off';
                        h.SingCase_OptionFig.Visible='Off';
                        cla(h.SingCaseAxis,'reset')
                        LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{h.SingCase_List.Value,1}.SelectedDatabase));
                        for k2=1:size(h.AllDiagrams{h.SingCase_List.Value,1}.HomeID,2)
                            
                            newDaily(:,k2)=nanmean(reshape(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{h.SingCase_List.Value,1}.HomeID(k2))),48,[]),2);
                        end
                        
                        
                        IQR(:,1)=prctile(newDaily,25,2);
                        IQR(:,2)=prctile(newDaily,50,2)-IQR(:,1);
                        IQR(:,3)=prctile(newDaily,75,2)-IQR(:,2)-IQR(:,1);
                        
                        h.SingCaseDC=[];
                        h.SingCaseDC(:,1)=prctile(newDaily,25,2);
                        h.SingCaseDC(:,2)=prctile(newDaily,50,2);
                        h.SingCaseDC(:,3)=prctile(newDaily,75,2);
                        
                        hold off
                        area1 = area(IQR,'Parent',h.SingCaseAxis);
                        hold on
                        
                        set(area1(2),'DisplayName','Median',...
                            'EdgeColor',[0.6 0.6 1]);
                        set(area1(3),'DisplayName','75%',...
                            'FaceColor',[0.6 0.6 1],...
                            'LineStyle','none');
                        set(area1(1),'DisplayName','25%','FaceColor',[1 1 1],...
                            'EdgeColor',[1 1 1],'FaceAlpha',0);
                        %                 plot(IQR(:,2)+IQR(:,1),'Parent',h.LoadAxes);
                        
                        xlim(h.SingCaseAxis,[1,48])
                        ylabel(h.SingCaseAxis,'kWh');
                        xlabel(h.SingCaseAxis,'30 min interval')
                        % title (h.LoadAxes,'show')
                        lgd = legend(h.SingCaseAxis,{''},'Location','northwest');
                        title(lgd,'Interquartile Range (25%, 50%, 75%)')
                        legend(h.SingCaseAxis,'boxoff')
                        title(h.AllDiagrams{h.SingCase_List.Value,1}.CaseName)
                        grid on
                    else
                        h.Clip_SingCase=[{'25%','50%','75%'}; num2cell(h.SingCaseDC)];
                    end
                    
            end
            
            ShowCase_Diag(src,evnt,h.SingCase_List.Value)
            DelMsg
            
        else
            
            cla(h.SingCaseAxis)
            
        end
    end

%% ********************* Exporting Figure and data*****************************
% 1- Export Figure:
% 1-1 Single Variable Figure

    function SinVar_ExpFig_CB(src,evnt)
        DelMsg;msgbox(['Please wait!'])
        DelMsg;fig1=figure;
        
        if  strcmp(h.SingVar_FigType_PUP.String{h.SingVar_FigType_PUP.Value},'Average Annual Profile')
            for i=1:size(h.AllDiagrams,1)
                
                LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                
                plot(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2),'DisplayName',h.AllDiagrams{i,1}.CaseName);
                hold on
                
            end
            legend ('show')
            ylabel('Average Load (kWh)')
            grid on
            box on
            datacursormode on
            title('Average Annual Load Profile')
            legend('boxoff')
        else
            ax=axes;
            newh=copyobj(get(h.SingVarAxis,'children'),ax);
            xlabel(h.SingVarAxis.XLabel.String)
            ylabel(h.SingVarAxis.YLabel.String)
            grid on
            legend ('show')
            legend('boxoff')
            box on
            ax=gca;
            ax.XTick=h.SingVarAxis.XTick;
            ax.XTickLabel=h.SingVarAxis.XTickLabel;
            
        end
    end

% 1-1 Dual Variable Figure
    function DualVar_ExpFig_CB(src,evnt)
        
        fig1=figure;
        ax=axes;
        newh=copyobj(get(h.DualVarAxis,'children'),ax);
        xlabel(h.DualVarAxis.XLabel.String)
        ylabel(h.DualVarAxis.YLabel.String)
        grid on
        legend ('show')
        legend('boxoff')
    end
% 1-1 Single Case Figure
    function SingCase_ExpFig_CB(src,evnt)
        fig1=figure;
        
        ax=axes;
        newh=copyobj(get(h.SingCaseAxis,'children'),ax);
        MyC=class(newh);
        xlabel(h.SingCaseAxis.XLabel.String)
        ylabel(h.SingCaseAxis.YLabel.String)
        
        if numel(findstr(MyC,'matlab.graphics.chart'))
            grid on
            
        end
    end
% 2- Copy Figure
% 2-1 Single Variable Figure
    function SinVar_CopyFig_CB(src,evnt)
        fig1=figure('Visible','Off');
        if  strcmp(h.SingVar_FigType_PUP.String{h.SingVar_FigType_PUP.Value},'Average Annual Profile')
            for i=1:size(h.AllDiagrams,1)
                
                LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{i,1}.SelectedDatabase));
                
                plot(h.AllLoads{LoadNo,2}.Load.TimeStamp(2:end),nanmean(h.AllLoads{LoadNo,2}.Load.kWh(2:end,ismember(h.AllLoads{LoadNo,2}.Load.kWh(1,:),h.AllDiagrams{i,1}.HomeID)),2),'DisplayName',h.AllDiagrams{i,1}.CaseName);
                hold on
                
            end
            legend ('show')
            ylabel('Average Load (kWh)')
            grid on
            box on
            datacursormode on
            title('Average Annual Load Profile')
            legend('boxoff')
            print(fig1,'-clipboard','-dbitmap')
            close(fig1)
        else
            
            ax=axes;
            newh=copyobj(get(h.SingVarAxis,'children'),ax);
            xlabel(h.SingVarAxis.XLabel.String)
            ylabel(h.SingVarAxis.YLabel.String)
            grid on
            legend ('show')
            legend('boxoff')
            %         hgexport(fig1,'-clipboard')
            print(fig1,'-clipboard','-dbitmap')
            close(fig1)
        end
        
    end

% 2-2 Dual Variable Figure
    function DualVar_CopyFig_CB(src,~)
        fig1=figure('Visible','Off');
        ax=axes;
        newh=copyobj(get(h.DualVarAxis,'children'),ax);
        xlabel(h.DualVarAxis.XLabel.String)
        ylabel(h.DualVarAxis.YLabel.String)
        grid on
        legend ('show')
        legend('boxoff')
        %         hgexport(fig1,'-clipboard')
        print(fig1,'-clipboard','-dbitmap')
        close(fig1)
        
    end

% 2-3 Single Case Figure
    function SingCase_CopyFig_CB(src,evnt)
        fig1=figure('Visible','Off');
        ax=axes;
        newh=copyobj(get(h.SingCaseAxis,'children'),ax);
        xlabel(h.SingCaseAxis.XLabel.String)
        ylabel(h.SingCaseAxis.YLabel.String)
        grid on
        print(fig1,'-clipboard','-dbitmap')
        close(fig1)
    end

% 3- Copying data of the graps
    function SinVar_CopyData_CB(src,evnt)
        update_SingVar(src,evnt,2)
        mat2clip(h.Clip_SingVar)
    end

    function DualVar_CopyData_CB(src,evnt)
        update_DualVar(src,evnt,2)
        
        mat2clip(h.Clip_DualVar)
    end

    function SingCase_CopyData_CB(src,evnt)
        update_SingCase(src,evnt,2)
        mat2clip(h.Clip_SingCase)
    end

    function update_listofExports(src,evnt)
        
        child_handles = allchild(h.menuExpRes);
        try
            delete(child_handles)
        end
        h.menuExport_all=uimenu(h.menuExpRes,'Label','All Cases','Callback',@Exp_AllCases_CB);
        for i=1:size(h.AllDiagrams,1)
            h.menuExport_cases{i,1}=uimenu(h.menuExpRes,'Label',[h.AllDiagrams{i,1}.CaseName],'Callback',{@Exp_Case_CB,i});
        end

    end

    function Exp_AllCases_CB(src,evnt)
        
        if size(h.AllDiagrams,1)<1
            
            DelMsg;msgbox('There are no cases yet! Please select the load and tariff and add the case to the diagrams before exporting!')
        else
            
            if ispc
                % exporting all cases
                [h.ExpFileName,h.ExpPathName,FilterIndex] = uiputfile({'*.xls';'*.xlsx'},'Save as',['Result_All_',datestr(now,'yyyymmdd_HHMM')]);
                if FilterIndex
                    DelMsg;msgbox('Exporting all cases to Excel..Please wait. This may take a few minutes!','Export');
                    
                    for j=1:size(h.AllDiagrams,1)
                        Exp_ToExcel(src,evnt,j);
                    end
                    
                    if h.status.Exc
                        
                        DelMsg
                        % Show where the file is saved and if user wants to open it:
                        choice = questdlg(['Results saved successfully in file: ',h.ExpFileName,'! Do you want to open the Excel file?'], ...
                            'Saved', ...
                            'Yes','No','No');
                        % Handle response
                        switch choice
                            case 'Yes'
                                
                                try
                                    winopen([h.ExpPathName,h.ExpFileName])
                                catch
                                    msgbox('Sorry! There is a problem in opening of the file!')
                                end
                                
                            case 'No'
                        end
                        % if writing was not successful:
                    else
                        errordlg('Something went wrong! Please try again!');
                    end
                    
                end
                
            else
                % export for mac
                % exporting all cases
                [h.ExpFileName,h.ExpPathName,FilterIndex] = uiputfile('*.csv','Save as',['Result_',datestr(now,'yyyymmdd_HHMM')]);
                if FilterIndex
                    DelMsg;msgbox('Exporting all cases to CSV..Please wait. This may take some time!','Export');
                    
                    Exp_ToCSV_all(src,evnt);
                    
                    if h.status.Exc
                        
                        DelMsg
                        % Show where the file is saved and if user wants to open it:
                        choice = questdlg(['Results were saved in folder" ',h.ExpPathName,'! Do you want to open the folder?'], ...
                            'Saved', ...
                            'Yes','No','No');
                        % Handle response
                        switch choice
                            case 'Yes'
                                
                                try
                                    system (['open ',h.ExpPathName])
                                catch
                                    msgbox('Sorry! There is a problem in opening!')
                                end
                                
                            case 'No'
                        end
                        % if writing was not successful:
                    else
                        errordlg('Something went wrong! Please try again!');
                    end
                    
                end
                
            end
            
        end
        
    end

    function Exp_Case_CB(src,evnt,j)
        
        if ispc
            [h.ExpFileName,h.ExpPathName,FilterIndex] = uiputfile({'*.xls';'*.xlsx'},'Save as',['Result_C',num2str(j),'_',datestr(now,'yyyymmdd_HHMM')]);
            if FilterIndex
                
                DelMsg;msgbox('Exporting Case Data to Excel..Please wait. This may take up to few minutes!','Export');
                Exp_ToExcel(src,evnt,j);
                
                if h.status.Exc
                    DelMsg
                    % Show where the file is saved and if user wants to open it:
                    choice = questdlg(['Results saved successfully in file: ',h.ExpFileName,'! Do you want to open the Excel file?'], ...
                        'Saved', ...
                        'Yes','No','No');
                    % Handle response
                    switch choice
                        case 'Yes'
                            try
                                winopen([h.ExpPathName,h.ExpFileName])
                            catch
                                msgbox('Sorry! There is a problem in opening the Excel file!')
                            end
                            
                        case 'No'
                    end
                    % if writing was not successful:
                else
                    errordlg('Something went wrong! Please try again!');
                end
            end
            
        else
            %          Export for mac
            
            [h.ExpFileName,h.ExpPathName,FilterIndex] = uiputfile('*.csv' ,'Save as',['Result_C',num2str(j),'_',datestr(now,'yyyymmdd_HHMM')]);
            if FilterIndex
                
                DelMsg;msgbox('Exporting Case Data to CSV..Please wait. This may take some time!','Export');
                Exp_ToCSV(src,evnt,j);
                
                if h.status.Exc
                    DelMsg
                    % Show where the file is saved and if user wants to open it:
                    choice = questdlg(['Results saved successfully in file: ',h.ExpFileName,'! Do you want to open the csv file?'], ...
                        'Saved', ...
                        'Yes','No','No');
                    % Handle response
                    switch choice
                        case 'Yes'
                            try
                                system (['open ',h.ExpPathName,h.ExpFileName])
                            catch
                                msgbox('Sorry! There is a problem in opening the CSV file!')
                            end
                            
                        case 'No'
                    end
                    % if writing was not successful:
                else
                    errordlg('Something went wrong! Please try again!');
                end
            end
            
        end
        
    end

    function Exp_ToExcel(src,evnt,j)
        
        % Exporting case
        LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
        if isfield(h.AllLoads{LoadNo,2},'Demog')
            Demog_Item_Header=h.AllLoads{LoadNo,2}.Demog(1,:);
            Demog_Item_all=h.AllLoads{LoadNo,2}.Demog(2:end,:);
            Demog_Item_F=Demog_Item_all(ismember(str2double(Demog_Item_all(:,1)),h.AllDiagrams{j,1}.HomeID),:);
            DatatoWrite=[[Demog_Item_Header;Demog_Item_F],[h.AllDiagrams{j,1}.Analysis.Properties.VariableNames;table2cell(h.AllDiagrams{j,1}.Analysis)]];
        else
            DatatoWrite=[h.AllDiagrams{j,1}.Analysis.Properties.VariableNames;table2cell(h.AllDiagrams{j,1}.Analysis)];
            
        end
        h.status.Exc=1;
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{['Results produced by TDA developed by Centre for Environmental and Energy Market (CEEM) UNSW on: ',datestr(now,'dd mmm yyyy')]},[h.AllDiagrams{j,1}.CaseName],'A1');
        h.status.Exc= h.status.Exc*status;
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],DatatoWrite,h.AllDiagrams{j,1}.CaseName,'A6');
        h.status.Exc= h.status.Exc*status;
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{'Tariff: '},h.AllDiagrams{j,1}.CaseName,'A2');
        h.status.Exc= h.status.Exc*status;
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{'No. of Users: '},h.AllDiagrams{j,1}.CaseName,'A3');
        h.status.Exc= h.status.Exc*status;
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{'Database:'},h.AllDiagrams{j,1}.CaseName,'A4');
        h.status.Exc= h.status.Exc*status;
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{h.AllDiagrams{j,1}.TariffDetail.Name},h.AllDiagrams{j,1}.CaseName,'B2');
        h.status.Exc= h.status.Exc*status;
        % writing the home ids
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{size(h.AllDiagrams{j,1}.HomeID,2)},h.AllDiagrams{j,1}.CaseName,'B3');
        h.status.Exc= h.status.Exc*status;
        % writing the selected database
        [status,~]=xlswrite([h.ExpPathName,h.ExpFileName],{h.AllDiagrams{j,1}.SelectedDatabase},h.AllDiagrams{j,1}.CaseName,'B4');
        h.status.Exc= h.status.Exc*status;
    end

    function Exp_ToCSV(src,evnt,j)
        
        % Exporting case
        LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
        if isfield(h.AllLoads{LoadNo,2},'Demog')
            Demog_Item_VN = matlab.lang.makeValidName(h.AllLoads{LoadNo,2}.Demog(1,:));
            Demog_Item_all=cell2table(h.AllLoads{LoadNo,2}.Demog(2:end,:));
            Demog_Item_F=Demog_Item_all(ismember(str2double(Demog_Item_all{:,1}),h.AllDiagrams{j,1}.HomeID),:);
            Demog_Item_F.Properties.VariableNames=Demog_Item_VN;
            DatatoWrite=[Demog_Item_F,h.AllDiagrams{j,1}.Analysis];
        else
            DatatoWrite=h.AllDiagrams{j,1}.Analysis;
        end
        try
            writetable(DatatoWrite,[h.ExpPathName,h.ExpFileName]);
            h.status.Exc=1;
        catch
            h.status.Exc=0;
        end
        
        
    end

    function Exp_ToCSV_all(src,evnt)
        
        % Exporting case
        h.status.Exc=1;
        for j=1:size(h.AllDiagrams,1)
            DelMsg;msgbox(['Exporting case: ',h.AllDiagrams{j,1}.CaseName])
            
            LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{j,1}.SelectedDatabase));
            if isfield(h.AllLoads{LoadNo,2},'Demog')
                Demog_Item_VN = matlab.lang.makeValidName(h.AllLoads{LoadNo,2}.Demog(1,:));
                Demog_Item_all=cell2table(h.AllLoads{LoadNo,2}.Demog(2:end,:));
                Demog_Item_F=Demog_Item_all(ismember(str2double(Demog_Item_all{:,1}),h.AllDiagrams{j,1}.HomeID),:);
                Demog_Item_F.Properties.VariableNames=Demog_Item_VN;
                DatatoWrite=[Demog_Item_F,h.AllDiagrams{j,1}.Analysis];
            else
                DatatoWrite=h.AllDiagrams{j,1}.Analysis;
            end
            try
                writetable(DatatoWrite,[h.ExpPathName,h.ExpFileName(1:end-4),'_Case_',num2str(j),'.csv']);
                status=1;
            catch
                status=0;
            end
            h.status.Exc=h.status.Exc* status;
        end
    end


    function ExpCurFig(src,evnt)
        switch h.tabg_Diag.SelectedTab.Title
            case 'Single Variable Graphs'
                
                SinVar_ExpFig_CB(src,evnt)
                
            case 'Dual Variable Graphs'
                DualVar_ExpFig_CB(src,evnt)
            case  'Single Case Graphs'
                SingCase_ExpFig_CB(src,evnt)
        end
    end

    function CopyCurFig(src,evnt)
        switch h.tabg_Diag.SelectedTab.Title
            case 'Single Variable Graphs'
                
                SinVar_CopyFig_CB(src,evnt)
                
            case 'Dual Variable Graphs'
                DualVar_CopyFig_CB(src,evnt)
            case  'Single Case Graphs'
                SingCase_CopyFig_CB(src,evnt)
        end
    end

    function CopyCurData(src,evnt)
        switch h.tabg_Diag.SelectedTab.Title
            case 'Single Variable Graphs'
                
                SinVar_CopyData_CB(src,evnt)
                
            case 'Dual Variable Graphs'
                DualVar_CopyData_CB(src,evnt)
            case  'Single Case Graphs'
                SingCase_CopyData_CB(src,evnt)
        end
    end

%% ********************* Updating materials when updating Graphs*****************************

% Update List of Cases Panel
    function UpdateListofCasesPanel(src,evnt)
        
        for i=1:size(h.AllDiagrams,1)
            h.ListofCases_CB{i,1}.Visible='On';
            h.ListofCases_CB{i,1}.TooltipString=['Hide/Unhide ',h.AllDiagrams{i,1}.CaseName];
            h.ListofCases_Show{i,1}.Visible='On';
            h.ListofCases_Show{i,1}.TooltipString=['Show ',h.AllDiagrams{i,1}.CaseName,' in load and tariff selection panels'];
            h.ListofCases_Export{i,1}.Visible='On';
            h.ListofCases_Export{i,1}.TooltipString=['Export the results of ',h.AllDiagrams{i,1}.CaseName];
            h.ListofCases_Delete{i,1}.Visible='On';
            h.ListofCases_Delete{i,1}.TooltipString=['Delete ',h.AllDiagrams{i,1}.CaseName];
        end
        
        for i=size(h.AllDiagrams,1)+1:10
            h.ListofCases_CB{i,1}.Visible='Off';
            h.ListofCases_Show{i,1}.Visible='Off';
            h.ListofCases_Export{i,1}.Visible='Off';
            h.ListofCases_Delete{i,1}.Visible='Off';
        end
    end

% Hide or unhide case
    function HideUnhideCase_Diag(src,evnt)
        
        for i=1:size(h.AllDiagrams,1)
            try
                switch h.ListofCases_CB{i,1}.Value
                    case 1
                        h.Plotted_Dual{i,1}.Visible='on';
                        h.Plotted_Sing{i,1}.Visible='on';
                        
                    case 0
                        h.Plotted_Dual{i,1}.Visible='off';
                        h.Plotted_Sing{i,1}.Visible='off';
                end
            end
            % for seasonal pattern who has two series
            try
                switch h.ListofCases_CB{i,1}.Value
                    case 1
                        h.Plotted_Sing{i,2}.Visible='on';
                        
                    case 0
                        h.Plotted_Sing{i,2}.Visible='off';
                end
            end
            
        end
        
    end

% Show cases in the diagram panel
    function ShowCase_Diag(src,evnt,j)
        
        h.CurrentCaseShowing=j;
        if h.AllDiagrams{j,1}.CaseNameMannual
            h.InfoLoadPan{1,1}.String=['Case ',num2str(j),' ( ',h.AllDiagrams{j,1}.CaseName,')'];
        else
            h.InfoLoadPan{1,1}.String=['Case ',num2str(j)];
        end
        h.InfoLoadPan{2,1}.String=['No. of users: ',num2str(size(h.AllDiagrams{j,1}.HomeID,2))];
        h.InfoLoadPan{3,1}.String=['Database: ',h.AllDiagrams{j,1}.SelectedDatabase];
        h.InfoLoadPan{15,1}.String=['Network Load: ',h.AllDiagrams{j,1}.PeakTimeBased];
        
        for kk=1:10
            h.InfoLoadPan_Dem{kk,1}.Visible='Off';
            h.InfoLoadPan_Dem_SA{kk,1}.Visible='Off';
        end
        
        if isfield(h.AllDiagrams{j,1},'Load')
            
            for kk=1:size(h.AllDiagrams{j,1}.Load.DemogInfo,1)
                
                h.InfoLoadPan_Dem{kk,1}.Visible='On';
                h.InfoLoadPan_Dem_SA{kk,1}.Visible='On';
                h.InfoLoadPan_Dem{kk,1}.String=[h.AllDiagrams{j,1}.Load.DemogInfo{kk,1},' ',h.AllDiagrams{j,1}.Load.DemogInfo{kk,2}];
                
                if ~strcmp(h.AllDiagrams{j,1}.Load.DemogInfo{kk,2},'All')
                    set(h.InfoLoadPan_Dem{kk,1},'FontWeight','bold')
                else
                    set(h.InfoLoadPan_Dem{kk,1},'FontWeight','normal')
                end
            end
            
        end
        
        if h.AllDiagrams{j,1}.CaseNameMannual
            h.InfoLoadPan{5,1}.String=['Case ',num2str(j),' ( ',h.AllDiagrams{j,1}.CaseName,')'];
        else
            h.InfoLoadPan{5,1}.String=['Case ',num2str(j)];
        end
        
        if h.AllDiagrams{j,1}.CaseNameMannual
            h.InfoLoadPan{13,1}.String=['Case ',num2str(j),' ( ',h.AllDiagrams{j,1}.CaseName,')'];
        else
            h.InfoLoadPan{13,1}.String=['Case ',num2str(j)];
        end
        
        h.InfoLoadPan{14,1}.String=['Tariff Component: ',h.AllDiagrams{j,1}.TarCom];
        
        h.InfoLoadPan{6,1}.String=['Name: ',h.AllDiagrams{j,1}.TariffDetail.Name];
        
        h.InfoLoadPan{7,1}.String=['Type: ',h.AllDiagrams{j,1}.TariffDetail.Type];
        h.InfoLoadPan{8,1}.String=['State: ',h.AllDiagrams{j,1}.TariffDetail.State];
        
        h.InfoLoadPan{9,1}.String=['Provider: ',h.AllDiagrams{j,1}.TariffDetail.Provider];
        
        try
            h.InfoLoadPan{10,1}.String=['Daily Charge ($/day): ',num2str(h.AllDiagrams{j,1}.TariffDetail.Parameters.Daily.Value)];
            
        end
        
        try
            h.InfoLoadPan{11,1}.String=['Energy Cost ($/kWh): ',num2str(h.AllDiagrams{j,1}.TariffDetail.Parameters.Energy.Value)];
            
        end
        
        % put the parameters of the table to the parameters of the tariff
        h.InfoLoadPan{12,1}.Data=table2cell(h.AllDiagrams{j,1}.TariffDetail.Parameters.Other);
        h.InfoLoadPan{12,1}.ColumnName=h.AllDiagrams{j,1}.TariffDetail.Parameters.Other.Properties.VariableNames;
        h.BeingShownCase=j;
    end

%% ********************* Statistical Analysis*****************************

    function SA_CB(src,evnt,kk2)
        
        % create a figure
        h.Stat.F = figure('Name','Statistical Analysis','NumberTitle','off', ...
            'HandleVisibility','on','Resize','off', ...
            'Position',[200,200, 600, 300],...
            'Toolbar','none','Menubar','none'); % Figure to get peak time
        %
        movegui(h.Stat.F ,'center')
        
        h.Stat.P=uipanel('Parent',h.Stat.F,...
            'Units', 'normalized', 'Position',[0 0 1 1],...
            'FontWeight','bold',...
            'FontSize',8);
        if kk2==0
            h.Stat.Text= uicontrol(h.Stat.P,'Style','Text',...
                'String',['Statistical Analysis of Case No: ',num2str(h.CurrentCaseShowing)], ...
                'FontUnits','normalized',...
                'Value',1,...
                'Units', 'normalized', 'Position',[.01 .85 .95 .08],...
                'HorizontalAlignment','left');
        else
            
            h.Stat.Text= uicontrol(h.Stat.P,'Style','Text',...
                'String',['Statistical Analysis of Case No: ',num2str(h.CurrentCaseShowing),', for demographical information: "',h.AllDiagrams{h.CurrentCaseShowing,1}.Load.DemogInfo{kk2,1}(1:end-1),'"'], ...
                'FontUnits','normalized',...
                'Value',1,...
                'Units', 'normalized', 'Position',[.01 .85 .95 .08],...
                'HorizontalAlignment','left');
            
        end
        % create the table
        LoadNo=find(strcmp(h.AllLoads(:,1),h.AllDiagrams{h.CurrentCaseShowing,1}.SelectedDatabase));
        if isfield(h.AllLoads{LoadNo,2},'Demog')
            
            Demog_Item_Header=h.AllLoads{LoadNo,2}.Demog(1,:);
            Demog_Item_all=h.AllLoads{LoadNo,2}.Demog(2:end,:);
            Demog_Item_F=Demog_Item_all(ismember(str2double(Demog_Item_all(:,1)),h.AllDiagrams{h.CurrentCaseShowing,1}.HomeID),:);
            
            DemogT=[Demog_Item_Header;Demog_Item_F];
            DemogTable= cell2table(DemogT(2:end,kk2+1));
            FTi=[DemogTable,h.AllDiagrams{h.CurrentCaseShowing, 1}.Analysis];
            FTi.Properties.VariableNames{1,1}='Options';
            
            if kk2==0
                FTi.Options=repmat({'All'},size(FTi,1),1);
            end
        else
            DemogTable=table;
            DemogTable.Options=repmat({'All'},size(h.AllDiagrams{h.CurrentCaseShowing, 1}.Analysis,1),1);
            FTi=[DemogTable,h.AllDiagrams{h.CurrentCaseShowing, 1}.Analysis]  ;
            
        end
        
        
        h.StatTable=grpstats(FTi,'Options',{'mean','std','min','max'},'DataVars',{'Annual_kWh','Demand_at_Network_Peak_kWh','Demand_at_Monthly_Network_Peak_kWh','Annual_Peak_kWh','Monthly_Peak_kWh','Average_Daily_kWh','Average_Daily_Peak_kWh','Bill','Unitised_Bill'});
        
        h.Stat.T=uitable(h.Stat.P,'Units', 'normalized','Position',[.05 .20 .90 .5]);
        h.Stat.T.Data=table2cell(h.StatTable);
        h.Stat.T.ColumnName=h.StatTable.Properties.VariableNames;
        
        temp12=uicontrol(h.Stat.P, ...
            'Style','pushbutton', 'String','Copy Data',...
            'Units', 'normalized', 'Position',[.8 .07 .15 .1],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'Callback', @CopyStatData);

    end

    function CopyStatData(src,evnt)
        mat2clip([h.StatTable.Properties.VariableNames;table2cell(h.StatTable)]);
    end

    function DeleteCase_Diag(src,evnt,k)
        if k>0
            if h.Confirm.BeforeDeleting.Case
                choice = questdlg(['Are you sure you want to delete case number ',num2str(k),'?'], ...
                    'Deleting case', ...
                    'Yes','No','No');
                % Handle response
                switch choice
                    case 'Yes'
                        DeleteCase_Diag2(src,evnt,k)
                    case 'No'
                end
            else
                DeleteCase_Diag2(src,evnt,k)
            end
        else
            if h.Confirm.BeforeDeleting.Case
                choice = questdlg(['Are you sure you want to delete all cases?'], ...
                    'Deleting case', ...
                    'Yes','No','No');
                % Handle response
                switch choice
                    case 'Yes'
                        DeleteCase_Diag2(src,evnt,k)
                    case 'No'
                        
                end
            else
                DeleteCase_Diag2(src,evnt,k)
            end
            
        end
        
    end

    function DeleteCase_Diag2(src,evnt,k)
        if k>0
            
            h.AllDiagrams(k,:)=[];
            for iD=1:size(h.AllDiagrams,1)
                if ~h.AllDiagrams{iD,1}.CaseNameMannual
                    h.AllDiagrams{iD,1}.CaseName=['Case ', num2str(iD)];
                end
            end
            update_DualVar(src,evnt,1);
            update_SingVar(src,evnt,1);
            update_SingCase(src,evnt,1);
            UpdateListofCasesPanel(src,evnt);
            update_listofExports
            try
                if h.BeingShownCase==k & size(h.AllDiagrams,1)>0
                    ShowCase_Diag(src,evnt,1)
                end
            end
            
            DelMsg;msgbox(['Case number ',num2str(k),' has been deleted!'])
        else
            h.AllDiagrams=[];
            update_DualVar(src,evnt,1);
            update_SingVar(src,evnt,1);
            update_SingCase(src,evnt,1);
            UpdateListofCasesPanel(src,evnt);
            update_listofExports
            DelMsg;msgbox(['All cases have been deleted!'])
            
        end
        
    end


%% Callbacks for Tariffs (adding, deleting, saving, etc):
% Deleting a tariff
    function DelCurTar(src,evnt)
        if h.Confirm.BeforeDeleting.Tariff
            choice = questdlg(['Are you sure you want to delete tariff: ',h.TariffListPup.String{h.TariffListPup.Value},'? You can reset the tariffs to the original list of tariffs in Menu>Tariff>Reset Tariffs.'], ...
                'Delete tariff', ...
                'Yes','No','No');
            % Handle response
            switch choice
                case 'Yes'
                    DelCurTar2(src,evnt)
            end
        else
            DelCurTar2(src,evnt)
        end
    end

    function DelCurTar2(src,evnt)

        if ispc
            
            if  h.TariffList.AllTariffs(1,strcmp({h.TariffList.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value})).Original
                TempTariff=load('Data\AllTariffs.mat','AllTariffs');
                TempTariff.AllTariffs(1,strcmp({ TempTariff.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value})).Show=false;
                AllTariffs=TempTariff.AllTariffs;
                
                save('Data\AllTariffs.mat','AllTariffs')
                
            else
                TempTariff=load('Data\AllTariffs_New.mat','AllTariffs');
                TempTariff.AllTariffs(:,strcmp({ TempTariff.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value}))=[];
                AllTariffs=TempTariff.AllTariffs;
                
                save('Data\AllTariffs_New.mat','AllTariffs')
            end
        else
            if  h.TariffList.AllTariffs(1,strcmp({h.TariffList.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value})).Original
                TempTariff=load([h.FilesPath,'/Data/AllTariffs.mat'],'AllTariffs');
                TempTariff.AllTariffs(1,strcmp({ TempTariff.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value})).Show=false;
                AllTariffs=TempTariff.AllTariffs;
                
                save([h.FilesPath,'/Data/AllTariffs.mat'],'AllTariffs')
                
            else
                TempTariff=load([h.FilesPath,'/Data/AllTariffs_New.mat'],'AllTariffs');
                TempTariff.AllTariffs(:,strcmp({ TempTariff.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value}))=[];
                AllTariffs=TempTariff.AllTariffs;
                
                save([h.FilesPath,'/Data/AllTariffs_New.mat'],'AllTariffs')
            end
            
        end
        
        h.TariffList.AllTariffs(:,strcmp({h.TariffList.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value}))=[];
        
        h.TariffListPup.String={'Select:',h.TariffList.AllTariffs.Name};
        
        if  h.TariffListPup.Value==1
            
            h.TariffListPup.Value=1;
        else
            h.TariffListPup.Value=h.TariffListPup.Value-1;
        end
        SelecTariff(src,evnt)
    end

% Opening the folder of a tariff
    function DocCurTar(src,evnt)
        
        SelTar=h.TariffList.AllTariffs(find(strcmp({h.TariffList.AllTariffs.Name},h.TariffListPup.String{h.TariffListPup.Value})));
        if ispc
            try
                winopen(['TariffDocs\',SelTar.Provider])
            catch
                DelMsg;msgbox('Sorry, can''t find any information!')
            end
        else
            try
                system(['open ',[h.FilesPath,'/TariffDocs/',SelTar.Provider]])  % check for MAC later
            catch
                DelMsg;msgbox('Sorry, can''t find any information!')
            end
        end
        
    end

% updating a tariff and save
    function TariffPar_CellEditCallback(src,evnt)
        
        % Show the save new tariff options and put the new tariff into handle.MyTariff
        if strcmp(h.TariffModifytext_2.Visible,'off')
            h.TariffModifytext_2.Visible='on';
            h.NewTariffName.Visible='on';
            h.AddTariffPB.Visible='on';
            kv=2;
            h.NewTariffName.String=h.NameSE.String;
            tempname=h.NewTariffName.String;
            dd=findstr(tempname(1,end-2:end),'V');
            if numel(dd)>0
                tempname=tempname(1,1:end-5+dd);
            end
            h.NameSE.String=tempname;
            h.NameSE.TooltipString='';
            while numel(find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Name},tempname))))>0
                tempname=[h.NameSE.String,' V',num2str(kv)];
                kv=kv+1;
            end
            h.NewTariffName.String=tempname;
        end
        h.MyTariff.Parameters.DUOS.Other=cell2table(h.TariffParTable_DUOS.Data);
        h.MyTariff.Parameters.TUOS.Other=cell2table(h.TariffParTable_TUOS.Data);
        h.MyTariff.Parameters.NUOS.Other=cell2table(h.TariffParTable_NUOS.Data);
        h.MyTariff.Parameters.DTUOS.Other=cell2table(h.TariffParTable_DTUOS.Data);
        
        h.MyTariff.Parameters.DUOS.Other.Properties.VariableNames=h.TariffParTable_DUOS.ColumnName;
        h.MyTariff.Parameters.TUOS.Other.Properties.VariableNames=h.TariffParTable_DUOS.ColumnName;
        h.MyTariff.Parameters.DTUOS.Other.Properties.VariableNames=h.TariffParTable_DUOS.ColumnName;
        h.MyTariff.Parameters.NUOS.Other.Properties.VariableNames=h.TariffParTable_DUOS.ColumnName;
        
        if strcmp(h.DailyChargeSTR_DUOS.Visible,'on')
            h.MyTariff.Parameters.DUOS.Daily.Value=str2num(h.DailySE_DUOS.String);
            h.MyTariff.Parameters.TUOS.Daily.Value=str2num(h.DailySE_TUOS.String);
            h.MyTariff.Parameters.DTUOS.Daily.Value=str2num(h.DailySE_DTUOS.String);
            h.MyTariff.Parameters.NUOS.Daily.Value=str2num(h.DailySE_NUOS.String);
            
        end
        if strcmp(h.EnergyCostStr_DUOS.Visible,'on')
            h.MyTariff.Parameters.DUOS.Energy.Value=str2num(h.EnergyCostEdit_DUOS.String);
            h.MyTariff.Parameters.TUOS.Energy.Value=str2num(h.EnergyCostEdit_TUOS.String);
            h.MyTariff.Parameters.DTUOS.Energy.Value=str2num(h.EnergyCostEdit_DTUOS.String);
            h.MyTariff.Parameters.NUOS.Energy.Value=str2num(h.EnergyCostEdit_NUOS.String);
            
        end
        
        % as the tariff is editted:
        h.SthEdited=1;
        
    end

% Adding a tariff
    function AddTariff(src,evnt)
        
        NewTariff1=h.MyTariff;
        NewTariff1.Parameters=h.MyTariff.Parameters.DUOS;
        NewTariff2=h.MyTariff;
        NewTariff2.Parameters=h.MyTariff.Parameters.TUOS;
        NewTariff3=h.MyTariff;
        NewTariff3.Parameters=h.MyTariff.Parameters.NUOS;
        
        NewTariff4=h.MyTariff;
        NewTariff4.Parameters=h.MyTariff.Parameters.DTUOS;
        
        [TariffOK1,Msg1]=TariffValidity(NewTariff1);
        
        [TariffOK2,Msg2]=TariffValidity(NewTariff2);
        
        [TariffOK3,Msg3]=TariffValidity(NewTariff3);
        
        [TariffOK4,Msg4]=TariffValidity(NewTariff4);
        
        h.TariffTableOK=TariffOK1*TariffOK2*TariffOK3*TariffOK4;
        
        if h.TariffTableOK==0
            DelMsg;msgbox([Msg1;Msg1;Msg1;Msg1])
            
        else
            
            
            if numel(find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Name},h.NewTariffName.String))))>0
                DelMsg;msgbox('There is already a tariff in this name! Please choose a different name and try again!')
            else
                % saving
                
                h.TariffList.AllTariffs(1,size(h.TariffList.AllTariffs,2)+1)=h.MyTariff;
                h.TariffList.AllTariffs(size(h.TariffList.AllTariffs,2)).Name=h.NewTariffName.String;
                h.TariffList.AllTariffs(size(h.TariffList.AllTariffs,2)).Original=false;
                [tmd ind]=sort({h.TariffList.AllTariffs.Name});
                h.TariffList.AllTariffs=h.TariffList.AllTariffs(ind);
                h.TariffListPup.String={'Select',h.TariffList.AllTariffs.Name};
                AllTariffs=h.TariffList.AllTariffs;
                AllTariffs(:,cell2mat({AllTariffs.Original}))=[];
                if ispc
                    save('Data\AllTariffs_New.mat','AllTariffs')
                else
                    save([h.FilesPath,'/Data/AllTariffs_New.mat'],'AllTariffs')
                end
                DelMsg;msgbox(['New Tariff ',h.NewTariffName.String,' saved! You can delete this tariff later by selecting it from tariff list dropdown list and press the delete pushbutton beside the pop-up menu! You can also reset the whole tariffs in Project > Reset Tariffs'])
                
            end
            
        end
        
    end

% Creating a new tariff
    function CreateTar(src,evnt,Type)
        
        h.CreateTar_F.F = figure('Name','Create a New Tariff','NumberTitle','off', ...
            'HandleVisibility','on','Resize','off', ...
            'Position',[200,200, 500, 450],...
            'Toolbar','none','Menubar','none'); % Figure to get peak time
        %
        movegui(h.CreateTar_F.F ,'center')
        h.CreateTar_F.P=uipanel('Parent',h.CreateTar_F.F,...
            'Units', 'normalized', 'Position',[0 0 1 1],...
            'FontWeight','bold',...
            'FontSize',8);
        
        h.CreateTar_F.TName= uicontrol(h.CreateTar_F.P,'Style','Text',...
            'String',['Name:'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.01 .9 .15 0.06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TNameVal= uicontrol(h.CreateTar_F.P,'Style','Edit',...
            'String','New Custom Tariff ', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.17 .9 .40 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TProvider= uicontrol(h.CreateTar_F.P,'Style','Text',...
            'String',['Provider:'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.60 .9 .15 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TProviderVal= uicontrol(h.CreateTar_F.P,'Style','Edit',...
            'String','N/A ', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.76 .9 .20 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TState= uicontrol(h.CreateTar_F.P,'Style','Text',...
            'String',['State:'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.01 .795 .13 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TStateVal= uicontrol(h.CreateTar_F.P,'Style','popupmenu',...
            'String',{'ACT','NSW','QLD','VIC','SA','TAS','WA','NT','N/A'}, ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.14 .80 .15 .055],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TYear= uicontrol(h.CreateTar_F.P,'Style','Text',...
            'String',['Year:'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.31 .795 .1 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TYearVal= uicontrol(h.CreateTar_F.P,'Style','edit',...
            'String','2017/18', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.42 .8 .17 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TInfo= uicontrol(h.CreateTar_F.P,'Style','Text',...
            'String',['Info:'], ...
            'FontUnits','normalized',...
            'ToolTipString','Additional info for this tariff. It will show up when you hover over the name of tariff once you select it.',...
            'Units', 'normalized', 'Position',[.6 .795 .1 .06],...
            'HorizontalAlignment','left');
        
        h.CreateTar_F.TInfoVal= uicontrol(h.CreateTar_F.P,'Style','edit',...
            'String',['Manually created tariff on: ',datestr(now)], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.7 .8 .25 .06],...
            'HorizontalAlignment','left');
        
        % Add remove row (only for some tariff types)
        h.CreateTar_F.AT= uicontrol(h.CreateTar_F.P, ...
            'Style','pushbutton', 'String','+',...
            'Units', 'normalized', 'Position',[.9 .01 .05 .06],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'Visible','Off',...
            'TooltipString',['Add new row'],...
            'Callback', @AddRowToTariff);
        
        h.CreateTar_F.RT= uicontrol(h.CreateTar_F.P, ...
            'Style','pushbutton', 'String','-',...
            'Units', 'normalized', 'Position',[.84 .01 .05 .06],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'Visible','Off',...
            'TooltipString',['Delete last row'],...
            'Callback', @DelRowFromTariff);
        
        h.NewNUOS= uicontrol(h.CreateTar_F.P,'Style','Pushbutton',...
            'String','NUOS=DUOS+TUOS', ...
            'FontUnits','normalized',...
            'Value',0,...
            'ToolTipString','Make NUOS equivalent to DUOS+TUOS',...
            'Units', 'normalized', 'Position',[.02 .01 .35 .06],...
            'HorizontalAlignment','left','Callback',@NewNUOSCB);
        
        h.tabg_creTar = uitabgroup('Parent',h.CreateTar_F.P,'Tag','Loadtabs', ...
            'Units','normalized','Position',[0 0.1 1 0.67]);
        h.tab_DUOS = uitab('parent',h.tabg_creTar, 'title', 'DUOS');
        h.tab_DUOS_P = uipanel('Parent',h.tab_DUOS, ...
            'Position',[.0 .0 1 1]);
        
        h.tab_TUOS = uitab('parent',h.tabg_creTar, 'title', 'TUOS');
        h.tab_TUOS_P = uipanel('Parent',h.tab_TUOS, ...
            'Position',[.0 .0 1 1]);
        
        h.tab_NUOS = uitab('parent',h.tabg_creTar, 'title', 'NUOS');
        h.tab_NUOS_P = uipanel('Parent',h.tab_NUOS, ...
            'Position',[.0 .0 1 1]);
        
        uicontrol(h.CreateTar_F.P, ...
            'Style','pushbutton', 'String','Add',...
            'Units', 'normalized', 'Position',[.79 .72 .1 .07],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'TooltipString',['Save this tariff'],...
            'Callback', @SetnewTariff);
        
        uicontrol(h.CreateTar_F.P, ...
            'Style','pushbutton', 'String','Cancel',...
            'Units', 'normalized', 'Position',[.89 .72 .1 .07],...
            'FontWeight','bold',...
            'FontUnits','normalized',...
            'TooltipString',['Cancel'],...
            'Callback', @CancelAdding);
        
        % DUOS
        h.CT.D.DailyC_Text= uicontrol(h.tab_DUOS_P,'Style','Text',...
            'String',['Daily Charge ($/day):'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.01 .85 .25 .085],...
            'HorizontalAlignment','left');
        
        h.CT.D.DailyC_Val= uicontrol(h.tab_DUOS_P,'Style','Edit',...
            'String','0', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.27 .85 .1 .085],...
            'HorizontalAlignment','left');
        
        h.CT.D.EnergyC_Text= uicontrol(h.tab_DUOS_P,'Style','Text',...
            'String',['Energy Charge ($/kWh):'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Visible','Off',...
            'Units', 'normalized', 'Position',[.4 .85 .3 .085],...
            'HorizontalAlignment','right');
        
        h.CT.D.EnergyC_Val= uicontrol(h.tab_DUOS_P,'Style','Edit',...
            'String','0', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Visible','Off',...
            'Units', 'normalized', 'Position',[.77 .85 .1 .085],...
            'HorizontalAlignment','left');

        % TUOS
        h.CT.T.DailyC_Text= uicontrol(h.tab_TUOS_P,'Style','Text',...
            'String',['Daily Charge ($/day):'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.01 .85 .25 .085],...
            'HorizontalAlignment','left');
        
        h.CT.T.DailyC_Val= uicontrol(h.tab_TUOS_P,'Style','Edit',...
            'String','0', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.27 .85 .1 .085],...
            'HorizontalAlignment','left');
        
        h.CT.T.EnergyC_Text= uicontrol(h.tab_TUOS_P,'Style','Text',...
            'String',['Energy Charge ($/kWh):'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Visible','Off',...
            'Units', 'normalized', 'Position',[.4 .85 .3 .085],...
            'HorizontalAlignment','right');
        
        h.CT.T.EnergyC_Val= uicontrol(h.tab_TUOS_P,'Style','Edit',...
            'String','0', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Visible','Off',...
            'Units', 'normalized', 'Position',[.77 .85 .1 .085],...
            'HorizontalAlignment','left');
        
        % NUOS
        h.CT.N.DailyC_Text= uicontrol(h.tab_NUOS_P,'Style','Text',...
            'String',['Daily Charge ($/day):'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.01 .85 .25 .085],...
            'HorizontalAlignment','left');
        
        h.CT.N.DailyC_Val= uicontrol(h.tab_NUOS_P,'Style','Edit',...
            'String','0', ...
            'FontUnits','normalized',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.27 .85 .1 .085],...
            'HorizontalAlignment','left');
        
        h.CT.N.EnergyC_Text= uicontrol(h.tab_NUOS_P,'Style','Text',...
            'String',['Energy Charge ($/kWh):'], ...
            'FontUnits','normalized',...
            'Value',1,...
            'Visible','Off',...
            'Units', 'normalized', 'Position',[.4 .85 .3 .085],...
            'HorizontalAlignment','right');
        
        h.CT.N.EnergyC_Val= uicontrol(h.tab_NUOS_P,'Style','Edit',...
            'String','0', ...
            'FontUnits','normalized',...
            'Visible','Off',...
            'Value',1,...
            'Units', 'normalized', 'Position',[.77 .85 .1 .085],...
            'HorizontalAlignment','left');
        
        % specific parameters for each tariff type
        switch Type
            
            case 'FR'
                h.CT.Type='Flat Rate';
                
                h.CreateTar_F.RT.Visible='Off';
                h.CreateTar_F.AT.Visible='Off';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                
                Name={'Energy cost'};
                Value=[0];
                Unit={'$/kWh'};
                h.CTTable=table(Name,Value,Unit);
                
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false];
                
                % TUOS
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false];
                
                % NUOS
                
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false];
                
            case 'FRSeas'
                h.CT.Type='Flat Rate Seasonal';
                
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                
                Name={'Season 1'};
                Rate=[0];
                Unit={'$/kWh'};
                StartMonth=[1];
                EndMonth=[12];
                h.CTTable=table(Name,Rate,Unit,StartMonth,EndMonth);
                
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false true true];
                
                % TUOS
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false true true];
                
                % NUOS
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false true true];
                

            case 'Block'
                h.CT.Type='Block';
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                
                Name={'Block 1'};
                Value=[0];
                Unit={'$/kWh'};
                HighBound=[Inf];
                Bound_unit={'kWh/yr'};
                h.CTTable=table(Name,Value,Unit,HighBound,Bound_unit);
                
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false true false];
                
                % TUOS
                
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false true false];
                
                % NUOS
                
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false true false];
                
            case 'Block_Quarterly'
                
                h.CT.Type='Block Quarterly';
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                
                Name={'Block 1'};
                Value=[0];
                Unit={'$/kWh'};
                HighBound=[Inf];
                Bound_unit={'kWh/Quarter'};
                h.CTTable=table(Name,Value,Unit,HighBound,Bound_unit);
                
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false true false];
                
                % TUOS
                
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false true false];
                
                % NUOS
                
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false true false];
                
                
                
            case 'TOU'
                h.CT.Type='TOU';
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                
                Name={'Peak 1'};
                Rate=[0];
                Unit={'$/kWh'};
                StartHour=[0];
                StartMin=[0];
                EndHour=[0];
                EndMin=[0];
                Weekday=true;
                Weekend=false;
                
                h.CTTable=table(Name,Rate,Unit,StartHour,StartMin,EndHour,EndMin,Weekday,Weekend);
                
                % DUOS
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false true true true true true true];
                
                % TUOS
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false true true true true true true];
                
                % NUOS
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false true true true true true true];
                
                
            case 'TOUSeas'
                
                
                h.CT.Type='TOU Seasonal';
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                
                
                Name={'Peak 1'};
                Rate=[0];
                Unit={'$/kWh'};
                StartHour=[0];
                StartMin=[0];
                EndHour=[0];
                EndMin=[0];
                StartMonth=[1];
                EndMonth=[12];
                Weekday=true;
                Weekend=false;
                
                h.CTTable=table(Name,Rate,Unit,StartHour,StartMin,EndHour,EndMin,StartMonth,EndMonth,Weekday,Weekend);
                
                % DUOS
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false true true true true true true true true];
                
                % TUOS
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false true true true  true true  true true true];
                
                % NUOS
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false true true true true true  true true true];
                
           case 'Demand'
               
                h.CT.Type='Demand Charge';
                h.CT.D.EnergyC_Text.Visible='On';
                h.CT.D.EnergyC_Val.Visible='On';
                h.CT.T.EnergyC_Text.Visible='On';
                h.CT.T.EnergyC_Val.Visible='On';
                h.CT.N.EnergyC_Text.Visible='On';
                h.CT.N.EnergyC_Val.Visible='On';
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                
                Name={'Summer peak'};
                Rate=[0];
                Unit={'$/kW/Month'};
                StartHour=[0];
                StartMin=[0];
                EndHour=[0];
                EndMin=[0];
                StartMonth=[1];
                EndMonth=[12];
                Weekday=true;
                Weekend=false;
                NetworkPeak=false;
                NumberofPeaks=[1];
                DemandWindowTSNo=[1];
                MinDemandkW=[0];
                MinDemandCharge=[0];
                TimeGroup=1;
                DayAverage=false;
                
                h.CTTable=table(Name,Rate,Unit,StartHour,StartMin,EndHour,EndMin,StartMonth,EndMonth,Weekday,Weekend,NetworkPeak,NumberofPeaks,DemandWindowTSNo,MinDemandkW,MinDemandCharge,TimeGroup,DayAverage);
                
                
                % DUOS
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_DUOS_table.Data=table2cell(h.CTTable);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true false true true true true true true true true true true true true true true true];
                
                % TUOS
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                
                h.tab_TUOS_table.Data=table2cell(h.CTTable);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true false true true true  true true true true true true true  true true true true];
                
                % NUOS
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.Data=table2cell(h.CTTable);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true false true true true true true true true true true true  true true true true];
                
            case 'Demand_Block'
                
            case 'Demand_TOU'
                 
                h.CT.Type='Demand Charge and TOU';
                h.CT.D.EnergyC_Text.Visible='Off';
                h.CT.D.EnergyC_Val.Visible='Off';
                h.CT.T.EnergyC_Text.Visible='Off';
                h.CT.T.EnergyC_Val.Visible='Off';
                h.CT.N.EnergyC_Text.Visible='Off';
                h.CT.N.EnergyC_Val.Visible='Off';
                h.CreateTar_F.RT.Visible='On';
                h.CreateTar_F.AT.Visible='On';
                
                Name={'Summer peak'};
                Rate=[0];
                Unit={'Choose'};
                StartHour=[0];
                StartMin=[0];
                EndHour=[0];
                EndMin=[0];
                StartMonth=[1];
                EndMonth=[12];
                Weekday=true;
                Weekend=false;
                NetworkPeak=false;
                NumberofPeaks=[1];
                DemandWindowTSNo=[1];
                MinDemandkW=[0];
                MinDemandCharge=[0];
                TimeGroup=1;
                DayAverage=false;
                
                h.CTTable=table(Name,Rate,Unit,StartHour,StartMin,EndHour,EndMin,StartMonth,EndMonth,Weekday,Weekend,NetworkPeak,NumberofPeaks,DemandWindowTSNo,MinDemandkW,MinDemandCharge,TimeGroup,DayAverage);
                
                % DUOS
                h.tab_DUOS_table=uitable(h.tab_DUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_DUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_DUOS_table.ColumnEditable=[true true true true true true true true true true true true true true true true true true];
                h.tab_DUOS_table.ColumnFormat=({[] [] {'$/kW/Month' '$/kWh'} [] [] [] [] [] [] [] [] [] [] [] [] [] [] []});
                h.tab_DUOS_table.Data=table2cell(h.CTTable);

                % TUOS
                h.tab_TUOS_table=uitable(h.tab_TUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_TUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_TUOS_table.ColumnEditable=[true true true true true true  true true true true true true true  true true true true];
                h.tab_TUOS_table.ColumnFormat=({[] [] {'$/kW/Month' '$/kWh'} [] [] [] [] [] [] [] [] [] [] [] [] [] [] []});
                h.tab_TUOS_table.Data=table2cell(h.CTTable);

                % NUOS
                h.tab_NUOS_table=uitable(h.tab_NUOS_P,'Units', 'normalized','Position',[.02 .05 .96 .77],'CellEditCallback',@ChangedParamCT);
                h.tab_NUOS_table.ColumnName=h.CTTable.Properties.VariableNames;
                h.tab_NUOS_table.ColumnEditable=[true true true true true true true true true true true true true  true true true true];
                h.tab_NUOS_table.ColumnFormat=({[] [] {'$/kW/Month' '$/kWh'} [] [] [] [] [] [] [] [] [] [] [] [] [] [] []});
                h.tab_NUOS_table.Data=table2cell(h.CTTable);

        end
        
    end

    function NewNUOSCB(src,evnt)
        
        h.tab_NUOS_table.Data(:,2)=num2cell(cell2mat(h.tab_DUOS_table.Data(:,2))+cell2mat(h.tab_TUOS_table.Data(:,2)));
        
        try
            h.CT.N.EnergyC_Val.String=num2str(str2num(h.CT.T.EnergyC_Val.String)+str2num(h.CT.D.EnergyC_Val.String));
        end
        
        try
            h.CT.N.DailyC_Val.String=num2str(str2num(h.CT.T.DailyC_Val.String)+str2num(h.CT.D.DailyC_Val.String));
            
        end
        
    end

    function AddRowToTariff(src,evnt)
        
        h.tab_DUOS_table.Data=[h.tab_DUOS_table.Data;h.tab_DUOS_table.Data(end,:)];
        h.tab_TUOS_table.Data=[h.tab_TUOS_table.Data;h.tab_TUOS_table.Data(end,:)];
        h.tab_NUOS_table.Data=[h.tab_NUOS_table.Data;h.tab_NUOS_table.Data(end,:)];
        
    end

    function DelRowFromTariff(src,evnt)
        
        h.tab_DUOS_table.Data(end,:)=[];
        h.tab_TUOS_table.Data(end,:)=[];
        h.tab_NUOS_table.Data(end,:)=[];
        
    end
% if any of the tables parameters was changed the other two tables (components) should also change (except for the rate):
    function ChangedParamCT(src,evnt)
        
        switch h.tabg_creTar.SelectedTab.Title
            case 'DUOS'
                h.tab_TUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]])=h.tab_DUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]]);
                h.tab_NUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]])=h.tab_DUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]]);
            case 'TUOS'
                h.tab_DUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]])=h.tab_TUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]]);
                h.tab_NUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]])=h.tab_TUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]]);
            case 'NUOS'
                
                h.tab_DUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]])=h.tab_NUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]]);
                h.tab_TUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]])=h.tab_NUOS_table.Data(:,[1,[3:size(h.tab_DUOS_table.Data,2)]]);
        end
        
        
    end

% set the new tariff
    function SetnewTariff(src,evnt)
        
        h.TariffNew.Provider=h.CreateTar_F.TProviderVal.String;
        h.TariffNew.Type=h.CT.Type;
        h.TariffNew.State=h.CreateTar_F.TStateVal.String{h.CreateTar_F.TStateVal.Value};
        h.TariffNew.Name=h.CreateTar_F.TNameVal.String;
        h.TariffNew.Info=h.CreateTar_F.TInfoVal.String;
        h.TariffNew.Show=true;
        h.TariffNew.Original=false;
        
        h.TariffNew.Year=h.CreateTar_F.TYearVal.String;
        h.TariffNew.Parameters.DUOS.Daily.Value=str2num(h.CT.D.DailyC_Val.String);
        h.TariffNew.Parameters.TUOS.Daily.Value=str2num(h.CT.T.DailyC_Val.String);
        h.TariffNew.Parameters.NUOS.Daily.Value=str2num(h.CT.N.DailyC_Val.String);
        h.TariffNew.Parameters.DTUOS.Daily.Value=str2num(h.CT.D.DailyC_Val.String)+str2num(h.CT.T.DailyC_Val.String);
        
        if strcmpi(h.TariffNew.Type,'Demand Charge')
            h.TariffNew.Parameters.DUOS.Energy.Value=str2num(h.CT.D.EnergyC_Val.String);
            h.TariffNew.Parameters.TUOS.Energy.Value=str2num(h.CT.T.EnergyC_Val.String);
            h.TariffNew.Parameters.NUOS.Energy.Value=str2num(h.CT.N.EnergyC_Val.String);
            h.TariffNew.Parameters.DTUOS.Energy.Value=str2num(h.CT.D.EnergyC_Val.String)+str2num(h.CT.T.EnergyC_Val.String);
        end
        h.TariffNew.Parameters.DUOS.Other=cell2table(h.tab_DUOS_table.Data);
        h.TariffNew.Parameters.DUOS.Other.Properties.VariableNames=h.tab_DUOS_table.ColumnName;
        
        h.TariffNew.Parameters.TUOS.Other=cell2table(h.tab_TUOS_table.Data);
        h.TariffNew.Parameters.TUOS.Other.Properties.VariableNames=h.tab_TUOS_table.ColumnName;
        
        h.TariffNew.Parameters.NUOS.Other=cell2table(h.tab_NUOS_table.Data);
        h.TariffNew.Parameters.NUOS.Other.Properties.VariableNames=h.tab_NUOS_table.ColumnName;
        
        h.TariffNew.Parameters.DTUOS.Other=h.TariffNew.Parameters.DUOS.Other;
        try
            h.TariffNew.Parameters.DTUOS.Other.Rate(:,1)=h.TariffNew.Parameters.DUOS.Other.Rate(:,1)+h.TariffNew.Parameters.TUOS.Other.Rate(:,1);
        end
        try
            h.TariffNew.Parameters.DTUOS.Other.Value(:,1)=h.TariffNew.Parameters.DUOS.Other.Value(:,1)+h.TariffNew.Parameters.TUOS.Other.Value(:,1);
        end
        
        NewTariff1=h.TariffNew;
        NewTariff1.Parameters=h.TariffNew.Parameters.DUOS;
        NewTariff2=h.TariffNew;
        NewTariff2.Parameters=h.TariffNew.Parameters.TUOS;
        NewTariff3=h.TariffNew;
        NewTariff3.Parameters=h.TariffNew.Parameters.NUOS;
        
        [TariffOK1,Msg1]=TariffValidity(NewTariff1);
        
        [TariffOK2,Msg2]=TariffValidity(NewTariff2);
        
        [TariffOK3,Msg3]=TariffValidity(NewTariff3);
        
        
        if TariffOK1*TariffOK2*TariffOK3==1
            
            if numel(find(~cellfun(@isempty,strfind({h.TariffList.AllTariffs.Name},h.TariffNew.Name))))>0
                DelMsg;msgbox('There is already a tariff in this name! Please choose a different name and try again!')
            else
                % saving
                h.TariffNew.Sector='Network';
%                 h.TariffList.AllTariffs
                h.TariffList.AllTariffs(1,size(h.TariffList.AllTariffs,2)+1)=h.TariffNew;
                
                [tmd,ind]=sort({h.TariffList.AllTariffs.Name});
                h.TariffList.AllTariffs=h.TariffList.AllTariffs(ind);
                h.TariffListPup.String={'Select',h.TariffList.AllTariffs.Name};
                
                AllTariffs=h.TariffList.AllTariffs;
                if ispc
                    try
                        tempTariff=load('Data\AllTariffs_New.mat','AllTariffs');
                        tempTariff.AllTariffs(1,size(tempTariff.AllTariffs,2)+1)=h.TariffNew;
                        
                    catch
                        tempTariff.AllTariffs(1,1)=h.TariffNew;
                        
                    end
                    
                    [tmd,ind]=sort({tempTariff.AllTariffs.Name});
                    tempTariff.AllTariffs=tempTariff.AllTariffs(ind);
                    AllTariffs=tempTariff.AllTariffs;
                    save('Data\AllTariffs_New.mat','AllTariffs')
                else
                    
                    try
                        tempTariff=load([h.FilesPath,'/Data/AllTariffs_New.mat'],'AllTariffs');
                        tempTariff.AllTariffs(1,size(tempTariff.AllTariffs,2)+1)=h.TariffNew;
                    catch
                        tempTariff.AllTariffs(1,1)=h.TariffNew;
                        
                    end

                    [tmd,ind]=sort({tempTariff.AllTariffs.Name});
                    tempTariff.AllTariffs=tempTariff.AllTariffs(ind);
                    AllTariffs=tempTariff.AllTariffs;
                    save([h.FilesPath,'/Data/AllTariffs_New.mat'],'AllTariffs')
                end
                DelMsg;msgbox(['New Tariff ',h.TariffNew.Name,' saved! You can delete this tariff later by selecting it from tariff list dropdown list and press the delete pushbutton beside the pop-up menu! You can also reset the whole tariffs in Menu > Tariff > Reset Tariffs'])
            end
        else
            DelMsg;msgbox([Msg1,'', Msg2,'',Msg3])
        end
        
    end


    function CancelAdding(src,evnt)
        
        delete(h.CreateTar_F.F)
    end

    function ChecktheTariffTable(src,evnt)

        [TariffOK,Msg]=TariffValidity(h.MyTariff);
        h.TariffTableOK=TariffOK;
        if TariffOK==0
            DelMsg;msgbox(Msg)
        end
    end


%% Callbacks for load (import new, delete, restore, etc)
    function ImpNewLoad_CB(src,evnt)
        
        choice = questdlg(['Please refer to instructions, section 5.3 (CREATING NEW LOAD DATA) and put the load and demographic data in required format before importing. You will need to import data after creating the load data. You can also open the sample file and see the required format or paste in your data into this file and save as a new load file and then load the file when creating the new load data.'], ...
            'Create load data', ...
            'Create now','Open sample file','Cancel','Cancel');
        
        % Handle response
       
        switch choice
            case 'Create now'
                
                [h.NewFile_FileName,h.NewFile_PathName,FilterIndex] = uigetfile({'*.xlsx';'*.xls'},'Upload new load file');
                h.NewLoad=[];
                if FilterIndex
                    try
                        DelMsg;msgbox('Loading Data..Please wait! Depending on the size of load data this can take several minutes.');
                        
                        newload_rawdata=readtable([h.NewFile_PathName,h.NewFile_FileName],'Sheet','Load');
                        try
                            newload_rawdata_dem=readtable([h.NewFile_PathName,h.NewFile_FileName],'Sheet','Info','ReadVariableNames',false);
                            newload_rawdata_dem=table2cell(newload_rawdata_dem);
                            
                            newload_rawdata_dem_HI=str2double(newload_rawdata_dem(2:end,1));
                            [indD1,indD2]=sort(newload_rawdata_dem_HI,'ascend');
                            newload_rawdata_dem_2=newload_rawdata_dem(2:end,:);
                            
                            newload_rawdata_dem=[newload_rawdata_dem(1,:);newload_rawdata_dem_2(indD2,:)];
                            
                            h.InfoExist=1;
                        catch
                            h.InfoExist=0;
                        end
                        LoadIDNames=newload_rawdata.Properties.VariableDescriptions(1,2:end);
                        clear LoadIDNames2
                        for ie=1:size(LoadIDNames,2)
                            LoadIDNames2(1,ie)=str2num(LoadIDNames{1,ie}(27:end-1));
                        end
                        
                        [indL1,indL2]=sort(LoadIDNames2,'ascend');
                        %
                        %                     newload_rawdata_TS = datetime(newload_rawdata(:,1),'InputFormat','dd/MM/yyyy h:mm:ss a');
                        %                     newload_rawdata_LD= cell2mat(newload_rawdata(:,2:end));
                        h.NewLoad.Load=table;
                        h.NewLoad.Load.TimeStamp=[NaT;newload_rawdata{:,1}];
                        newload_rawdata2=newload_rawdata{:,2:end};
                        h.NewLoad.Load.kWh=[indL1;newload_rawdata2(:,indL2)];
                        h.LoadDemMatch=1;
                        if h.InfoExist
                            h.NewLoad.Demog=newload_rawdata_dem;
                            
                            if (numel(setdiff(indL1,indD1))+numel(setdiff(indD1,indL1)))>0
                                h.LoadDemMatch=0;
                                
                            end
                            
                        end
                        
                        if  h.LoadDemMatch
                            
                            DelMsg
                            
                            h.CreateLoad.F = figure('Name','Create Load','NumberTitle','off', ...
                                'HandleVisibility','on','Resize','off', ...
                                'Position',[200,200, 400, 150],...
                                'Toolbar','none','Menubar','none'); % Figure to save project
                            
                            movegui(h.CreateLoad.F ,'center')
                            h.CreateLoad.P=uipanel('Parent',h.CreateLoad.F,...
                                'Units', 'normalized', 'Position',[0 0 1 1],...
                                'FontWeight','bold',...
                                'FontSize',10);
                            
                            h.CreateLoad.T1= uicontrol(h.CreateLoad.P,'Style','Text',...
                                'String','Load Name:', ...
                                'FontUnits','normalized',...
                                'Value',1,...
                                'Units', 'normalized', 'Position',[.01 .75 .3 .17],...
                                'HorizontalAlignment','left');
                            
                            h.CreateLoad.T2= uicontrol(h.CreateLoad.P,'Style','Edit',...
                                'String',['L_',datestr(now,'yyyymmdd_HHMM')], ...
                                'FontUnits','normalized',...
                                'Value',1,...
                                'Units', 'normalized', 'Position',[.31 .75 .5 .17],...
                                'HorizontalAlignment','left');
                            
                            temp1=uicontrol(h.CreateLoad.P, ...
                                'Style','pushbutton', 'String','Create',...
                                'Units', 'normalized', 'Position',[.2 .1 .2 .2],...
                                'FontWeight','bold',...
                                'FontUnits','normalized',...
                                'Callback', @CreateLoad_CB);
                            
                            temp2=uicontrol(h.CreateLoad.P, ...
                                'Style','pushbutton', 'String','Cancel',...
                                'Units', 'normalized', 'Position',[.6 .1 .2 .2],...
                                'FontWeight','bold',...
                                'FontUnits','normalized',...
                                'Callback', @CreateLoad_Cancel_CB);
                        else
                            DelMsg;msgbox('The users'' ID in load and demographic information do not match! Please try again!')
                            
                        end
                        
                        if size(newload_rawdata,2)<2
                            DelMsg;msgbox('There was a problem in the load data file. Please make sure you followed the required data format described in the instruction and try again!');
                            
                        end
                        
                    catch
                        
                        DelMsg; msgbox('There was a problem in the load data file. Please make sure you followed the required data format described in the instruction!');
                        
                    end
                    
                end
              
                
            case 'Open sample file'
                
                
                if ispc
                    copyfile('Data\SampleLoad_BU.xlsx','SampleLoad.xlsx');
                    winopen('SampleLoad.xlsx')
                else
                    copyfile([h.FilesPath,'/Data/SampleLoad_BU.xlsx'],[h.FilesPath,'/SampleLoad.xlsx']);
                    system(['open ',[h.FilesPath,'/SampleLoad.xlsx']])
                end
        end
        
    end


    function CreateLoad_CB(src,evnt)
        LoadData=h.NewLoad;
        if ispc
            save(['Data\LoadData_',h.CreateLoad.T2.String,'.mat'],['LoadData'])
        else
            
            save([h.FilesPath,'/Data/LoadData_',h.CreateLoad.T2.String,'.mat'],['LoadData'])
            
        end
        
        try
            close (h.CreateLoad.F)
        end
        updateLoadList_del
        
        if h.InfoExist
            DelMsg;msgbox('The load data has been successfully imported. You may use this data by selecting it from the list of loads. You can also delete the load from Menu: Load > Delete Load Data.');
        else
            DelMsg;msgbox('The load data has been successfully imported. HOWEVER, THERE WAS NO DEMOGRAPHIC INFORMATION AVAILABLE! You may use this data by selecting it from the list of loads. You can also delete the load from Menu: Load > Delete Load Data.');
            
        end
    end


    function CreateLoad_Cancel_CB(src,evnt)
        try
            close (h.CreateLoad.F)
        end
    end

% delete all figures except the main figure
    function DelMsg(src,evnt)
        
        all_figs = findobj(0, 'type', 'figure');
        delete(setdiff(all_figs, h.MainFigure));
        
    end

% Restore load
    function RestoreLoad(src,evnt)
        
        choice = questdlg(['Are you sure you want to restore the load data to the original list? This will delete all your imported loads and restore the original load data if you deleted them.'], ...
            'Restore load data', ...
            'Yes','No','No');
        % Handle response
        switch choice
            case 'Yes'
                
                DelMsg;msgbox('Please wait. This may take up to few minutes.');
                OriginalList= {'LoadData_AG300_2010_11_Gross.mat';'LoadData_AG300_2010_11_Net.mat';'LoadData_AG300_2011_12_Gross.mat';'LoadData_AG300_2011_12_Net.mat';'LoadData_AG300_2012_13_Gross.mat';'LoadData_AG300_2012_13_Net.mat';'LoadData_SGSC.mat';'LoadData_SGSC_sample.mat'};
                
                if ispc
                    ListofLoads=dir('Data\LoadData_*');
                else
                    ListofLoads=dir([h.FilesPath,'/Data/LoadData_*']);
                end
                
                for i=1:size(ListofLoads,1)
                    if numel(find(strcmp(OriginalList,ListofLoads(i).name)))
                    else
                        if ispc
                            delete(['Data\',ListofLoads(i).name])
                        else
                            delete([h.FilesPath,'/Data/',ListofLoads(i).name])
                        end
                    end
                end
                
                if ispc
                    ListofDelLoads=dir('Data\Del_LoadData_*');
                    for i=1:size(ListofDelLoads,1)
                        movefile(['Data\',ListofDelLoads(i).name],['Data\',ListofDelLoads(i).name(5:end)]);
                    end
                else
                    ListofDelLoads=dir([h.FilesPath,'/Data/Del_LoadData_*']);
                    for i=1:size(ListofDelLoads,1)
                        movefile([h.FilesPath,'/Data/',ListofDelLoads(i).name],[h.FilesPath,'/Data/',ListofDelLoads(i).name(5:end)]);
                    end
                end
                
                DelMsg;msgbox('The load data list has been restored to the original list.');
                if ispc
                    ListofLoads=dir('Data\LoadData_*');
                else
                    ListofLoads=dir([h.FilesPath,'/Data/LoadData_*']);
                    
                end
                temp2=struct2cell(ListofLoads);
                temp2=strrep(temp2(1,:),'.mat','');
                temp2=strrep(temp2(1,:),'LoadData_','');
                h.SelectLoad_Pup.String=temp2;
        end
        updateLoadList_del
        
    end




end

