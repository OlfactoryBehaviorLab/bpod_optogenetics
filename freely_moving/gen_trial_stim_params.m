function params = gen_trial_stim_params(num_trials_per_combo, position, power)
    position_index = 1:length(position);
    possible_combos = combinations(position_index, power);
    repeat_combos = repelem(possible_combos, num_trials_per_combo, 1);
    repeat_combos.position_um = zeros(size(repeat_combos, 1), 1);
    for i = 1:length(position_index)
        repeat_combos.position_um(repeat_combos.position_index == i) = position(i);
    end
    
    null_trial = [];
    null_trial.position_index = 0;
    null_trial.power = 0;
    null_trial.position_um = 0;

    null_trials = struct2table(repelem(null_trial, num_trials_per_combo, 1));
    repeat_combos = [repeat_combos; null_trials];
    rand_row_order = randperm(size(repeat_combos, 1));
    params = repeat_combos(rand_row_order, :);
end