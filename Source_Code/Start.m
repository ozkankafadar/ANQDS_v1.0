function varargout = Start(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Start_OpeningFcn, ...
                   'gui_OutputFcn',  @Start_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function Start_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

set(handles.axes1,'visible','off');
set(handles.axes2,'visible','off');
set(handles.axes3,'visible','off');

global lat0;
global lon0;

lat0=[];
lon0=[];

function varargout = Start_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

global stations;
global blasting_fields;

[num_w,txt_w,raw_data] = xlsread(strcat(GetExecutableFolder(),'\Bin\Stations.xlsx')) ;
stations=cell2table(raw_data);
clear raw_data;
clear num_w;
clear txt_w;

[num_bf,txt_bf,raw_data] = xlsread(strcat(GetExecutableFolder(),'\Bin\Blasting_Fields.xlsx')) ;
blasting_fields=cell2table(raw_data);
clear raw_data;
clear num_bf;
clear txt_bf;

WindowAPI(gcf, 'maximize');

function Load_Button_Callback(hObject, eventdata, handles)

global results;

global counter;

global z_comp;
global n_comp;
global e_comp;

global t;
global dt;

global z_comp_temp;
global n_comp_temp;
global e_comp_temp;

global z_comp_filt_1;
global z_comp_filt_2;

global station_name
global component_name
global event_time

global P_point;
global S_point;
global F_point;

global station_list;

global plot_z_comp;
global plot_n_comp;
global plot_e_comp;

global guide_line1;
global guide_line2;
global guide_line3;
global guide_line4;
global guide_line5;
global guide_line6;

global lat0;
global lon0;
global event0;

global prg_bar;
global Close_chk;


if(counter>0)
    selection = questdlg('Are you sure you want to load a new event?',...
                     'Load',...
                     'Yes','No','No');
    switch selection,
    case 'Yes'    
        uiresume;
    case 'No'     
        return
    end
end;

%%%%%%reset global variables%%%%%
counter=0;

z_comp=[];
n_comp=[];
e_comp=[];

t=[];
dt=0;

z_comp_temp=[];
n_comp_temp=[];
e_comp_temp=[];

z_comp_filt_1=[];
z_comp_filt_2=[];

results=[];

station_name='';
component_name='';
event_time='';
P_point=[];
S_point=[];
F_point=[];

station_list='';
plot_z_comp='';
plot_n_comp='';
plot_e_comp='';

guide_line1='';
guide_line2='';
guide_line3='';
guide_line4='';
guide_line5='';
guide_line6='';

lat0=[];
lon0=[];
event0='';

Close_chk=0;

%%%%%%Clear Axes%%%%%%
cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);

selpath = uigetdir(GetExecutableFolder(),'Select the Event Folder');
if selpath>0
    
prg_bar = waitbar(0,'Loading...');
WindowAPI(gcf, 'TopMost');

fileList=dir(fullfile(selpath, '*.SAC'));    
count=length(fileList);

waitbar(0.33,prg_bar,'Loading...');

