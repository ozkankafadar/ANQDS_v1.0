[num_w,txt_w,raw_data] = xlsread('\Bin\Stations.xlsx') ;
stations=cell2table(raw_data);
sta_list=[];
station_list=[];
event_list=[];

station_list{1,1}='AKCA';
station_list{2,1}='KAHM';
station_list{3,1}='NARI';
station_list{4,1}='DBOC';
station_list{5,1}='DBAD';
station_list{6,1}='DDEM';
station_list{7,1}='GEYV';
station_list{8,1}='HISA';
station_list{9,1}='KAND';
station_list{10,1}='SAHE';
station_list{11,1}='SUSU';

event_list{1,1}='06.06.2019 08:39:13';
event_list{1,2}=37.6656;
event_list{1,3}=37.4463;

event_list{2,1}='12.07.2019 12:06:20';
event_list{2,2}=40.6455;
event_list{2,3}=30.6455;

event_list{3,1}='17.10.2019 09:17:45';
event_list{3,2}=41.2293;
event_list{3,3}=41.6681;

sta_list=cell2table(station_list);

[station_cnt un_var]=size(stations);
station_array1={};
station_array2={};
event_array3={};
lat1=[];
lon1=[];
lat2=[];
lon2=[];
lat3=[];
lon3=[];
p1=1;
p2=1;

for jk=2:station_cnt
   
   %out=[];
   %out=stations(ismember(stations.raw_data1,upper(char(station_list{:}))),:);       
   toy=0;
   for jj=1:11
    stat1= char(stations{jk,1});
    stat2= char(sta_list{jj,1});
    if strcmp(stat1,stat2)
        toy=1;
        break
    end;
   end;
   
   if toy==0
   station_array1{p1}=char(stations{jk,1});
   lat1(p1) = cell2mat(stations{jk,2});
   lon1(p1) = cell2mat(stations{jk,3});
   p1=p1+1;
   end;
   if toy==1
   station_array2{p2}=char(stations{jk,1});
   lat2(p2) = cell2mat(stations{jk,2});
   lon2(p2) = cell2mat(stations{jk,3});
   p2=p2+1;
   end;
   
end

p3=1;
for jm=1:3
   event_array1{p3}=char(event_list{jm,1});
   lat3(p3) = event_list{jm,2};
   lon3(p3) = event_list{jm,3};
   p3=p3+1; 
end

wmmarker(lat3,lon3,'FeatureName',event_array1,'Description',' ','icon','images/daire.png','IconScale',1.2);%Stations
wmmarker(lat1,lon1,'FeatureName',station_array1,'Description',' ','icon','images/ucgen.png','IconScale',0.4);%Stations
wmmarker(lat2,lon2,'FeatureName',station_array2,'Description',' ','icon','images/ucgen2.png','IconScale',0.4);%Stations

