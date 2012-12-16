function data = ft_datatype_raw(data, varargin)

% FT_DATATYPE_RAW describes the FieldTrip MATLAB structure for raw data
%
% The raw datatype represents sensor-level time-domain data typically
% obtained after calling FT_DEFINETRIAL and FT_PREPROCESSING. It contains
% one or multiple segments of data, each represented as Nchan X Ntime
% arrays.
%
% An example of a raw data structure with 151 MEG channels is
%
%          label: {151x1 cell}      the channel labels (e.g. 'MRC13')
%           time: {1x266 cell}      the timeaxis [1*Ntime double] per trial
%          trial: {1x266 cell}      the numeric data [151*Ntime double] per trial
%     sampleinfo: [266x2 double]    the begin and endsample of each trial relative to the recording on disk
%      trialinfo: [266x1 double]    optional trigger or condition codes for each trial
%            hdr: [1x1 struct]      the full header information of the original dataset on disk
%           grad: [1x1 struct]      information about the sensor array (for EEG it is called elec)
%            cfg: [1x1 struct]      the configuration used by the function that generated this data structure
%
% Required fields:
%   - time, trial, label
%
% Optional fields:
%   - sampleinfo, trialinfo, grad, elec, hdr, cfg
%
% Deprecated fields:
%   - fsample
%
% Obsoleted fields:
%   - offset
%
% Revision history:
%
% (2011/latest) The description of the sensors has changed, see FT_DATATYPE_SENS
% for further information.
%
% (2010v2) The trialdef field has been replaced by the sampleinfo and
% trialinfo fields. The sampleinfo corresponds to trl(:,1:2), the trialinfo
% to trl(4:end).
%
% (2010v1) In 2010/Q3 it shortly contained the trialdef field which was a copy
% of the trial definition (trl) is generated by FT_DEFINETRIAL.
%
% (2007) It used to contain the offset field, which correcponds to trl(:,3).
% Since the offset field is redundant with the time axis, the offset field is
% from now on not present any more. It can be recreated if needed.
%
% (2003) The initial version was defined
%
% See also FT_DATATYPE, FT_DATATYPE_COMP, FT_DATATYPE_TIMELOCK, FT_DATATYPE_FREQ,
% FT_DATATYPE_SPIKE, FT_DATATYPE_SENS

% Copyright (C) 2011, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% get the optional input arguments, which should be specified as key-value pairs
version       = ft_getopt(varargin, 'version', 'latest');
hassampleinfo = ft_getopt(varargin, 'hassampleinfo', true);

if isequal(hassampleinfo, 'ifmakessense')
  hassampleinfo = 'yes';
  if isfield(data, 'sampleinfo') && size(data.sampleinfo,1)~=numel(data.trial)
    % it does not make sense, so don't keep it
    hassampleinfo = 'no';
  end
  if isfield(data, 'trialinfo') && size(data.trialinfo,1)~=numel(data.trial)
    % it does not make sense, so don't keep it
    hassampleinfo = 'no';
  end
  if isfield(data, 'sampleinfo')
    numsmp = data.sampleinfo(:,2)-data.sampleinfo(:,1)+1;
    for i=1:length(data.trial)
      if size(data.trial{i},2)~=numsmp(i);
        % it does not make sense, so don't keep it
        hassampleinfo = 'no';
        break;
      end
    end
  end
  if strcmp(hassampleinfo, 'no')
    % the actual removal will be done further down
    warning('removing inconsistent sampleinfo');
  end
end

% convert it into true/false
hassampleinfo = istrue(hassampleinfo);

if strcmp(version, 'latest')
  version = '2011';
end

if isempty(data)
  return;
end