outfull=regexp(selpath,'\','split');
set(handles.Text_Folder_Name,'string',outfull{end});
delete('Temp_files\*')

waitbar(0.66,prg_bar,'Loading...');

lat0=[];
lon0=[];

%Read info.txt
fileinfostr=fullfile(selpath, 'info.txt');
if exist(fileinfostr, 'file') == 2
     infostr=fileread(fileinfostr);
     infostr2=regexp(infostr,'\t','split');
     event0=infostr2{1};
     lat0=str2double(infostr2{3});
     lon0=str2double(infostr2{4});
end

waitbar(1,prg_bar,'Loading...');
close(prg_bar);

count_z_comp=0;
if count>0
%Find the number of the stations with Z component
    z_comp_station_list=[];
    counter=1;
    for indis=1:count
        filename=char(fileList(indis).name);
        filename_array=regexp(filename,'_','split');
        if char(filename_array{5})=='z.sac'
            z_comp_station_list{counter}=filename_array{1};
            count_z_comp=count_z_comp+1;
            counter=counter+1;
        end        
    end
    
    total=length(fileList);
    
    if count_z_comp>0
        set(handles.Text_Station_Count,'string',num2str(count_z_comp));
        set(handles.Next_Event_Button,'enable','on');
    end
    
    %Sort
    station_list=sort(unique(z_comp_station_list));    
    station_list=station_list'; 
    
   set(handles.Reset_Selection_Button,'enable','on');
    
    [sl1 sl2]=size(station_list);
    counter=1;    
    while counter<=sl1
      
        if counter>1
            set(handles.Prior_Event_Button,'enable','on');
        else
           set(handles.Prior_Event_Button,'enable','off'); 
        end
        
        P_point=[];
        S_point=[];
        F_point=[];
        
        set(handles.P_Selection_Button,'enable','on');
        set(handles.S_Selection_Button,'enable','off');
        set(handles.F_Selection_Button,'enable','off');
        set(handles.Start_Analysis_Button,'visible','off');
        
        set(handles.Apply_Filter_Button,'enable','on');
        set(handles.Reset_Filter_Button,'enable','on');
        
        set(handles.Text_Station_Name,'string',upper(num2str(station_list{counter})));
        
        filename_array='';
        
        k=1;
        for j=1:total
            filename_array=regexp(char(fileList(j).name),'_','split'); 
            if isequal(filename_array{1},station_list{counter})
                fileList2{k}=char(fileList(j).name);
                k=k+1;
            end
        end
        
        filename_array='';
        fileList2=fileList2';
        
        for j=1:length(fileList2)
            filename_array=regexp(char(fileList2{j}),'_','split'); 
            if filename_array{5}=='z.sac'
                f=fullfile(selpath,fileList2{j});
                [z_comp,T0,H]=Read_SAC(f);
                z_comp_temp=z_comp;
                z_comp_temp=z_comp_temp-mean(z_comp_temp);
                z_comp_temp=detrend(z_comp_temp); %remove the linear trend
                dt=H.DELTA;
                station_name=H.KSTNM;
                component_name=H.KCMPNM;
                event_time=H.KZTIME;
                
                N=length(z_comp_temp);
                fn=0.5/(dt);
                t=0:dt:(N-1)*dt;
                wn=[5/fn 10/fn];
                [b,a]=butter(3,wn,'bandpass');
                z_comp_filt_1=filter(b,a,z_comp_temp);%apply the filter (5-10Hz)
                wn1=[1/fn 5/fn];
                [b1,a1]=butter(3,wn1,'bandpass');
                z_comp_filt_2=filter(b1,a1,z_comp_temp);%apply the filter (1-5Hz)
                
                axes(handles.axes1);
                plot(t,z_comp_temp,'-k');
                xlabel('Time(s)');
                ylabel('Amplitude');
                set(gca,'FontSize',7);
                set(gca,'color',[0.85 0.9 0.77])               
                zoom on
                set(handles.P_Selection_Button,'enable','on');
                
                set(handles.messageLabel,'string','Please, click the "P" button and pick the P-wave arrival time on the Z-component');
                
                [xx yy]=size(station_list);
                if yy>1
                for e=1:xx
                    if isequal(station_list{e,1},station_name)
                        s1=station_list{e,2};
                        s2=station_list{e,3};
                        s3=station_list{e,4};
                        
                        if ~isempty(s1) 
                            P_point=s1;
                            set(handles.S_Selection_Button,'enable','on');
                            
                            axes(handles.axes1);
                            getLim = ylim(handles.axes1);
                            plot_z_comp=line([s1;s1],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');
                            axes(handles.axes2);
                            getLim = ylim(handles.axes2);
                            guide_line1=line([s1;s1],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');
                            axes(handles.axes3);
                            getLim = ylim(handles.axes3);
                            guide_line2=line([s1;s1],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');

                        else
                            set(handles.S_Selection_Button,'enable','off');
                            set(handles.F_Selection_Button,'enable','off');
                        end
                        if ~isempty(s2) 
                            S_point=s2;
                            set(handles.F_Selection_Button,'enable','on');
                            axes(handles.axes1);
                            getLim = ylim(handles.axes1);
                            plot_n_comp=line([s2;s2],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');
                            axes(handles.axes2);
                            getLim = ylim(handles.axes2);
                            guide_line3=line([s2;s2],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');
                            axes(handles.axes3);
                            getLim = ylim(handles.axes3);
                            guide_line4=line([s2;s2],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');

                        else
                            set(handles.F_Selection_Button,'enable','off');
                        end
                        if ~isempty(s3) 
                            F_point=s3;
                            axes(handles.axes1);
                            getLim = ylim(handles.axes1);
                            plot_e_comp=line([s3;s3],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');
                            axes(handles.axes2);
                            getLim = ylim(handles.axes2);
                            guide_line5=line([s3;s3],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');
                            axes(handles.axes3);
                            getLim = ylim(handles.axes3);
                            guide_line6=line([s3;s3],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');

                        end
                        if ~isempty(s1) && ~isempty(s2) && ~isempty(s3)
                                set(handles.Start_Analysis_Button,'visible','on');
                            else
                                set(handles.Start_Analysis_Button,'visible','off');
                        end
                    end
                    if isequal(station_list{e,1},lower(station_name))
                        s1=station_list{e,2};
                        s2=station_list{e,3};
                        s3=station_list{e,4};

                        if ~isempty(s1) 
                            P_point=s1;
                            set(handles.S_Selection_Button,'enable','on');
                            axes(handles.axes1);
                            getLim = ylim(handles.axes1);
                            plot_z_comp=line([s1;s1],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');
                            axes(handles.axes2);
                            getLim = ylim(handles.axes2);
                            guide_line1=line([s1;s1],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');
                            axes(handles.axes3);
                            getLim = ylim(handles.axes3);
                            guide_line2=line([s1;s1],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');
                        else
                            set(handles.S_Selection_Button,'enable','off');
                            set(handles.F_Selection_Button,'enable','off');
                        end
                        if ~isempty(s2) 
                            S_point=s2;
                            set(handles.F_Selection_Button,'enable','on');
                            axes(handles.axes1);
                            getLim = ylim(handles.axes1);
                            plot_n_comp=line([s2;s2],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');
                            axes(handles.axes2);
                            getLim = ylim(handles.axes2);
                            guide_line3=line([s2;s2],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');
                            axes(handles.axes3);
                            getLim = ylim(handles.axes3);
                            guide_line4=line([s2;s2],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');
                        else
                            set(handles.F_Selection_Button,'enable','off');
                        end
                        if ~isempty(s3) 
                            F_point=s3;
                            axes(handles.axes1);
                            getLim = ylim(handles.axes1);
                            plot_e_comp=line([s3;s3],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');
                            axes(handles.axes2);
                            getLim = ylim(handles.axes2);
                            guide_line5=line([s3;s3],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');
                            axes(handles.axes3);
                            getLim = ylim(handles.axes3);
                            guide_line6=line([s3;s3],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');

                        end
                        if ~isempty(s1) && ~isempty(s2) && ~isempty(s3)
                            set(handles.Start_Analysis_Button,'visible','on');
                            set(handles.messageLabel,'string','Start Analysis');
                        else
                            set(handles.Start_Analysis_Button,'visible','off');
                        end
                    end                           
                end
                end
            else
            end        
            if filename_array{5}=='n.sac'
                f=fullfile(selpath,fileList2{j});
                [n_comp,T0,H]=Read_SAC(f);
                n_comp_temp=n_comp;
                n_comp_temp=n_comp_temp-mean(n_comp_temp);
                n_comp_temp=detrend(n_comp_temp); %removing a linear trend from the vector
                
                dt=H.DELTA;
                N=length(n_comp_temp);
                t=0:dt:(N-1)*dt;

                axes(handles.axes2);
                plot(t,n_comp_temp,'-k');
                xlabel('Time(s)');
                ylabel('Amplitude');
                set(gca,'FontSize',7);
                set(gca,'color',[0.85 0.9 0.77])
                zoom on;
            else
            end
            if filename_array{5}=='e.sac'
                f=fullfile(selpath,fileList2{j});
                [e_comp,T0,H]=Read_SAC(f);
                e_comp_temp=e_comp;
                e_comp_temp=e_comp_temp-mean(e_comp_temp);  %eksene oturtma
                e_comp_temp=detrend(e_comp_temp); %removing a linear trend from a vector
                
                dt=H.DELTA;
                N=length(e_comp_temp);
                t=0:dt:(N-1)*dt;

                axes(handles.axes3);
                plot(t,e_comp_temp,'-k');
                xlabel('Time(s)');
                ylabel('Amplitude');
                set(gca,'FontSize',7);
                set(gca,'color',[0.85 0.9 0.77])
                zoom on;  
            else
            end
        end       
        
        if counter==sl1
            set(handles.Next_Event_Button,'enable','off');
        end
        
        if counter<sl1
            set(handles.Next_Event_Button,'enable','on');
        end
        
        counter=counter+1;
        
        ax=handles.axes1;
        bx=handles.axes2;
        cx=handles.axes3;
        linkaxes([ax bx cx],'x');
        
        uiwait;
        
        if Close_chk==1
            break;
        end
    end
else
        set(handles.Next_Event_Button,'enable','off');
end
end

function P_Selection_Button_Callback(hObject, eventdata, handles)

global z_comp_temp;

global P_point;
global S_point;
global F_point;

global plot_z_comp;
global station_list;
global station_name;

global guide_line1;
global guide_line2;

ax=handles.axes1;
bx=handles.axes2;
cx=handles.axes3;
linkaxes([ax bx cx],'off');
        
P_point=ginput(1);
set(handles.S_Selection_Button,'enable','on');

[station_cnt,~]=size(station_list);
for i=1:station_cnt
    if isequal(station_list{i},station_name)
        station_list{i,2}=P_point(1);
    end
    if isequal(station_list{i},lower(station_name))
        station_list{i,2}=P_point(1);
    end
end

getLim = ylim(handles.axes1);
axes(handles.axes1);
plot_z_comp=line([P_point(1);P_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');

getLim = ylim(handles.axes2);
axes(handles.axes2);
guide_line1=line([P_point(1);P_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');

getLim = ylim(handles.axes3);
axes(handles.axes3);
guide_line2=line([P_point(1);P_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','red');

set(handles.messageLabel,'string','Please, click the "S" button and pick the S-wave arrival time on the N-component');

zoom on;

if ~isempty(P_point) && ~isempty(S_point) && ~isempty(F_point)
    set(handles.Start_Analysis_Button,'visible','on');
end

ax=handles.axes1;
bx=handles.axes2;
cx=handles.axes3;
linkaxes([ax bx cx],'x');

function S_Selection_Button_Callback(hObject, eventdata, handles)

global z_comp_temp;

global P_point;
global S_point;
global F_point;

global plot_n_comp;
global station_list;
global station_name;

global guide_line3;
global guide_line4;

ax=handles.axes1;
bx=handles.axes2;
cx=handles.axes3;
linkaxes([ax bx cx],'off');
        
S_point=ginput(1);

[station_cnt,~]=size(station_list);
for i=1:station_cnt
    if isequal(station_list{i},station_name)
        station_list{i,3}=S_point(1);
    end
    if isequal(station_list{i},lower(station_name))
        station_list{i,3}=S_point(1);
    end
end

getLim = ylim(handles.axes1);
axes(handles.axes1);
plot_n_comp=line([S_point(1);S_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');

getLim = ylim(handles.axes2);
axes(handles.axes2);
guide_line3=line([S_point(1);S_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');

getLim = ylim(handles.axes3);
axes(handles.axes3);
guide_line4=line([S_point(1);S_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','blue');


set(handles.messageLabel,'string','Please, click the "F" button and pick the finish time of the signal on the Z-component');

set(handles.F_Selection_Button,'enable','on');
zoom on;
if ~isempty(P_point) && ~isempty(S_point) && ~isempty(F_point)
    set(handles.Start_Analysis_Button,'visible','on');
end

ax=handles.axes1;
bx=handles.axes2;
cx=handles.axes3;
linkaxes([ax bx cx],'x');

function F_Selection_Button_Callback(hObject, eventdata, handles)

global z_comp_temp;

global P_point;
global S_point;
global F_point;

global plot_e_comp;
global station_list;
global station_name;

global guide_line5;
global guide_line6;

ax=handles.axes1;
bx=handles.axes2;
cx=handles.axes3;
linkaxes([ax bx cx],'off');

F_point=ginput(1);

[station_cnt,~]=size(station_list);
for i=1:station_cnt
    if isequal(station_list{i},station_name)
        station_list{i,4}=F_point(1);
    end
    if isequal(station_list{i},lower(station_name))
        station_list{i,4}=F_point(1);
    end
end

getLim = ylim(handles.axes1);
axes(handles.axes1);
plot_e_comp=line([F_point(1);F_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');

getLim = ylim(handles.axes2);
axes(handles.axes2);
guide_line5=line([F_point(1);F_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');

getLim = ylim(handles.axes3);
axes(handles.axes3);
guide_line6=line([F_point(1);F_point(1)],[getLim(1);getLim(2)],'linestyle','--','linewidth',2,'Color','magenta');

set(handles.messageLabel,'string','Start Analysis...');

zoom off;
if ~isempty(P_point) && ~isempty(S_point) && ~isempty(F_point)
    set(handles.Start_Analysis_Button,'visible','on');
    set(handles.Start_Analysis_Button,'enable','on');
    set(handles.P_Selection_Button,'enable','off');
    set(handles.S_Selection_Button,'enable','off');
    set(handles.F_Selection_Button,'enable','off');
end

ax=handles.axes1;
bx=handles.axes2;
cx=handles.axes3;
linkaxes([ax bx cx],'x');
zoom on;

function Reset_Selection_Button_Callback(hObject, eventdata, handles)
global plot_z_comp;
global plot_n_comp;
global plot_e_comp;
global results;
global station_name;

global guide_line1;
global guide_line2;
global guide_line3;
global guide_line4;
global guide_line5;
global guide_line6;

global P_point;
global S_point;
global F_point;

P_point=[];
S_point=[];
F_point=[];

if exist('plot_z_comp','var')
    delete(plot_z_comp);
end
if exist('plot_n_comp','var')
    delete(plot_n_comp);
end
if exist('plot_e_comp','var')
    delete(plot_e_comp);
end

if exist('guide_line1','var')
    delete(guide_line1);
end
if exist('guide_line2','var')
    delete(guide_line2);
end
if exist('guide_line3','var')
    delete(guide_line3);
end
if exist('guide_line4','var')
    delete(guide_line4);
end
if exist('guide_line5','var')
    delete(guide_line5);
end
if exist('guide_line6','var')
    delete(guide_line6);
end

[result_cnt ~]=size(results);
if result_cnt>0
    jg=0;
    for i=1:result_cnt
        data=results{i,1};
        if isequal(data,station_name)
            jg=i;
            break;
        end
    end
    
    if jg>0
        results(jg,:)=[];
    end
end

close(findall(0,'type','figure','name','Exec_Form'));

set(handles.P_Selection_Button,'enable','on');
set(handles.S_Selection_Button,'enable','off');
set(handles.F_Selection_Button,'enable','off');
set(handles.Start_Analysis_Button,'visible','off');

set(handles.messageLabel,'string','Please, click the "P" button and pick the P-wave arrival time on the Z-component');

function Apply_Filter_Button_Callback(hObject, eventdata, handles)

global guide_line1;
global guide_line2;
global guide_line3;
global guide_line4;
global guide_line5;
global guide_line6;

global z_comp;
global n_comp;
global e_comp;

global filtered_z_comp;
global filtered_n_comp;
global filtered_e_comp;

global dt;
global t;

global plot_z_comp;
global plot_n_comp;
global plot_e_comp;

global results;
global station_name;

cc1 = str2double(get(handles.Edit_Freq_Min,'string'));
cc2 = str2double(get(handles.Edit_Freq_Max,'string'));
%bandpass filter
if ~isempty(cc1) && ~isempty(cc2)
    fs=1/(dt);
    [b,a]=butter(2,[cc1 cc2]/(fs/2),'bandpass');
    
    filtered_z_comp=filter(b,a,z_comp); 
    filtered_n_comp=filter(b,a,n_comp); 
    filtered_e_comp=filter(b,a,e_comp);
    
    axes(handles.axes1);
    plot(t,filtered_z_comp,'-k');
    xlabel('Time(s)');
    ylabel('Amplitude');
    set(gca,'FontSize',7);
    set(gca,'color',[0.85 0.9 0.77])               
    zoom on
    
    axes(handles.axes2);
    plot(t,filtered_n_comp,'-k');
    xlabel('Time(s)');
    ylabel('Amplitude');
    set(gca,'FontSize',7);
    set(gca,'color',[0.85 0.9 0.77])               
    zoom on
    
    axes(handles.axes3);
    plot(t,filtered_e_comp,'-k');
    xlabel('Time(s)');
    ylabel('Amplitude');
    set(gca,'FontSize',7);
    set(gca,'color',[0.85 0.9 0.77])               
    zoom on

    if exist('plot_z_comp','var')
        delete(plot_z_comp);
    end
    if exist('plot_n_comp','var')
        delete(plot_n_comp);
    end
    if exist('plot_e_comp','var')
        delete(plot_e_comp);
    end

    if exist('guide_line1','var')
        delete(guide_line1);
    end
    if exist('guide_line2','var')
        delete(guide_line2);
    end
    if exist('guide_line3','var')
        delete(guide_line3);
    end
    if exist('guide_line4','var')
        delete(guide_line4);
    end
    if exist('guide_line5','var')
        delete(guide_line5);
    end
    if exist('guide_line6','var')
        delete(guide_line6);
    end

    [result_cnt, ~]=size(results);
    if result_cnt>0
        jg=0;
        for i=1:result_cnt
            data=results{i,1};
            if isequal(data,station_name)
                jg=i;
                break;
            end
        end
    
        if jg>0
            results(jg,:)=[];
        end
    end

close(findall(0,'type','figure','name','Exec_Form'));

set(handles.P_Selection_Button,'enable','on');
set(handles.S_Selection_Button,'enable','off');
set(handles.F_Selection_Button,'enable','off');
set(handles.Start_Analysis_Button,'visible','off');

set(handles.messageLabel,'string','Please, click the "P" button and pick the P-wave arrival time on the Z-component');
    
end

function Reset_Filter_Button_Callback(hObject, eventdata, handles)

global plot_z_comp;
global plot_n_comp;
global plot_e_comp;
global results;
global station_name;

global guide_line1;
global guide_line2;
global guide_line3;
global guide_line4;
global guide_line5;
global guide_line6;

global z_comp;
global n_comp;
global e_comp;

global t;

global P_point;
global S_point;
global F_point;

P_point=[];
S_point=[];
F_point=[];

w1=z_comp;
w1=w1-mean(w1);
w1=detrend(w1); %remove the linear trend

w2=n_comp;
w2=w2-mean(w2);
w2=detrend(w2); %remove the linear trend

w3=e_comp;
w3=w3-mean(w3);
w3=detrend(w3); %remove the linear trend

cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);

axes(handles.axes1);
plot(t,w1,'-k');    
xlabel('Time(s)');
ylabel('Amplitude');
set(gca,'FontSize',7);
set(gca,'color',[0.85 0.9 0.77])               

axes(handles.axes2);
plot(t,w2,'-k');
xlabel('Time(s)');
ylabel('Amplitude');
set(gca,'FontSize',7);
set(gca,'color',[0.85 0.9 0.77])

axes(handles.axes3);
plot(t,w3,'-k');
xlabel('Time(s)');
ylabel('Amplitude');
set(gca,'FontSize',7);
set(gca,'color',[0.85 0.9 0.77])

if exist('plot_z_comp','var')
    delete(plot_z_comp);
end
if exist('plot_n_comp','var')
    delete(plot_n_comp);
end
if exist('plot_e_comp','var')
    delete(plot_e_comp);
end

if exist('guide_line1','var')
    delete(guide_line1);
end
if exist('guide_line2','var')
    delete(guide_line2);
end
if exist('guide_line3','var')
    delete(guide_line3);
end
if exist('guide_line4','var')
    delete(guide_line4);
end
if exist('guide_line5','var')
    delete(guide_line5);
end
if exist('guide_line6','var')
    delete(guide_line6);
end

[result_cnt, ~]=size(results);
if result_cnt>0
    jg=0;
    for i=1:result_cnt
        data=results{i,1};
        if isequal(data,station_name)
            jg=i;
            break;
        end
    end
    
    if jg>0
        results(jg,:)=[];
    end
end

close(findall(0,'type','figure','name','Exec_Form'));

set(handles.P_Selection_Button,'enable','on');
set(handles.S_Selection_Button,'enable','off');
set(handles.F_Selection_Button,'enable','off');
set(handles.Start_Analysis_Button,'visible','off');

set(handles.messageLabel,'string','Please, click the "P" button and pick the P-wave arrival time on the Z-component');

function Start_Analysis_Button_Callback(hObject, eventdata, handles)

global button_id;%Start_Analysis_Button:2, Results_Button:1

global P_point;
global S_point;
global F_point;

global dt

global z_comp_temp;
global z_comp_filt_1;
global z_comp_filt_2;

global station_name
global component_name
global event_time

%global station_struct;
global station_list;
zoom reset;
hold off;

button_id=2;

set(handles.Start_Analysis_Button,'enable','off');

[C,SR,PMax,SMax,AmpRatio,Slog,Interval] = Amp_Comp_Ratios(P_point,S_point,F_point,z_comp_temp,z_comp_filt_1,z_comp_filt_2,dt );

for j=1:size(station_list,1)
    if isequal(station_name,upper(station_list{j}))
        station_list{j,5}=C;
        station_list{j,6}=SR;
        station_list{j,7}=PMax;
        station_list{j,8}=SMax;
        station_list{j,9}=AmpRatio;
        station_list{j,10}=Slog;
        station_list{j,11}=Interval;
        station_list{j,12}=component_name;
        station_list{j,13}=event_time;        
        station_list{j,14}=1;%Active station
    else
        station_list{j,14}=0;%Active station
    end
end

setappdata(0,'MainForm',station_list);
run Exec_Form;
set(handles.Results_Button,'enable','on');

function Results_Button_Callback(hObject, eventdata, handles)

global results;
global button_id;%Start_Analysis_Button:2, Results_Button:1

[result_cnt, ~]=size(results);
if result_cnt>0
    button_id=1;
    run Exec_Form;
end

function Show_Map_Button_Callback(hObject, eventdata, handles)

global stations;
global blasting_fields;
global station_list;

global lat0;
global lon0;
global event0;

[station_cnt, ~]=size(station_list);
station_array={};
lat=[];
lon=[];
p=1;
if station_cnt>0
for jk=1:station_cnt
   out=stations(ismember(stations.raw_data1,upper(char(station_list{jk}))),:);       
   if ~isempty(out)
      station_array{p}=char(out{1,1});
      lat(p) = cell2mat(out{1,2});
      lon(p) = cell2mat(out{1,3});
      p=p+1;
   end
end
  
wmmarker(lat,lon,'FeatureName',station_array,'Description',' ','icon','images/ucgen.png');%Stations
end

if ~isempty(lat0) && ~isempty(lon0)
   radius = 60000; 
   az = []; 
   e = wgs84Ellipsoid; 
   [lat,lon] = scircle1(lat0,lon0,radius,az,e);
   desc=strcat('<table><tr><td>Latitude:<td><td>',num2str(lat0),'</td></tr><tr><td>Longitude:<td><td>',num2str(lon0),'</td></tr></table>');
   wmline(lat,lon,'Color','red','OverlayName','10000 Meters')
   wmmarker(lat0,lon0,'FeatureName',event0,'Description',desc,'icon','images/daire.png','IconScale',2);%Event Location

   [station_cnt, ~]=size(blasting_fields);    
   lat=[];
   lon=[];
   p=1;
   for jk=2:station_cnt
      out=blasting_fields(jk,:);       
      if ~isempty(out)
         lony = cell2mat(out{1,2});
         laty = cell2mat(out{1,3});        
         arclen = deg2km(distance('gc',[laty,lony],[lat0,lon0]));
         if arclen<60
            lon(p)=lony;
            lat(p)=laty;
            p=p+1;
         end
      end
   end
wmmarker(lat,lon,'FeatureName',' ','Description','Blasting Area','icon','images/yildiz.png','IconScale',1);%Blasting Areas
end

function Next_Event_Button_Callback(hObject, eventdata, handles)
set(handles.Next_Event_Button,'enable','off');
cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);

uiresume;

function Prior_Event_Button_Callback(hObject, eventdata, handles)
global counter;
counter=counter-2;
set(handles.Prior_Event_Button,'enable','off');
cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);

uiresume;

function figure1_CloseRequestFcn(hObject, eventdata, handles)
global counter;
global Close_chk;
selection = questdlg('Are you sure you want to exit the program?',...
                     'Close',...
                     'Yes','No','Yes');
switch selection,
   case 'Yes'
     Close_chk=1;
     uiresume;
     delete('Temp_files\*')
     delete(hObject);
     counter=0;
     close all;
   case 'No'
     Close_chk=0;
     return
end

function executableFolder = GetExecutableFolder() 
	try
		if isdeployed 
			[~, result] = system('set PATH');
			executableFolder = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
		else
			executableFolder = pwd; 
		end 
	catch ME
		errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
			ME.stack(1).name, ME.stack(1).line, ME.message);
		uiwait(warndlg(errorMessage));
	end
	return;
