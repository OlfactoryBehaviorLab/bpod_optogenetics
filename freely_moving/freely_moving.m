function freely_moving
%% EXPERIMENT PARAMETERS
GALVOSTATION_CAL_COEFFICIENT = 1;
GALVOSTATION_CAL_CONSTANT = 2;
GALVOSTATION_OFFSET_V = 0.075;

STIMULATION_POSITIONS = [250, 750, 1250]; % Center(s) in um of stimulation positions; stimulation is +/- 250um of center

LASER_CALIBRATIONS = []; % Each galvostation position attenuates the laser slightly differently; so each position will need a slightly
LASER_CALIBRATIONS(1, :) = [1, 2]; % different set of calibration values to ensure the power is delivered consistently
LASER_CALIBRATIONS(2, :) = [2, 3]; % Each calibration should be two values in the form [coefficient, constant] based on a linear fit
LASER_CALIBRATIONS(3, :) = [3, 4];

NUM_TRIALS_PER_POSITION = 20;

DESIRED_POWERS_MW = [0.5, 1, 2]; % Stimulation power(s) in mW
PULSE_DURATIONS_S = [-1, -1, -1]; % Pulse durations for duty-cycle; -1 indicates constant power
INTER_PULSE_INTERVALS_S = [0, 0, 0]; % Inter-pulse-intervals for duty-cycle in seconds; 0 indicates constant power


PRE_STIM_TIME_S = 4; % Pre stimulation time in seconds
STIMULATION_TIME_S = 2; % Stimulation time in seconds
POST_STIMULATION_TIME_S = 4; % Post stimulation time in seconds

MIN_ITI_S = 20; % Minimum ITI time in seconds
MAX_ITI_S = 40; % Maximum ITI time in seconds

TOTAL_NUM_TRIALS = NUM_TRIALS_PER_POSITION * length(STIMULATION_POSITIONS) * length(DESIRED_POWERS_MW);
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
if (length(DESIRED_POWERS_MW) ~= length(PULSE_DURATIONS_S)) && (length(PULSE_DUREATIONS_S) ~= length(INTER_PULSE_INTERVALS_S))
    error("The length of DESIRED_POWERS_MW and DESIRED_DUTY_CYCLE must be the same! There must be one duty cycle per power level!");
end

if GALVOSTATION_CAL_CONSTANT == 0 | GALVOSTATION_CAL_CONSTANT == 0
    error("Please provide calibration values for the Galvostation!");
end

if size(LASER_CALIBRATIONS, 1) ~= length(STIMULATION_POSITIONS)
    error("Please provide a laser calibration for each stimulation position!");
end

%% Implement Experiment
trial_params = gen_trial_stim_params(NUM_TRIALS_PER_POSITION, STIMULATION_POSITIONS, DESIRED_POWERS_MW);
trial_params.ITI = randi([MIN_ITI_S MAX_ITI_S], size(trial_params, 1), 1); % Generate an ITI between MIN_ITI_S and MAX_ITI_S for each row in stim params

init_params = struct();
init_params.GUI.trial = 0;
init_params.GUI.position_um = 0;
init_params.GUI.position_index = 0;
init_params.GUI.power = 0;
init_params.GUI.ITI = 0;
BpodParameterGUI('init', init_params);


for current_trial = 1:TOTAL_NUM_TRIALS
    % For each trial

    % TODO: Lock galvostation GUI but still update the display

    % Params for this trial
    params = trial_params(current_trial, :);
    gui_params = unpack_params(params);
    gui_params.GUI.trial = current_trial;
    gui_params = BpodParameterGUI('sync', gui_params);

    trial_position_um = params.position_um;
    trial_position_index = params.position_index;
    trial_power = params.power;
    trial_ITI = params.ITI;
    disp("Trial: " + num2str(current_trial))
    disp(params)
    % Move Galvostation
    move_time = PRE_STIM_TIME_S + STIMULATION_TIME_S + 1; % Add a buffer of 1s
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
        break
    end
end

close(galvo_gui.GalvostationManualControlUIFigure);
galvostation = [];
EndPulsePal;
EndBpod;

end

function GUI_struct = unpack_params(params)

    fields = fieldnames(params);

    for i=1:length(fields)
        field = fields{i};
        disp(field);
        GUI_struct.GUI.(field) = params.(field);
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