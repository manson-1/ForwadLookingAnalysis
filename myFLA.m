classdef myFLA
    
    properties 
        count_walks = 0;
        investment = 10.000;  
        Instrument;             % which data to load, e.g. 'EURUSD'
        totalDataSize;          % measured from the first data point, how much data should be taken into calculation for the consecutive walks. FLA stops when end of totalWindowSize is reached
        windowLenght_iS;        % window length of data for in-sample optimization, measured in trading days, default = 518
        windowLength_ooS;       % window length of data for out-of-sample backtest measured in trading days, default = 259 
        graphics;               % if graphics == 1 plotting is activated
    end
    
    methods
        
        function obj = myFLA(Instrument, totalDataSize, windowLenght_iS, windowLength_ooS, graphics)
            obj.Instrument = Instrument;
            obj.totalDataSize = totalDataSize;
            obj.windowLenght_iS = windowLenght_iS;%
            obj.windowLength_ooS = windowLength_ooS;%
            obj.graphics = graphics;
        end % Constructor
        
        function [] = RunFLA(obj)   

            % DATA PREPARATION
            % read price data and dates
            [data txt] = xlsread(obj.Instrument);

            % save dates in array
            dates = txt(2:end,1);
            %----------------------------------------------------------------------

            % CHECK FOR CORRECT INPUT

            if obj.graphics > 1
                errordlg('Please check your input parameters, graphics must not be greater than 1');
                disp('Error, see messagebox!');
                return;
            end

            if obj.graphics < 0
                errordlg('Please check your input parameters, graphics must not be less than 1');
                disp('Error, see messagebox!');
                return;
            end

            if (obj.windowLenght_iS + obj.windowLength_ooS) > obj.totalDataSize
                errordlg('Please check your input parameters, in-sample + out-of-sample window length must not exceed totalDataSize')
                disp('Error, see messagebox!');
                return;
            end

            % INITIALIZE VECTORS/ARRAYS/VARIABLES

            % global to be available in all functions          
            %global investment;

            % ======================= USER INPUT ==============================

            %investment = 10000; % amount of $ to invest per trade = account size -> 100% of acc size are invested in the market all the time

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

            % WALK FORWARD

            % Assign values for the first walk
            startDateIndex = 1;
            endDateIndex = obj.totalDataSize;

            %==================== MAJOR CALCULATION ===============================

            % data is moved each walk by the size obj.windowLength_ooS
            for date = startDateIndex : obj.windowLength_ooS : endDateIndex

                obj.count_walks = obj.count_walks + 1;

            %         ---------------------
            %         DEBUGGING
            %         if count_walks == 8        
            %             x = 0;            
            %         end
            %         ---------------------

                % ONLY FOR PRINTING TO THE COMMAND WINDOW

                if (date > length(dates)) % if startDate_iS exceeds the array size
                    msgbox('ATTENTION! data_iS exceeds the size of the dataseries, no data for walk forward left -> end');
                    obj.count_walks = obj.count_walks - 1; % Walk is not completely done
                    break; % exit the loop
                else
                    startDate_iS(obj.count_walks,:) = dates(date);  % startDate_iS does not exceed the array size
                end

                if (date + obj.windowLenght_iS > length(dates)) % if endDate_iS exceeds the array size
                    msgbox('ATTENTION! data_iS exceeds the size of the dataseries, no data for walk forward left -> end');
                    obj.count_walks = obj.count_walks - 1; % Walk is not completely done
                    break; % exit the loop
                else
                    endDate_iS(obj.count_walks,:) = dates(date + obj.windowLenght_iS); % endDate_ooS does not exceed the array size
                end

                if (date + obj.windowLenght_iS + 1 > length(dates)) % if startDate_ooS exceeds the array size
                    msgbox('ATTENTION! data_iS exceeds the size of the dataseries, no data for walk forward left -> end');  
                    obj.count_walks = obj.count_walks -1;
                    break; % exit the loop
                else
                    startDate_ooS(obj.count_walks,:) = dates(date + obj.windowLenght_iS + 1); % endDate_ooS does not exceed the array size
                end

                if (date + obj.windowLenght_iS + 1 + obj.windowLength_ooS > length(dates)) % if endDate_ooS exceeds the array size
                    endDate_ooS(obj.count_walks,:) = dates(length(dates));
                    msgbox('ATTENTION! endDate_ooS exceeds the dimension of the dataseries and was trimmed to fit to the array-size');        
                else
                    endDate_ooS(obj.count_walks,:) = dates(date + obj.windowLenght_iS + 1 + obj.windowLength_ooS); % endDate_ooS does not exceed the array size
                end

                % Define the dataset for the first walk == normal calculation
                if (obj.count_walks == 1)

                    data_iS = data(date : date + obj.windowLenght_iS - 1, :); % no data check needed, already done above

                    if (date + obj.windowLenght_iS + obj.windowLength_ooS > length(dates)) % if endDate_ooS exceeds the array size
                        data_ooS = data(date + obj.windowLenght_iS : length(dates)-1, :);
                        disp('data_ooS was trimmed to fit the array size');        
                    else
                        data_ooS = data(date + obj.windowLenght_iS : date + obj.windowLenght_iS + obj.windowLength_ooS - 1, :); % endDate_ooS does not exceed the array size
                    end

                end

                % Define the dataset for 2nd and all following walks -> add 1 time ooS data size to the beginning of the dataset for Supertrend calculation
                % -> with this logic Supertrend has values from the first real starting point       
                if (obj.count_walks > 1)

                    % add windowLenth_ooS size to the beginning of the data
                    if (date - obj.windowLength_ooS) > 0 % if start_date would exceed first datapoint of array
                        data_iS = data(date - obj.windowLength_ooS : date + obj.windowLenght_iS - 1, :);
                    else
                        data_iS = data(1 : date + obj.windowLenght_iS - 1, :); % start from the first available datapoint also in the second walk
                    end

                    % add windowLenth_ooS size to the beginning of the data
                    if (date + obj.windowLenght_iS + obj.windowLength_ooS > length(dates)) % if endDate_ooS exceeds the array size
                        data_ooS = data(date - obj.windowLength_ooS + obj.windowLenght_iS : length(dates)-1, :);
                        disp('data_ooS was trimmed to fit the array size');        
                    else
                        data_ooS = data(date - obj.windowLength_ooS + obj.windowLenght_iS : date + obj.windowLenght_iS + obj.windowLength_ooS - 1, :); % endDate_ooS does not exceed the array size
                    end

                end

            % ========================= WALK FORWARD ==============================

                % run in-sample optimization
                [optParam1, optParam2] = runOptimizer_iS(lowLim_ATR, upLim_ATR, step_ATR, lowLim_mult, upLim_mult, step_mult, data_iS);
                [iS_pdRatio, iS_cleanPL, iS_pdMsgCode] = runBacktest(optParam1, optParam2, data_iS); % for later comparison to ooS-pdRatio

                % run out-of-sample backtest        
                [ooS_pdRatio, ooS_cleanPL, ooS_pdMsgCode] = runBacktest(optParam1, optParam2, data_ooS);    
                % mySuperTrend(data_ooS, optParam1, optParam2, 1); % for testing purpose - to see on which chart is traded

            % =====================================================================

                % Save the results in vectors for later display in command window                     
                optParams(obj.count_walks,:) = [optParam1, optParam2];
                ooS_pdRatios(obj.count_walks,1) = ooS_pdRatio;  
                ooS_pdRatios(obj.count_walks,2) = ooS_pdMsgCode; % info about pd-ratio calculation
                iS_pdRatios(obj.count_walks,1) = iS_pdRatio;
                iS_pdRatios(obj.count_walks,2) = iS_pdMsgCode; % info about pd-ratio calculation

                % Calculate the combined forwardLooking-P&L by combining each out-of-sample P&L vector   
                ooS_ProfitLoss = vertcat(ooS_ProfitLoss, ooS_cleanPL);
                iS_ProfitLoss = vertcat(iS_ProfitLoss, iS_cleanPL);
            end

            % calculate final equity curve by adding up each profit/loss to current account balance
            ooS_Equity(1) = obj.investment; % first data point = initial account balance = investment size
            ooS_Equity(2:length(ooS_ProfitLoss),1) = NaN; % Preallocate for speed

            iS_Equity(1) = obj.investment; % first data point = initial account balance = investment size
            iS_Equity(2:length(iS_ProfitLoss),1) = NaN; % Preallocate for speed

            for kk = 2:length(ooS_ProfitLoss)

                ooS_Equity(kk,1) = ooS_Equity(kk-1) + ooS_ProfitLoss(kk); %[€]               

            end

            for kk = 2:length(iS_ProfitLoss)

                iS_Equity(kk,1) = iS_Equity(kk-1) + iS_ProfitLoss(kk); %[€]

            end

            % Create char-array for error-code definitions, plot to console in next section
            pdMsg = {'pd_ratio error messages';'0 = calculation ok';'1 = no trade computed';'2 = only one negative trade computed';'3 = only one positive trade computed';'4 = no negative trades - maxdrawdown = 0';'5 = SuperTrend could not be calculated'};

            % Print to command window for controlling dates
            obj.count_walks;
            startDate_iS;
            endDate_iS;
            startDate_ooS;
            endDate_ooS;
            optParams   
            iS_pdRatios
            ooS_pdRatios
            disp(pdMsg)

            % Plot the combined FLA-Equity curve
            if (obj.graphics == 1)

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
    % INPUT PARAMETER

        % lowerLimit1, lowerLimit2 = lower limit for optimization of parameter 1 / parameter 2
        % upperLimit1, upperLimit2 = upper limit for optimization of parameter 1 / parameter 2
        % stepParam1, setpParam2   = step forward interval for optimizing parameter 1 / parameter 2
        % param1, param2           = input parameter 1 / parameter 2 for the trading strategy

        % For Supertrend Trading:
        % -- Param1 = ATR
        % -- Param2 = Multiplier

        
    % Preallocate array with dimensions according to input limits
    iS_pdRatio = NaN((upperLimit1 - lowerLimit1)/ stepParam1 + 1, (upperLimit2 - lowerLimit2) / stepParam2 + 1);

    % cicle through all parameter combinations and create a heatmap
    for ii = 1 : (upperLimit1 - lowerLimit1)/ stepParam1 + 1 % cicle through each column = ATR, divisions necc. for steps < 1
        for jj = 1 : (upperLimit2 - lowerLimit2) / stepParam2 + 1 % cicle through each row = Multiplier, divisions necc. for steps < 1

            currATR = lowerLimit1 + (ii * stepParam1) - stepParam1; % convert back to use as input param for trading 
            currMult = lowerLimit2 + (jj * stepParam2) - stepParam2; % convert back to use as input param for trading

            % trade on current data set with ii and jj as input parameter, pd_ratio is returned and saved for each walk
            pdRatio = trade_strategy(currATR, currMult, data); 
            iS_pdRatio(ii,jj) = pdRatio; % save result in array

        end       
    end

    % detect max value of pdRatio-array and save the position-indices of it -> optimal input parameter
    [maximumTemp, indexTemp] = max(iS_pdRatio); % detect max of each column and save as vector
    [max_, ind] = max(maximumTemp); % detect max of the above saved maximum-vector

    optParam1 = indexTemp(ind) * stepParam1 + lowerLimit1 - stepParam1; % convert from index to real trade-strategy input
    optParam2 = ind * stepParam2 + lowerLimit2 - stepParam2; % convert from index to real trade-strategy input

        end
        
        function [pdRatio, cleanPL, pdMsgCode] = runBacktest(optParam1, optParam2, data)
    %INPUT PARAMETER

        % optParam1 = in-sample optimized input parameter 1
        % optParam2 = in-sample optimized input parameter 2

    % trade strategy with optimal parameters calculated in the iS-test
    % use current data set //  pd_ratio and equity are returned and saved for each walk

    [pdRatio, cleanPL, pdMsgCode] = trade_strategy(optParam1, optParam2, data); 

    % Plot the graphs where pdRatio is 0 -> to be able to check 
    showSupertrends = true;
    if (showSupertrends)
        if pdMsgCode == 2
            mySuperTrend(data, optParam1, optParam2, 1);
        end
    end
        end
        
        function [pdRatio, cleanPL, pdMsgCode] = trade_strategy(param1, param2, data)
    % INPUT PARAMETER

        % For SuperTrend-Trading:
        % param1 = period ATR
        % param2 = multiplier
        % data = dataset to trade the strategy

    % CALCULATE SUPERTREND
    % receive array with supertrend data and trend-direction (not necessary) of data
    % the input data for supertrend calculation is incl. datapoints at the beginning (size of obj.windowLength_ooS) which are only for ST calculation, not for trading with them
    % later on. 
    [supertrend, trend] = mySuperTrend(data, param1, param2, 0); % call SuperTrend calculation and trading, graphics set to 0 -> no drawing
    
    % Trim the arrays so the first datapoints are not used for trading -> they are only for ST calculation (see lines ~130-160)
    % Starting only from the second walk, as the first walk has no added datapoints at the beginning
    
    
    if (obj.count_walks > 1)
        supertrend = supertrend(obj.windowLength_ooS:end);
        trend = trend(obj.windowLength_ooS:end);
    end
    
    % if supertrend could not be calculate, e.g. because atrPeriod > available data
    if (isnan(supertrend) || isnan(trend))
        pdRatio = NaN;
        cleanPL = NaN;
        pdMsgCode = 5;
        return;
    end

    % PREPARE DATA
    % use only data which is meant for trading, the first datapoints are trimmed, they are only for ST calculation
    if (obj.count_walks == 1)
        open = data(:,1);
        close = data(:,4);
        
    elseif (obj.count_walks > 1)
        open = data(obj.windowLength_ooS,1);
        close = data(obj.windowLength_ooS,4);
        
    end

    % INITIALIZE 

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

    % DECLARE TRADING FUNCTIONS

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


    % SUPERTREND TRADING

    for kk = param1+1 : length(data) % cicle through all candles of current data

    % ======================
