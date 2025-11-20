%% MUST LAUNCH THROUGH PROTOCOL LAUNCHER
function freely_moving
%% CALIBRATION VALUES
GALVOSTATION_CAL_COEFFICIENT = 2.703;
GALVOSTATION_CAL_CONSTANT = 0.217;
GALVOSTATION_OFFSET_V = 0.075;

LASER_CALIBRATIONS = []; % Each galvostation position attenuates the laser slightly differently; so each position will need a slightly
LASER_CALIBRATIONS(1, :) = [2.0966, -1.9703]; % different set of calibration values to ensure the power is delivered consistently
LASER_CALIBRATIONS(2, :) = [1.9434, -1.8747]; % Each calibration should be two values in the form [coefficient, constant] based on a linear fit
LASER_CALIBRATIONS(3, :) = [1.7618, -1.7209];


%% DEFAULT VALUES
DEFAULTS = {};
DEFAULTS.STIMULATION_POSITIONS = [250, 750, 1250]; % Center(s) in um of stimulation positions; stimulation is +/- 250um of center

DEFAULTS.NUM_TRIALS_PER_POSITION = 20;

DEFAULTS.DESIRED_POWERS_MW = [0.5, 1, 2, 3, 4]; % Stimulation power(s) in mW
DEFAULTS.PULSE_DURATIONS_S = [-1]; % Pulse durations for duty-cycle; -1 indicates constant power
DEFAULTS.INTER_PULSE_INTERVALS_S = [0]; % Inter-pulse-intervals for duty-cycle in seconds; 0 indicates constant power

DEFAULTS.PRE_STIMULATION_TIME_S = 4; % Pre stimulation time in seconds
DEFAULTS.STIMULATION_TIME_S = 2; % Stimulation time in seconds
DEFAULTS.POST_STIMULATION_TIME_S = 4; % Post stimulation time in seconds

DEFAULTS.MIN_ITI_S = 15; % Minimum ITI time in seconds
DEFAULTS.MAX_ITI_S = 25; % Maximum ITI time in seconds

%% ============NO TOUCH BELOW================== %%

%% Objects
% Start BPOD if it isn't started
try 
    bpod = evalin('base', 'BpodSystem');
catch
    if ~exist('BpodSystem', 'var')
        Bpod();
    end
end
global BpodSystem;

% Start PulsePal if it isn't started
try
    pulsepal = evalin('base', 'PulsePalSystem');
    if isempty(pulsepal)
        PulsePal;
    end
catch
    if ~exist('PulsePalSystem', 'var') || isempty('PulsePalSystem', 'var')
        PulsePal();
    end
end
global PulsePalSystem;

BpodSystem.PluginObjects.PulsePal = PulsePalSystem;  % Bpod is gonna hold onto the PulsePal
PulsePalSystem.Params.LinkTriggerChannel1(:) = 0; % Uncouple all channels from triggers
PulsePalSystem.Params.LinkTriggerChannel2(:) = 0; 

% Create galvostation object
galvostation = bpod_galvostation.galvostation(BpodSystem, 'offset_voltage', GALVOSTATION_OFFSET_V, 'calibration', [GALVOSTATION_CAL_COEFFICIENT, GALVOSTATION_CAL_CONSTANT]);
galvo_gui = bpod_galvostation.gui.main_gui(galvostation);
galvostation.laser_1.calibration_values = LASER_CALIBRATIONS;

%% CHECK INPUTS
% if (length(DEFAULTS.DESIRED_POWERS_MW) ~= length(DEFAULTS.PULSE_DURATIONS_S)) && (length(DEFAULTS.PULSE_DUREATIONS_S) ~= length(DEFAULTS.INTER_PULSE_INTERVALS_S))
%     error("The length of DESIRED_POWERS_MW, PULSE_DURATIONS_S, and INTER_PULSE_INTERVALS_S must be the same! There must be one duty cycle per power level!");
% end
% Pulsed stimulation not implemented yet! -ACP 11-20-25

if GALVOSTATION_CAL_CONSTANT == 0 | GALVOSTATION_CAL_CONSTANT == 0
    error("Please provide calibration values for the Galvostation!");
end

if size(LASER_CALIBRATIONS, 1) ~= length(DEFAULTS.STIMULATION_POSITIONS)
    error("Please provide a laser calibration for each stimulation position!");
end

% Experiment GUI
if isempty(BpodSystem.Path.CurrentDataFile)
    error("Please launch freely_moving from the Bpod Protocol Manager!");
else
    path_components = parse_path(BpodSystem.Path.CurrentDataFile);
end
% Pull mouse and experiment from path
% Path must be in form C:\[BPOD_DATA_DIR]\[ANIMAL]\[EXPERIMENT]
% Extra subdirectory will throw it off for now

gui_setup_struct = {};
gui_setup_struct.defaults = DEFAULTS;
gui_setup_struct.bpod = BpodSystem; % Not used currently
gui_setup_struct.mouse = path_components.mouse;
gui_setup_struct.experiment = path_components.experiment;
gui_setup_struct.start_handle = @start_button_callback;
gui_setup_struct.stop_handle = @stop_button_callback;
gui_setup_struct.pause_handle = @pause_button_callback;
gui_setup_struct.close_handle = @close_gui_callback;

