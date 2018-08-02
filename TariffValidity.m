function [TariffOK,Msg]=TariffValidity(MyTariff)
% for cheking all user input data if they are correct
       
TariffOK=1;
            
            PossibleHour=[0:24];
        PossibleMin=[0 30];
Msg='';
try
if MyTariff.Parameters.Daily.Value<0
    
    Msg='Daily Charge cannot be negetive! Please try again!';
TariffOK=0;    
end
end
try
if MyTariff.Parameters.Energy.Value<0
    
    Msg='Energy Charge cannot be negetive! Please try again!';
    TariffOK=0;
    
end
end

switch MyTariff.Type
    
    case 'Flat Rate'
        if  MyTariff.Parameters.Other.Value<0
            TariffOK=0;
            Msg='$/kWh should be positive!';
            
        end
        
    case 'Flat Rate Seasonal'

        for i=1:size(MyTariff.Parameters.Other,1)
           if  MyTariff.Parameters.Other.Rate(i)<0
            TariffOK=0;
            Msg='$/kWh should be positive!';
        break
           end 
        end
        
    case 'Block Quarterly'
         
        if numel(find(sign(diff(MyTariff.Parameters.Other.HighBound(:,1)))<=0))>0 ||numel(find(MyTariff.Parameters.Other.HighBound(:,1)<=0))>0
            
            TariffOK=0;
            Msg='Block usage bounds should be Postive and incremental';
            %
        elseif MyTariff.Parameters.Other.HighBound(end,1)~=inf
            TariffOK=0;
            Msg='Last block usage bound should be Inf';
        elseif numel(find(MyTariff.Parameters.Other.Value(:,1)<0))>0
            TariffOK=0;
            Msg='The values should be positive';
        end
        
    case 'Block Annual'
        
        if numel(find(sign(diff(MyTariff.Parameters.Other.HighBound(:,1)))<=0))>0 ||numel(find(MyTariff.Parameters.Other.HighBound(:,1)<=0))>0
            
            TariffOK=0;
            Msg='Block usage bounds should be positive and incremental';
            %
        elseif MyTariff.Parameters.Other.HighBound(end,1)~=inf
            TariffOK=0;
            Msg='Last block usage bound should be Inf';
             elseif numel(find(MyTariff.Parameters.Other.Value(:,1)<0))>0
            TariffOK=0;
            Msg='The values should be positive';
        end
        
        
    case 'TOU'
        MockTime=[datetime(2013,1,1,0,30,0):minutes(30):datetime(2014,1,1,0,0,0)]';
        TimeIndex=zeros(size(MockTime));
        
        DayNumber=weekday(TimeIndex);
        
        for T=1:size(MyTariff.Parameters.Other,1)
            if MyTariff.Parameters.Other.Weekday(T,1)==1
                TimeIndex(DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                    TimeIndex(DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
            end
            if MyTariff.Parameters.Other.Weekend(T,1)==1
                TimeIndex((DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                    TimeIndex((DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
            end
        end
        
        if numel(find(TimeIndex>1))>0
            TariffOK=0;
            
            Msg='You have covered some time stamps in multiple lines! Please correct the tariffs!';
            
        end
        
        for T=1:size(MyTariff.Parameters.Other,1)
            
            WWF(T,1)=MyTariff.Parameters.Other.Weekend(T,1)+MyTariff.Parameters.Other.Weekday(T,1);
            
        end
        
        if numel(find(WWF==0))>0
            TariffOK=0;
            
            Msg='In at least one line you did not select weekend or weekday!';
            
        end
        
        for T=1:size(MyTariff.Parameters.Other,1)
            WWF(T,1)=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))-(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1));
            
        end
        
        if numel(find(WWF>0))>0
            TariffOK=0;
            
            Msg='Start time should be before end time!';
        end
        
        
        if (numel(find(ismember(MyTariff.Parameters.Other{:,[4,6]},PossibleHour)<1))>0)...
            ||(numel(find(ismember(MyTariff.Parameters.Other{:,[5,7]},PossibleMin)<1))>0)...
            
         TariffOK=0;
            
            Msg='There is a problem in entering the hour or minute value';
        
        
        end
        
        
    case 'TOU Seasonal'
        
              MockTime=[datetime(2013,1,1,0,30,0):minutes(30):datetime(2014,1,1,0,0,0)]';
  
        TimeIndex=zeros(size(MockTime,1),1);
        
        DayNumber=weekday(TimeIndex);
        
        
        for T=1:size(MyTariff.Parameters.Other,1)
            if MyTariff.Parameters.Other.Weekday(T,1)==1
                if MyTariff.Parameters.Other.StartMonth(T,1)>MyTariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                else
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                end
            end
            
            if MyTariff.Parameters.Other.Weekend(T,1)==1
                if MyTariff.Parameters.Other.StartMonth(T,1)>MyTariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                else
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                    
                end
            end
        end
        
        
        
        if numel(find(TimeIndex>1))>0
            TariffOK=0;
            
            Msg='You have covered some time stamps in multiple lines! Please correct the tariffs!';
            
        end
        for T=1:size(MyTariff.Parameters.Other,1)
            
            WWF(T,1)=MyTariff.Parameters.Other.Weekend(T,1)+MyTariff.Parameters.Other.Weekday(T,1);
            
        end
        
        if numel(find(WWF==0))>0
            TariffOK=0;
            
            Msg='In at least one line you did not select weekend or weekday!';
            
        end
        
        for T=1:size(MyTariff.Parameters.Other,1)
            WWF(T,1)=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))-(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1));
            
        end
        
        if numel(find(WWF>0))>0
            TariffOK=0;
            
            Msg='Start time should be before end time!';
        end
        
         if (numel(find(ismember(MyTariff.Parameters.Other{:,[4,6]},PossibleHour)<1))>0)...
            ||(numel(find(ismember(MyTariff.Parameters.Other{:,[5,7]},PossibleMin)<1))>0)...
            
         TariffOK=0;
            
            Msg='There is a problem in entering the hour or minute value';
        
        
         end
        
         
    case 'Demand Charge'
        
         MockTime=[datetime(2013,1,1,0,30,0):minutes(30):datetime(2014,1,1,0,0,0)]';
  
        TimeIndex=zeros(size(MockTime,1),1);
