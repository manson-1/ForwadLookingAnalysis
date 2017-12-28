% INPUT
Instrument = 'NZDUSD';
soundAlertIfFinished = true; % play a beep-sound if analysis is finished

% SETUP LOG FILE
filePath = horzcat(Instrument, '.txt');
columnNames = 'windowLength_iS / windowLength_ooS / ForwardEfficiency';

fileID = fopen(filePath, 'wt'); % open log file for writing
fprintf(fileID, '\t\t\t%s\n \t\t(daily candles)\n\n', Instrument); % write Instrument name to the log file
fprintf(fileID, '%s\n\n', columnNames); % write column headers to the log file
formatSpec = '\t%2d\t\t %2d\t\t %.4g\n'; % predefine the format of the printed variables

% =============================  RUN STATIC ANALYSIS  =====================================
% =========================================================================================

tic
for i = 900 : 100 : 1000 % in sample length
    for j = 350 : 50 : 500 % out of sample length
    
    % Input: myFLA('Instrument', totalDataSize, windowLenght_iS, windowLength_ooS, graphics)
    % Initialize the analysis object
    analysis = myFLA(Instrument, 2500, i, j, 0); 

    % RUN FORWARD LOOKING ANALYSIS
    % ForwardEfficiency is returned by RunFLA() and assigned to the analysis object.
    analysis.ForwardEfficiency = RunFLA(analysis);
    
    % BUILD RESULT TABLE
     resultTable = [analysis.windowLenght_iS, analysis.windowLength_ooS, analysis.ForwardEfficiency];

    fprintf(fileID, formatSpec, resultTable);
    
    end
end
timer = toc;

% =========================================================================================

fprintf(fileID, '\nElapsed time: %.4g seconds', timer); % print timer

if(soundAlertIfFinished)
    beep; % audio information that analysis is finished
end

fclose(fileID); %close the log file