gui = interface(gui_setup_struct);

experiment_timer = timer;
experiment_timer.Name = "experiment_timer";
experiment_timer.ExecutionMode = "fixedRate";
experiment_timer.UserData.experiment_time_elapsed_seconds = 0;
experiment_timer.TimerFcn = @(timer, ~)timer_callback(timer, gui);
BpodSystem.Timers.experiment_timer = experiment_timer;

%% Implement Experiment
while true
    % If we close the GUI early break this; otherwise, wait for start
    if gui.early_close
        disp("GUI Closed Early, aborting!");
        break;
    elseif gui.start
        break;
    end

    pause(0.1);
end

if gui.start
% If the GUI was closed early don't actually run the experiment

%% Get Parameters from GUI
user_supplied_params = gui.return_params();
NUM_TRIALS_PER_POSITION = user_supplied_params.trials_per_state;
STIMULATION_POSITIONS = sort(str2double(user_supplied_params.positions)); % Make sure they are in order from smallest -> largest for the calibration selection
DESIRED_POWERS_MW = str2double(user_supplied_params.power);
MIN_ITI_S = user_supplied_params.min_ITI;
MAX_ITI_S = user_supplied_params.max_ITI;
PRE_STIM_TIME_S = user_supplied_params.pre_stim_s;
STIMULATION_TIME_S = user_supplied_params.stim_s;
POST_STIMULATION_TIME_S = user_supplied_params.post_stim_s;

TOTAL_NUM_TRIALS = NUM_TRIALS_PER_POSITION * length(STIMULATION_POSITIONS) * length(DESIRED_POWERS_MW);
TOTAL_NUM_TRIALS = TOTAL_NUM_TRIALS + 20; % Add no stimulation trials to total

%% Save Global Parameters
GlobalParams = {};
GlobalParams.Galvostation.Calibration_Coefficient = GALVOSTATION_CAL_CONSTANT;
GlobalParams.Galvostation.Calibration_Constant = GALVOSTATION_CAL_CONSTANT;
GlobalParams.Galvostation.Offset_Voltage = GALVOSTATION_OFFSET_V;

GlobalParams.Laser_Calibrations = LASER_CALIBRATIONS;

GlobalParams.Trial_Structure.Num_Trials_Per_Position = NUM_TRIALS_PER_POSITION;
GlobalParams.Trial_Structure.Total_Trials = TOTAL_NUM_TRIALS;
GlobalParams.Trial_Structure.Stimulation_Positions = STIMULATION_POSITIONS;
GlobalParams.Trial_Structure.Desired_Powers_mw = DESIRED_POWERS_MW;
% GlobalParams.Trial_Structure.Pulse_Durations_s = PULSE_DURATIONS_S;
% GlobalParams.Trial_Structure.Inter_Pulse_Intervals_s = INTER_PULSE_INTERVALS_S;
GlobalParams.Trial_Structure.Pre_Stim_Time_s = PRE_STIM_TIME_S;
GlobalParams.Trial_Structure.Stim_Time_s = STIMULATION_TIME_S;
GlobalParams.Trial_Structure.Post_Stim_Time_s = POST_STIMULATION_TIME_S;
GlobalParams.Trial_Structure.ITI_Min_s = MIN_ITI_S;
GlobalParams.Trial_Structure.ITI_Max_s = MAX_ITI_S;

BpodSystem.Data.GlobalParams = GlobalParams;

trial_params = gen_trial_stim_params(NUM_TRIALS_PER_POSITION, STIMULATION_POSITIONS, DESIRED_POWERS_MW);
trial_params.ITI = randi([MIN_ITI_S MAX_ITI_S], size(trial_params, 1), 1); % Generate an ITI between MIN_ITI_S and MAX_ITI_S for each row in stim params


    for current_trial = 1:TOTAL_NUM_TRIALS
        % For each trial
        % Params for this trial
        gui_update_data = {};
    
        params = trial_params(current_trial, :);
        gui_update_data.trial_number = current_trial;
        gui_update_data.current_position = params.position_um;
        gui_update_data.current_power = params.power;
        gui_update_data.current_ITI = params.ITI;
    
    
        next_trial = current_trial + 1;
        if next_trial > TOTAL_NUM_TRIALS
            gui_update_data.next_position = 999;
            gui_update_data.next_power = 999;
            gui_update_data.next_ITI = 999;
        else
            next_params = trial_params(next_trial, :);
            gui_update_data.next_position =  next_params.position_um;
            gui_update_data.next_power = next_params.power;
            gui_update_data.next_ITI = next_params.ITI;
        end
    
        gui.update_trial_info(gui_update_data);
    
        trial_position_um = params.position_um;
        trial_position_index = params.position_index;
        trial_power = params.power;
        trial_ITI = params.ITI;
        disp("Trial: " + num2str(current_trial))
        disp(params)
        % Move Galvostation
        move_time = PRE_STIM_TIME_S + STIMULATION_TIME_S + POST_STIMULATION_TIME_S;
        galvostation.configure_trial_move(trial_position_um, move_time);
    
        % Set Laser Power
        galvostation.laser_1.configure_trial_stimulation(trial_position_index, trial_power, STIMULATION_TIME_S);
        % Assemble State Machine
        state_machine = gen_state_machine(PRE_STIM_TIME_S, STIMULATION_TIME_S, POST_STIMULATION_TIME_S, trial_ITI);
        % Send state machine
        SendStateMachine(state_machine);
        % Wait for data to come back
        raw_events = RunStateMachine();
        % Save data
        if ~isempty(fieldnames(raw_events))
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, raw_events);
            BpodSystem.Data.TrialSettings(current_trial, :) = params;
            SaveBpodSessionData();
        end
        
        HandlePauseCondition;
        
        if BpodSystem.Status.BeingUsed == 0
            break;
        end
    end
