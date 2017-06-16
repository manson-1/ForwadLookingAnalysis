function [] = myFLA(Instrument, totalDataSize, windowLenght_iS, windowLength_ooS, graphics)   
    %% INPUT PARAMETER
        % Instrument        = which data to load, e.g. 'EURUSD'
        % totalDataSize     = measured from the first data point, how much data
        %                   should be taken into calculation for the consecutive walks.
        %                   FLA stops when end of totalWindowSize is reached
        % windowLenght_iS   = window length of data for in-sample optimization, measured in trading days, default = 518 
        % windowLength_ooS  = window length of data for out-of-sample backtest measured in trading days, default = 259 
        % if graphics       == 1 plotting is activated
    %--------------------------------------------------------------------------

    %% DATA PREPARATION

    % read price data and dates
    [data txt] = xlsread(Instrument);

    % save dates in array
    dates = txt(2:end,1);
    %----------------------------------------------------------------------

    %% CHECK FOR CORRECT INPUT

    if graphics > 1
        errordlg('Please check your input parameters, graphics must not be greater than 1');
        disp('Error, see messagebox!');
        return;
    end

    if graphics < 0
        errordlg('Please check your input parameters, graphics must not be less than 1');
        disp('Error, see messagebox!');
        return;
    end

    if (windowLenght_iS + windowLength_ooS) > totalDataSize
        errordlg('Please check your input parameters, in-sample + out-of-sample window length must not exceed totalDataSize')
        disp('Error, see messagebox!');
        return;
    end

    %% INITIALIZE VECTORS/ARRAYS/VARIABLES

    % global to be available in all functions          
    global investment;

    % ======================= USER INPUT ==============================

    investment = 10000; % amount of $ to invest per trade = account size -> 100% of acc size are invested in the market all the time

    % Params for ATR optimization - ATR parameters must be integers -> no decimals
    lowLim_ATR = 10;
    upLim_ATR = 50;
    step_ATR = 1; 

        % in case user chose decimals, delete decimals to ensure correct calulations in ATR calculatoin
        lowLim_ATR = round(lowLim_ATR); 
        upLim_ATR = round(upLim_ATR);
        step_ATR = round(step_ATR);

    % Params for multiplier optimization - Multiplier parameters can have decimals
    lowLim_mult = 1;
    upLim_mult = 7;
    step_mult = 0.5;  

    % =================================================================

    iS_pdRatios = 0;
    ooS_pdRatios = 0;
    iS_ProfitLoss = NaN; 
    ooS_ProfitLoss = NaN;
    ooS_Equity = 0; % array with all generated PL
    count_walks = 0; % count how many forward-walks are performed 

    %% WALK FORWARD

    % Assign values for the first walk
    startDateIndex = 1;
    endDateIndex = 1+totalDataSize;

    %==================== MAJOR CALCULATION ===============================

    % data is moved each walk by the size windowLength_ooS
    for date = startDateIndex : windowLength_ooS : endDateIndex

        count_walks = count_walks + 1;

    %         ---------------------
    %         DEBUGGING
    %         if count_walks == 8        
    %             x = 0;            
    %         end
    %         ---------------------

        % ONLY FOR PRINTING TO THE COMMAND WINDOW

        if (date > length(dates)) % if startDate_iS exceeds the array size
            msgbox('ATTENTION! data_iS exceeds the size of the dataseries, no data for walk forward left -> end');
            count_walks = count_walks - 1; % Walk is not completely done
            break; % exit the loop
        else
            startDate_iS(count_walks,:) = dates(date);  % startDate_iS does not exceed the array size
        end

        if (date + windowLenght_iS > length(dates)) % if endDate_iS exceeds the array size
            msgbox('ATTENTION! data_iS exceeds the size of the dataseries, no data for walk forward left -> end');
            count_walks = count_walks - 1; % Walk is not completely done
            break; % exit the loop
        else
            endDate_iS(count_walks,:) = dates(date + windowLenght_iS); % endDate_ooS does not exceed the array size
        end

        if (date + windowLenght_iS + 1 > length(dates)) % if startDate_ooS exceeds the array size
            msgbox('ATTENTION! data_iS exceeds the size of the dataseries, no data for walk forward left -> end');  
            count_walks = count_walks -1;
            break; % exit the loop
        else
            startDate_ooS(count_walks,:) = dates(date + windowLenght_iS + 1); % endDate_ooS does not exceed the array size
        end

        if (date + windowLenght_iS + 1 + windowLength_ooS > length(dates)) % if endDate_ooS exceeds the array size
            endDate_ooS(count_walks,:) = dates(length(dates));
            msgbox('ATTENTION! endDate_ooS exceeds the dimension of the dataseries and was trimmed to fit to the array-size');        
        else
            endDate_ooS(count_walks,:) = dates(date + windowLenght_iS + 1 + windowLength_ooS); % endDate_ooS does not exceed the array size
        end

        % Define the dataset for all further calculations

        data_iS = data(date : date + windowLenght_iS, :); % no data check needed, already done above

        if (date + windowLenght_iS + 1 + windowLength_ooS > length(dates)) % if endDate_ooS exceeds the array size
            data_ooS = data(date + windowLenght_iS + 1 : length(dates)-1, :);
            disp('data_ooS was trimmed to fit the array size');        
        else
            data_ooS = data(date + windowLenght_iS + 1 : date + windowLenght_iS + 1 + windowLength_ooS, :); % endDate_ooS does not exceed the array size
        end

        % ===================== WALK FORWARD ==============================

        % run in-sample optimization
        [optParam1, optParam2] = runOptimizer_iS(lowLim_ATR, upLim_ATR, step_ATR, lowLim_mult, upLim_mult, step_mult, data_iS);
        [iS_pdRatio, iS_cleanPL, iS_pdMsgCode] = runBacktest(optParam1, optParam2, data_iS); % for later comparison to ooS-pdRatio

        % run out-of-sample backtest        
        [ooS_pdRatio, ooS_cleanPL, ooS_pdMsgCode] = runBacktest(optParam1, optParam2, data_ooS);    
        % mySuperTrend(data_ooS, optParam1, optParam2, 1); % for testing purpose - to see on which chart is traded

        % =================================================================

        % Save the results in vectors for later display in command window                     
        optParams(count_walks,:) = [optParam1, optParam2];
        ooS_pdRatios(count_walks,1) = ooS_pdRatio;  
        ooS_pdRatios(count_walks,2) = ooS_pdMsgCode; % info about pd-ratio calculation
        iS_pdRatios(count_walks,1) = iS_pdRatio;
        iS_pdRatios(count_walks,2) = iS_pdMsgCode; % info about pd-ratio calculation

        % Calculate the combined forwardLooking-P&L by combining each out-of-sample P&L vector   
        ooS_ProfitLoss = vertcat(ooS_ProfitLoss, ooS_cleanPL);
        iS_ProfitLoss = vertcat(iS_ProfitLoss, iS_cleanPL);
    end

    % calculate final equity curve by adding up each profit/loss to current account balance
    ooS_Equity(1) = investment; % first data point = initial account balance = investment size
    iS_Equity(1) = investment; % first data point = initial account balance = investment size

    for kk = 2:length(ooS_ProfitLoss)

        ooS_Equity(kk,1) = ooS_Equity(kk-1) + ooS_ProfitLoss(kk); %[€]               

    end

    for kk = 2:length(iS_ProfitLoss)

        iS_Equity(kk,1) = iS_Equity(kk-1) + iS_ProfitLoss(kk); %[€]

    end

    pdMsg = {'0 = calculation ok';'1 = no trade computed';'2 = only one trade computed';'3 = no negative trades - maxdrawdown = 0'};

    % Print to command window for controlling dates
    count_walks
    startDate_iS;
    endDate_iS;
    startDate_ooS;
    endDate_ooS;
    optParams   
    iS_pdRatios
    ooS_pdRatios
    pdMsg

    % Plot the combined FLA-Equity curve
    if (graphics == 1)

        figure;
            % IN SAMPLE PLOTTING
            s1 = subplot(1,2,1);
                hold on                
                    plot(iS_Equity, 'k'); 
                    title(s1, 'IN SAMPLE');  
                    ylabel(s1, 'Account Balance [€]');
                    xlabel(s1, '# of Trades');
                hold off

            % OUT OF SAMPLE PLOTTING
            s2 = subplot(1,2,2); 
                hold on                
                    plot(ooS_Equity, 'r'); % ooS_Equity = each ooS_equity combined
                    title(s2, 'OUT OF SAMPLE');
                    ylabel(s2, 'Account Balance [€]');
                    xlabel(s2, '# of Trades');
                hold off  
    end