%         IndexMonth=zeros(1,12);
                DayNumber=weekday(TimeIndex);

        
        for T=1:size(MyTariff.Parameters.Other,1)
            if MyTariff.Parameters.Other.Weekday(T,1)==1
                if MyTariff.Parameters.Other.StartMonth(T,1)>MyTariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                else
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&DayNumber>1&DayNumber<7&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                end
            end
            
            if MyTariff.Parameters.Other.Weekend(T,1)==1
                if MyTariff.Parameters.Other.StartMonth(T,1)>MyTariff.Parameters.Other.EndMonth(T,1)
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)|MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                else
                    TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)=...
                        TimeIndex((MockTime.Month>=MyTariff.Parameters.Other.StartMonth(T,1)&MockTime.Month<=MyTariff.Parameters.Other.EndMonth(T,1))&(DayNumber==1|DayNumber==7)&(60*MockTime.Hour+MockTime.Minute)>=(60*MyTariff.Parameters.Other.StartHour(T,1)+MyTariff.Parameters.Other.StartMin(T,1))&(60*MockTime.Hour+MockTime.Minute)<(60*MyTariff.Parameters.Other.EndHour(T,1)+MyTariff.Parameters.Other.EndMin(T,1)),1)+1;
                    
                end
            end
        end
        if numel(find(TimeIndex>1))>0
            TariffOK=0;
            
            Msg='You have covered some time stamps in multiple lines! Please correct the tariffs!';
            
        end
        
                
        for T=1:size(MyTariff.Parameters.Other,1)
            
            WWF(T,1)=MyTariff.Parameters.Other.Weekend(T,1)+MyTariff.Parameters.Other.Weekday(T,1);
            
        end
        
        if numel(find(WWF==0))>0
            TariffOK=0;
            
            Msg='In at least one line you did not select weekend or weekday!';
            
        end
        
end
end