end

cleanup(gui);
close_galvo_gui(galvo_gui);
galvostation = [];
% EndPulsePal;
% EndBpod;

beep();
msgbox("Experiment Finished!", "Finished");
figure(gui.figure);

end

function wait_dialog = create_wait_dialog(BpodSystem, galvo_gui)
    dialog_size_x = 200;
    dialog_size_y = 80;

    size = get(0, 'screensize');
    size_x = size(3);
    size_y = size(4);
    dialog_position_x = size_x/2 - (dialog_size_x/2);
    dialog_position_y = size_y/2 - (dialog_size_y/2);
    
    wait_dialog = dialog('Position', [dialog_position_x, dialog_position_y, dialog_size_x, dialog_size_y], 'Name', 'Start');
    uicontrol('Parent', wait_dialog, 'Style', 'text', 'Position', [dialog_size_x/2 - 100, dialog_size_y/2-10, 200 40], 'String', 'Click start to begin experiment!');
    uicontrol('Parent', wait_dialog, 'Position', [dialog_size_x/2 - 35, dialog_size_y/2 - 25, 70, 25], 'String', 'Start!', 'Callback', @(obj, ~)start_dialog_callback(obj, BpodSystem, galvo_gui))
end

function close_galvo_gui(galvo_gui)
    if isprop(galvo_gui, 'GalvostationManualControlUIFigure')
        close(galvo_gui.GalvostationManualControlUIFigure);
    end
end

function state_machine = gen_state_machine(pre_stim_time_s, stim_time_s, post_stim_time_s, ITI_s)
    state_machine = NewStateMachine();

    state_machine = AddState(state_machine,...
        'Name', 'pre_stim',...
        'Timer', pre_stim_time_s,...
        'StateChangeConditions', {'Tup', 'stim'},...
        'OutputActions', {'BNC2', '1'}... % Trigger galvostation move and camera via pulsepal
    );

    state_machine = AddState(state_machine,...
        'Name', 'stim',...
        'Timer', stim_time_s,...
        'StateChangeConditions', {'Tup', 'post_stim'},...
        'OutputActions', {'BNC1', '1'}...  % Trigger laser stimulation via pulsepal
    );

    state_machine = AddState(state_machine,...
        'Name', 'post_stim',...
        'Timer', post_stim_time_s,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {}...
    );
    
    state_machine = AddState(state_machine,...
        'Name', 'ITI',...
        'Timer', ITI_s,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {}...
    );
end

function components = parse_path(full_path)
    split_path = split(full_path, '\');
    components.mouse = split_path{3};
    components.experiment = split_path{4};
end

function timer_callback(timer, gui)
    current_time = timer.UserData.experiment_time_elapsed_seconds;
    new_time = current_time + 1;
    timer.UserData.experiment_time_elapsed_seconds = new_time;
    gui.update_timer(new_time);
end

function start_button_callback(app)
    global BpodSystem;
    %disp("Start Clicked!");
    start(BpodSystem.Timers.experiment_timer);
    app.start = true;
end

function stop_button_callback(app)
    global BpodSystem;
    %disp("Stop Triggered!");
    if BpodSystem.Status.BeingUsed
        BpodSystem.Status.BeingUsed = 0;
        app.open_wait_dialog();
    end
end

function pause_button_callback()
    disp("Pause Clicked!");
end


function close_gui_callback(gui)
% src is the GUI figure
    global BpodSystem;
    if isfield(BpodSystem, 'Status')
        % Enter here if Bpod still exists
        if BpodSystem.Status.BeingUsed
            % If still running, lets make them manually stop the experiment
            msgbox("End current session before closing the GUI!")
        else
            % We're closing early, trigger system shutdown
            if ~gui.start
                gui.early_close = true;
            end
        end
    else
        % If Bpod is gone we can definitely close
        disp("Closing Freely Moving GUI!");
        delete(gui.figure);
    end
end

function cleanup(gui)
    global BpodSystem;
    if isfield(BpodSystem.Timers, 'experiment_timer')
        disp("Stopping and removing timer!")
        stop(BpodSystem.Timers.experiment_timer);
        delete(BpodSystem.Timers.experiment_timer);
        BpodSystem.Timers = rmfield(BpodSystem.Timers, 'experiment_timer');
        gui.can_close = true;
        delete(gui.wait_dialog);
    end
end