end


function [optParam1, optParam2] = runOptimizer_iS(lowerLimit1, upperLimit1, stepParam1, lowerLimit2, upperLimit2, stepParam2, data)
    %% INPUT PARAMETER

        % lowerLimit1, lowerLimit2 = lower limit for optimization of parameter 1 / parameter 2
        % upperLimit1, upperLimit2 = upper limit for optimization of parameter 1 / parameter 2
        % stepParam1, setpParam2   = step forward interval for optimizing parameter 1 / parameter 2
        % param1, param2           = input parameter 1 / parameter 2 for the trading strategy

        % For Supertrend Trading:
        % -- Param1 = ATR
        % -- Param2 = Multiplier

    % Preallocate array with dimensions according to input limits
    iS_pdRatio = zeros(upperLimit1 / stepParam1, upperLimit2 / stepParam2);

    % cicle through all parameter combinations and create a heatmap
    for ii = (lowerLimit1 / stepParam1) : (upperLimit1 / stepParam1) % cicle through each column = ATR, divisions necc. for steps < 1
        for jj = (lowerLimit2 / stepParam2) : (upperLimit2 / stepParam2) % cicle through each row = Multiplier, divisions necc. for steps < 1

            currATR = ii * stepParam1; % convert back to use as input param for trading 
            currMult = jj * stepParam2; % convert back to use as input param for trading

            if (currATR == 1)
                x=0;
            end

            % trade on current data set with ii and jj as input parameter, pd_ratio is returned and saved for each walk       
            pdRatio = trade_strategy(currATR, currMult, data); 
            iS_pdRatio(ii,jj) = pdRatio; % save result in array

        end
    end

    % detect max value of pdRatio-array and save the position-indices of it -> optimal input parameter
    [maximumTemp, indexTemp] = max(iS_pdRatio); % detect max of each column and save as vector
    [max_, ind] = max(maximumTemp); % detect max of the above saved maximum-vector

    optParam1 = indexTemp(ind) * stepParam1;
    optParam2 = ind * stepParam2;

