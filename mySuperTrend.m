function [supertrend, trend] = mySuperTrend(data, periodATR, multiplier, graphics)
%% INPUT PARAMETER 

% DEFAULT VALUES
% Instrument = 'EURUSD'
% periodATR = 10
% multiplier = 3
% if graphics == 1 plotting is activated
%--------------------------------------------------------------------------

%% CHECK FOR CORRECT INPUT

if graphics > 1
    error_graphics = 'Please check your input parameter, graphics must not be greater than 1'
elseif graphics < 0 
    error_graphics = 'Please check your input parameter, graphics must not be less than 1'
else %no input error -> run code
    
%--------------------------------------------------------------------------

%% DATA PREPARATION

% read data
% [data txt] = xlsread(Instrument);

% assign data
open = data(:,1);
high = data(:,2);
low = data(:,3);
close = data(:,4);
date = datetime(txt(2:end,1));

for ii = 1:length(close)
    mid(ii,:) = (high(ii) + low(ii)) / 2; %Median price
end

%--------------------------------------------------------------------------

%% INITIALIZE VECTORS

supertrend_low = 1000000;
supertrend_high = 0;
trend = zeros(size(close));
atr = zeros(size(close));
true_range = zeros(size(close));
offset = zeros(size(close));
supertrend_up_tmp = zeros(size(close));
supertrend_up = zeros(size(close));
supertrend_dn_tmp = zeros(size(close));
supertrend_dn = zeros(size(close));
supertrend = zeros(size(close));
supertrend_draw_up = zeros(size(close));
supertrend_draw_dn = zeros(size(close));

% -------------------------------------------------------------------------

%% TRUE RANGE

for ii = 2:length(close)
    true_range_temp(ii, :) = [(high(ii) - low(ii)), abs(high(ii) - close(ii-1)), abs(low(ii) - close(ii-1))];
    true_range(ii,:) = max(true_range_temp(ii,:));
    true_range(1,:) = high(1) - low(1); %first value = high-low
end

% -------------------------------------------------------------------------

%% AVERAGE TRUE RANGE

atr(periodATR,:) = sum(true_range(1:periodATR)) / periodATR; %first value = simple MA of true range 
offset(periodATR,:) = atr(periodATR) * multiplier;
for ii = periodATR+1:length(close)
    atr(ii,:) = (atr(ii-1) * (periodATR - 1) + true_range(ii)) / periodATR;
    offset(ii,:) = atr(ii) * multiplier;
end

atr(1:periodATR-1,:) = NaN;
offset(1:periodATR-1,:) = NaN;

% -------------------------------------------------------------------------

%% SUPER TREND

%Resistance Line
supertrend_up_tmp = mid + offset;

%Support Line
supertrend_dn_tmp = mid - offset;


for ii = periodATR+1:length(close) %start from ii = 15

% Debugging
% if ii == 120
%     x=0;
% end

        %///////////////////////////////////////////////////////////////
        % UP LINE
        %///////////////////////////////////////////////////////////////
        
        if supertrend_up_tmp(ii) < supertrend_low
            supertrend_low = supertrend_up_tmp(ii);
            supertrend_up(ii,:) = supertrend_low;
        end
            
        if supertrend_up_tmp(ii) > supertrend_low && close(ii)<supertrend_low
            supertrend_up(ii,:) = supertrend_low;
        end

        if supertrend_up_tmp(ii) > supertrend_low && close(ii) > supertrend_low
            supertrend_low = 1000000;
            supertrend_up(ii) = supertrend_dn_tmp(ii);
        end
        
        %///////////////////////////////////////////////////////////////
        % DOWN LINE
        %///////////////////////////////////////////////////////////////
        
         if supertrend_dn_tmp(ii) > supertrend_high
            supertrend_high = supertrend_dn_tmp(ii);
            supertrend_dn(ii,:) = supertrend_high;
        end
            
        if supertrend_dn_tmp(ii) < supertrend_high && close(ii)>supertrend_high
            supertrend_dn(ii,:) = supertrend_high;
        end

        if supertrend_dn_tmp(ii) < supertrend_high && close(ii) < supertrend_high
            supertrend_high = 0;
            supertrend_dn(ii) = supertrend_up_tmp(ii);
        end                            
end

for ii = periodATR+2:length(close) % Start ii from 16 -> need values from ii=15 (-> values from ii=14 are NaN so 15 is first accessible value)
    
        %///////////////////////////////////////////////////////////////
        % TREND DETECTION
        %///////////////////////////////////////////////////////////////
        
        trend(periodATR+1) = -1; % Initialize
        
        if trend(ii-1) == -1 && close(ii) < supertrend_up(ii)
            trend(ii,:) = -1;
        end
        
        if trend(ii-1) == -1 && close(ii) > supertrend_up(ii)
            trend(ii,:) = 1;
        end
        
        if trend(ii-1) == 1 && close(ii) > supertrend_dn(ii)
            trend(ii,:) = 1;
        end
        
        if trend(ii-1) == 1 && close(ii) < supertrend_dn(ii)
            trend(ii,:) = -1;
        end
        
        %///////////////////////////////////////////////////////////////
        % SUPER TREND
        %///////////////////////////////////////////////////////////////
        if trend(ii-1) == 1;
            supertrend(ii-1) = supertrend_dn(ii-1);
            
            % for 2-colour drawing
            supertrend_draw_up(ii) = supertrend_dn(ii-1);
            supertrend_draw_dn(ii) = NaN;
            
        elseif trend(ii-1) == -1;
            supertrend(ii-1) = supertrend_up(ii-1);
            
            % for 2-colour drawing
            supertrend_draw_up(ii) = NaN;
            supertrend_draw_dn(ii) = supertrend_up(ii-1);
        end
end

% -------------------------------------------------------------------------

end

supertrend_draw_dn(1:periodATR+1) = NaN; 
supertrend_draw_up(1:periodATR+1) = NaN;

% -------------------------------------------------------------------------

 %% GRAPHICS

%Currently not used
%start_bar = 1; % first bar to plot
%end_bar = 2500; % last bar to plot

    if graphics == 1
        figure;
         s1 = subplot(1,1,1);
%               candle(high(start_bar:end_bar),low(start_bar:end_bar),close(start_bar:end_bar),open(start_bar:end_bar), 'k', date(start_bar:end_bar), 'yyyy'); % plot the candle chart
                candle(high,low,close,open,'k');
                title(s1, Instrument); % Instrument = name of input data series
                ylabel(s1, 'Price');
                xlabel(s1, 'Date');
                hold on
                   plot(supertrend_draw_up, 'g'); % plot the sma_slow
                   plot(supertrend_draw_dn, 'r'); % plot the sma_fast
                hold off

    end

    % -------------------------------------------------------------------------

    %% DEBUGGING
    % x = 1;
    
    %% SAMPLE INPUT COMMAND
    %mySuperTrend('EURUSD', 10, 3, 1);
end