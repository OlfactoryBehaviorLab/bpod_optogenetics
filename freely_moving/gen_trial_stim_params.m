function params = gen_trial_stim_params(num_trials_per_combo, position, power)
    position_indices = 1:length(position);
    possible_combos = combinations(position_indices, power);
    repeat_combos = repelem(possible_combos, num_trials_per_combo, 1);
    repeat_combos.position_um = zeros(size(repeat_combos, 1), 1);
    for i = 1:length(position_indices)
        repeat_combos.position_um(repeat_combos.position_indices == i) = position(i);
    end
    rand_row_order = randperm(size(repeat_combos, 1));
    params = repeat_combos(rand_row_order, :);
end