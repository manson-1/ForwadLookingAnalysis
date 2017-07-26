% ------------------------
% FORWARD LOOKING ANALYSIS
% ------------------------

% myFLA('Instrument', totalDataSize, windowLenght_iS, windowLength_ooS, graphics)
analysis = myFLA('EURUSD', 2000, 500, 250, 1); % initialize object with basic input informations

% RUN ANALYSIS
RunFLA(analysis);

% ------------------------
% DEFAULT INPUT VALUES:
% total data size           -> 2000 days    = ~10 years of testable data on which the forward looking analysis can be performed
% in sample optimization    -> 500 days     = ~2 years for in sample supertrend-parameter optimization
% out of sample testing     -> 250 days     = ~1 year for out of sample testing data with optimized supertrend parameters
% ------------------------