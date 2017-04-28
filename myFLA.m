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
iS_pdRatio(1:lowerLimit1-1, 1:upperLimit2) = NaN; % set not needed values to NaN

% cicle through all parameter combinations and create a heatmap
for ii = lowerLimit1 : stepParam1 : upperLimit1 %cicle through each column
    for jj = lowerLimit2 : stepParam2 : upperLimit2 %cicle through each row
        
        % trade on current data set with ii and jj as input parameter, pd_ratio is returned and saved for each walk       
        pdRatio = trade_strategy(ii, jj, data); 
        iS_pdRatio(ii,jj) = pdRatio; % save result in array
        
    end
end

% detect max value of pdRatio-array and save the position-indices of it -> optimal input parameter
[maximumTemp, indexTemp] = max(iS_pdRatio); % detect max of each column and save as vector
[max_, ind] = max(maximumTemp); % detect max of the above saved maximum-vector

optParam1 = indexTemp(ind);
optParam2 = ind;

end


function [ooS_pdRatio, ooS_equity] = runBacktest_ooS(optParam1, optParam2, data)
%% INPUT PARAMETER

% optParam1 = in-sample optimized input parameter 1
% optParam2 = in-sample optimized input parameter 2

% trade strategy with optimal parameters calculated in the iS-test
% use current data set //  pd_ratio and equity are returned and saved for each walk
[ooS_pdRatio, ooS_equity] = trade_strategy(optParam1, optParam2, data); 

end


function [pdRatio, cleanEquity] = trade_strategy(param1, param2, data)
%% INPUT PARAMETER

% For SuperTrend-Trading:
% param1 = period ATR
% param2 = multiplier
% data = dataset to trade the strategy

%% CALCULATE SUPERTREND
% receive array with supertrend data and trend-direction (not necessary) of data
[supertrend, trend] = mySuperTrend(data, param1, param2, 0); % call SuperTrend calculation and trading, graphics set to 0 -> no drawing

%% PREPARE DATA
open = data(:,1);
close = data(:,4);

%% INITIALIZE 

% global variables to be able to access them in all following functions
global initBalance; 
global riskPercent;
global positionSize;

global profitLoss;
global runningTrade;

global entryTimeShort;
global entryTimeLong;
global entryPriceShort;
global entryPriceLong;

global exitCounterShort;
global exitCounterLong;
global tradeCounterShort;
global tradeCounterLong;
global tradeDurationLong;
global tradeDurationShort;

runningTrade(1:param1, :) = 0; % set first values of the array to 0 -> no running trade at the beginning
riskPercent = 0.05; % Percentage value of account size to be risked per trade

%% DECLARE TRADING FUNCTIONS

function [] = enterShort(now)
    
            runningTrade(now) = -1;
            entryTimeShort = (now); % save time index of entry signal
            entryPriceShort = open(now); % save entry price
            positionSize = initBalance * riskPercent; % risk 1% of initial account size
            tradeCounterShort = tradeCounterShort + 1; % count how many short trades      

end


function [] = enterLong(now)
      
            runningTrade(now) = 1;
            entryTimeLong = now; % save time index of entry signal
            entryPriceLong = open(now); % save entry price
            positionSize = initBalance * riskPercent; % risk 1% of initial account size
            tradeCounterLong = tradeCounterLong + 1; % count how many short trades   

end


function [] = exitShort(now)

    if  (runningTrade(now-1) == -1) % make sure there is a running short trade        
            
        runningTrade(now) = 0;
        tradeDurationShort(now) = (now) - (entryTimeShort - 1); % calculate number of bars of trade duration (for further statistics)
        profitLoss(now,:) = (entryPriceShort - open(now)) * positionSize; % calculate realized profit/loss
        exitCounterShort = exitCounterShort + 1; % count how many short trades are stopped out
   
    end
    
end


function [] = exitLong(now)

    if  (runningTrade(now-1) == 1) % make sure there is a running short trade        
            
        runningTrade(now) = 0;
        tradeDurationLong(now) = (now) - (entryTimeLong - 1); % calculate number of bars of trade duration (for further statistics)
        profitLoss(now,:) = (open(now) - entryPriceLong) * positionSize; % calculate realized profit/loss
        exitCounterLong = exitCounterLong + 1; % count how many short trades are stopped out
    
    end
    
end

        
%% SUPERTREND TRADING

for kk = param1+1 : length(data) % cicle through all candles of current data
  
% ======================
%     %Debugging
%     if kk == 250
%         x = 0;
%     end
% ======================
    
    % careful not to use data which we do not know today! 
    % crossing of price/supertrend calculated on the close prices can only be known and traded tomorrow! -> entry in (kk+1)
    
        
    % SHORT CROSSING OCCURED ON YESTERDAYS CLOSE 
    % check: supertrend has a real value + supertrend crossing occured yesterday
    if supertrend(kk-2) >= 0 && (close(kk-2) > supertrend(kk-2) && close(kk-1) <= supertrend(kk-1))
    
        % no running trade
        if (runningTrade(kk-1) == 0) % if currently no running trade
            enterShort(kk);
            
        % current long trade           
        elseif (runningTrade(kk-1) == 1) % if currently running long trade
            exitLong(kk);
            enterShort(kk);            
        end
            
    
    % LONG CROSSING OCCURED ON YESTERDAYS CLOSE
    elseif supertrend(kk-2) >= 0 && (close(kk-2) < supertrend(kk-2) && close(kk-1) >= supertrend(kk-1))
            
        % no running trade
        if (runningTrade(kk-1) == 0) % if currently no running trade
            enterLong(kk);
            
        % current long trade           
        elseif (runningTrade(kk-1) == -1) % if currently running short trade
            exitShort(kk);
            enterLong(kk);
        end
        
    else % ADD DISPLAY FOR ALL OPTIM PARAMS
        
        if (runningTrade(kk-1) == -1) % if we have a running short trade set running trade to 1 for each bar until exit
        runningTrade(kk) = -1;
        
        
        elseif (runningTrade(kk-1) == 1) % if we have a running long trade set running trade to 1 for each bar until exit 
        runningTrade(kk) = 1;
        
        
        elseif (runningTrade(kk-1) == 0) % if we have a running long trade set running trade to 1 for each bar until exit 
        runningTrade(kk) = 0;
        end
    
    end    
end

%% KEY FIGURES 

totalPL = sum(profitLoss); 

% clean profitLoss array from zeros
cleanPL = profitLoss;
cleanPL(find(cleanPL == 0)) = [];

% calculate cleanEquity curve with clean profitLoss array
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
% Welche Metrics/statistics sollen noch berechnet werden?
% WalkForwardEfficiency berechnen? Siehe Robert Pardo

