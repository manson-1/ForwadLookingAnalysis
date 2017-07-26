% FORWARD LOOKING ANALYSIS
% ------------------------

% myFLA('Instrument', totalDataSize, windowLenght_iS, windowLength_ooS, graphics)
analysis = myFLA('EURUSD', 2000, 750, 350, 1); % initialize object with basic input informations

% RUN ANALYSIS
RunFLA(analysis);