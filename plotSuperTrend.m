function [] = plotSuperTrend(open, high, low, close, supertrend)   
    figure;
    s1 = subplot(1,1,1);
        candle(high,low,close,open,'k')
            ylabel(s1, 'Price');
            xlabel(s1, 'Date');
        hold on
           plot(supertrend, 'b'); 
        hold off
end
