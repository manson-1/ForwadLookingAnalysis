function [pdRatio, cleanPL, pdMsgCode] = runBacktest(optParam1, optParam2, data, obj)
    
    %INPUT PARAMETER
    % optParam1 = in-sample optimized input parameter 1
    % optParam2 = in-sample optimized input parameter 2

    % trade strategy with optimal parameters calculated in the iS-test
    % use current data set //  pd_ratio and equity are returned and saved for each walk

    [pdRatio, cleanPL, pdMsgCode] = tradeStrategy(optParam1, optParam2, data, obj); 

end