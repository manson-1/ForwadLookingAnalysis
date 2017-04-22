function [fla_equity] = myFLA(totalWindowSize, windowLenght_iS, windowLength_ooS, moveInterval, graphics)
%% INPUT PARAMETER

% totalWindowSize =
% windowLenght_iS =
% windowLength_ooS =
% moveInterval =
% graphics =
%--------------------------------------------------------------------------

%% INITIALIZE VECTORS/ARRAYS/VARIABLES
% global to be available in all functions

global startDate;
global endDate;
global currStartDate;
global currEndDate;
global priceData;
global open;
global high;
global low;
global close;
global date;

%--------------------------------------------------------------------------

%% DATA PREPARATION

% read data
[data txt] = xlsread(Instrument);

% assign data - global to be available in all functions
open = data(:,1);
high = data(:,2);
low = data(:,3);
close = data(:,4);
date = datetime(txt(2:end,1));
%--------------------------------------------------------------------------

    %%
    for currDate = startDate : moveInterval : endDate

        % run in-sample optimization
        runOptimizer_iS(1,2,3,4);
        

        % run out-of-sample backtest
        runBacktest_ooS(1,2);

        continue;
        end
        
    continue;
    
    plot(forward_equity); % forward_equity = each ooS_equity combined
    
    end
   

function [optParam1, optParam2] = runOptimizer_iS(lowerLimit1, upperLimit1, lowerLimit2, upperLimit2, param1, param2)
        %% INPUT PARAMETER

        % lowerLimit1 = lower limit for optimization of parameter 1
        % upperLimit1 = upper limit for optimization of parameter 1
        % lowerLimit2 = lower limit for optimization of parameter 2 
        % upperLimit2 = upper limit for optimization of parameter 2
        % param1 = input parameter 1 for the trading strategy
        % param2 = input parameter 2 for the trading strategy

        % Set current date borders
        currStartDate = date;
        currEndDate = date + windowLenght_iS;
        
        % Initialize arrays with dimensions according to input limits
        curr_pdRatio = cell(upperLimit1 - lowerLimit1, upperLimit2- lowerLimit2);
        curr_pl = cell(upperLimit1 - lowerLimit1, upperLimit2- lowerLimit2);
        curr_totalPL = cell(upperLimit1 - lowerLimit1, upperLimit2- lowerLimit2);
        
        currData = close(currStartDate : currEndDate, 1) %set current data set with date-borders
        
        % cicle through all parameter combinations and create a heatmap
        for i = lowerLimit1 : upperLimit1 %cicle through each column        
            for j = lowerLimit2 : upperLimit2 %cicle through each row               
                
                trade_strategy(supertrend, i, j, currData); %trade on current data set, pd_ratio, pl, totalPL are returned and saved for each walk            
                % save returned values in arrays
                curr_pdRatio(i,j) = pdRatio;
                curr_pl(i,j) = pl;
                curr_totalPL(i,j) = totalPL;
                
            end            
        end
        
        % create a heatmap of data matrix with returned curr_pdRatio
        pd_heatmap = heatmap(curr_pdRatio,xvar,yvar);
        
        if (graphics) 
            plot(pd_heatmap);
        end
        
        % detect max value of pdRatio array and save the position indices
        % of it as optParams
        [optParam1, optParam2] = max(curr_pdRatio);
        
              
        
        
        
end

function [ooS_equity] = runBacktest_ooS(optParam1, optParam2)
  %% INPUT PARAMETER

        % optParam1 =
        % optParam2 =
        
        
end

function [pdRatio, pl, totalPL] = trade_strategy(strategy, param1, param2, data)
  %% INPUT PARAMETER

        % strategy =
        % param1 =
        % param2 =
        % data =
        
        
end


% Variante statt global variables: nested functions -> https://de.mathworks.com/help/matlab/matlab_prog/nested-functions.html
% müsste nur das end der FLA function ganz ans ende setzen, dann sollten
% die functions auch ohne global variables auf alles zugreifen können