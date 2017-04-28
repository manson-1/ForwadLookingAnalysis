function [] = myFLA(Instrument, totalDataSize, windowLenght_iS, windowLength_ooS, moveInterval, graphics)

clear global; % clear all global variables from previous runs
    
    %% INPUT PARAMETER
% Instrument        = which data to load, e.g. 'EURUSD'
% totalDataSize   = measured from the first data point, how much data
%                   should be taken into calculation for the consecutive walks.
%                   FLA stops when end of totalWindowSize is reached
% windowLenght_iS   = window length of data for in-sample optimization, measured in trading days, default = 518 
% windowLength_ooS  = window length of data for out-of-sample backtest measured in trading days, default = 259 
% moveInterval      = number of trading days to shift (per walk), default = 259
% if graphics       == 1 plotting is activated
%--------------------------------------------------------------------------

%% CHECK FOR CORRECT INPUT

if graphics > 1
    error_graphics = 'Please check your input parameters, graphics must not be greater than 1'
    
elseif graphics < 0
    error_graphics = 'Please check your input parameters, graphics must not be less than 1'
    
elseif (windowLenght_iS + windowLength_ooS) > totalDataSize
    error_windowlength = 'Please check your input parameters, in-sample + out-of-sample window length must not exceed totalDataSize'
    
elseif moveInterval > totalDataSize
    error_moveinterval = 'Please check your input parameters, moveInterval must not exceed totalDataSize'
    
else %no input error -> run code   
    
    %% INITIALIZE VECTORS/ARRAYS/VARIABLES
    
    % global to be available in all functions        
    global initBalance;    
    
    count_walks = 0; % count how many forward-walks are performed
    
%     startDate_iS = datetime(50,1); % prepare array for 50 walks
%     startDate_ooS = datetime(50,1); % prepare array for 50 walks
%     endDate_iS = zeros(50,1); % prepare array for 50 walks
%     endDate_ooS = zeros(50,1); % prepare array for 50 walks
    
    flaEquity = 0; % array with all generated PL
    initBalance = 10000; % Initial account balance
    
    %----------------------------------------------------------------------
    
    %% DATA PREPARATION
    
    % read price data and dates
    [data txt] = xlsread(Instrument);
    
    % convert txt-dates to datetime variables
     dates = datetime(txt(2:end,1));
    %----------------------------------------------------------------------
    
    %% WALK FORWARD
    
    % Assign values for the first walk
    startDateIndex = 1;
    endDateIndex = 1+totalDataSize;
    
    %==================== MAJOR CALCULATION ===============================
    for date = startDateIndex : moveInterval : endDateIndex
        
        count_walks = count_walks + 1;
        
        % Save start and end-dates for later print to command window
        startDate_iS(count_walks,:) = dates(date); 
        endDate_iS(count_walks,:) = dates(date + windowLenght_iS);
        startDate_ooS(count_walks,:) = dates(date + windowLenght_iS);
        endDate_ooS(count_walks,:) = dates(date + windowLenght_iS + 1 + windowLength_ooS);
    
        data_iS = data(date : date + windowLenght_iS, :);
        data_ooS = data(date + windowLenght_iS + 1 : date + windowLenght_iS + 1 + windowLength_ooS, :);
        
        % run in-sample optimization
        [optParam1, optParam2] = runOptimizer_iS(5, 15, 1, 5, 1, 1, data_iS);
        
        % run out-of-sample backtest
        [ooS_pdRatio, ooS_equity] = runBacktest_ooS(optParam1, optParam2, data_ooS);       
        
        if flaEquity(1) ~= 0 % only relevant in first walk
            flaEquity = vertcat(flaEquity, ooS_equity); % merge new ooS_pl into final pl-array
        else
            flaEquity = ooS_equity; % only relevant in first walk
        end
        
    end
    
    % Print to command window for controlling dates
    count_walks
    startDate_iS
    endDate_iS
    startDate_ooS
    endDate_ooS
   
    %======================================================================
        
    if (graphics == 1)
        plot(flaEquity); % flaEquity = each ooS_equity combined
    end
    
end

end

function [optParam1, optParam2] = runOptimizer_iS(lowerLimit1, upperLimit1, lowerLimit2, upperLimit2, stepParam1, stepParam2, data)
%% INPUT PARAMETER

% lowerLimit1 = lower limit for optimization of parameter 1
% upperLimit1 = upper limit for optimization of parameter 1
% lowerLimit2 = lower limit for optimization of parameter 2
% upperLimit2 = upper limit for optimization of parameter 2
% stepParam1 = step forward for parameter 1 optimization
% stepParam2 = step forward for parameter 2 optimization
% param1 = input parameter 1 for the trading strategy
% param2 = input parameter 2 for the trading strategy

% Initialize arrays with dimensions according to input limits
iS_pdRatio = zeros(upperLimit1, upperLimit2- lowerLimit2+1);
iS_pdRatio(1:lowerLimit1-1, 1:upperLimit2) = NaN;

% cicle through all parameter combinations and create a heatmap
for ii = lowerLimit1 : stepParam1 : upperLimit1 %cicle through each column
    for jj = lowerLimit2 : stepParam2 : upperLimit2 %cicle through each row
        
        pdRatio = trade_strategy(ii, jj, data); %trade on current data set, pd_ratio is returned and saved for each walk save returned values in arrays        
        iS_pdRatio(ii,jj) = pdRatio;
        
    end
end

% detect max value of pdRatio array and save the position indices of it as optParams
[maximumsTemp, indexTemp] = max(iS_pdRatio);
[M, I] = max(maximumsTemp);

optParam1 = indexTemp(I);
optParam2 = I;

end


