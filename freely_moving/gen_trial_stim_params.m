function params = gen_trial_stim_params(num_trials_per_combo, position, power)
    possible_combos = combinations(position, power);
    repeat_combos = repelem(possible_combos, num_trials_per_combo, 1);
    rand_row_order = randperm(size(repeat_combos, 1));
    params = repeat_combos(rand_row_order, :);
end