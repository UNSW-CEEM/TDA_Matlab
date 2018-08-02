function [ Bill,Status ] = BillCalc( Tariff,LoadData,Type)

% This function is for caluclating Annual bill based on any tariff

% updated on 24 November 2017
% n.haghdadi@unsw.edu.au

% Inputs:

% - TariffDetail: has the name of tariff as well as parameters needed for
% calculation


% - LoadData: is a table with one TimeStamp column and one Load column which
% can have multiple columns of different homes all in **kWh**
% - and one NetworkLoad column which has the network load (kWh) it's used
% for peak time, etc..
% The network load is only used for finding the times of the network peak
% so the absolute values are not that important. 
% Type: reserved for further works

% Outputs:

% - Bill: is total annual bill for each home in $
% - Status: if everything was OK it's empty otherwise it has the error message


LoadData.Load(isnan(LoadData.Load))=0;
LoadData.Load(LoadData.Load<0)=0;
% for unitised bill:
 BaseLoad=0.5*ones(size(LoadData.TimeStamp,1),1);

if nargin<3
    Type='ordinary';
end


switch Tariff.Type
% The followings are for calculating the bill based on the tariff parameters.    
    case 'Block Quarterly'
        % Daily component
        Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));
        % Bounds for quarters
        AllBounds=Tariff.Parameters.Other.HighBound;
        AllBounds=[0;AllBounds];
        for i=2:size(AllBounds,1)-1
            AllBoundsCost(i,1)=(AllBounds(i,1)-AllBounds(i-1,1))*Tariff.Parameters.Other.Value(i-1,1);
        end
        
        AllBoundsCostCS=cumsum(AllBoundsCost);
        % base load for calculating unitised bill        
        BaseLoad=0.5*ones(size(LoadData.TimeStamp,1),1);
                
        for Q=1:4
            AllUsage(Q,:)=nansum(LoadData.Load(floor((LoadData.TimeStamp.Month-1)/3)==Q-1,:),1);
            AllUsage_B(Q,1)=nansum(BaseLoad(floor((LoadData.TimeStamp.Month-1)/3)==Q-1,:),1);
            for i=1:size(AllBounds,1)-1
                UsageCost(Q,AllUsage(Q,:)>AllBounds(i)&AllUsage(Q,:)<=AllBounds(i+1))=Tariff.Parameters.Other.Value(i,1)*(AllUsage(Q,AllUsage(Q,:)>AllBounds(i)&AllUsage(Q,:)<=AllBounds(i+1))-AllBounds(i,1))+AllBoundsCostCS(i,1);
                UsageCost_B(Q,AllUsage_B(Q,:)>AllBounds(i)&AllUsage_B(Q,:)<=AllBounds(i+1))=Tariff.Parameters.Other.Value(i,1)*(AllUsage_B(Q,AllUsage_B(Q,:)>AllBounds(i)&AllUsage_B(Q,:)<=AllBounds(i+1))-AllBounds(i,1))+AllBoundsCostCS(i,1);
            end
        end