function [ooS_pdRatio, ooS_equity] = runBacktest_ooS(optParam1, optParam2, data)
%% INPUT PARAMETER

% optParam1 = in-sample optimized input parameter 1
% optParam2 = in-sample optimized input parameter 2

% Trade strategy with optimal parameters calculated in the iS-test
[ooS_pdRatio, ooS_equity] = trade_strategy(optParam1, optParam2, data); %trade on current data set, pd_ratio, pl, totalPL are returned and saved for each walk

end


function [pdRatio, cleanEquity] = trade_strategy(param1, param2, data)
%% INPUT PARAMETER

% param1 = period ATR
% param2 = multiplier
% data = dataset to trade the strategy

% receive array with supertrend data + trend-direction of data
[supertrend, trend] = mySuperTrend(data, param1, param2, 0); % call SuperTrend calculation and trading, graphics set to 0 -> no drawing

open = data(:,1);
close = data(:,4);

riskPercent = 0.05; % Percentage value of account size to be risked per trade

running_trade(1:param1, :) = 0;
count_short_trades = 0;
count_long_trades = 0;

global entry_time_short;
global entry_time_long;
global entry_price_short;
global entry_price_long;
global short_exit;
global position_size;
global profit_loss;
global trade_duration_long;
global trade_duration_short;
global initBalance; 

%% DECLARE TRADING FUNCTIONS

function [] = enterShort(now)
    
            running_trade(now) = -1;
            entry_time_short = (now); % save time index of entry signal
            entry_price_short = open(now); % save entry price
            position_size = initBalance * riskPercent; % risk 1% of initial account size
            count_short_trades = count_short_trades + 1; %how many short trades      
end


function [] = enterLong(now)
      
            running_trade(now) = 1;
            entry_time_long = now; % save time index of entry signal
            entry_price_long = open(now); % save entry price
            position_size = initBalance * riskPercent; % risk 1% of initial account size
            count_long_trades = count_long_trades + 1; %how many short trades   
end


function [] = exitShort(now)

    if  (running_trade(now-1) == -1) % make sure there is a running short trade        
            running_trade(now,1) = 0;
            trade_duration_short(now,1) = (now) - (entry_time_short - 1); % calc number of bars of trade duration (for further statistics)
            profit_loss(now,1) = (entry_price_short - open(now)) * position_size; 
            short_exit = short_exit + 1; % count how many short trades are stopped out
    end
    
end


function [] = exitLong(now)

    if  (running_trade(now-1) == 1) % make sure there is a running short trade        
            running_trade(now,1) = 0;
            trade_duration_long(now,1) = (now) - (entry_time_long - 1); % calc number of bars of trade duration (for further statistics)
            profit_loss(now,1) = (entry_price_long - open(now)) * position_size; 
            short_exit = short_exit + 1; % count how many short trades are stopped out
    end
    
end

        
%% SUPERTREND TRADING

for kk = param1+1 : length(data) % cicle through all candles of current data
    
    %Debugging
    if kk == 250
        x = 0;
    end
    
    % careful not to use data which we do not know today! 
    % crossing of price/supertrend calculated on the close prices can only be known and traded tomorrow! -> entry in (kk+1)
    % check: no running trade and price crosses supertrend
        
    % SHORT CROSSING OCCURS
    if supertrend(kk-2) >= 0 && close(kk-2) > supertrend(kk-2) && close(kk-1) < supertrend(kk-1)
    
        % no running trade
        if (running_trade(kk-1) == 0) 
            enterShort(kk);
            
        % current long trade           
        elseif (running_trade(kk-1) == 1)
            exitLong(kk);
            enterShort(kk);            
        end
            
    
    % LONG CROSSING OCCURS
    elseif close(kk-2) < supertrend(kk-2) && close(kk-1) > supertrend(kk-1)
            
        % no running trade
        if (running_trade(kk-1) == 0)
            enterLong(kk);
            
        % current long trade           
        elseif (running_trade(kk-1) == -1)           
            exitShort(kk);
            enterLong(kk);
        end
        
    else
        
        if (running_trade(kk-1) == -1) % if we have a running short trade set running trade to 1 for each bar until exit
        running_trade(kk) = -1;
        
        
        elseif (running_trade(kk-1) == 1) % if we have a running long trade set running trade to 1 for each bar until exit 
        running_trade(kk) = 1;
        
        
        elseif (running_trade(kk-1) == 0) % if we have a running long trade set running trade to 1 for each bar until exit 
        running_trade(kk) = 0;
        end
    
    end    
end

%% KEY FIGURES 

totalPL = sum(profit_loss); 

% clean profit_loss array from zeros
cleanPL = profit_loss;
cleanPL(find(cleanPL == 0)) = [];

% calculate cleanEquity curve with clean profit_loss array
cleanEquity(1) = initBalance;
for kk = 2:length(cleanPL)
        cleanEquity(kk,1) = cleanEquity(kk-1) + cleanPL(kk); %[€]        
end

% plot(cleanEquity); % only for testing and checking each equity graph

maxDrawdown = maxdrawdown(cleanEquity);

%ProfitDrawdownRatio
pdRatio = totalPL / (maxDrawdown * 100);

end

% =========================================================================

% DEFAULT INPUT
% myFLA(Instrument, totalWindowSize, windowLenght_iS, windowLength_ooS, moveInterval, graphics)
% myFLA('EURUSD', 2000, 518, 259, 259, 0)

%% FRAGEN:

% Positionsgröße aktuell 1% des Startkapitals (statische Positionsgröße) -> ok oder ändern?
% Welche Logik für den StopLoss / TakeProfit verwenden?
% soll jede verwendete Variable zuerst einmal mit 0 o der zeros() initialisiert werden?

