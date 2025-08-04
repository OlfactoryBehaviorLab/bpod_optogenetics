function freely_moving
GALVOSTATION_CAL_COEFFICIENT = 0.0;
GALVOSTATION_CAL_CONSTANT = 0.0;
GALVOSTATION_OFFSET_V = 0.075;

STIMULATION_POSITIONS = [250, 750, 1250]; % Center(s) in um of stimulation positions; stimulation is +/- 250um of center

LASER_CALIBRATIONS = struct(); % Each galvostation position attenuates the laser slightly differently; so each position will need a slightly
LASER_CALIBRATIONS.POS_1 = []; % different set of calibration values to ensure the power is delivered consistently
LASER_CALIBRATIONS.POS_2 = []; % Each calibration should be two values in the form [coefficient, constant] based on a linear fit
LASER_CALIBRATIONS.POS_3 = [];

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


global BpodSystem;

%% CHECK INPUTS
if (length(DESIRED_POWERS_MW) ~= length(PULSE_DURATIONS_S)) && (length(PULSE_DUREATIONS_S) ~= length(INTER_PULSE_INTERVALS_S))
    error("The length of DESIRED_POWERS_MW and DESIRED_DUTY_CYCLE must be the same! There must be one duty cycle per power level!");
end

if GALVOSTATION_CAL_CONSTANT == 0 | GALVOSTATION_CAL_CONSTANT == 0
    error("Please provide calibration values for the Galvostation!");
end

if length(fieldnames(LASER_CALIBRATIONS)) ~= length(STIMULATION_POSITIONS)
    error("Please provide a laser calibration for each stimulation position!");
end

% Start BPOD if it isn't started
if ~exist('BpodSystem', 'var')
    Bpod();
end

% Start PulsePal if it isn't started
if ~exist('PulsePalSystem', 'var')
    PulsePal();
end

trial_params = gen_trial_stim_params(NUM_TRIALS_PER_POSITION, STIMULATION_POSITIONS, DESIRED_POWERS_MW);
trial_params.ITI = randi([MAX_ITI_S MIN_ITI_S], size(trial_params, 1), 1); % Generate an ITI between MIN_ITI_S and MAX_ITI_S for each row in stim params



end

