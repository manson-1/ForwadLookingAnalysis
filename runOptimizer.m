function [optParam1, optParam2] = runOptimizer(lowerLimit1, upperLimit1, stepParam1, lowerLimit2, upperLimit2, stepParam2, data, obj)
    
    % INPUT PARAMETER
    % lowerLimit1, lowerLimit2 = lower limit for optimization of parameter 1 / parameter 2
    % upperLimit1, upperLimit2 = upper limit for optimization of parameter 1 / parameter 2
    % stepParam1, setpParam2   = step forward interval for optimizing parameter 1 / parameter 2
    % param1, param2           = input parameter 1 / parameter 2 for the trading strategy

    % For Supertrend Trading:
    % -- Param1 = ATR
    % -- Param2 = Multiplier
      
    % Preallocate array with dimensions according to input limits
    % iS_pdRatio = NaN((upperLimit1 - lowerLimit1)/ stepParam1 + 1, (upperLimit2 - lowerLimit2) / stepParam2 + 1);
    is_normalizedPL = NaN((upperLimit1 - lowerLimit1)/ stepParam1 + 1, (upperLimit2 - lowerLimit2) / stepParam2 + 1);

    % cicle through all parameter combinations and create a heatmap
    for ii = 1 : (upperLimit1 - lowerLimit1)/ stepParam1 + 1 % cicle through each column = ATR, divisions necc. for steps < 1
        for jj = 1 : (upperLimit2 - lowerLimit2) / stepParam2 + 1 % cicle through each row = Multiplier, divisions necc. for steps < 1

            currATR = lowerLimit1 + (ii * stepParam1) - stepParam1; % convert back to use as input param for trading 
            currMult = lowerLimit2 + (jj * stepParam2) - stepParam2; % convert back to use as input param for trading

            % trade on current data set with ii and jj as input parameter, pd_ratio is returned and saved for each walk
            % pdRatio = tradeStrategy(currATR, currMult, data, obj);             
            % iS_pdRatio(ii,jj) = pdRatio; % save result in array
            
            % trade on current data set with ii and jj as input parameter, PL is returned and saved for each walk
            cleanPL = tradeStrategy(currATR, currMult, data, obj); 
            normalizedPL = sum(cleanPL) / length(data); % agreed in Meeting in R7 on 29th Dec, optimize for normalized PL by length of data set, do not use drawdown
            is_normalizedPL(ii,jj) = normalizedPL; % save result in array
                
        end       
    end

    % [maximumTemp, indexTemp] = max(iS_pdRatio); % detect max of each column and save as vector
    
    % detect max value of pdRatio-array and save the position-indices of it -> optimal input parameter
    [maximumTemp, indexTemp] = max(is_normalizedPL); % detect max of each column and save as vector
    [max_, ind] = max(maximumTemp); % detect max of the above saved maximum-vector

    optParam1 = indexTemp(ind) * stepParam1 + lowerLimit1 - stepParam1; % convert from index to real trade-strategy input
    optParam2 = ind * stepParam2 + lowerLimit2 - stepParam2; % convert from index to real trade-strategy input

end