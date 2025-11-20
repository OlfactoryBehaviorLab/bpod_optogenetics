classdef interface_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure                         matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        GridLayout2                    matlab.ui.container.GridLayout
        STOPButton                     matlab.ui.control.Button
        STARTButton                    matlab.ui.control.Button
        DutyCycleEditField             matlab.ui.control.NumericEditField
        DutyCycleEditFieldLabel        matlab.ui.control.Label
        InterPulseIntervalEditField    matlab.ui.control.NumericEditField
        InterPulseIntervalEditFieldLabel  matlab.ui.control.Label
        PulseDurationEditField         matlab.ui.control.NumericEditField
        PulseDurationEditFieldLabel    matlab.ui.control.Label
        StimulationModeButtonGroup     matlab.ui.container.ButtonGroup
        PulsedButton                   matlab.ui.control.ToggleButton
        ConstantButton                 matlab.ui.control.ToggleButton
        StimulationParametersLabel     matlab.ui.control.Label
        POSTSTIMsEditField             matlab.ui.control.NumericEditField
        POSTSTIMsEditFieldLabel        matlab.ui.control.Label
        STIMsEditField                 matlab.ui.control.NumericEditField
        STIMsEditFieldLabel            matlab.ui.control.Label
        PRESTIMsEditField              matlab.ui.control.NumericEditField
        PRESTIMsEditFieldLabel         matlab.ui.control.Label
        MAXsEditField                  matlab.ui.control.NumericEditField
        MAXsEditFieldLabel             matlab.ui.control.Label
        MINsEditField                  matlab.ui.control.NumericEditField
        MINsEditFieldLabel             matlab.ui.control.Label
        TrialTimesLabel                matlab.ui.control.Label
        ITITimesLabel                  matlab.ui.control.Label
        SelectPowersListBox            matlab.ui.control.ListBox
        SelectPowersListBoxLabel       matlab.ui.control.Label
        SelectPositionsListBox         matlab.ui.control.ListBox
        SelectPositionsListBoxLabel    matlab.ui.control.Label
        TrialsperStateEditField        matlab.ui.control.NumericEditField
        TrialsperStateEditFieldLabel   matlab.ui.control.Label
        RightPanel                     matlab.ui.container.Panel
        GridLayout3                    matlab.ui.container.GridLayout
        TrialNumberEditField           matlab.ui.control.NumericEditField
        TrialNumberEditFieldLabel      matlab.ui.control.Label
        Timer                          matlab.ui.control.Label
        RunningTimeLabel               matlab.ui.control.Label
        ExperimentEditField            matlab.ui.control.EditField
        ExperimentEditFieldLabel       matlab.ui.control.Label
        MouseIDEditField               matlab.ui.control.EditField
        MouseIDEditFieldLabel          matlab.ui.control.Label
        ExperimentInfoLabel            matlab.ui.control.Label
        EstimatedExperimentDurationEditField  matlab.ui.control.NumericEditField
        EstimatedExperimentDurationEditFieldLabel  matlab.ui.control.Label
        AverageTrialDurationEditField  matlab.ui.control.NumericEditField
        AverageTrialDurationEditFieldLabel  matlab.ui.control.Label
        TotalCombinationsEditField     matlab.ui.control.NumericEditField
        TotalCombinationsEditFieldLabel  matlab.ui.control.Label
        SummaryLabel                   matlab.ui.control.Label
        NextITIEditField               matlab.ui.control.NumericEditField
        ITIEditField_2Label            matlab.ui.control.Label
        NextPowerEditField             matlab.ui.control.NumericEditField
        PowerEditField_2Label          matlab.ui.control.Label
        NextStimulationPositionEditField  matlab.ui.control.NumericEditField
        StimulationPositionEditField_2Label  matlab.ui.control.Label
        NextTrialLabel                 matlab.ui.control.Label
        ITIEditField                   matlab.ui.control.NumericEditField
        ITIEditFieldLabel              matlab.ui.control.Label
        PowerEditField                 matlab.ui.control.NumericEditField
        PowerEditFieldLabel            matlab.ui.control.Label
        StimulationPositionEditField   matlab.ui.control.NumericEditField
        StimulationPositionEditFieldLabel  matlab.ui.control.Label
        CurrentTrialLabel              matlab.ui.control.Label
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = public)
        start_callback;
        stop_callback;
        pause_callback;
        close_callback;
        Bpod;
        start = false; % Description
        can_close = false; % Description
        early_close = false; % Description
        wait_dialog;
    end
    
    properties (Access = private)
        DEFAULTS; % Description
    end
   
    
    methods (Access = private)
        
        function trigger_update(app)
            app.update_total_combinations;
            app.update_average_trial_duration;
            app.update_estimated_duration;    
        end

        function update_total_combinations(app)
            selected_positions = app.SelectPositionsListBox.Value;
            selected_powers = app.SelectPowersListBox.Value;

            num_positions = length(selected_positions);
            num_powers = length(selected_powers); 
            total_combinations = num_positions * num_powers;

            app.TotalCombinationsEditField.Value = total_combinations + 1;
            % Add 1 for the no stim powers

        end

        function update_average_trial_duration(app)
            min_ITI = app.MINsEditField.Value;
            max_ITI = app.MAXsEditField.Value;
            avg_ITI = mean([min_ITI max_ITI]);

            stim_length = app.PRESTIMsEditField.Value + app.STIMsEditField.Value + app.POSTSTIMsEditField.Value;

            avg_length = round(avg_ITI + stim_length, 1);
            app.AverageTrialDurationEditField.Value = avg_length;
        end

        function update_estimated_duration(app)
            total_time_sec = ...
            app.TotalCombinationsEditField.Value * ...
            app.TrialsperStateEditField.Value * ...
            app.AverageTrialDurationEditField.Value;

            total_time_min = round(total_time_sec/60, 2);
            app.EstimatedExperimentDurationEditField.Value = total_time_min;
        end
        
        function enable_stim_params(app, state)
            app.PulseDurationEditField.Enable = state;
            app.InterPulseIntervalEditField.Enable = state;
            app.DutyCycleEditField.Enable = state;
        end
        
        function duty_cycle = calc_duty_cycle(~, pulse, ipi)
            duty_cycle = (pulse / (pulse + ipi)) * 100;
            duty_cycle = round(duty_cycle, 1);
        end
        
        function populate_defaults(app)
            app.SelectPowersListBox.Items = app.num2char_mat(app.DEFAULTS.DESIRED_POWERS_MW);
            app.SelectPositionsListBox.Items = app.num2char_mat(app.DEFAULTS.STIMULATION_POSITIONS);
            app.TrialsperStateEditField.Value = app.DEFAULTS.NUM_TRIALS_PER_POSITION;
            app.PRESTIMsEditField.Value = app.DEFAULTS.PRE_STIMULATION_TIME_S;
            app.STIMsEditField.Value = app.DEFAULTS.STIMULATION_TIME_S;
            app.POSTSTIMsEditField.Value = app.DEFAULTS.POST_STIMULATION_TIME_S;
            app.MINsEditField.Value = app.DEFAULTS.MIN_ITI_S;
            app.MAXsEditField.Value = app.DEFAULTS.MAX_ITI_S;
        end
        
        function results = num2char_mat(~, num_mat)
            results = arrayfun(@(val) num2str(val), num_mat, 'UniformOutput', false);
        end
    end
    
    methods (Access = public)

        function open_wait_dialog(app)
            ss = get(0, 'screensize');
            width = ss(3);
            height = ss(4);
            size_x = 200;
            size_y = 80;
            
            display_x = (width/2) - (size_x/2);
            display_y = (height/2) - (size_y/2);
            
            text_size_x = size_x - 20;
            text_size_y = size_y - 20;
            text_position_x = 10;
            text_position_y = -10;
            
            app.wait_dialog = dialog("Position", [display_x display_y size_x size_y], "Name", "Wait!", 'WindowStyle', 'modal');
            uicontrol('Parent', app.wait_dialog, ...
            'Style', 'text', ...
            'Position', [text_position_x text_position_y text_size_x text_size_y], ...
            'String', "Waiting for protocol to finish!");

        end

        function update_timer(app, num_seconds)
            time = seconds(num_seconds);
            time.Format = 'mm:ss';
            app.Timer.Text = string(time);
        end
        
        function update_trial_info(app, data)
            app.TrialNumberEditField.Value = data.trial_number;
            app.StimulationPositionEditField.Value = data.current_position;
            app.PowerEditField.Value = data.current_power;
            app.ITIEditField.Value = data.current_ITI;
            app.NextStimulationPositionEditField.Value = data.next_position;
            app.NextPowerEditField.Value = data.next_power;
            app.NextITIEditField.Value = data.next_ITI;
        end
        
        function lock_when_running(app)
            app.STARTButton.Enable = 'off';
            app.TrialsperStateEditField.Enable = 'off';
            app.DutyCycleEditField.Enable = 'off';
            app.InterPulseIntervalEditField.Enable = 'off';
            app.PulseDurationEditField.Enable = 'off';
            app.StimulationModeButtonGroup.Enable = 'off';
            app.POSTSTIMsEditField.Enable = 'off';
            app.STIMsEditField.Enable = 'off';
            app.PRESTIMsEditField.Enable = 'off';
            app.MAXsEditField.Enable = 'off';
            app.MINsEditField.Enable = 'off';
            app.SelectPositionsListBox.Enable = 'off';
            app.SelectPowersListBox.Enable = 'off';
        end
        
        function experiment_params = return_params(app)     
            experiment_params = {};
            experiment_params.trials_per_state = app.TrialsperStateEditField.Value;
            experiment_params.positions = app.SelectPositionsListBox.Value;
            experiment_params.power = app.SelectPowersListBox.Value;
            experiment_params.min_ITI = app.MINsEditField.Value;
            experiment_params.max_ITI = app.MAXsEditField.Value;
            experiment_params.pre_stim_s = app.PRESTIMsEditField.Value;
            experiment_params.stim_s = app.STIMsEditField.Value;
            experiment_params.post_stim_s = app.POSTSTIMsEditField.Value;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, setup_struct)
            app.start_callback = setup_struct.start_handle;
            app.stop_callback = setup_struct.stop_handle;
            app.pause_callback = setup_struct.pause_handle;
            app.close_callback = setup_struct.close_handle;
            app.Bpod = setup_struct.bpod;
            app.DEFAULTS = setup_struct.defaults;

            app.MouseIDEditField.Value = setup_struct.mouse;
            app.ExperimentEditField.Value = setup_struct.experiment;

            app.STARTButton.ButtonPushedFcn = @(fig, ~, ~)app.start_button_callback;
            app.STOPButton.ButtonPushedFcn = @(fig, ~, ~)app.stop_button_callback;
            app.figure.CloseRequestFcn = @(~,~)app.close_callback(app);
            app.populate_defaults;
        end

        % Callback function
        function TrialsperStateEditFieldValueChanged(app, event)
            app.trigger_update;
        end

        % Value changed function: MAXsEditField, MINsEditField, 
        % ...and 5 other components
        function update_callback(app, event)
            app.trigger_update;
        end

        % Selection changed function: StimulationModeButtonGroup
        function stim_mode_changed(app, event)
            stim_mode_button = app.StimulationModeButtonGroup.SelectedObject;
            if strcmp(stim_mode_button.Text, 'Pulsed')
                app.enable_stim_params(true);
            else
                app.enable_stim_params(false);
            end
        end

        % Value changed function: InterPulseIntervalEditField, 
        % ...and 1 other component
        function update_duty_cycle(app, event)
            pulse_dur = app.PulseDurationEditField.Value;
            inter_pulse_int = app.InterPulseIntervalEditField.Value;
            if inter_pulse_int > 0  
                app.DutyCycleEditField.Value = app.calc_duty_cycle(pulse_dur, inter_pulse_int);
            end
        end

        % Button pushed function: STARTButton
        function start_button_callback(app, event)
            app.start_callback(app);
            app.lock_when_running;
        end

        % Button pushed function: STOPButton
        function stop_button_callback(app, event)
            app.stop_callback(app);
        end

        % Value changed function: SelectPositionsListBox
        function SelectPositionsListBoxValueChanged(app, event)
            value = app.SelectPositionsListBox.Value;
            app.update_callback;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.figure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {687, 687};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {298, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create figure and hide until all components are created
            app.figure = uifigure('Visible', 'off');
            app.figure.AutoResizeChildren = 'off';
            app.figure.Position = [100 100 620 687];
            app.figure.Name = 'Freely Moving Optogenetics';
            app.figure.Icon = fullfile(pathToMLAPP, 'icon.png');
            app.figure.Resize = 'off';
            app.figure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.figure);
            app.GridLayout.ColumnWidth = {298, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.ForegroundColor = [1 1 1];
            app.LeftPanel.TitlePosition = 'centertop';
            app.LeftPanel.Title = 'Freely Moving Optogenetics';
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.FontName = 'Arial';
            app.LeftPanel.FontWeight = 'bold';
            app.LeftPanel.FontSize = 18;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.LeftPanel);
            app.GridLayout2.RowHeight = {'fit', 'fit', 'fit', 'fit', 50, 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '3x'};
            app.GridLayout2.RowSpacing = 8;

            % Create TrialsperStateEditFieldLabel
            app.TrialsperStateEditFieldLabel = uilabel(app.GridLayout2);
            app.TrialsperStateEditFieldLabel.FontName = 'Arial';
            app.TrialsperStateEditFieldLabel.FontColor = [1 1 1];
            app.TrialsperStateEditFieldLabel.Layout.Row = 1;
            app.TrialsperStateEditFieldLabel.Layout.Column = 1;
            app.TrialsperStateEditFieldLabel.Text = 'Trials per State';

            % Create TrialsperStateEditField
            app.TrialsperStateEditField = uieditfield(app.GridLayout2, 'numeric');
            app.TrialsperStateEditField.Limits = [0 Inf];
            app.TrialsperStateEditField.ValueDisplayFormat = '%.0f';
            app.TrialsperStateEditField.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.TrialsperStateEditField.FontName = 'Arial';
            app.TrialsperStateEditField.FontColor = [1 1 1];
            app.TrialsperStateEditField.Layout.Row = 1;
            app.TrialsperStateEditField.Layout.Column = 2;
            app.TrialsperStateEditField.Value = 20;

            % Create SelectPositionsListBoxLabel
            app.SelectPositionsListBoxLabel = uilabel(app.GridLayout2);
            app.SelectPositionsListBoxLabel.FontName = 'Arial';
            app.SelectPositionsListBoxLabel.FontColor = [1 1 1];
            app.SelectPositionsListBoxLabel.Layout.Row = 2;
            app.SelectPositionsListBoxLabel.Layout.Column = 1;
            app.SelectPositionsListBoxLabel.Text = 'Select Positions';

            % Create SelectPositionsListBox
            app.SelectPositionsListBox = uilistbox(app.GridLayout2);
            app.SelectPositionsListBox.Items = {'250', '750', '1250'};
            app.SelectPositionsListBox.Multiselect = 'on';
            app.SelectPositionsListBox.ValueChangedFcn = createCallbackFcn(app, @SelectPositionsListBoxValueChanged, true);
            app.SelectPositionsListBox.FontName = 'Arial';
            app.SelectPositionsListBox.FontColor = [1 1 1];
            app.SelectPositionsListBox.Layout.Row = 2;
            app.SelectPositionsListBox.Layout.Column = 2;
            app.SelectPositionsListBox.Value = {'250'};

            % Create SelectPowersListBoxLabel
            app.SelectPowersListBoxLabel = uilabel(app.GridLayout2);
            app.SelectPowersListBoxLabel.FontName = 'Arial';
            app.SelectPowersListBoxLabel.FontColor = [1 1 1];
            app.SelectPowersListBoxLabel.Layout.Row = 3;
            app.SelectPowersListBoxLabel.Layout.Column = 1;
            app.SelectPowersListBoxLabel.Text = 'Select Powers';

            % Create SelectPowersListBox
            app.SelectPowersListBox = uilistbox(app.GridLayout2);
            app.SelectPowersListBox.Items = {'0.5', '1.0', '2.0'};
            app.SelectPowersListBox.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.SelectPowersListBox.FontName = 'Arial';
            app.SelectPowersListBox.FontColor = [1 1 1];
            app.SelectPowersListBox.Layout.Row = 3;
            app.SelectPowersListBox.Layout.Column = 2;
            app.SelectPowersListBox.Value = '0.5';

            % Create ITITimesLabel
            app.ITITimesLabel = uilabel(app.GridLayout2);
            app.ITITimesLabel.BackgroundColor = [0.502 0.502 0.502];
            app.ITITimesLabel.HorizontalAlignment = 'center';
            app.ITITimesLabel.FontName = 'Arial';
            app.ITITimesLabel.FontWeight = 'bold';
            app.ITITimesLabel.Layout.Row = 9;
            app.ITITimesLabel.Layout.Column = [1 2];
            app.ITITimesLabel.Text = 'ITI Times';

            % Create TrialTimesLabel
            app.TrialTimesLabel = uilabel(app.GridLayout2);
            app.TrialTimesLabel.BackgroundColor = [0.502 0.502 0.502];
            app.TrialTimesLabel.HorizontalAlignment = 'center';
            app.TrialTimesLabel.FontName = 'Arial';
            app.TrialTimesLabel.FontWeight = 'bold';
            app.TrialTimesLabel.Layout.Row = 12;
            app.TrialTimesLabel.Layout.Column = [1 2];
            app.TrialTimesLabel.Text = 'Trial Times';

            % Create MINsEditFieldLabel
            app.MINsEditFieldLabel = uilabel(app.GridLayout2);
            app.MINsEditFieldLabel.FontName = 'Arial';
            app.MINsEditFieldLabel.FontColor = [1 1 1];
            app.MINsEditFieldLabel.Layout.Row = 10;
            app.MINsEditFieldLabel.Layout.Column = 1;
            app.MINsEditFieldLabel.Text = 'MIN (s)';

            % Create MINsEditField
            app.MINsEditField = uieditfield(app.GridLayout2, 'numeric');
            app.MINsEditField.ValueDisplayFormat = '%.1f s';
            app.MINsEditField.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.MINsEditField.FontName = 'Arial';
            app.MINsEditField.FontColor = [1 1 1];
            app.MINsEditField.Layout.Row = 10;
            app.MINsEditField.Layout.Column = 2;
            app.MINsEditField.Value = 15;

            % Create MAXsEditFieldLabel
            app.MAXsEditFieldLabel = uilabel(app.GridLayout2);
            app.MAXsEditFieldLabel.FontName = 'Arial';
            app.MAXsEditFieldLabel.FontColor = [1 1 1];
            app.MAXsEditFieldLabel.Layout.Row = 11;
            app.MAXsEditFieldLabel.Layout.Column = 1;
            app.MAXsEditFieldLabel.Text = 'MAX (s)';

            % Create MAXsEditField
            app.MAXsEditField = uieditfield(app.GridLayout2, 'numeric');
            app.MAXsEditField.ValueDisplayFormat = '%.1f s';
            app.MAXsEditField.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.MAXsEditField.FontName = 'Arial';
            app.MAXsEditField.Layout.Row = 11;
            app.MAXsEditField.Layout.Column = 2;
            app.MAXsEditField.Value = 25;

            % Create PRESTIMsEditFieldLabel
            app.PRESTIMsEditFieldLabel = uilabel(app.GridLayout2);
            app.PRESTIMsEditFieldLabel.FontName = 'Arial';
            app.PRESTIMsEditFieldLabel.FontColor = [1 1 1];
            app.PRESTIMsEditFieldLabel.Layout.Row = 13;
            app.PRESTIMsEditFieldLabel.Layout.Column = 1;
            app.PRESTIMsEditFieldLabel.Text = 'PRE STIM (s)';

            % Create PRESTIMsEditField
            app.PRESTIMsEditField = uieditfield(app.GridLayout2, 'numeric');
            app.PRESTIMsEditField.Limits = [0 Inf];
            app.PRESTIMsEditField.ValueDisplayFormat = '%.1f s';
            app.PRESTIMsEditField.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.PRESTIMsEditField.FontName = 'Arial';
            app.PRESTIMsEditField.FontColor = [1 1 1];
            app.PRESTIMsEditField.Layout.Row = 13;
            app.PRESTIMsEditField.Layout.Column = 2;
            app.PRESTIMsEditField.Value = 4;

            % Create STIMsEditFieldLabel
            app.STIMsEditFieldLabel = uilabel(app.GridLayout2);
            app.STIMsEditFieldLabel.FontName = 'Arial';
            app.STIMsEditFieldLabel.FontColor = [1 1 1];
            app.STIMsEditFieldLabel.Layout.Row = 14;
            app.STIMsEditFieldLabel.Layout.Column = 1;
            app.STIMsEditFieldLabel.Text = 'STIM (s)';

            % Create STIMsEditField
            app.STIMsEditField = uieditfield(app.GridLayout2, 'numeric');
            app.STIMsEditField.Limits = [0 Inf];
            app.STIMsEditField.ValueDisplayFormat = '%.1f s';
            app.STIMsEditField.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.STIMsEditField.FontName = 'Arial';
            app.STIMsEditField.FontColor = [1 1 1];
            app.STIMsEditField.Layout.Row = 14;
            app.STIMsEditField.Layout.Column = 2;
            app.STIMsEditField.Value = 2;

            % Create POSTSTIMsEditFieldLabel
            app.POSTSTIMsEditFieldLabel = uilabel(app.GridLayout2);
            app.POSTSTIMsEditFieldLabel.FontName = 'Arial';
            app.POSTSTIMsEditFieldLabel.FontColor = [1 1 1];
            app.POSTSTIMsEditFieldLabel.Layout.Row = 15;
            app.POSTSTIMsEditFieldLabel.Layout.Column = 1;
            app.POSTSTIMsEditFieldLabel.Text = 'POST STIM (s)';

            % Create POSTSTIMsEditField
            app.POSTSTIMsEditField = uieditfield(app.GridLayout2, 'numeric');
            app.POSTSTIMsEditField.Limits = [0 Inf];
            app.POSTSTIMsEditField.ValueDisplayFormat = '%.1f s';
            app.POSTSTIMsEditField.ValueChangedFcn = createCallbackFcn(app, @update_callback, true);
            app.POSTSTIMsEditField.FontName = 'Arial';
            app.POSTSTIMsEditField.FontColor = [1 1 1];
            app.POSTSTIMsEditField.Layout.Row = 15;
            app.POSTSTIMsEditField.Layout.Column = 2;
            app.POSTSTIMsEditField.Value = 4;

            % Create StimulationParametersLabel
            app.StimulationParametersLabel = uilabel(app.GridLayout2);
            app.StimulationParametersLabel.BackgroundColor = [0.502 0.502 0.502];
            app.StimulationParametersLabel.HorizontalAlignment = 'center';
            app.StimulationParametersLabel.FontName = 'Arial';
            app.StimulationParametersLabel.FontWeight = 'bold';
            app.StimulationParametersLabel.Layout.Row = 4;
            app.StimulationParametersLabel.Layout.Column = [1 2];
            app.StimulationParametersLabel.Text = 'Stimulation Parameters';

            % Create StimulationModeButtonGroup
            app.StimulationModeButtonGroup = uibuttongroup(app.GridLayout2);
            app.StimulationModeButtonGroup.AutoResizeChildren = 'off';
            app.StimulationModeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @stim_mode_changed, true);
            app.StimulationModeButtonGroup.Enable = 'off';
            app.StimulationModeButtonGroup.TitlePosition = 'centertop';
            app.StimulationModeButtonGroup.Title = 'Stimulation Mode';
            app.StimulationModeButtonGroup.Layout.Row = 5;
            app.StimulationModeButtonGroup.Layout.Column = [1 2];
            app.StimulationModeButtonGroup.FontName = 'Arial';

            % Create ConstantButton
            app.ConstantButton = uitogglebutton(app.StimulationModeButtonGroup);
            app.ConstantButton.Text = 'Constant';
            app.ConstantButton.Position = [16 3 100 23];
            app.ConstantButton.Value = true;

            % Create PulsedButton
            app.PulsedButton = uitogglebutton(app.StimulationModeButtonGroup);
            app.PulsedButton.Text = 'Pulsed';
            app.PulsedButton.Position = [151 3 100 23];

            % Create PulseDurationEditFieldLabel
            app.PulseDurationEditFieldLabel = uilabel(app.GridLayout2);
            app.PulseDurationEditFieldLabel.FontName = 'Arial';
            app.PulseDurationEditFieldLabel.FontColor = [1 1 1];
            app.PulseDurationEditFieldLabel.Layout.Row = 6;
            app.PulseDurationEditFieldLabel.Layout.Column = 1;
            app.PulseDurationEditFieldLabel.Text = 'Pulse Duration';

            % Create PulseDurationEditField
            app.PulseDurationEditField = uieditfield(app.GridLayout2, 'numeric');
            app.PulseDurationEditField.Limits = [0 Inf];
            app.PulseDurationEditField.ValueDisplayFormat = '%.3f ms';
            app.PulseDurationEditField.AllowEmpty = 'on';
            app.PulseDurationEditField.ValueChangedFcn = createCallbackFcn(app, @update_duty_cycle, true);
            app.PulseDurationEditField.FontName = 'Arial';
            app.PulseDurationEditField.FontColor = [1 1 1];
            app.PulseDurationEditField.Enable = 'off';
            app.PulseDurationEditField.Layout.Row = 6;
            app.PulseDurationEditField.Layout.Column = 2;
            app.PulseDurationEditField.Value = 1;

            % Create InterPulseIntervalEditFieldLabel
            app.InterPulseIntervalEditFieldLabel = uilabel(app.GridLayout2);
            app.InterPulseIntervalEditFieldLabel.FontName = 'Arial';
            app.InterPulseIntervalEditFieldLabel.FontColor = [1 1 1];
            app.InterPulseIntervalEditFieldLabel.Layout.Row = 7;
            app.InterPulseIntervalEditFieldLabel.Layout.Column = 1;
            app.InterPulseIntervalEditFieldLabel.Text = 'Inter Pulse Interval';

            % Create InterPulseIntervalEditField
            app.InterPulseIntervalEditField = uieditfield(app.GridLayout2, 'numeric');
            app.InterPulseIntervalEditField.Limits = [0 Inf];
            app.InterPulseIntervalEditField.ValueDisplayFormat = '%.3f ms';
            app.InterPulseIntervalEditField.ValueChangedFcn = createCallbackFcn(app, @update_duty_cycle, true);
            app.InterPulseIntervalEditField.FontName = 'Arial';
            app.InterPulseIntervalEditField.FontColor = [1 1 1];
            app.InterPulseIntervalEditField.Enable = 'off';
            app.InterPulseIntervalEditField.Layout.Row = 7;
            app.InterPulseIntervalEditField.Layout.Column = 2;
            app.InterPulseIntervalEditField.Value = 1;

            % Create DutyCycleEditFieldLabel
            app.DutyCycleEditFieldLabel = uilabel(app.GridLayout2);
            app.DutyCycleEditFieldLabel.FontName = 'Arial';
            app.DutyCycleEditFieldLabel.FontColor = [1 1 1];
            app.DutyCycleEditFieldLabel.Layout.Row = 8;
            app.DutyCycleEditFieldLabel.Layout.Column = 1;
            app.DutyCycleEditFieldLabel.Text = 'Duty Cycle';

            % Create DutyCycleEditField
            app.DutyCycleEditField = uieditfield(app.GridLayout2, 'numeric');
            app.DutyCycleEditField.Limits = [0 Inf];
            app.DutyCycleEditField.ValueDisplayFormat = '%.1f  %%';
            app.DutyCycleEditField.Editable = 'off';
            app.DutyCycleEditField.FontName = 'Arial';
            app.DutyCycleEditField.FontColor = [1 1 1];
            app.DutyCycleEditField.Enable = 'off';
            app.DutyCycleEditField.Layout.Row = 8;
            app.DutyCycleEditField.Layout.Column = 2;
            app.DutyCycleEditField.Value = 50;

            % Create STARTButton
            app.STARTButton = uibutton(app.GridLayout2, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @start_button_callback, true);
            app.STARTButton.BackgroundColor = [0.2314 0.6667 0.1961];
            app.STARTButton.FontName = 'Arial';
            app.STARTButton.FontSize = 24;
            app.STARTButton.FontColor = [1 1 1];
            app.STARTButton.Layout.Row = 16;
            app.STARTButton.Layout.Column = 1;
            app.STARTButton.Text = 'START';

            % Create STOPButton
            app.STOPButton = uibutton(app.GridLayout2, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @stop_button_callback, true);
            app.STOPButton.BackgroundColor = [0.6902 0.0078 0.0078];
            app.STOPButton.FontName = 'Arial';
            app.STOPButton.FontSize = 24;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [1 1 1];
            app.STOPButton.Layout.Row = 16;
            app.STOPButton.Layout.Column = 2;
            app.STOPButton.Text = 'STOP';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.ForegroundColor = [1 1 1];
            app.RightPanel.TitlePosition = 'centertop';
            app.RightPanel.Title = 'Current Parameters';
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.FontName = 'Arial';
            app.RightPanel.FontWeight = 'bold';
            app.RightPanel.FontSize = 18;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.RightPanel);
            app.GridLayout3.ColumnWidth = {'fit', 'fit'};
            app.GridLayout3.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '0.25x', '1x'};

            % Create CurrentTrialLabel
            app.CurrentTrialLabel = uilabel(app.GridLayout3);
            app.CurrentTrialLabel.BackgroundColor = [0.502 0.502 0.502];
            app.CurrentTrialLabel.HorizontalAlignment = 'center';
            app.CurrentTrialLabel.FontName = 'Arial';
            app.CurrentTrialLabel.FontWeight = 'bold';
            app.CurrentTrialLabel.FontColor = [1 1 1];
            app.CurrentTrialLabel.Layout.Row = 4;
            app.CurrentTrialLabel.Layout.Column = [1 2];
            app.CurrentTrialLabel.Text = 'Current Trial';

            % Create StimulationPositionEditFieldLabel
            app.StimulationPositionEditFieldLabel = uilabel(app.GridLayout3);
            app.StimulationPositionEditFieldLabel.FontColor = [1 1 1];
            app.StimulationPositionEditFieldLabel.Layout.Row = 6;
            app.StimulationPositionEditFieldLabel.Layout.Column = 1;
            app.StimulationPositionEditFieldLabel.Text = 'Stimulation Position';

            % Create StimulationPositionEditField
            app.StimulationPositionEditField = uieditfield(app.GridLayout3, 'numeric');
            app.StimulationPositionEditField.Editable = 'off';
            app.StimulationPositionEditField.FontColor = [1 1 1];
            app.StimulationPositionEditField.Layout.Row = 6;
            app.StimulationPositionEditField.Layout.Column = 2;

            % Create PowerEditFieldLabel
            app.PowerEditFieldLabel = uilabel(app.GridLayout3);
            app.PowerEditFieldLabel.FontColor = [1 1 1];
            app.PowerEditFieldLabel.Layout.Row = 7;
            app.PowerEditFieldLabel.Layout.Column = 1;
            app.PowerEditFieldLabel.Text = 'Power';

            % Create PowerEditField
            app.PowerEditField = uieditfield(app.GridLayout3, 'numeric');
            app.PowerEditField.Editable = 'off';
            app.PowerEditField.FontColor = [1 1 1];
            app.PowerEditField.Layout.Row = 7;
            app.PowerEditField.Layout.Column = 2;

            % Create ITIEditFieldLabel
            app.ITIEditFieldLabel = uilabel(app.GridLayout3);
            app.ITIEditFieldLabel.FontColor = [1 1 1];
            app.ITIEditFieldLabel.Layout.Row = 8;
            app.ITIEditFieldLabel.Layout.Column = 1;
            app.ITIEditFieldLabel.Text = 'ITI';

            % Create ITIEditField
            app.ITIEditField = uieditfield(app.GridLayout3, 'numeric');
            app.ITIEditField.Editable = 'off';
            app.ITIEditField.FontColor = [1 1 1];
            app.ITIEditField.Layout.Row = 8;
            app.ITIEditField.Layout.Column = 2;

            % Create NextTrialLabel
            app.NextTrialLabel = uilabel(app.GridLayout3);
            app.NextTrialLabel.BackgroundColor = [0.502 0.502 0.502];
            app.NextTrialLabel.HorizontalAlignment = 'center';
            app.NextTrialLabel.FontName = 'Arial';
            app.NextTrialLabel.FontWeight = 'bold';
            app.NextTrialLabel.FontColor = [1 1 1];
            app.NextTrialLabel.Layout.Row = 9;
            app.NextTrialLabel.Layout.Column = [1 2];
            app.NextTrialLabel.Text = 'Next Trial';

            % Create StimulationPositionEditField_2Label
            app.StimulationPositionEditField_2Label = uilabel(app.GridLayout3);
            app.StimulationPositionEditField_2Label.FontColor = [1 1 1];
            app.StimulationPositionEditField_2Label.Layout.Row = 10;
            app.StimulationPositionEditField_2Label.Layout.Column = 1;
            app.StimulationPositionEditField_2Label.Text = 'Stimulation Position';

            % Create NextStimulationPositionEditField
            app.NextStimulationPositionEditField = uieditfield(app.GridLayout3, 'numeric');
            app.NextStimulationPositionEditField.Editable = 'off';
            app.NextStimulationPositionEditField.FontColor = [1 1 1];
            app.NextStimulationPositionEditField.Layout.Row = 10;
            app.NextStimulationPositionEditField.Layout.Column = 2;

            % Create PowerEditField_2Label
            app.PowerEditField_2Label = uilabel(app.GridLayout3);
            app.PowerEditField_2Label.FontColor = [1 1 1];
            app.PowerEditField_2Label.Layout.Row = 11;
            app.PowerEditField_2Label.Layout.Column = 1;
            app.PowerEditField_2Label.Text = 'Power';

            % Create NextPowerEditField
            app.NextPowerEditField = uieditfield(app.GridLayout3, 'numeric');
            app.NextPowerEditField.Editable = 'off';
            app.NextPowerEditField.FontColor = [1 1 1];
            app.NextPowerEditField.Layout.Row = 11;
            app.NextPowerEditField.Layout.Column = 2;

            % Create ITIEditField_2Label
            app.ITIEditField_2Label = uilabel(app.GridLayout3);
            app.ITIEditField_2Label.FontColor = [1 1 1];
            app.ITIEditField_2Label.Layout.Row = 12;
            app.ITIEditField_2Label.Layout.Column = 1;
            app.ITIEditField_2Label.Text = 'ITI';

            % Create NextITIEditField
            app.NextITIEditField = uieditfield(app.GridLayout3, 'numeric');
            app.NextITIEditField.Editable = 'off';
            app.NextITIEditField.FontColor = [1 1 1];
            app.NextITIEditField.Layout.Row = 12;
            app.NextITIEditField.Layout.Column = 2;

            % Create SummaryLabel
            app.SummaryLabel = uilabel(app.GridLayout3);
            app.SummaryLabel.BackgroundColor = [0.502 0.502 0.502];
            app.SummaryLabel.HorizontalAlignment = 'center';
            app.SummaryLabel.FontName = 'Arial';
            app.SummaryLabel.FontWeight = 'bold';
            app.SummaryLabel.FontColor = [1 1 1];
            app.SummaryLabel.Layout.Row = 13;
            app.SummaryLabel.Layout.Column = [1 2];
            app.SummaryLabel.Text = 'Summary';

            % Create TotalCombinationsEditFieldLabel
            app.TotalCombinationsEditFieldLabel = uilabel(app.GridLayout3);
            app.TotalCombinationsEditFieldLabel.FontName = 'Arial';
            app.TotalCombinationsEditFieldLabel.FontColor = [1 1 1];
            app.TotalCombinationsEditFieldLabel.Layout.Row = 14;
            app.TotalCombinationsEditFieldLabel.Layout.Column = 1;
            app.TotalCombinationsEditFieldLabel.Text = 'Total Combinations';

            % Create TotalCombinationsEditField
            app.TotalCombinationsEditField = uieditfield(app.GridLayout3, 'numeric');
            app.TotalCombinationsEditField.ValueDisplayFormat = '%.0f';
            app.TotalCombinationsEditField.Editable = 'off';
            app.TotalCombinationsEditField.FontName = 'Arial';
            app.TotalCombinationsEditField.FontColor = [1 1 1];
            app.TotalCombinationsEditField.Layout.Row = 14;
            app.TotalCombinationsEditField.Layout.Column = 2;
            app.TotalCombinationsEditField.Value = 3;

            % Create AverageTrialDurationEditFieldLabel
            app.AverageTrialDurationEditFieldLabel = uilabel(app.GridLayout3);
            app.AverageTrialDurationEditFieldLabel.FontName = 'Arial';
            app.AverageTrialDurationEditFieldLabel.FontColor = [1 1 1];
            app.AverageTrialDurationEditFieldLabel.Layout.Row = 15;
            app.AverageTrialDurationEditFieldLabel.Layout.Column = 1;
            app.AverageTrialDurationEditFieldLabel.Text = 'Average Trial Duration';

            % Create AverageTrialDurationEditField
            app.AverageTrialDurationEditField = uieditfield(app.GridLayout3, 'numeric');
            app.AverageTrialDurationEditField.ValueDisplayFormat = '%.1f s';
            app.AverageTrialDurationEditField.Editable = 'off';
            app.AverageTrialDurationEditField.FontName = 'Arial';
            app.AverageTrialDurationEditField.FontColor = [1 1 1];
            app.AverageTrialDurationEditField.Layout.Row = 15;
            app.AverageTrialDurationEditField.Layout.Column = 2;
            app.AverageTrialDurationEditField.Value = 30;

            % Create EstimatedExperimentDurationEditFieldLabel
            app.EstimatedExperimentDurationEditFieldLabel = uilabel(app.GridLayout3);
            app.EstimatedExperimentDurationEditFieldLabel.HorizontalAlignment = 'right';
            app.EstimatedExperimentDurationEditFieldLabel.FontName = 'Arial';
            app.EstimatedExperimentDurationEditFieldLabel.FontColor = [1 1 1];
            app.EstimatedExperimentDurationEditFieldLabel.Layout.Row = 16;
            app.EstimatedExperimentDurationEditFieldLabel.Layout.Column = 1;
            app.EstimatedExperimentDurationEditFieldLabel.Text = 'Estimated Experiment Duration';

            % Create EstimatedExperimentDurationEditField
            app.EstimatedExperimentDurationEditField = uieditfield(app.GridLayout3, 'numeric');
            app.EstimatedExperimentDurationEditField.ValueDisplayFormat = '%.1f min';
            app.EstimatedExperimentDurationEditField.Editable = 'off';
            app.EstimatedExperimentDurationEditField.FontName = 'Arial';
            app.EstimatedExperimentDurationEditField.FontColor = [1 1 1];
            app.EstimatedExperimentDurationEditField.Layout.Row = 16;
            app.EstimatedExperimentDurationEditField.Layout.Column = 2;
            app.EstimatedExperimentDurationEditField.Value = 30;

            % Create ExperimentInfoLabel
            app.ExperimentInfoLabel = uilabel(app.GridLayout3);
            app.ExperimentInfoLabel.BackgroundColor = [0.502 0.502 0.502];
            app.ExperimentInfoLabel.HorizontalAlignment = 'center';
            app.ExperimentInfoLabel.FontName = 'Arial';
            app.ExperimentInfoLabel.FontWeight = 'bold';
            app.ExperimentInfoLabel.FontColor = [1 1 1];
            app.ExperimentInfoLabel.Layout.Row = 1;
            app.ExperimentInfoLabel.Layout.Column = [1 2];
            app.ExperimentInfoLabel.Text = 'Experiment Info';

            % Create MouseIDEditFieldLabel
            app.MouseIDEditFieldLabel = uilabel(app.GridLayout3);
            app.MouseIDEditFieldLabel.FontName = 'Arial';
            app.MouseIDEditFieldLabel.FontColor = [1 1 1];
            app.MouseIDEditFieldLabel.Layout.Row = 2;
            app.MouseIDEditFieldLabel.Layout.Column = 1;
            app.MouseIDEditFieldLabel.Text = 'Mouse ID';

            % Create MouseIDEditField
            app.MouseIDEditField = uieditfield(app.GridLayout3, 'text');
            app.MouseIDEditField.Editable = 'off';
            app.MouseIDEditField.FontName = 'Arial';
            app.MouseIDEditField.FontColor = [1 1 1];
            app.MouseIDEditField.Placeholder = 'Mouse-ID';
            app.MouseIDEditField.Layout.Row = 2;
            app.MouseIDEditField.Layout.Column = 2;

            % Create ExperimentEditFieldLabel
            app.ExperimentEditFieldLabel = uilabel(app.GridLayout3);
            app.ExperimentEditFieldLabel.FontName = 'Arial';
            app.ExperimentEditFieldLabel.FontColor = [1 1 1];
            app.ExperimentEditFieldLabel.Layout.Row = 3;
            app.ExperimentEditFieldLabel.Layout.Column = 1;
            app.ExperimentEditFieldLabel.Text = 'Experiment';

            % Create ExperimentEditField
            app.ExperimentEditField = uieditfield(app.GridLayout3, 'text');
            app.ExperimentEditField.Editable = 'off';
            app.ExperimentEditField.FontName = 'Arial';
            app.ExperimentEditField.FontColor = [1 1 1];
            app.ExperimentEditField.Placeholder = 'Experiment';
            app.ExperimentEditField.Layout.Row = 3;
            app.ExperimentEditField.Layout.Column = 2;

            % Create RunningTimeLabel
            app.RunningTimeLabel = uilabel(app.GridLayout3);
            app.RunningTimeLabel.BackgroundColor = [0.502 0.502 0.502];
            app.RunningTimeLabel.HorizontalAlignment = 'center';
            app.RunningTimeLabel.FontName = 'Arial';
            app.RunningTimeLabel.FontSize = 18;
            app.RunningTimeLabel.FontWeight = 'bold';
            app.RunningTimeLabel.FontColor = [1 1 1];
            app.RunningTimeLabel.Layout.Row = 17;
            app.RunningTimeLabel.Layout.Column = [1 2];
            app.RunningTimeLabel.Text = 'Running Time';

            % Create Timer
            app.Timer = uilabel(app.GridLayout3);
            app.Timer.HorizontalAlignment = 'center';
            app.Timer.FontName = 'Arial';
            app.Timer.FontSize = 48;
            app.Timer.FontColor = [1 1 1];
            app.Timer.Layout.Row = 18;
            app.Timer.Layout.Column = [1 2];
            app.Timer.Text = '00:00';

            % Create TrialNumberEditFieldLabel
            app.TrialNumberEditFieldLabel = uilabel(app.GridLayout3);
            app.TrialNumberEditFieldLabel.FontName = 'Arial';
            app.TrialNumberEditFieldLabel.FontColor = [1 1 1];
            app.TrialNumberEditFieldLabel.Layout.Row = 5;
            app.TrialNumberEditFieldLabel.Layout.Column = 1;
            app.TrialNumberEditFieldLabel.Text = 'Trial Number';

            % Create TrialNumberEditField
            app.TrialNumberEditField = uieditfield(app.GridLayout3, 'numeric');
            app.TrialNumberEditField.Editable = 'off';
            app.TrialNumberEditField.FontName = 'Arial';
            app.TrialNumberEditField.FontColor = [1 1 1];
            app.TrialNumberEditField.Layout.Row = 5;
            app.TrialNumberEditField.Layout.Column = 2;

            % Show the figure after all components are created
            app.figure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = interface_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.figure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.figure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.figure)
        end
    end
end