end



function [pdRatio, cleanPL, pdMsgCode] = runBacktest(optParam1, optParam2, data)
    %% INPUT PARAMETER

        % optParam1 = in-sample optimized input parameter 1
        % optParam2 = in-sample optimized input parameter 2

    % trade strategy with optimal parameters calculated in the iS-test
    % use current data set //  pd_ratio and equity are returned and saved for each walk

    [pdRatio, cleanPL, pdMsgCode] = trade_strategy(optParam1, optParam2, data); 

    % Plot the graphs where pdRatio is 0 -> to be able to check 
    showSupertrends = true;
    if (showSupertrends)
        if pdMsgCode > 0
            mySuperTrend(data, optParam1, optParam2, 1);
        end
    end
end


function [pdRatio, cleanPL, pdMsgCode] = trade_strategy(param1, param2, data)
    %% INPUT PARAMETER

        % For SuperTrend-Trading:
        % param1 = period ATR
        % param2 = multiplier
        % data = dataset to trade the strategy

    %% CALCULATE SUPERTREND
    % receive array with supertrend data and trend-direction (not necessary) of data
    [supertrend, trend] = mySuperTrend(data, param1, param2, 0); % call SuperTrend calculation and trading, graphics set to 0 -> no drawing

    if (isnan(supertrend) | isnan(trend))
        pdRatio = NaN;
        cleanPL = NaN;
        return;
    end

    %% PREPARE DATA
    open = data(:,1);
    close = data(:,4);

    %% INITIALIZE 

    global investment;

    profitLoss = 0;
    runningTrade(1:param1, :) = 0; % set first values of the array to 0 -> no running trade at the beginning

    entryTimeShort = [];
    entryTimeLong = [];
    entryPriceShort = [];
    entryPriceLong = [];

    exitCounterShort = [];
    exitCounterLong = [];
    tradeCounterShort = [];
    tradeCounterLong = [];
    tradeDurationLong = [];
    tradeDurationShort = [];

    %% DECLARE TRADING FUNCTIONS

    function [] = enterShort(now)

                runningTrade(now) = -1;
                entryTimeShort = (now); % save time index of entry signal
                entryPriceShort = open(now); % save entry price
                tradeCounterShort = tradeCounterShort + 1; % count how many short trades      

    end


    function [] = enterLong(now)

                runningTrade(now) = 1;
                entryTimeLong = now; % save time index of entry signal
                entryPriceLong = open(now); % save entry price
                tradeCounterLong = tradeCounterLong + 1; % count how many short trades   

    end


    function [] = exitShort(now)

        if  (runningTrade(now-1) == -1) % make sure there is a running short trade        

            runningTrade(now) = 0;
            tradeDurationShort(now) = (now) - (entryTimeShort - 1); % calculate number of bars of trade duration (for further statistics)
            profitLoss(now,:) = (entryPriceShort - open(now,:)) * investment; % calculate P/L in USD
            exitCounterShort = exitCounterShort + 1; % count how many short trades are stopped out

        end

    end


    function [] = exitLong(now)

        if  (runningTrade(now-1) == 1) % make sure there is a running short trade        

            runningTrade(now) = 0;
            tradeDurationLong(now) = (now) - (entryTimeLong - 1); % calculate number of bars of trade duration (for further statistics)
            profitLoss(now,:) = (open(now,:) - entryPriceLong) * investment; % calculate P/L in USD
            exitCounterLong = exitCounterLong + 1; % count how many short trades are stopped out

        end

    end


    %% SUPERTREND TRADING

    for kk = param1+1 : length(data) % cicle through all candles of current data

    % ======================
    %     Debugging
        if kk == 2
            x = 0;
        end
    % ======================

        % careful not to use data which we do not know today! 
        % crossing of price/supertrend calculated on the close prices can only be known and traded tomorrow! -> entry in (kk+1)

        % SHORT CROSSING OCCURED ON YESTERDAYS CLOSE 
        % check: supertrend has a real value + supertrend crossing occured yesterday
        if supertrend(kk-2) > 0 && supertrend(kk-1) > 0 &&(close(kk-2) > supertrend(kk-2) && close(kk-1) <= supertrend(kk-1))

            % no running trade
            if (runningTrade(kk-1) == 0) % if currently no running trade
                enterShort(kk);

            % current long trade           
            elseif (runningTrade(kk-1) == 1) % if currently running long trade
                exitLong(kk);
                enterShort(kk);            
            end


        % LONG CROSSING OCCURED ON YESTERDAYS CLOSE
        elseif supertrend(kk-2) > 0 && supertrend(kk-1) > 0 && (close(kk-2) < supertrend(kk-2) && close(kk-1) >= supertrend(kk-1))

            % no running trade
            if (runningTrade(kk-1) == 0) % if currently no running trade
                enterLong(kk);

            % current long trade           
            elseif (runningTrade(kk-1) == -1) % if currently running short trade
                exitShort(kk);
                enterLong(kk);
            end


        % NO CROSSING OCCURED - NO CHANGES IN A RUNNING TRADE    
        else 

            if (runningTrade(kk-1) == -1) % if yesterday = running short trade -> today = running short trade
                runningTrade(kk) = -1;


            elseif (runningTrade(kk-1) == 1) % if yesterday = running long trade -> today = running long trade
                runningTrade(kk) = 1;


            elseif (runningTrade(kk-1) == 0) % if yesterday = no trade -> today = no trade
                runningTrade(kk) = 0;

            end    
        end   

        % if last datapoint reached -> close all running trades    
        if kk == length(data)

            if runningTrade(kk-1) == -1
                exitShort(kk);

            elseif runningTrade(kk-1) == 1
                exitLong(kk);

            end
        end
    end

    %% KEY FIGURES 
    
    totalPL = sum(profitLoss); 
    totalPL_percent = (totalPL / investment) * 100;

    % Clean profitLoss array from zeros
    cleanPL = profitLoss; % use new array for further changes -> profitLoss array should not be changed
    cleanPL(find(cleanPL == 0)) = []; % delete value if value = 0

    % Calculate cleanEquity curve with clean profitLoss array
    cleanEquity(1) = investment; % first vaule = initial account balance

    % Check how many datapoints available
    if length(cleanPL) == 0 % no trade was computed
        maxDrawdown = NaN;
        pdRatio = 0;
        pdMsgCode = 1;

    elseif length(cleanPL) == 1 % only one trade was computed
        cleanEquity(2) = cleanEquity(1) + cleanPL(1);
        maxDrawdown = NaN;
        pdRatio = 0;
        pdMsgCode = 2;

    else % more than 1 trades were computed

        for kk = 1:length(cleanPL)

                % calculate equity curve by adding up each profit/loss to current account balance
                cleanEquity(kk+1,1) = cleanEquity(kk) + cleanPL(kk); %[€]        

        end

        % Calculate maximum drawdown of the equity-curve - use internal matlab function maxdrawdown(), output = % value
        maxDrawdown = maxdrawdown(cleanEquity) * 100;
        
        % Calculate ProfitDrawdownRatio
        if maxDrawdown ~= 0

            pdRatio = totalPL_percent / maxDrawdown;
            pdMsgCode = 0;
        else
            pdRatio = 0;
            pdMsgCode = 3;
        end
    end     
end

%% DEFAULT INPUT

% =========================================================================
% myFLA(Instrument, totalWindowSize, windowLenght_iS, windowLength_ooS, graphics)
% myFLA('EURGBP', 2000, 518, 259, 0)

% tic
% myFLA('EURUSD', 2000, 1000, 259, 1)
% toc
% =========================================================================
