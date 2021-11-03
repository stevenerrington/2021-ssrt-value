%% value-based inhibition function
monkeyList = {'darwin','Euler','joule','Xena'};
valueConds = {'lo','hi'}; % 'hi'
nSessions = length(valuedata_master.sessionN);

getColor_value

for valueCondIdx = 1:2
    valueCond = valueConds{valueCondIdx};
    
    for sessionIdx = 1:nSessions
        
        % Get the generated weibull fitted inhibition function
        % y axis (pNC)
        rtDistCDF.(valueCond).x_noncanc{sessionIdx,1} =...
            valuedata_master.valueRTdist(sessionIdx).(valueCond).noncanc(:,1)';
        rtDistCDF.(valueCond).y_noncanc{sessionIdx,1} =...
            valuedata_master.valueRTdist(sessionIdx).(valueCond).noncanc(:,2)';
        
        rtDistCDF.(valueCond).x_nostop{sessionIdx,1} =...
            valuedata_master.valueRTdist(sessionIdx).(valueCond).nostop(:,1)';
        rtDistCDF.(valueCond).y_nostop{sessionIdx,1} =...
            valuedata_master.valueRTdist(sessionIdx).(valueCond).nostop(:,2)';    
        
        rtDistCDF.(valueCond).monkeyLabel{sessionIdx,1} = valuedata_master.monkey(sessionIdx);
        
        rtDistCDF.(valueCond).valueLabel{sessionIdx,1} = valueCond;
    end
end




for monkeyIdx = 1:length(monkeyList)
    
    monkeySessionIdx = []; monkeyArrayIdx = [];
    monkeySessionIdx = find(strcmp(valuedata_master.monkey, monkeyList{monkeyIdx})==1);
    monkeyArrayIdx = find(strcmp([rtDistCDF.lo.monkeyLabel; rtDistCDF.hi.monkeyLabel],...
        monkeyList{monkeyIdx})==1);
    
    % Setup gramm parameters and data
    % Weibull averaged inhibition function
    valRTCDF_monkey(1,monkeyIdx)=...
        gramm('x',[rtDistCDF.lo.x_nostop(monkeySessionIdx);rtDistCDF.lo.x_noncanc(monkeySessionIdx)],... % Weibull fit between 1 and 600 ms
        'y',[rtDistCDF.lo.y_nostop(monkeySessionIdx);rtDistCDF.lo.y_noncanc(monkeySessionIdx)],...
        'color',[repmat({'No-stop'},length(monkeySessionIdx),1);...
        repmat({'Non-canc'},length(monkeySessionIdx),1)]);
    
    valRTCDF_monkey(2,monkeyIdx)=...
        gramm('x',[rtDistCDF.hi.x_nostop(monkeySessionIdx);rtDistCDF.hi.x_noncanc(monkeySessionIdx)],... % Weibull fit between 1 and 600 ms
        'y',[rtDistCDF.hi.y_nostop(monkeySessionIdx);rtDistCDF.hi.y_noncanc(monkeySessionIdx)],...
        'color',[repmat({'No-stop'},length(monkeySessionIdx),1);...
        repmat({'Non-canc'},length(monkeySessionIdx),1)]);
        
    
    
    valRTCDF_monkey(1,monkeyIdx).geom_line('alpha',0.2);
    valRTCDF_monkey(1,monkeyIdx).axe_property('XLim',[0 600]);
    valRTCDF_monkey(1,monkeyIdx).axe_property('YLim',[0 1]);
    
 
    valRTCDF_monkey(2,monkeyIdx).geom_line('alpha',0.2);
    valRTCDF_monkey(2,monkeyIdx).axe_property('XLim',[0 600]);
    valRTCDF_monkey(2,monkeyIdx).axe_property('YLim',[0 1]);
    
    valRTCDF_monkey(1,monkeyIdx).no_legend
    valRTCDF_monkey(2,monkeyIdx).no_legend
        
end

figure('Renderer', 'painters', 'Position', [100 100 1200 500]);
valRTCDF_monkey.draw();