%         Debugging
%             if kk == 2
%                 x = 0;
%             end
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

    % KEY FIGURES 
    
    totalPL = sum(profitLoss); 
    totalPL_percent = (totalPL / investment) * 100;

    % Clean profitLoss array from zeros
    cleanPL = profitLoss; % use new array for further changes -> profitLoss array should not be changed
    cleanPL(find(cleanPL == 0)) = []; % delete value if value = 0

    % Calculate cleanEquity curve with clean profitLoss array
    cleanEquity(1) = investment; % first vaule = initial account balance

    % Check how many datapoints available
    if isemtpy(cleanPL) % no trade was computed

        maxDrawdown = NaN;
        pdRatio = 0;
        pdMsgCode = 1; % error code for detecting why no pd-ratio could be calculated

    elseif length(cleanPL) == 1 % only one trade was computed

        cleanEquity(2) = cleanEquity(1) + cleanPL(1);
        
        if(cleanEquity(2) > cleanEquity(1)) % only one positive trade
            maxDrawdown = 0.01; % set manually so calculation is possible -> value is a percentage value -> 0.01%
            pdRatio = totalPL_percent / maxDrawdown;
            pdMsgCode = 3;
            
        else % only one negative trade
            pdRatio = 0;
            pdMsgCode = 2; % error code for detecting why no pd-ratio could be calculated
        end

    else % more than 1 trades were computed
        
        % Preallocate cleanEquity -> speed
        cleanEquity(2:length(cleanPL)+1,1) = NaN;
        
        for kk = 1:length(cleanPL)
 
            % calculate equity curve by adding up each profit/loss to current account balance
            cleanEquity(kk+1,1) = cleanEquity(kk) + cleanPL(kk); %[€]        
            cleanEquity(cleanEquity <= 0) = 0.01; % if equity would go below zero, set balance to 1cent (negative balance not possible)
        end

        % Calculate maximum drawdown of the equity-curve - use internal matlab function maxdrawdown(), output = % value      
        maxDrawdown = maxdrawdown(cleanEquity) * 100;
        
        % Calculate ProfitDrawdownRatio
        if maxDrawdown ~= 0

            pdRatio = totalPL_percent / maxDrawdown;
            pdMsgCode = 0; 
            
        else
            pdRatio = 0;
            pdMsgCode = 4; % error code for detecting why no pd-ratio could be calculated
            
        end
    end     
end
end  
end