switch version
  case '2011'
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isfield(data, 'grad')
      % ensure that the gradiometer balancing is specified
      if ~isfield(data.grad, 'balance') || ~isfield(data.grad.balance, 'current')
        data.grad.balance.current = 'none';
      end
      
      % ensure the new style sensor description
      data.grad = ft_datatype_sens(data.grad);
    end
    
    if isfield(data, 'elec')
      data.elec = ft_datatype_sens(data.elec);
    end
    
    if ~isfield(data, 'fsample')
      data.fsample = 1/mean(diff(data.time{1}));
    end
    
    if isfield(data, 'offset')
      data = rmfield(data, 'offset');
    end
    
    % the trialdef field should be renamed into sampleinfo
    if isfield(data, 'trialdef')
      data.sampleinfo = data.trialdef;
      data = rmfield(data, 'trialdef');
    end
    
    if hassampleinfo && (~isfield(data, 'sampleinfo') || ~isfield(data, 'trialinfo'))
      % try to reconstruct sampleinfo and trialinfo
      data = fixsampleinfo(data);
    end
    
    if ~hassampleinfo && isfield(data, 'sampleinfo')
      data = rmfield(data, 'sampleinfo');
    end
    if ~hassampleinfo && isfield(data, 'trialinfo')
      data = rmfield(data, 'trialinfo');
    end
    
  case '2010v2'
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isfield(data, 'fsample')
      data.fsample = 1/mean(diff(data.time{1}));
    end
    
    if isfield(data, 'offset')
      data = rmfield(data, 'offset');
    end
    
    % the trialdef field should be renamed into sampleinfo
    if isfield(data, 'trialdef')
      data.sampleinfo = data.trialdef;
      data = rmfield(data, 'trialdef');
    end
    
    if hassampleinfo && (~isfield(data, 'sampleinfo') || ~isfield(data, 'trialinfo'))
      % try to reconstruct sampleinfo and trialinfo
      data = fixsampleinfo(data);
    end
    
    if ~hassampleinfo && isfield(data, 'sampleinfo')
      data = rmfield(data, 'sampleinfo');
    end
    if ~hassampleinfo && isfield(data, 'trialinfo')
      data = rmfield(data, 'trialinfo');
    end
    
  case {'2010v1' '2010'}
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isfield(data, 'fsample')
      data.fsample = 1/mean(diff(data.time{1}));
    end
    
    if isfield(data, 'offset')
      data = rmfield(data, 'offset');
    end
    
    if ~isfield(data, 'trialdef') && hascfg
      % try to find it in the nested configuration history
      data.trialdef = ft_findcfg(data.cfg, 'trl');
    end
    
  case '2007'
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isfield(data, 'fsample')
      data.fsample = 1/mean(diff(data.time{1}));
    end
    
    if isfield(data, 'offset')
      data = rmfield(data, 'offset');
    end
    
  case '2003'
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isfield(data, 'fsample')
      data.fsample = 1/mean(diff(data.time{1}));
    end
    
    if ~isfield(data, 'offset')
      data.offset = zeros(length(data.time),1);
      for i=1:length(data.time);
        data.offset(i) = round(data.time{i}(1)*data.fsample);
      end
    end
    
  otherwise
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    error('unsupported version "%s" for raw datatype', version);
end


% Numerical inaccuracies in the binary representations of floating point
% values may accumulate. The following code corrects for small inaccuracies
% in the time axes of the trials. See http://bugzilla.fcdonders.nl/show_bug.cgi?id=1390
data = fixtimeaxes(data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = fixtimeaxes(data)

if ~isfield(data, 'fsample')
  fsample = 1/mean(diff(data.time{1}));
else
  fsample = data.fsample;
end

begtime   = zeros(1, length(data.time));
endtime   = zeros(1, length(data.time));
numsample = zeros(1, length(data.time));
for i=1:length(data.time)
  begtime(i)   = data.time{i}(1);
  endtime(i)   = data.time{i}(end);
  numsample(i) = length(data.time{i});
end

% compute the differences over trials and the tolerance
tolerance     = 0.01*(1/fsample);
begdifference = abs(begtime-begtime(1));
enddifference = abs(endtime-endtime(1));

% check whether begin and/or end are identical, or close to identical
begidentical  = all(begdifference==0);
endidentical  = all(enddifference==0);
begsimilar    = all(begdifference < tolerance);
endsimilar    = all(enddifference < tolerance);

% Compute the offset of each trial relative to the first trial, and express
% that in samples. Non-integer numbers indicate that there is a slight skew
% in the time over trials. This works in case of variable length trials.
offset = fsample * (begtime-begtime(1));
skew   = abs(offset - round(offset));

% try to determine all cases where a correction is needed
% note that this does not yet address all possible cases where a fix might be needed
needfix = false;
needfix = needfix || ~begidentical && begsimilar;
needfix = needfix || ~endidentical && endsimilar;
needfix = needfix || ~all(skew==0) && all(skew<0.01);

% if the skew is less than 1% it will be corrected
if needfix
  warning_once('correcting numerical inaccuracy in the time axes');
  for i=1:length(data.time)
    % reconstruct the time axis of each trial, using the begin latency of
    % the first trial and the integer offset in samples of each trial
    data.time{i} = begtime(1) + ((1:numsample(i)) - 1 + round(offset(i)))/fsample;
  end
end