%         
        if numel(find(sign(diff(AllBounds))<1))|| numel(find(AllBounds<0))
            Status='Usage block bounds should be positive and incremental.';
            Bill='';
        elseif Tariff.Parameters.Daily.Value<0
            Status='Daily charge should be positive.';
            Bill='';
        else
            Status='';
            Bill.Daily=repmat(Daily,1,size(LoadData.Load,2));
            Bill.Usage=sum(UsageCost,1);
            Bill.Usage_Q1=UsageCost(1,:);
            Bill.Usage_Q2=UsageCost(2,:);
            Bill.Usage_Q3=UsageCost(3,:);
            Bill.Usage_Q4=UsageCost(4,:);
            Bill.Total=Daily+sum(UsageCost,1);
            Bill.Unitised=Bill.Total/(Daily+sum(UsageCost_B));
            Bill.Components.Value=[Bill.Daily;Bill.Usage_Q1;Bill.Usage_Q2;Bill.Usage_Q3; Bill.Usage_Q4];
            Bill.Components.Names={'Daily';'Usage_Q1';'Usage_Q2';'Usage_Q3';'Usage_Q4'};
        end
        
    case 'Block Annual'
        
        Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));
        AllBounds=Tariff.Parameters.Other.HighBound;
        AllBounds=[0;AllBounds];
        clear AllUsage UsageCost AllBoundsCost Bill
        AllUsage(1,:)=nansum(LoadData.Load,1);
        AllUsage_B(1,1)=nansum(BaseLoad,1);

        for i=2:size(AllBounds,1)-1
            AllBoundsCost(i,1)=(AllBounds(i,1)-AllBounds(i-1,1))*Tariff.Parameters.Other.Value(i-1,1);
        end
        
        AllBoundsCostCS=cumsum(AllBoundsCost);
        
        for i=1:size(AllBounds,1)-1
            UsageCost(1,AllUsage(1,:)>AllBounds(i)&AllUsage(1,:)<=AllBounds(i+1))=Tariff.Parameters.Other.Value(i,1)*(AllUsage(1,AllUsage(1,:)>AllBounds(i)&AllUsage(1,:)<=AllBounds(i+1))-AllBounds(i,1))+AllBoundsCostCS(i,1);
            UsageCost_B(1,AllUsage_B(1,:)>AllBounds(i)&AllUsage_B(1,:)<=AllBounds(i+1))=Tariff.Parameters.Other.Value(i,1)*(AllUsage_B(1,AllUsage_B(1,:)>AllBounds(i)&AllUsage_B(1,:)<=AllBounds(i+1))-AllBounds(i,1))+AllBoundsCostCS(i,1);
       
        end
        
        if numel(find(sign(diff(AllBounds))<1))|| numel(find(AllBounds<0))
            Status='Usage block bounds should be positive and incremental.';
            Bill='';
        elseif Tariff.Parameters.Daily.Value<0
            Status='Daily charge should be positive.';
            Bill='';
            
        else
            Status='';
            
            Bill.Daily=repmat(Daily,1,size(LoadData.Load,2));
            Bill.Usage=sum(UsageCost,1);
            Bill.Total=Daily+sum(UsageCost,1);
            Bill.Unitised=Bill.Total./(Daily+sum(UsageCost_B));
            Bill.Components.Value=[Bill.Daily;Bill.Usage];
            Bill.Components.Names={'Daily';'Usage'};
         
        end
        
    case 'Flat Rate'
        
     Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));

        
        if Tariff.Parameters.Other.Value<0
            Status='Usage rate should be positive.';
            Bill='';
            
        else
            Status='';
            Bill.Daily=repmat(Daily,1,size(LoadData.Load,2));
            Bill.Energy=Tariff.Parameters.Other.Value*nansum(LoadData.Load,1);
            Bill.Total=Daily+Bill.Energy;
            
            Bill_B=Daily+Tariff.Parameters.Other.Value*nansum(BaseLoad,1);
            
            Bill.Components.Value=[Bill.Daily;Bill.Energy];
            
            Bill.Unitised= Bill.Total./Bill_B;
         Bill.Components.Names={'Daily';'Energy'};
        end
        
    case   'Flat Rate Seasonal'
        
           Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));

        if numel(find(sign(Tariff.Parameters.Other.Rate)<1))
            Status='Usage rate should be positive.';
            Bill='';
            
        else
               TimeIndex=zeros(size(LoadData.TimeStamp,1),1);
        TimeIndexCheck=zeros(size(LoadData.TimeStamp,1),1);
                       
            
              for T=1:size(Tariff.Parameters.Other,1)
                if Tariff.Parameters.Other.StartMonth(T,1)>Tariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1)),1)=T;
                    TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1)),1)=...
                        TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1)),1)+1;
                    
                else
                    TimeIndex((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1)),1)=T;
                    TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1)),1)=...
                        TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1)),1)+1;
                    
                end
            
              end
              
              
        if numel(find(sign([Tariff.Parameters.Daily.Value;[Tariff.Parameters.Other.Rate]])<1))
            Status='Some tariff components rates are not correct!';
            Bill='';
        elseif numel(find(TimeIndexCheck<1))>0
            Status='Tariff parameters are not sufficient for calculating bill!';
            Bill='';
        elseif  numel(find(TimeIndexCheck>1))>0
            Status='There is a problem in tariff parameters. Some time periods are included in more than one tariff components!';
            Bill='';
        else
            for T=1:size(Tariff.Parameters.Other,1)
                BillT(T,:)=Tariff.Parameters.Other.Rate(T,1)*nansum(LoadData.Load(TimeIndex==T,:));
                BillT_B(T,1)=Tariff.Parameters.Other.Rate(T,1)*nansum(BaseLoad(TimeIndex==T,:));
            end
            
            Bill.Daily=repmat(Daily,1,size(LoadData.Load,2));
            
            Bill.Energy=sum(BillT,1);
            Bill.Total=Daily+sum(BillT,1);
            Bill.Unitised=Bill.Total/(Daily+sum(BillT_B,1));
            Status='';
            
            Bill.Components.Value=[Bill.Daily;Bill.Energy];
         Bill.Components.Names={'Daily';'Energy'};
         
         
        end
        
           
        end
        
    case   'TOU'
        
        [DayNumber,~] = weekday(LoadData.TimeStamp);
        Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));
        
        TimeIndex=zeros(size(LoadData.TimeStamp,1),1);
        TimeIndexCheck=zeros(size(LoadData.TimeStamp,1),1);
        for T=1:size(Tariff.Parameters.Other,1)
            if Tariff.Parameters.Other.Weekday(T,1)==1
                TimeIndex(DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=T;
                TimeIndexCheck(DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=...
                    TimeIndexCheck(DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)+1;
                
            end
            if Tariff.Parameters.Other.Weekend(T,1)==1
                TimeIndex((DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=T;
                TimeIndexCheck((DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=...
                TimeIndexCheck((DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)+1;
                
            end
        end
        
        if numel(find(TimeIndexCheck<1))>0
            Status='Tariff parameters are not sufficient for calculating bill!';
            Bill='';
            
        elseif  numel(find(TimeIndexCheck>1))>0
            Status='There is a problem in tariff parameters. Some time periods are included in more than one tariff components!';
            Bill='';
            
        else
            for T=1:size(Tariff.Parameters.Other,1)
                BillT(T,:)=Tariff.Parameters.Other.Rate(T,1)*nansum(LoadData.Load(TimeIndex==T,:));
                BillT_B(T,1)=Tariff.Parameters.Other.Rate(T,1)*nansum(BaseLoad(TimeIndex==T,:));
            end
            Status='';
            Bill.Daily=repmat(Daily,1,size(LoadData.Load,2));
            Bill.TOU=sum(BillT,1);
            Bill.Total=Daily+sum(BillT,1);
            Bill.Unitised=Bill.Total/(Daily+sum(BillT_B,1));
            Bill.Components.Value=[Bill.Daily;Bill.TOU];
         Bill.Components.Names={'Daily';'TOU'};
         
        end
        
        
    case   'TOU Seasonal'
        
        [DayNumber,~] = weekday(LoadData.TimeStamp);
        Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));
        
        TimeIndex=zeros(size(LoadData.TimeStamp,1),1);
        TimeIndexCheck=zeros(size(LoadData.TimeStamp,1),1);
        
        for T=1:size(Tariff.Parameters.Other,1)
            if Tariff.Parameters.Other.Weekday(T,1)==1
                if Tariff.Parameters.Other.StartMonth(T,1)>Tariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=T;
                    TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)+1;
                    
                else
                    TimeIndex((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=T;
                    TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)+1;
                    
                end
            end
            
            if Tariff.Parameters.Other.Weekend(T,1)==1
                if Tariff.Parameters.Other.StartMonth(T,1)>Tariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=T;
                    TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)|LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)+1;
                    
                else
                    TimeIndex((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=T;
                    TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndexCheck((LoadData.TimeStamp.Month>=Tariff.Parameters.Other.StartMonth(T,1)&LoadData.TimeStamp.Month<=Tariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*Tariff.Parameters.Other.StartHour(T,1)+Tariff.Parameters.Other.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*Tariff.Parameters.Other.EndHour(T,1)+Tariff.Parameters.Other.EndMin(T,1)),1)+1;
                    
                end
            end
        end
        
        
        if numel(find(sign([Tariff.Parameters.Daily.Value;[Tariff.Parameters.Other.Rate]])<1))
            Status='Some tariff components rates are not correct!';
            Bill='';
        elseif numel(find(TimeIndexCheck<1))>0
            Status='Tariff parameters are not sufficient for calculating bill!';
            Bill='';
        elseif  numel(find(TimeIndexCheck>1))>0
            Status='There is a problem in tariff parameters. Some time periods are included in more than one tariff components!';
            Bill='';
        else
            for T=1:size(Tariff.Parameters.Other,1)
                BillT(T,:)=Tariff.Parameters.Other.Rate(T,1)*nansum(LoadData.Load(TimeIndex==T,:));
                BillT_B(T,:)=Tariff.Parameters.Other.Rate(T,1)*nansum(BaseLoad(TimeIndex==T,:));
           
            end
            
            Bill.Daily=repmat(Daily,1,size(LoadData.Load,2));
            Bill.TOU=sum(BillT,1);
            Bill.Total=Daily+sum(BillT,1);
            Bill.Unitised=Bill.Total/(Daily+sum(BillT_B,1));
            
            
            Status='';
            
            Bill.Components.Value=[Bill.Daily;Bill.TOU];
         Bill.Components.Names={'Daily';'TOU'};
         
         
        end
        
    case 'Demand Charge'
        
        Daily=Tariff.Parameters.Daily.Value*numel(unique(floor(datenum(LoadData.TimeStamp))));

        [DayNumber,~] = weekday(LoadData.TimeStamp);

        LoadData.Load=[LoadData.Load,BaseLoad];

                TGs=unique(Tariff.Parameters.Other.TimeGroup);
                TimeIndex=zeros(size(LoadData.TimeStamp));
                TimeIndexCheck=zeros(size(LoadData.TimeStamp,1),1);
                clear Res
                for TT=1:size(TGs,1)
                    
                    NewPar=Tariff.Parameters.Other(Tariff.Parameters.Other.TimeGroup==TGs(TT,1),:);
                    DayAverage=NewPar.DayAverage(1,1); % Only one day average per timegroup can be aceepted
                    NetworkPeak=NewPar.NetworkPeak(1,1);
                    for T=1:size(NewPar,1)
                        
                        if NewPar.Weekday(T,1)==1
                            if NewPar.StartMonth(T,1)>NewPar.EndMonth(T,1)
                                TimeIndex((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)|LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=TT;
                                TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)|LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=...
                                    TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)|LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)+1;
                                
                            else
                                TimeIndex((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)&LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=TT;
                                TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)&LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=...
                                    TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)&LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)+1;
                                
                            end
                        end
                        
                        if NewPar.Weekend(T,1)==1
                            if NewPar.StartMonth(T,1)>NewPar.EndMonth(T,1)
                                TimeIndex((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)|LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=TT;
                                TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)|LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=...
                                    TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)|LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)+1;
                              
                            else
                                TimeIndex((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)&LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=TT;
                                TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)&LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)=...
                                    TimeIndexCheck((LoadData.TimeStamp.Month>=NewPar.StartMonth(T,1)&LoadData.TimeStamp.Month<=NewPar.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)>=(60*NewPar.StartHour(T,1)+NewPar.StartMin(T,1))&(60*LoadData.TimeStamp.Hour+LoadData.TimeStamp.Minute)<(60*NewPar.EndHour(T,1)+NewPar.EndMin(T,1)),1)+1;
                                 
                            end
                        end
                    end
                
                    
                  DemandWindowTSNo= NewPar.DemandWindowTSNo(1,1);
                  NumberofPeaks=NewPar.NumberofPeaks(1,1);
                   TL2=LoadData;
                        TL2.Load(TimeIndex~=TT,:)=nan;
                        TL2.NetworkLoad(TimeIndex~=TT,:)=nan;
                  
                        
                        MnList=unique(LoadData.TimeStamp.Month(TimeIndex==TT));
                    for Mn2=1:size(MnList,1)
                        Mn=MnList(Mn2);
                        clear TempDay UPD NPD
                       
                        TL3=TL2(TL2.TimeStamp.Month==Mn,:);
                        
                        if DayAverage
                            
                            if NetworkPeak
                                
                                for Dn=1:size(unique(TL3.TimeStamp.Day),1)
                                    [NPD(Dn,1),ind2]=nanmax(TL3.NetworkLoad(TL3.TimeStamp.Day==Dn,1));
                                    
                                    TempDay(Dn,:)=nanmean(TL3.Load(TL3.TimeStamp.Day==Dn,:));
                                end
                                TempDay(isnan(TempDay))=0;
                               NPD(isnan(NPD))=0;
                                [ind3,ind4]=sort(NPD,'descend'); 
                                 TempDay=TempDay(ind4,:);
                            else
                                for Dn=1:size(unique(TL3.TimeStamp.Day),1)
                                    TempDay(Dn,:)=nanmean(TL3.Load(TL3.TimeStamp.Day==Dn,:));
                                end
                                TempDay(isnan(TempDay))=0;
                                TempDay=sort(TempDay,'descend');
                            end
                        else
                            
                            if NetworkPeak
                                
                                for Dn=1:size(unique(TL3.TimeStamp.Day),1)
                                    [NPD(Dn,1),ind2]=nanmax(TL3.NetworkLoad(TL3.TimeStamp.Day==Dn,1));
                                    TL3_2=LoadData.Load(LoadData.TimeStamp.Month==Mn&LoadData.TimeStamp.Day==Dn,:);

                                    TempDay(Dn,:)=nanmean(TL3_2([ind2-DemandWindowTSNo+1:ind2],:),1);
                                end
                                TempDay(isnan(TempDay))=0;
                                NPD(isnan(NPD))=0;
                                [ind3,ind4]=sort(NPD,'descend');
                                TempDay=TempDay(ind4,:);

                            else
                               
                                for Dn=1:size(unique(TL3.TimeStamp.Day),1)
                                   [UPD(Dn,:),ind2]=nanmax(TL3.Load(TL3.TimeStamp.Day==Dn,:));
                                    TL3_3=LoadData.Load(LoadData.TimeStamp.Month==Mn&LoadData.TimeStamp.Day==Dn,:);
                                   TL3_4=TL3_3;
                                    for iDTS=2:DemandWindowTSNo
                                    TL3_4=TL3_4+[zeros(iDTS-1,size(TL3_3,2));TL3_3(1:end-iDTS+1,:)];
                                   end
                                   TL3_4=TL3_4/DemandWindowTSNo;
                                   TempDay(Dn,:)=TL3_4(sub2ind(size(TL3_4), ind2 ,   1:size(TL3_4,2)));
                                end
                                TempDay(isnan(TempDay))=0;
                                UPD(isnan(UPD))=0;
                                [ind3,ind4]=sort(UPD,'descend');
                                ind5=ind4+repmat([0:size(TempDay,1):size(TempDay,1)*size(TempDay,2)-1],size(TempDay,1),1);
                              TempDay=TempDay(ind5);
                                
                            end
                               
                           end
                         DemkW=2*nanmean(TempDay(1:NumberofPeaks,:),1);  %kW
                         DemkW(DemkW<NewPar.MinDemandkW(1,1))=NewPar.MinDemandkW(1,1);
                         
                         DemCost=NewPar.Rate(1,1)*DemkW;
                         if  numel(strmatch('MinDemandCharge',NewPar.Properties.VariableNames))
                             DemCost(DemCost<NewPar.MinDemandCharge(1,1))=NewPar.MinDemandCharge(1,1);
                         end
                      Res{Mn,TT}=DemCost;  
                    end    
                       

                end
                FinalDemCost=zeros(1,size(LoadData.Load,2));
                for TT=1:size(TGs,1)
                    for Mn=1:12
                        try
                   FinalDemCost=FinalDemCost+ Res{Mn,TT};
                        end
                    end
                end
                
        Ener_AnyTime=Tariff.Parameters.Energy.Value(1,1)*nansum(LoadData.Load);
        Status='';
        Bill.Daily=repmat(Daily,1,size(LoadData.Load,2)-1);
        Bill.Energy=Ener_AnyTime(1,1:end-1);
        Bill.CapacityCharge=FinalDemCost(1,1:end-1);
        Bill.Total=Bill.Daily+Bill.Energy+Bill.CapacityCharge;
        Bill.Unitised=Bill.Total./(Daily+Ener_AnyTime(end)+FinalDemCost(end));
        
        Bill.Components.Value=[Bill.Daily;Bill.Energy;Bill.CapacityCharge];
        Bill.Components.Names={'Daily';'Energy';'CapacityCharge'};
         
  
end

end

