
function dat = ftz_concatTrial(data)

% cfg.feedback     = 'no', 'text', 'textbar', 'gui' (default = 'text')
cfg.feedback = 'text';

Ntrials  = length(data.trial);
Nchans   = length(data.label);

% determine the size of each trial, they can be variable length
Nsamples = zeros(1,Ntrials);
for trial=1:Ntrials
  Nsamples(trial) = size(data.trial{trial},2);
end

% concatenate all the data into a 2D matrix unless we already have an
% unmixing matrix or unless the user request it otherwise
dat = zeros(Nchans, sum(Nsamples));
ft_progress('init', cfg.feedback, 'concatenating trials...');
for trial=1:Ntrials
    ft_progress(trial/Ntrials, 'Concatenating trial %d from %d', trial, Ntrials);
    begsample = sum(Nsamples(1:(trial-1))) + 1;
    endsample = sum(Nsamples(1:trial));
    dat(:,begsample:endsample) = data.trial{trial};
end
ft_progress('close')
ft_info('concatenated data matrix size %dx%d\n', size(dat,1), size(dat,2));


hasdatanans = any(~isfinite(dat(:)));
if hasdatanans
    ft_info('data contains nan or inf, only using the samples without nan or inf\n');
    finitevals = sum(~isfinite(dat))==0;
    if ~any(finitevals)
        ft_error('no samples remaining');
    else
        dat = dat(:,finitevals);
    end
end

end