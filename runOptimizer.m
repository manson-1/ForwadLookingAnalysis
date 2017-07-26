function [optParam1, optParam2] = runOptimizer(lowerLimit1, upperLimit1, stepParam1, lowerLimit2, upperLimit2, stepParam2, data)
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
            pdRatio = myFLA.trade_strategy(currATR, currMult, data); 
            iS_pdRatio(ii,jj) = pdRatio; % save result in array

        end       
    end

    % detect max value of pdRatio-array and save the position-indices of it -> optimal input parameter
    [maximumTemp, indexTemp] = max(iS_pdRatio); % detect max of each column and save as vector
    [max_, ind] = max(maximumTemp); % detect max of the above saved maximum-vector

    optParam1 = indexTemp(ind) * stepParam1 + lowerLimit1 - stepParam1; % convert from index to real trade-strategy input
    optParam2 = ind * stepParam2 + lowerLimit2 - stepParam2; % convert from index to real trade-strategy input

end