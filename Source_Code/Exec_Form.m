function varargout = Exec_Form(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Exec_Form_OpeningFcn, ...
                   'gui_OutputFcn',  @Exec_Form_OutputFcn, ...
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

function Exec_Form_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
movegui(gcf,'center');

function varargout = Exec_Form_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

cla(handles.axes1,'reset')
cla(handles.axes2,'reset')
cla(handles.axes3,'reset')
cla(handles.axes4,'reset')
cla(handles.axes5,'reset')
cla(handles.axes6,'reset')
cla(handles.axes7,'reset')

global process_status;

global button_id;%Start_Analysis_Button:2, Results_Button:1

global stations;
global z_comp;
global z_comp_temp;
global results;

global station_struct;
global station_list;

global dt;
global t;
global t2;

global P_point;
global S_point;
global F_point;

global station_no;
global data;

global operation;
global counter1;
global results_row_count;

global first_point;
global interval;
global nt;
global fn;
global nfft;
global tfr;

global freq;
global gsignal;
global idx;
global fc1;
global fcstr1;
global tx;
global ty;
global str;

process_status=0;

%Start Analysis
if button_id==2
process_status=1;
fdb2 = waitbar(0,'Analysis in progress, please wait ...');
WindowAPI(gcf, 'TopMost');

for j=1:size(station_list,1)
    if isequal(1,upper(station_list{j,14}))
        station_struct.C=station_list{j,5};
        station_struct.SR=station_list{j,6};
        station_struct.Pmax=station_list{j,7};
        station_struct.Smax=station_list{j,8};
        station_struct.ampratio=station_list{j,9};
        station_struct.Slog=station_list{j,10};
        station_struct.Interval=station_list{j,11};
        station_struct.Component=station_list{j,12};
        station_struct.Station=station_list{j,1};
        station_struct.Time=station_list{j,13};
    end;
end;

if ~isempty(station_struct)
station_name=upper(station_struct.Station);

%Station Weight Information
weights_array=stations(ismember(stations.raw_data1,station_name),:);
A_LDF=0;%Amplitude Linear Discrimination Function       
A_QDF=0;%Amplitude Quadratic Discrimination Function
C_LDF=0;%Complexity Linear Discrimination Function       
C_QDF=0;%Complexity Quadratic Discrimination Function
STFT=0;%Short Time Fourier Transform       
PS=0;%Power Spectrum

if ~isempty(weights_array)
    A_LDF=cell2mat(weights_array{1,5});       
    A_QDF=cell2mat(weights_array{1,6});
    C_LDF=cell2mat(weights_array{1,7});       
    C_QDF=cell2mat(weights_array{1,8});
    STFT=cell2mat(weights_array{1,9});       
    PS=cell2mat(weights_array{1,10});        
end

total_weights=A_LDF+A_QDF+C_LDF+C_QDF+STFT+PS;

A_LDF_percent=(A_LDF/total_weights)*100;       
A_QDF_percent=(A_QDF/total_weights)*100;
C_LDF_percent=(C_LDF/total_weights)*100;       
C_QDF_percent=(C_QDF/total_weights)*100;
STFT_percent=(STFT/total_weights)*100;       
PS_percent=(PS/total_weights)*100;
    
set(handles.Panel_Station_Report,'title',strcat('Station-',station_name,' Report'));

[results_row_count, ~]=size(results);

operation=0;
if ~isempty(results)
    res=results(:,1);
    res_size=size(res);
    for counter1=1:res_size(1)
        if isequal(res{counter1},station_name)            
            operation=2;
            break;
        end
    end    
    if(operation==0)
        results{results_row_count+1,1}=station_name;
        operation=1;
    end
else
    results{1,1}=station_name;
    operation=1;
end

waitbar(0.1,fdb2,'Analysis in progress, please wait ...');

if ~isempty(station_struct)
    st_f=strcat(GetExecutableFolder(),'\Bin\Amplitude_Complexity_Ratio\',station_name,'.mat');
    if exist(st_f, 'file') == 2        
        set(handles.Text_Axes1_Info,'visible','off');
        set(handles.Text_Axes2_Info,'visible','off');
        set(handles.Text_Axes3_Info,'visible','off');
        set(handles.Text_Axes4_Info,'visible','off');
        
        load(st_f);
        x_g = station_struct.Slog;
        y_g = station_struct.ampratio;
        x_k = station_struct.SR;
        y_k = station_struct.C;  
        
        [group,ind]=sort(group);
        SL_g = SL_g(ind);
        SW_g = SW_g(ind);
        SL_k = SL_k(ind);
        SW_k = SW_k(ind);
        
        C_gl_new = classify([x_g y_g],[SL_g SW_g],group,'linear');
        C_kl_new = classify([x_k y_k],[SL_k SW_k],group,'linear');
        C_gq_new = classify([x_g y_g],[SL_g SW_g],group,'quadratic');
        C_kq_new = classify([x_k y_k],[SL_k SW_k],group,'quadratic');
        
        [X_g,Y_g] = meshgrid(linspace(0,x_g+3,70),linspace(0,y_g+3,70));
        X_g = X_g(:); 
        Y_g = Y_g(:);
        [X_k,Y_k] = meshgrid(linspace(0,x_k+3,70),linspace(0,y_k+3,70));
        X_k = X_k(:); 
        Y_k = Y_k(:);
        
        [C_gl,~,~,~,coeff_gl] = classify([X_g Y_g],[SL_g SW_g],group,'linear');
        axes(handles.axes1);
        
        if strcmp(C_gl{1},'QB')
        gscatter(X_g,Y_g,C_gl,'br','.',1,'off');
        else
        gscatter(X_g,Y_g,C_gl,'rb','.',1,'off');    
        end;
        
        hold on
        gscatter(SL_g,SW_g,group,'rb','o^',[],'on');
        h1=ezplot(f_gl,[0 x_g+3 0 y_g+3]);
        set(h1,'Color','b','LineWidth',2);
        hold on
        scatter(x_g,y_g,350,'kp','filled');
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-LDF');
        axis([0 x_g+3 0 y_g+3]);        
        set(gca,'FontSize',9);
        
        waitbar(0.2,fdb2,'Analysis in progress, please wait ...');
        
        [C_kl,~,~,~,coeff_kl] = classify([X_k Y_k],[SL_k SW_k],group,'linear');
        axes(handles.axes2);
        if strcmp(C_kl{1},'QB')
            gscatter(X_k,Y_k,C_kl,'br','.',1,'off');
        else
            gscatter(X_k,Y_k,C_kl,'rb','.',1,'off');
        end;
        hold on
        gscatter(SL_k,SW_k,group,'rb','o^',[],'on');
        h2=ezplot(f_kl,[0 x_k+3 0 y_k+3]); 
        set(h2,'Color','b','LineWidth',2);
        hold on 
        scatter(x_k,y_k,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        title('Complexity-LDF');
        axis([0 x_k+3 0 y_k+3]);        
        set(gca,'FontSize',9);
        
        waitbar(0.3,fdb2,'Analysis in progress, please wait ...');

        [C_gq,~,~,~,coeff_gq] = classify([X_g Y_g],[SL_g SW_g],group,'quadratic');
        axes(handles.axes3);
        if strcmp(C_gq{1},'QB')
            gscatter(X_g,Y_g,C_gq,'br','.',1,'off');
        else
            gscatter(X_g,Y_g,C_gq,'rb','.',1,'off');
        end;
        hold on
        gscatter(SL_g,SW_g,group,'rb','o^',[],'on');
        h3=ezplot(f_gq,[0 x_g+3 0 y_g+3]); 
        set(h3,'Color','b','LineWidth',2);
        hold on
        scatter(x_g,y_g,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-QDF');
        axis([0 x_g+3 0 y_g+3]);        
        set(gca,'FontSize',9);
        
        waitbar(0.4,fdb2,'Analysis in progress, please wait ...');

        [C_kq,~,~,~,coeff_kq] = classify([X_k Y_k],[SL_k SW_k],group,'quadratic');
        axes(handles.axes4);
        if strcmp(C_kq{1},'QB')
            gscatter(X_k,Y_k,C_kq,'br','.',1,'off');
        else
            gscatter(X_k,Y_k,C_kq,'rb','.',1,'off');
        end;
        hold on
        gscatter(SL_k,SW_k,group,'rb','o^',[],'on');
        h4=ezplot(f_kq,[0 x_k+3 0 y_k+3]); 
        set(h4,'Color','b','LineWidth',2);
        hold on
        scatter(x_k,y_k,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        title('Complexity-QDF');
        axis([0 x_k+3 0 y_k+3]);        
        set(gca,'FontSize',9);
        
        waitbar(0.5,fdb2,'Analysis in progress, please wait ...');
        
        total=0;
        
        if operation==1
            results{results_row_count+1,2}=char(C_gl_new);
            results{results_row_count+1,3}=char(C_gq_new);
            results{results_row_count+1,4}=char(C_kl_new);
            results{results_row_count+1,5}=char(C_kq_new);
            results{results_row_count+1,6}='UN';%UN:Undefined,EQ:Natural,QB:Artificial
            results{results_row_count+1,7}='UN';        
            results{results_row_count+1,8}=A_LDF_percent;
            results{results_row_count+1,9}=A_QDF_percent;
            results{results_row_count+1,10}=C_LDF_percent;
            results{results_row_count+1,11}=C_QDF_percent;
            results{results_row_count+1,12}=STFT_percent;
            results{results_row_count+1,13}=PS_percent;
            results{results_row_count+1,14}='A';%A:Active,P:Passive        
            results{results_row_count+1,15}=A_LDF;
            results{results_row_count+1,16}=A_QDF;
            results{results_row_count+1,17}=C_LDF;
            results{results_row_count+1,18}=C_QDF;
            results{results_row_count+1,19}=STFT;
            results{results_row_count+1,20}=PS;
        
            if char(C_gl_new)~='UN'
                total=total+results{results_row_count+1,15};
            end
            if char(C_gq_new)~='UN'
                total=total+results{results_row_count+1,16};
            end
            if char(C_kl_new)~='UN'
                total=total+results{results_row_count+1,17};
            end
            if char(C_kq_new)~='UN'
                total=total+results{results_row_count+1,18};
            end
        
            A_LDF_percent_2=100*results{results_row_count+1,15}/total;
            A_QDF_percent_2=100*results{results_row_count+1,16}/total;
            C_LDF_percent_2=100*results{results_row_count+1,17}/total;
            C_QDF_percent_2=100*results{results_row_count+1,18}/total;
        
        end
        
        if operation==2
            results{counter1,2}=char(C_gl_new);
            results{counter1,3}=char(C_gq_new);
            results{counter1,4}=char(C_kl_new);
            results{counter1,5}=char(C_kq_new);
            results{counter1,6}='UN';
            results{counter1,7}='UN';        
            results{counter1,8}=A_LDF_percent;
            results{counter1,9}=A_QDF_percent;
            results{counter1,10}=C_LDF_percent;
            results{counter1,11}=C_QDF_percent;
            results{counter1,12}=STFT_percent;
            results{counter1,13}=PS_percent;
            results{counter1,14}='A';%A:Active,P:Passive        
            results{counter1,15}=A_LDF;
            results{counter1,16}=A_QDF;
            results{counter1,17}=C_LDF;
            results{counter1,18}=C_QDF;
            results{counter1,19}=STFT;
            results{counter1,20}=PS;
        
            if char(C_gl_new)~='UN'
                total=total+results{counter1,15};
            end
            if char(C_gq_new)~='UN'
                total=total+results{counter1,16};
            end
            if char(C_kl_new)~='UN'
                total=total+results{counter1,17};
            end
            if char(C_kq_new)~='UN'
                total=total+results{counter1,18};
            end
        
            A_LDF_percent_2=100*results{counter1,15}/total;
            A_QDF_percent_2=100*results{counter1,16}/total;
            C_LDF_percent_2=100*results{counter1,17}/total;
            C_QDF_percent_2=100*results{counter1,18}/total;
        
        end

        natural=0;
        artificial=0;     
       
        if char(C_gl_new)=='EQ'
            natural=natural+A_LDF_percent_2;
            set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',A_LDF_percent),')',':','Natural'));
        elseif char(C_gl_new)=='QB'
            artificial=artificial+A_LDF_percent_2;
            set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',A_LDF_percent),')',':','Artificial'));
        end
        
        if char(C_gq_new)=='EQ'
            natural=natural+A_QDF_percent_2;
            set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',A_QDF_percent),')',':','Natural'));
        elseif char(C_gq_new)=='QB'
            artificial=artificial+A_QDF_percent_2;
            set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',A_QDF_percent),')',':','Artificial'));
        end
        
        if char(C_kl_new)=='EQ'
            natural=natural+C_LDF_percent_2;
            set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',C_LDF_percent),')',':','Natural'));
        elseif char(C_kl_new)=='QB'
            artificial=artificial+C_LDF_percent_2;
            set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',C_LDF_percent),')',':','Artificial'));
        end
        
        if char(C_kq_new)=='EQ'
            natural=natural+C_QDF_percent_2;
            set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',C_QDF_percent),')',':','Natural'));
        elseif char(C_kq_new)=='QB'
            artificial=artificial+C_QDF_percent_2;
            set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',C_QDF_percent),')',':','Artificial'));
        end
        
        set(handles.Text_Short_Time_Fourier_Transform,'string',strcat('Short Time Fourier Transform',' (%',sprintf('%.2f',STFT_percent),')',':'));
        set(handles.Text_Power_Spectra,'string',strcat('Power Spectrum',' (%',sprintf('%.2f',PS_percent),')',':'));
        
        a=sprintf('%.2f',natural);
        b=sprintf('%.2f',artificial);
        
        set(handles.Text_Natural_Event,'string',strcat('Natural (%):',a));
        set(handles.Text_Artificial_Event,'string',strcat('Artificial (%):',b));
    else        
        if operation==1
            results{results_row_count+1,2}='UN';
            results{results_row_count+1,3}='UN';
            results{results_row_count+1,4}='UN';
            results{results_row_count+1,5}='UN';
            results{results_row_count+1,6}='UN';%UN:Undefined,EQ:Natural,QB:Artificial
            results{results_row_count+1,7}='UN';        
            results{results_row_count+1,8}=A_LDF_percent;
            results{results_row_count+1,9}=A_QDF_percent;
            results{results_row_count+1,10}=C_LDF_percent;
            results{results_row_count+1,11}=C_QDF_percent;
            results{results_row_count+1,12}=STFT_percent;
            results{results_row_count+1,13}=PS_percent;
            results{results_row_count+1,14}='A';%A:Active,P:Passive        
            results{results_row_count+1,15}=A_LDF;
            results{results_row_count+1,16}=A_QDF;
            results{results_row_count+1,17}=C_LDF;
            results{results_row_count+1,18}=C_QDF;
            results{results_row_count+1,19}=STFT;
            results{results_row_count+1,20}=PS;
        end
        if operation==2
            results{counter1,2}='UN';
            results{counter1,3}='UN';
            results{counter1,4}='UN';
            results{counter1,5}='UN';
            results{counter1,6}='UN';
            results{counter1,7}='UN';        
            results{counter1,8}=A_LDF_percent;
            results{counter1,9}=A_QDF_percent;
            results{counter1,10}=C_LDF_percent;
            results{counter1,11}=C_QDF_percent;
            results{counter1,12}=STFT_percent;
            results{counter1,13}=PS_percent;
            results{counter1,14}='A';%A:Active,P:Passive        
            results{counter1,15}=A_LDF;
            results{counter1,16}=A_QDF;
            results{counter1,17}=C_LDF;
            results{counter1,18}=C_QDF;
            results{counter1,19}=STFT;
            results{counter1,20}=PS;
        end
        
        axes(handles.axes1);
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-LDF');
        set(gca,'FontSize',9);
        
        waitbar(0.2,fdb2,'Analysis in progress, please wait ...');

        axes(handles.axes2);
        xlabel('Sr');
        ylabel('C');
        title('Complexity-LDF');
        set(gca,'FontSize',9);
        
        waitbar(0.3,fdb2,'Analysis in progress, please wait ...');

        axes(handles.axes3);
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-QDF');
        set(gca,'FontSize',9);
        
        waitbar(0.4,fdb2,'Analysis in progress, please wait ...');

        axes(handles.axes4);
        xlabel('Sr');
        ylabel('C');
        title('Complexity-QDF');
        set(gca,'FontSize',9);
        
        waitbar(0.5,fdb2,'Analysis in progress, please wait ...');

        set(handles.Text_Axes1_Info,'visible','on');
        set(handles.Text_Axes2_Info,'visible','on');
        set(handles.Text_Axes3_Info,'visible','on');
        set(handles.Text_Axes4_Info,'visible','on');
  
        set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',A_LDF_percent),')',':','Undefined'));
        set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',A_QDF_percent),')',':','Undefined'));
        set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',C_LDF_percent),')',':','Undefined'));
        set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',C_QDF_percent),')',':','Undefined'));
        set(handles.Text_Short_Time_Fourier_Transform,'string',strcat('Short Time Fourier Transform',' (%',sprintf('%.2f',STFT_percent),')',':'));
        set(handles.Text_Power_Spectra,'string',strcat('Power Spectrum',' (%',sprintf('%.2f',PS_percent),')',':'));

        set(handles.Text_Natural_Event,'string',strcat('Natural  (%):','0.00'));
        set(handles.Text_Artificial_Event,'string',strcat('Artificial (%):','0.00'));
        
    end   
     
     [results_row_cnt, ~]=size(results);
     station_no=1;
     for k=1:results_row_cnt
        if isequal(results{k},station_name);       
            station_no=k;
            break;
        end
     end
     
     waitbar(0.6,fdb2,'Analysis in progress, please wait ...');
     
    if results_row_cnt==1
        set(handles.Prior_Analysis_Button,'enable','off');
        set(handles.Next_Analysis_Button,'enable','off');
    end
    if results_row_cnt>1
        if station_no==1
            set(handles.Prior_Analysis_Button,'enable','off');
            set(handles.Next_Analysis_Button,'enable','on');
        elseif station_no==results_row_cnt
            set(handles.Prior_Analysis_Button,'enable','on');
            set(handles.Next_Analysis_Button,'enable','off');
        else        
            set(handles.Prior_Analysis_Button,'enable','on');
            set(handles.Next_Analysis_Button,'enable','on');
        end       
    end
     
    v=z_comp-mean(z_comp);  
    fs=1/dt; 
    fn=0.5/(dt);
    N=length(v);
    T=dt*(N-1);
    t=0:dt:T;

    wn=[1/fn 10/fn];
    [b,a]=butter(3,wn,'bandpass');
    vfil=filter(b,a,v);
    
    %Power Spectrum
    data2=vfil(round(P_point(1)/dt):round((F_point(1))/dt));
    [freq,gsignal,fc1,idx ] = Power_Spec( data2,fs); 
    
    interval=F_point(1)-P_point(1);
    tx=fc1;
    ty=max(gsignal);
    fcstr1=num2str(fc1, '%3.1f');
    
    axes(handles.axes7);
    loglog(freq',gsignal,'k','LineWidth',1);hold on
    plot(fc1,(gsignal(idx)),'ro', 'MarkerSize',7,'MarkerEdgeColor','k','MarkerFaceColor','g');
    hold on
    str = ['f_c= ',fcstr1,' Hz'];
    text(double(tx)*1.1,double(ty),str,'FontSize',12)
    xlabel('Frequency (Hz)');ylabel('(Count/Hz)^2');title('Power Spectrum')
    set(gca, 'XLim', [1 1/(2*dt)]);    
    set(gca, 'XTick', [1 5 10 50]);
    set(gca,'FontSize',9);
    set(gca,'color',[0.85 0.9 0.77]);
    ps_2=strcat(GetExecutableFolder(),'\Bin\Power_Spectra\',station_name,'.xlsx');
    if exist(ps_2, 'file') == 2
        [~,~,rawst3] = xlsread(ps_2) ;
        powspec=cell2table(rawst3);
        [~, powspec_cnt]=size(powspec);
        if powspec_cnt>1
            x1=powspec{:,1};
            y1=powspec{:,2};
            pl1=loglog(x1,y1,'r--','LineWidth',1.5);hold on            
            legend(pl1,{'Natural'},'Location','southwest');
        end
        if powspec_cnt>3
            x2=powspec{:,3};
            y2=powspec{:,4};
            pl2=loglog(x2,y2,'r--','LineWidth',1.5);hold on
            legend(pl2,{'Natural'},'Location','southwest');
        end
        if powspec_cnt>5
            x3=powspec{:,5};
            y3=powspec{:,6};
            pl3=loglog(x3,y3,'b--','LineWidth',1.5);hold on
            legend([pl1 pl3],{'Natural','Artificial'},'Location','southwest');
        end;
        if powspec_cnt>7
            x4=powspec{:,7};
            y4=powspec{:,8};
            pl4=loglog(x4,y4,'b--','LineWidth',1.5);hold on
            legend([pl1 pl4],{'Natural','Artificial'},'Location','southwest');
        end
    end
    hold off;
    
first_point=round(P_point(1)-2);
if first_point>0
    first_point=2;
else
    first_point=0;
end

data=z_comp_temp(round((P_point(1)-first_point)/dt):round((P_point(1)+interval)/dt));
t2=t(round((P_point(1)-first_point)/dt):round((P_point(1)+interval)/dt))';

fn=1/(2*dt);             
tfr=TFRSTFT(data);           

[~,nt]=size(tfr);
nfft=2^nextpow2(nt);

waitbar(0.7,fdb2,'Analysis in progress, please wait ...');

axes(handles.axes5);
plot(t2,data,'-k');
h1=line([P_point(1);P_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','red');
h2=line([S_point(1);S_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','blue');
h3=line([F_point(1);F_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','magenta');
xlabel('Time (s)');
ylabel('Amplitude');
title(strcat(station_name,' - Z Component'));
axis([min(t2) max(t2)+0.02 min(data) max(data) ]);
set(gca,'FontSize',9);
set(gca,'color',[0.85 0.9 0.77]);
waitbar(0.8,fdb2,'Analysis in progress, please wait ...');

axes(handles.axes6);
imagesc(linspace(P_point(1)-first_point,P_point(1)+interval,nt),linspace(0,fn*2,nfft),abs((tfr)));
set(gca,'YDir','normal')
cb = colorbar('southoutside');
title('Short Time Fourier Transform');
xlabel('Time (s)')
ylabel('Frequency (Hz)');
axis([min(t2) max(t2) 0 fn])
set(gca,'FontSize',9);
cb.Label.String = 'Amplitude';
zoom on;

waitbar(0.9,fdb2,'Analysis in progress, please wait ...');

filename=['Temp_files\' station_name '.mat'];
if exist('f_gl','var') && exist('f_kl','var') && exist('f_gq','var') && exist('f_kq','var') && exist('x_g','var') && exist('y_g','var') && exist('x_k','var') && exist('y_k','var') && exist('X_g','var') && exist('Y_g','var')  && exist('X_k','var') && exist('Y_k','var') && exist('C_gl','var') && exist('C_kl','var') && exist('C_gq','var') && exist('C_kq','var') && exist('SL_g','var') && exist('SW_g','var') && exist('SL_k','var') && exist('SW_k','var') && exist('group','var')
save (filename,'f_gl','f_kl','f_gq','f_kq','x_g','y_g','x_k','y_k','X_g','Y_g','X_k','Y_k','C_gl','C_kl','C_gq','C_kq','SL_g','SW_g','SL_k','SW_k','group','freq','gsignal','fc1','tx','ty','str','t2','data','P_point','S_point','F_point','z_comp_temp','first_point','interval','fcstr1','nt','nfft','tfr','fn'); 
else
save (filename,'freq','gsignal','fc1','tx','ty','str','t2','data','P_point','S_point','F_point','z_comp_temp','first_point','interval','fcstr1','nt','nfft','tfr','fn'); 
end

waitbar(1,fdb2,'Analysis in progress, please wait ...');

end

close(fdb2);

switch char(results{station_no,6})
    case 'UN'
        set(handles.Popup_STFT,'Value',1);
    case 'EQ'
        set(handles.Popup_STFT,'Value',2); 
    case 'QB'
        set(handles.Popup_STFT,'Value',3);    
end

switch char(results{station_no,7})
    case 'UN'
        set(handles.Popup_Power_Spectra,'Value',1);
    case 'EQ'
        set(handles.Popup_Power_Spectra,'Value',2); 
    case 'QB'
        set(handles.Popup_Power_Spectra,'Value',3);    
end

     if results{station_no,14}=='A'
         set(handles.Checkbox_Include_Analysis,'Value',1);
     elseif results{station_no,14}=='P'
         set(handles.Checkbox_Include_Analysis,'Value',0);
     end
process_status=0;
else
    %No active station
end;

end

%Results Button
if button_id==1
process_status=1;
fdb3 = waitbar(0,'Analysis in progress, please wait ...');
WindowAPI(gcf, 'TopMost');

cla(handles.axes1,'reset');
cla(handles.axes2,'reset');
cla(handles.axes3,'reset');
cla(handles.axes4,'reset');
cla(handles.axes5,'reset');
cla(handles.axes6,'reset');
cla(handles.axes7,'reset');

station_no=1;

if ~isempty(results)
    tt=results{station_no};
    set(handles.Panel_Station_Report,'title',strcat('Station-',tt,' Report'));

    for j=1:size(station_list,1)
        if isequal(upper(tt),upper(station_list{j,1}))
            station_struct.C=station_list{j,5};
            station_struct.SR=station_list{j,6};
            station_struct.Pmax=station_list{j,7};
            station_struct.Smax=station_list{j,8};
            station_struct.ampratio=station_list{j,9};
            station_struct.Slog=station_list{j,10};
            station_struct.Interval=station_list{j,11};
            station_struct.Component=station_list{j,12};
            station_struct.Station=station_list{j,1};
            station_struct.Time=station_list{j,13};
        end;
    end;
    
    if(~isempty(results{station_no,2}))
        if char(results{station_no,2})=='EQ'
            set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',results{station_no,15}),')',':','Natural'));
        elseif char(results{station_no,2})=='QB'
            set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',results{station_no,15}),')',':','Artificial'));
        elseif char(results{station_no,2})=='UN'
            set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',results{station_no,15}),')',':','Undefined'));
        end
    end

    if(~isempty(results{station_no,3}))
        if char(results{station_no,3})=='EQ'
            set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',results{station_no,16}),')',':','Natural'));
        elseif char(results{station_no,3})=='QB'
            set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',results{station_no,16}),')',':','Artificial'));
        elseif char(results{station_no,3})=='UN'
            set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',results{station_no,16}),')',':','Undefined'));
        end
    end
    if(~isempty(results{station_no,4}))
        if char(results{station_no,4})=='EQ'
            set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',results{station_no,17}),')',':','Natural'));
        elseif char(results{station_no,4})=='QB'
            set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',results{station_no,17}),')',':','Artificial'));
        elseif char(results{station_no,4})=='UN'
            set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',results{station_no,17}),')',':','Undefined'));
        end
    end
    if(~isempty(results{station_no,5}))
        if char(results{station_no,5})=='EQ'
            set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',results{station_no,18}),')',':','Natural'));
        elseif char(results{station_no,5})=='QB'
            set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',results{station_no,18}),')',':','Artificial'));
        elseif char(results{station_no,5})=='UN'
            set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',results{station_no,18}),')',':','Undefined'));
        end
    end

    filename=[strcat(GetExecutableFolder(),'\Temp_files\') tt '.mat'];
    load(filename);

end

waitbar(0.16,fdb3,'Analysis in progress, please wait ...');

if exist('f_gl','var') && exist('f_kl','var') && exist('f_gq','var') && exist('f_kq','var') && exist('x_g','var') && exist('y_g','var') && exist('x_k','var') && exist('y_k','var') && exist('X_g','var') && exist('Y_g','var')  && exist('X_k','var') && exist('Y_k','var') && exist('C_gl','var') && exist('C_kl','var') && exist('C_gq','var') && exist('C_kq','var') && exist('SL_g','var') && exist('SW_g','var') && exist('SL_k','var') && exist('SW_k','var') && exist('group','var')
    
        axes(handles.axes1);
        if strcmp(C_gl{1},'QB')
            gscatter(X_g,Y_g,C_gl,'br','.',1,'off');
        else
            gscatter(X_g,Y_g,C_gl,'rb','.',1,'off');    
        end;
        
        hold on
        gscatter(SL_g,SW_g,group,'rb','o^',[],'on');
        h1=ezplot(f_gl,[0 x_g+3 0 y_g+3]);
        set(h1,'Color','b','LineWidth',2);
        hold on
        scatter(x_g,y_g,350,'kp','filled');
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-LDF');
        axis([0 x_g+3 0 y_g+3]);        
        set(gca,'FontSize',9);
       
        axes(handles.axes2);
        if strcmp(C_kl{1},'QB')
            gscatter(X_k,Y_k,C_kl,'br','.',1,'off');
        else
            gscatter(X_k,Y_k,C_kl,'rb','.',1,'off');
        end;
        
        hold on
        gscatter(SL_k,SW_k,group,'rb','o^',[],'on');
        h2=ezplot(f_kl,[0 x_k+3 0 y_k+3]); 
        set(h2,'Color','b','LineWidth',2);
        hold on 
        scatter(x_k,y_k,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        title('Complexity-LDF');
        axis([0 x_k+3 0 y_k+3]);        
        set(gca,'FontSize',9);
        
        axes(handles.axes3);
        if strcmp(C_gq{1},'QB')
            gscatter(X_g,Y_g,C_gq,'br','.',1,'off');
        else
            gscatter(X_g,Y_g,C_gq,'rb','.',1,'off');
        end;

        hold on
        gscatter(SL_g,SW_g,group,'rb','o^',[],'on');
        h3=ezplot(f_gq,[0 x_g+3 0 y_g+3]); 
        set(h3,'Color','b','LineWidth',2);
        hold on
        scatter(x_g,y_g,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-QDF');
        axis([0 x_g+3 0 y_g+3]);        
        set(gca,'FontSize',9);
        
        axes(handles.axes4);
        if strcmp(C_kq{1},'QB')
            gscatter(X_k,Y_k,C_kq,'br','.',1,'off');
        else
            gscatter(X_k,Y_k,C_kq,'rb','.',1,'off');
        end;

        hold on
        gscatter(SL_k,SW_k,group,'rb','o^',[],'on');
        h4=ezplot(f_kq,[0 x_k+3 0 y_k+3]); 
        set(h4,'Color','b','LineWidth',2);
        hold on
        scatter(x_k,y_k,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        title('Complexity-QDF');
        axis([0 x_k+3 0 y_k+3]);        
        set(gca,'FontSize',9);
        
    set(handles.Text_Axes1_Info,'visible','off');
    set(handles.Text_Axes2_Info,'visible','off');
    set(handles.Text_Axes3_Info,'visible','off');
    set(handles.Text_Axes4_Info,'visible','off');
else
    set(handles.Text_Axes1_Info,'visible','on');
    set(handles.Text_Axes2_Info,'visible','on');
    set(handles.Text_Axes3_Info,'visible','on');
    set(handles.Text_Axes4_Info,'visible','on');
end

waitbar(0.32,fdb3,'Analysis in progress, please wait ...');

if exist('freq','var')
    [~, idx] = min( abs(freq - fc1) );  
    
    axes(handles.axes7);
    loglog(freq',gsignal,'k','LineWidth',1);hold on
    plot(fc1,(gsignal(idx)),'ro', 'MarkerSize',7,'MarkerEdgeColor','k','MarkerFaceColor','g');
    str = ['f_c= ',fcstr1,' Hz'];
    text(double(tx)*1.1,double(ty),str,'FontSize',12)
    xlabel('Frequency (Hz)');ylabel('(Count/Hz)^2');title('Power Spectrum')
    set(gca, 'XLim', [1 1/(2*dt)]);
    set(gca, 'XTick', [1 5 10 50]);
    set(gca,'FontSize',9);
    set(gca,'color',[0.85 0.9 0.77])

    ps_2=strcat('Bin\Power_Spectra\',results{station_no,1},'.xlsx');
    if exist(ps_2, 'file') == 2
        [~,~,rawst3] = xlsread(ps_2) ;
        powspec=cell2table(rawst3);
        [powspec_row, ~]=size(powspec);
        if powspec_row>1
            x1=powspec{:,1};
            y1=powspec{:,2};
            pl1=loglog(x1,y1,'r--','LineWidth',1.5);hold on            
        end
        if powspec_row>3
            x2=powspec{:,3};
            y2=powspec{:,4};
            pl2=loglog(x2,y2,'r--','LineWidth',1.5);hold on
            legend([pl1],{'Natural'},'Location','southwest');
        end
        if powspec_row>5
            x3=powspec{:,5};
            y3=powspec{:,6};
            pl3=loglog(x3,y3,'b--','LineWidth',1.5);hold on
        end
        if powspec_row>7
            x4=powspec{:,7};
            y4=powspec{:,8};
            pl4=loglog(x4,y4,'b--','LineWidth',1.5);hold on
            legend([pl1 pl4],{'Natural','Artificial'},'Location','southwest');
        end
    end
    hold off;
end

waitbar(0.48,fdb3,'Analysis in progress, please wait ...');

if exist('t2','var')
    axes(handles.axes5);
    plot(t2,data,'-k');
    h1=line([P_point(1);P_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','red');
    h2=line([S_point(1);S_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','blue');
    h3=line([F_point(1);F_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','magenta');
    xlabel('Time (s)');
    ylabel('Amplitude');
    title(strcat(tt,' - Z Component'));
    axis([min(t2) max(t2)+0.02 min(data) max(data) ]);
    set(gca,'FontSize',9);
    set(gca,'color',[0.85 0.9 0.77])
end

waitbar(0.64,fdb3,'Analysis in progress, please wait ...');

if exist('first_point','var')
    axes(handles.axes6);
    imagesc(linspace(P_point(1)-first_point,P_point(1)+interval,nt),linspace(0,fn*2,nfft),abs((tfr)));
    set(gca,'YDir','normal')
    cb = colorbar('southoutside');
    title('Short Time Fourier Transform');
    xlabel('Time (s)')
    ylabel('Frequency (Hz)');
    axis([min(t2) max(t2) 0 50])
    set(gca,'FontSize',9);
    zoom on;
end

waitbar(0.80,fdb3,'Analysis in progress, please wait ...');

if(~isempty(results))
    
    [results_row_cnt, ~]=size(results);
    
    if results_row_cnt==1
        set(handles.Prior_Analysis_Button,'enable','off');
        set(handles.Next_Analysis_Button,'enable','off');
    end
    if results_row_cnt>1
        if station_no==1
            set(handles.Prior_Analysis_Button,'enable','off');
            set(handles.Next_Analysis_Button,'enable','on');
        end
        if station_no>1 && station_no<results_row_cnt
            set(handles.Prior_Analysis_Button,'enable','on');
            set(handles.Next_Analysis_Button,'enable','on');
        end
        if station_no==results_row_cnt
            set(handles.Prior_Analysis_Button,'enable','on');
            set(handles.Next_Analysis_Button,'enable','off');
        end
    end

    waitbar(1,fdb3,'Analysis in progress, please wait ...');
    close(fdb3);

    switch char(results{station_no,6})
        case 'UN'
            set(handles.Popup_STFT,'Value',1);
        case 'EQ'
            set(handles.Popup_STFT,'Value',2); 
        case 'QB'
            set(handles.Popup_STFT,'Value',3);    
    end

    switch char(results{station_no,7})
        case 'UN'
            set(handles.Popup_Power_Spectra,'Value',1);
        case 'EQ'
            set(handles.Popup_Power_Spectra,'Value',2); 
        case 'QB'
            set(handles.Popup_Power_Spectra,'Value',3);    
    end

    if results{station_no,14}=='A'
        set(handles.Checkbox_Include_Analysis,'Value',1);
    elseif results{station_no,14}=='P'
        set(handles.Checkbox_Include_Analysis,'Value',0);
    end

    total=0;
    
    if results{station_no,2}~='UN'
        total=total+results{station_no,15};
    end
    if results{station_no,3}~='UN'
        total=total+results{station_no,16};
    end
    if results{station_no,4}~='UN'
        total=total+results{station_no,17};
    end
    if results{station_no,5}~='UN'
        total=total+results{station_no,18};
    end
    if results{station_no,6}~='UN'
        total=total+results{station_no,19};
    end
    if results{station_no,7}~='UN'
        total=total+results{station_no,20};
    end
     
    A_LDF_percent_2=100*results{station_no,15}/total;
    A_QDF_percent_2=100*results{station_no,16}/total;
    C_LDF_percent_2=100*results{station_no,17}/total;
    C_QDF_percent_2=100*results{station_no,18}/total;
    STFT_percent_2=100*results{station_no,19}/total;
    PS_percent_2=100*results{station_no,20}/total;
     
    natural=0;
    artificial=0;     
       
    if results{station_no,2}=='EQ'
        natural=natural+A_LDF_percent_2;
    elseif results{station_no,2}=='QB'
        artificial=artificial+A_LDF_percent_2;
    end
        
    if results{station_no,3}=='EQ'
        natural=natural+A_QDF_percent_2;
    elseif results{station_no,3}=='QB'
        artificial=artificial+A_QDF_percent_2;
    end
        
    if results{station_no,4}=='EQ'
        natural=natural+C_LDF_percent_2;
    elseif results{station_no,4}=='QB'
        artificial=artificial+C_LDF_percent_2;
    end
        
    if results{station_no,5}=='EQ'
        natural=natural+C_QDF_percent_2;
    elseif results{station_no,5}=='QB'
        artificial=artificial+C_QDF_percent_2;
    end
        
    if results{station_no,6}=='EQ'
        natural=natural+STFT_percent_2;
    elseif results{station_no,6}=='QB'
        artificial=artificial+STFT_percent_2;
    end

    if results{station_no,7}=='EQ'
        natural=natural+PS_percent_2;
    elseif results{station_no,7}=='QB'
        artificial=artificial+PS_percent_2;
    end     
        
    a=sprintf('%.2f',natural);
    b=sprintf('%.2f',artificial);
        
    set(handles.Text_Natural_Event,'string',strcat('Natural  (%):',a));
    set(handles.Text_Artificial_Event,'string',strcat('Artificial (%):',b));
    
    if results{station_no,14}=='A'
        set(handles.Checkbox_Include_Analysis,'Value',1);
    elseif results{station_no,14}=='P'
        set(handles.Checkbox_Include_Analysis,'Value',0);
    end
else
    waitbar(1,fdb3,'Analysis in progress, please wait ...');
    close(fdb3);
end
process_status=0;
end

function Prior_Analysis_Button_Callback(hObject, eventdata, handles)
global station_no;
 
station_no=station_no-1;
Run(hObject, eventdata, handles);

function Next_Analysis_Button_Callback(hObject, eventdata, handles)
global station_no;

station_no=station_no+1;
Run(hObject, eventdata, handles);

function Run(hObject, eventdata, handles)
global results;
global station_no;
global station_list;
global station_struct;
global dt;

for j=1:size(station_list,1)
    if isequal(upper(results{station_no}),upper(station_list{j,1}))
        station_struct.C=station_list{j,5};
        station_struct.SR=station_list{j,6};
        station_struct.Pmax=station_list{j,7};
        station_struct.Smax=station_list{j,8};
        station_struct.ampratio=station_list{j,9};
        station_struct.Slog=station_list{j,10};
        station_struct.Interval=station_list{j,11};
        station_struct.Component=station_list{j,12};
        station_struct.Station=station_list{j,1};
        station_struct.Time=station_list{j,13};
    end;
end;


fdb5 = waitbar(0,'Analysis in progress, please wait ...');
WindowAPI(gcf, 'TopMost');

cla(handles.axes1,'reset')
cla(handles.axes2,'reset')
cla(handles.axes3,'reset')
cla(handles.axes4,'reset')
cla(handles.axes5,'reset')
cla(handles.axes6,'reset')
cla(handles.axes7,'reset')

set(handles.Panel_Station_Report,'title',strcat('Station-',results{station_no},' Report'));

if results{station_no,2}=='EQ'
    set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',results{station_no,8}),')',':','Natural'));
elseif results{station_no,2}=='QB'
    set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',results{station_no,8}),')',':','Artificial'));
elseif results{station_no,2}=='UN'
    set(handles.Text_Amplitude_Ratio_Method_LDF,'string',strcat('Amplitude Peak Ratio-LDF',' (%',sprintf('%.2f',results{station_no,8}),')',':','Undefined'));
end
        
if results{station_no,3}=='EQ'
    set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',results{station_no,9}),')',':','Natural'));
elseif results{station_no,3}=='QB'
    set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',results{station_no,9}),')',':','Artificial'));
elseif results{station_no,3}=='UN'
    set(handles.Text_Amplitude_Ratio_Method_QDF,'string',strcat('Amplitude Peak Ratio-QDF',' (%',sprintf('%.2f',results{station_no,9}),')',':','Undefined'));
end
        
if results{station_no,4}=='EQ'
    set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',results{station_no,10}),')',':','Natural'));
elseif results{station_no,4}=='QB'
    set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',results{station_no,10}),')',':','Artificial'));
elseif results{station_no,4}=='UN'
    set(handles.Text_Complexity_Method_LDF,'string',strcat('Complexity-LDF',' (%',sprintf('%.2f',results{station_no,10}),')',':','Undefined'));
end
        
if results{station_no,5}=='EQ'
    set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',results{station_no,11}),')',':','Natural'));
elseif results{station_no,5}=='QB'
    set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',results{station_no,11}),')',':','Artificial'));
elseif results{station_no,5}=='UN'
    set(handles.Text_Complexity_Method_QDF,'string',strcat('Complexity-QDF',' (%',sprintf('%.2f',results{station_no,11}),')',':','Undefined'));
end

if results{station_no,6}=='EQ'
    set(handles.Text_Short_Time_Fourier_Transform,'string',strcat('Short Time Fourier Transform',' (%',sprintf('%.2f',results{station_no,12}),')',':'));
elseif results{station_no,6}=='QB'
    set(handles.Text_Short_Time_Fourier_Transform,'string',strcat('Short Time Fourier Transform',' (%',sprintf('%.2f',results{station_no,12}),')',':'));
elseif results{station_no,6}=='UN'
    set(handles.Text_Short_Time_Fourier_Transform,'string',strcat('Short Time Fourier Transform',' (%',sprintf('%.2f',results{station_no,12}),')',':'));
end

if results{station_no,7}=='EQ'
    set(handles.Text_Power_Spectra,'string',strcat('Power Spectrum',' (%',sprintf('%.2f',results{station_no,13}),')',':'));
elseif results{station_no,7}=='QB'
    set(handles.Text_Power_Spectra,'string',strcat('Power Spectrum',' (%',sprintf('%.2f',results{station_no,13}),')',':'));
elseif results{station_no,7}=='UN'
    set(handles.Text_Power_Spectra,'string',strcat('Power Spectrum',' (%',sprintf('%.2f',results{station_no,13}),')',':'));
end

filename=[strcat(GetExecutableFolder(),'\Temp_files\') results{station_no} '.mat'];
load(filename);

waitbar(0.16,fdb5,'Analysis in progress, please wait ...');

if exist('f_gl','var') && exist('f_kl','var') && exist('f_gq','var') && exist('f_kq','var') && exist('x_g','var') && exist('y_g','var') && exist('x_k','var') && exist('y_k','var') && exist('X_g','var') && exist('Y_g','var')  && exist('X_k','var') && exist('Y_k','var') && exist('C_gl','var') && exist('C_kl','var') && exist('C_gq','var') && exist('C_kq','var') && exist('SL_g','var') && exist('SW_g','var') && exist('SL_k','var') && exist('SW_k','var') && exist('group','var')
        
        [C_gl,~,~,~,coeff_gl] = classify([X_g Y_g],[SL_g SW_g],group,'linear');
        axes(handles.axes1);
        if strcmp(C_gl{1},'QB')
        gscatter(X_g,Y_g,C_gl,'br','.',1,'off');
        else
        gscatter(X_g,Y_g,C_gl,'rb','.',1,'off');    
        end;
        %gscatter(X_g,Y_g,C_gl,'br','.',1,'off');
        hold on
        gscatter(SL_g,SW_g,group,'rb','o^',[],'on');
        h1=ezplot(f_gl,[0 x_g+3 0 y_g+3]);
        set(h1,'Color','b','LineWidth',2);
        hold on
        scatter(x_g,y_g,350,'kp','filled');
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-LDF');
        axis([0 x_g+3 0 y_g+3]);        
        set(gca,'FontSize',9);
        
        [C_kl,~,~,~,coeff_kl] = classify([X_k Y_k],[SL_k SW_k],group,'linear');
        axes(handles.axes2);
        if strcmp(C_kl{1},'QB')
            gscatter(X_k,Y_k,C_kl,'br','.',1,'off');
        else
            gscatter(X_k,Y_k,C_kl,'rb','.',1,'off');
        end;
        %gscatter(X_k,Y_k,C_kl,'br','.',1,'off');
        hold on
        gscatter(SL_k,SW_k,group,'rb','o^',[],'on');
        h2=ezplot(f_kl,[0 x_k+3 0 y_k+3]); 
        set(h2,'Color','b','LineWidth',2);
        hold on 
        scatter(x_k,y_k,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        title('Complexity-LDF');
        axis([0 x_k+3 0 y_k+3]);        
        set(gca,'FontSize',9);
        
        [C_gq,~,~,~,coeff_gq] = classify([X_g Y_g],[SL_g SW_g],group,'quadratic');
        axes(handles.axes3);
        if strcmp(C_gq{1},'QB')
            gscatter(X_g,Y_g,C_gq,'br','.',1,'off');
        else
            gscatter(X_g,Y_g,C_gq,'rb','.',1,'off');
        end;
        %gscatter(X_g,Y_g,C_gq,'br','.',1,'off');
        hold on
        gscatter(SL_g,SW_g,group,'rb','o^',[],'on');
        h3=ezplot(f_gq,[0 x_g+3 0 y_g+3]); 
        set(h3,'Color','b','LineWidth',2);
        hold on
        scatter(x_g,y_g,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        xlabel('log(As)');
        ylabel('As/Ap');
        title('Amplitude Peak Ratio-QDF');
        axis([0 x_g+3 0 y_g+3]);        
        set(gca,'FontSize',9);

        [C_kq,~,~,~,coeff_kq] = classify([X_k Y_k],[SL_k SW_k],group,'quadratic');
        axes(handles.axes4);
        if strcmp(C_kq{1},'QB')
            gscatter(X_k,Y_k,C_kq,'br','.',1,'off');
        else
            gscatter(X_k,Y_k,C_kq,'rb','.',1,'off');
        end;
        %gscatter(X_k,Y_k,C_kq,'br','.',1,'off');
        hold on
        gscatter(SL_k,SW_k,group,'rb','o^',[],'on');
        h4=ezplot(f_kq,[0 x_k+3 0 y_k+3]); 
        set(h4,'Color','b','LineWidth',2);
        hold on
        scatter(x_k,y_k,350,'kp','filled');
        xlabel('Sr');
        ylabel('C');
        title('Complexity-QDF');
        axis([0 x_k+3 0 y_k+3]);        
        set(gca,'FontSize',9);
        
    set(handles.Text_Axes1_Info,'visible','off');
    set(handles.Text_Axes2_Info,'visible','off');
    set(handles.Text_Axes3_Info,'visible','off');
    set(handles.Text_Axes4_Info,'visible','off');
else
    set(handles.Text_Axes1_Info,'visible','on');
    set(handles.Text_Axes2_Info,'visible','on');
    set(handles.Text_Axes3_Info,'visible','on');
    set(handles.Text_Axes4_Info,'visible','on');
end

waitbar(0.32,fdb5,'Analysis in progress, please wait ...');

[~, idx] = min( abs(freq - fc1) );  
     
axes(handles.axes7);
loglog(freq',gsignal,'k','LineWidth',1);hold on
plot(fc1,(gsignal(idx)),'ro', 'MarkerSize',7,'MarkerEdgeColor','k','MarkerFaceColor','g');
str = ['f_c= ',fcstr1,' Hz'];
text(double(tx)*1.1,double(ty),str,'FontSize',12)
xlabel('Frequency (Hz)');ylabel('(Count/Hz)^2');title('Power Spectrum')
set(gca, 'XLim', [1 1/(2*dt)]);
set(gca, 'XTick', [1 5 10 50]);
set(gca,'FontSize',9);
set(gca,'color',[0.85 0.9 0.77])

ps_2=strcat(GetExecutableFolder(),'\Bin\Power_Spectra\',results{station_no,1},'.xlsx');
if exist(ps_2, 'file') == 2
    [~,~,rawst3] = xlsread(ps_2) ;
    powspec=cell2table(rawst3);
    [powspec_row_cnt, ~]=size(powspec);
    if powspec_row_cnt>1
        x1=powspec{:,1};
        y1=powspec{:,2};
        pl1=loglog(x1,y1,'r--','LineWidth',1.5);hold on            
    end
    if powspec_row_cnt>3
        x2=powspec{:,3};
        y2=powspec{:,4};
        pl2=loglog(x2,y2,'r--','LineWidth',1.5);hold on
        legend([pl1],{'Natural'},'Location','southwest');
    end
    if powspec_row_cnt>5
        x3=powspec{:,5};
        y3=powspec{:,6};
        pl3=loglog(x3,y3,'b--','LineWidth',1.5);hold on
    end
    if powspec_row_cnt>7
        x4=powspec{:,7};
        y4=powspec{:,8};
        pl4=loglog(x4,y4,'b--','LineWidth',1.5);hold on
        legend([pl1 pl4],{'Natural','Artificial'},'Location','southwest');
    end
end
hold off;    
    
waitbar(0.48,fdb5,'Analysis in progress, please wait ...');

axes(handles.axes5);
plot(t2,data,'-k');
h1=line([P_point(1);P_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','red');
h2=line([S_point(1);S_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','blue');
h3=line([F_point(1);F_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','magenta');
xlabel('Time (s)');
ylabel('Amplitude');
title(strcat(results{station_no},' - Z Component'));
axis([min(t2) max(t2)+0.02 min(data) max(data) ]);
set(gca,'FontSize',9);
set(gca,'color',[0.85 0.9 0.77])
waitbar(0.64,fdb5,'Analysis in progress, please wait ...');

axes(handles.axes6);
imagesc(linspace(P_point(1)-first_point,P_point(1)+interval,nt),linspace(0,fn*2,nfft),abs((tfr)));
set(gca,'YDir','normal')
cb = colorbar('southoutside');
title('Short Time Fourier Transform');
xlabel('Time (s)')
ylabel('Frequency (Hz)');
axis([min(t2) max(t2) 0 50])
set(gca,'FontSize',9);
zoom on;

waitbar(0.80,fdb5,'Analysis in progress, please wait ...');

[result_cnt, ~]=size(results);
    
if result_cnt==1
    set(handles.Prior_Analysis_Button,'enable','off');
    set(handles.Next_Analysis_Button,'enable','off');
end
if result_cnt>1
    if station_no==1
        set(handles.Prior_Analysis_Button,'enable','off');
        set(handles.Next_Analysis_Button,'enable','on');
    end
    if station_no>1 && station_no<result_cnt
        set(handles.Prior_Analysis_Button,'enable','on');
        set(handles.Next_Analysis_Button,'enable','on');
    end
    if station_no==result_cnt
        set(handles.Prior_Analysis_Button,'enable','on');
        set(handles.Next_Analysis_Button,'enable','off');
    end
end
    
waitbar(1,fdb5,'Analysis in progress, please wait ...');
close(fdb5);

switch char(results{station_no,6})
    case 'UN'
        set(handles.Popup_STFT,'Value',1);
    case 'EQ'
        set(handles.Popup_STFT,'Value',2); 
    case 'QB'
        set(handles.Popup_STFT,'Value',3);    
end

switch char(results{station_no,7})
    case 'UN'
        set(handles.Popup_Power_Spectra,'Value',1);
    case 'EQ'
        set(handles.Popup_Power_Spectra,'Value',2); 
    case 'QB'
        set(handles.Popup_Power_Spectra,'Value',3);    
end

total=0;
    
if results{station_no,2}~='UN'
    total=total+results{station_no,15};
end
if results{station_no,3}~='UN'
    total=total+results{station_no,16};
end
if results{station_no,4}~='UN'
    total=total+results{station_no,17};
end
if results{station_no,5}~='UN'
    total=total+results{station_no,18};
end
if results{station_no,6}~='UN'
    total=total+results{station_no,19};
end
if results{station_no,7}~='UN'
    total=total+results{station_no,20};
end
     
A_LDF_percent_2=100*results{station_no,15}/total;
A_QDF_percent_2=100*results{station_no,16}/total;
C_LDF_percent_2=100*results{station_no,17}/total;
C_QDF_percent_2=100*results{station_no,18}/total;
STFT_percent_2=100*results{station_no,19}/total;
PS_percent_2=100*results{station_no,20}/total;
     
natural=0;
artificial=0;     
       
if results{station_no,2}=='EQ'
    natural=natural+A_LDF_percent_2;
elseif results{station_no,2}=='QB'
    artificial=artificial+A_LDF_percent_2;
end
        
if results{station_no,3}=='EQ'
    natural=natural+A_QDF_percent_2;
elseif results{station_no,3}=='QB'
    artificial=artificial+A_QDF_percent_2;
end
        
if results{station_no,4}=='EQ'
    natural=natural+C_LDF_percent_2;
elseif results{station_no,4}=='QB'
    artificial=artificial+C_LDF_percent_2;
end
        
if results{station_no,5}=='EQ'
    natural=natural+C_QDF_percent_2;
elseif results{station_no,5}=='QB'
    artificial=artificial+C_QDF_percent_2;
end
        
if results{station_no,6}=='EQ'
    natural=natural+STFT_percent_2;
elseif results{station_no,6}=='QB'
    artificial=artificial+STFT_percent_2;
end

if results{station_no,7}=='EQ'
    natural=natural+PS_percent_2;
elseif results{station_no,7}=='QB'
    artificial=artificial+PS_percent_2;
end
        
a=sprintf('%.2f',natural);
b=sprintf('%.2f',artificial);
        
set(handles.Text_Natural_Event,'string',strcat('Natural  (%):',a));
set(handles.Text_Artificial_Event,'string',strcat('Artificial (%):',b));

if results{station_no,14}=='A'
    set(handles.Checkbox_Include_Analysis,'Value',1);
elseif results{station_no,14}=='P'
    set(handles.Checkbox_Include_Analysis,'Value',0);
end
  
function Popup_Power_Spectra_Callback(hObject, eventdata, handles)
global results;
global station_no;

Text = get(handles.Popup_Power_Spectra,'string');
Index = get(handles.Popup_Power_Spectra,'Value');
selItem = strcat(Text{Index});

switch selItem
case 'Undefined'
    results{station_no,7}='UN';
case 'Natural'
    results{station_no,7}='EQ';
case 'Artificial'
    results{station_no,7}='QB';
end       

total=0;
    
if results{station_no,2}~='UN'
    total=total+results{station_no,15};
end
if results{station_no,3}~='UN'
    total=total+results{station_no,16};
end
if results{station_no,4}~='UN'
    total=total+results{station_no,17};
end
if results{station_no,5}~='UN'
    total=total+results{station_no,18};
end
if results{station_no,6}~='UN'
    total=total+results{station_no,19};
end
if results{station_no,7}~='UN'
    total=total+results{station_no,20};
end
     
A_LDF_percent_2=100*results{station_no,15}/total;
A_QDF_percent_2=100*results{station_no,16}/total;
C_LDF_percent_2=100*results{station_no,17}/total;
C_QDF_percent_2=100*results{station_no,18}/total;
STFT_percent_2=100*results{station_no,19}/total;
PS_percent_2=100*results{station_no,20}/total; 
     
natural=0;
artificial=0;     
       
if results{station_no,2}=='EQ'
    natural=natural+A_LDF_percent_2;
elseif results{station_no,2}=='QB'
    artificial=artificial+A_LDF_percent_2;
end
        
if results{station_no,3}=='EQ'
    natural=natural+A_QDF_percent_2;
elseif results{station_no,3}=='QB'
    artificial=artificial+A_QDF_percent_2;
end
        
if results{station_no,4}=='EQ'
    natural=natural+C_LDF_percent_2;
elseif results{station_no,4}=='QB'
    artificial=artificial+C_LDF_percent_2;
end
        
if results{station_no,5}=='EQ'
    natural=natural+C_QDF_percent_2;
elseif results{station_no,5}=='QB'
    artificial=artificial+C_QDF_percent_2;
end
        
if results{station_no,6}=='EQ'
    natural=natural+STFT_percent_2;
elseif results{station_no,6}=='QB'
    artificial=artificial+STFT_percent_2;
end

if results{station_no,7}=='EQ'
    natural=natural+PS_percent_2;
elseif results{station_no,7}=='QB'
    artificial=artificial+PS_percent_2;
end       
        
a=sprintf('%.2f',natural);
b=sprintf('%.2f',artificial);
        
set(handles.Text_Natural_Event,'string',strcat('Natural  (%):',a));
set(handles.Text_Artificial_Event,'string',strcat('Artificial (%):',b));

function Popup_Power_Spectra_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Popup_STFT_Callback(hObject, eventdata, handles)

global results;
global station_no;

Text = get(handles.Popup_STFT,'string');
Index = get(handles.Popup_STFT,'Value');
selItem = strcat(Text{Index});

switch selItem
case 'Undefined'
    results{station_no,6}='UN';
case 'Natural'
    results{station_no,6}='EQ';
case 'Artificial'
    results{station_no,6}='QB';
end     

total=0;
    
if results{station_no,2}~='UN'
    total=total+results{station_no,15};
end
if results{station_no,3}~='UN'
    total=total+results{station_no,16};
end
if results{station_no,4}~='UN'
    total=total+results{station_no,17};
end
if results{station_no,5}~='UN'
    total=total+results{station_no,18};
end
if results{station_no,6}~='UN'
    total=total+results{station_no,19};
end
if results{station_no,7}~='UN'
    total=total+results{station_no,20};
end
     
A_LDF_percent_2=100*results{station_no,15}/total;
A_QDF_percent_2=100*results{station_no,16}/total;
C_LDF_percent_2=100*results{station_no,17}/total;
C_QDF_percent_2=100*results{station_no,18}/total;
STFT_percent_2=100*results{station_no,19}/total;
PS_percent_2=100*results{station_no,20}/total; 
     
natural=0;
artificial=0;     
       
if results{station_no,2}=='EQ'
    natural=natural+A_LDF_percent_2;
elseif results{station_no,2}=='QB'
    artificial=artificial+A_LDF_percent_2;
end
        
if results{station_no,3}=='EQ'
    natural=natural+A_QDF_percent_2;
elseif results{station_no,3}=='QB'
    artificial=artificial+A_QDF_percent_2;
end
        
if results{station_no,4}=='EQ'
    natural=natural+C_LDF_percent_2;
elseif results{station_no,4}=='QB'
    artificial=artificial+C_LDF_percent_2;
end
        
if results{station_no,5}=='EQ'
    natural=natural+C_QDF_percent_2;
elseif results{station_no,5}=='QB'
    artificial=artificial+C_QDF_percent_2;
end
        
if results{station_no,6}=='EQ'
    natural=natural+STFT_percent_2;
elseif results{station_no,6}=='QB'
    artificial=artificial+STFT_percent_2;
end

if results{station_no,7}=='EQ'
    natural=natural+PS_percent_2;
elseif results{station_no,7}=='QB'
    artificial=artificial+PS_percent_2;
end       
        
a=sprintf('%.2f',natural);
b=sprintf('%.2f',artificial);
        
set(handles.Text_Natural_Event,'string',strcat('Natural  (%):',a));
set(handles.Text_Artificial_Event,'string',strcat('Artificial (%):',b));
  
function Popup_STFT_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function General_Report_Button_Callback(hObject, eventdata, handles)
Result_Form;

function Checkbox_Include_Analysis_Callback(hObject, eventdata, handles)
global results;
global station_no;

cbox = get(handles.Checkbox_Include_Analysis, 'Value');
[res_row_count, ~]=size(results);
if cbox==1
     ts=0;
     for cnt=1:res_row_count
        if isequal(results{cnt},results{station_no,1});       
            ts=cnt;
            break;
        end
     end
    if ts~=0
        results{ts,14}='A';%A:Active,P:Passive
    end
else
     ts=0;
     for cnt=1:res_row_count
        if isequal(results{cnt},results{station_no,1});       
            ts=cnt;
            break;
        end
     end
    if ts~=0
        results{ts,14}='P';%A:Active,P:Passive
    end
end

function Save_Figures_Button_Callback(hObject, eventdata, handles)
global station_struct;
global z_comp_temp;
global t2;
global P_point;
global S_point;
global F_point;
global data;
global first_point;
global interval;
global nt;
global fn;
global nfft;
global tfr;
global freq;
global gsignal;
global idx;
global fc1;
global fcstr1;
global tx;
global ty;
global str;
global dt;

station_name=upper(station_struct.Station);

st_f=strcat(GetExecutableFolder(),'\Bin\Amplitude_Complexity_Ratio\',station_name,'.mat');

load(st_f);

x_g = station_struct.Slog;
y_g = station_struct.ampratio;
x_k = station_struct.SR;
y_k = station_struct.C;  

[group,ind]=sort(group);
SL_g = SL_g(ind);
SW_g = SW_g(ind);
SL_k = SL_k(ind);
SW_k = SW_k(ind);

C_gl_new = classify([x_g y_g],[SL_g SW_g],group,'linear');
C_kl_new = classify([x_k y_k],[SL_k SW_k],group,'linear');
C_gq_new = classify([x_g y_g],[SL_g SW_g],group,'quadratic');
C_kq_new = classify([x_k y_k],[SL_k SW_k],group,'quadratic');
        
[X_g,Y_g] = meshgrid(linspace(0,x_g+3,100),linspace(0,y_g+3,100));
X_g = X_g(:); 
Y_g = Y_g(:);
[X_k,Y_k] = meshgrid(linspace(0,x_k+3,100),linspace(0,y_k+3,100));
X_k = X_k(:); 
Y_k = Y_k(:);

selpath = uigetdir;

if isequal(selpath,0)
else
    [C_gl,~,~,~,coeff_gl] = classify([X_g Y_g],[SL_g SW_g],group,'linear');
        
    file_name=strcat(station_name,'_AmpRatio_LDF','.tiff');
    file=fullfile(selpath,file_name);
    figu1=figure;
    
    if strcmp(C_gl{1},'QB')
        gscatter(X_g,Y_g,C_gl,'br','.',5,'off');
    else
        gscatter(X_g,Y_g,C_gl,'rb','.',5,'off');    
    end;
    hold on;
    gscatter(SL_g,SW_g,group,'rb','o^',20,'on');
    h1=ezplot(f_gl,[0 x_g+3 0 y_g+3]);
    scatter(x_g,y_g,700,'kp','filled');
    xlabel('log(As)');
    ylabel('As/Ap');
    title('Amplitude Peak Ratio-LDF');
    set(h1,'Color','b','LineWidth',4)
    set(gca,'FontSize',27);
    axis([0 x_g+3 0 y_g+3]);
    hold off;
    print(figu1, '-dtiff', file);
    close(figu1);   
    
    
    [C_kl,~,~,~,coeff_kl] = classify([X_k Y_k],[SL_k SW_k],group,'linear');
        
    file_name=strcat(station_name,'_Complexity_LDF','.tiff');
    file=fullfile(selpath,file_name);
    figu2=figure;
    
    if strcmp(C_kl{1},'QB')
        gscatter(X_k,Y_k,C_kl,'br','.',5,'off');
    else
        gscatter(X_k,Y_k,C_kl,'rb','.',5,'off');
    end;
    hold on;
    gscatter(SL_k,SW_k,group,'rb','o^',20,'on');
    h2=ezplot(f_kl,[0 x_k+3 0 y_k+3]);
    scatter(x_k,y_k,700,'kp','filled');
    xlabel('Sr');
    ylabel('C');
    title('Complexity-LDF');
    set(h2,'Color','b','LineWidth',4)
    set(gca,'FontSize',27);
    axis([0 x_k+3 0 y_k+3]);
    hold off;
    print(figu2, '-dtiff', file);
    close(figu2);
    
    [C_gq,~,~,~,coeff_gq] = classify([X_g Y_g],[SL_g SW_g],group,'quadratic');
        
    file_name=strcat(station_name,'_AmpRatio_QDF','.tiff');
    file=fullfile(selpath,file_name);
    figu3=figure;
    if strcmp(C_gq{1},'QB')
        gscatter(X_g,Y_g,C_gq,'br','.',5,'off');
    else
        gscatter(X_g,Y_g,C_gq,'rb','.',5,'off');
    end;
    hold on;
    gscatter(SL_g,SW_g,group,'rb','o^',20,'on');
    h3=ezplot(f_gq,[0 x_g+3 0 y_g+3]);
    scatter(x_g,y_g,700,'kp','filled');
    xlabel('log(As)');
    ylabel('As/Ap');
    title('Amplitude Peak Ratio-QDF');
    set(h3,'Color','b','LineWidth',4)
    set(gca,'FontSize',27);
    axis([0 x_g+3 0 y_g+3]);
    hold off;
    print(figu3, '-dtiff', file);
    close(figu3);
    
    [C_kq,~,~,~,coeff_kq] = classify([X_k Y_k],[SL_k SW_k],group,'quadratic');
        
    file_name=strcat(station_name,'_Complexity_QDF','.tiff');
    file=fullfile(selpath,file_name);
    figu4=figure;
    if strcmp(C_kq{1},'QB')
        gscatter(X_k,Y_k,C_kq,'br','.',5,'off');
    else
        gscatter(X_k,Y_k,C_kq,'rb','.',5,'off');
    end;
    hold on;
    gscatter(SL_k,SW_k,group,'rb','o^',20,'on');
    h4=ezplot(f_kq,[0 x_k+3 0 y_k+3]);
    scatter(x_k,y_k,700,'kp','filled');
    xlabel('Sr');
    ylabel('C');
    title('Complexity-QDF');
    set(h4,'Color','b','LineWidth',4);
    set(gca,'FontSize',27);
    axis([0 x_k+3 0 y_k+3]);
    hold off;
    print(figu4, '-dtiff', file);
    close(figu4);
    
    file_name=strcat(station_name,'_ZComp','.tiff');
    file=fullfile(selpath,file_name);
    figu5=figure;
    plot(t2,data,'-k');hold on;
    h1=line([P_point(1);P_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','red');
    h2=line([S_point(1);S_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','blue');
    h3=line([F_point(1);F_point(1)],[min(z_comp_temp);max(z_comp_temp)],'linestyle','--','linewidth',2,'Color','magenta');
    
    xlabel('Time (s)');
    ylabel('Amplitude');
    title(strcat(station_name,' - Z Component'));
    axis([min(t2) max(t2)+0.02 min(data) max(data) ]);    
    set(gca,'FontSize',22);  
    hold off;
    print(figu5, '-dtiff', file);
    close(figu5);
    
    file_name=strcat(station_name,'_STFT','.tiff');
    file=fullfile(selpath,file_name);
    figu6=figure;
    imagesc(linspace(P_point(1)-first_point,P_point(1)+interval,nt),linspace(0,fn*2,nfft),abs((tfr)));
    set(gca,'YDir','normal')
    cb = colorbar('southoutside');
    title('Short Time Fourier Transform');
    xlabel('Time (s)')
    ylabel('Frequency (Hz)');
    axis([min(t2) max(t2) 0 50])  
    set(gca,'FontSize',22);
    cb.FontSize = 22;
    cb.Label.String = 'Amplitude';    
    print(figu6, '-dtiff', file);
    close(figu6);
    
    file_name=strcat(station_name,'_PS','.tiff');
    file=fullfile(selpath,file_name);
    figu7=figure;
    loglog(freq',gsignal,'LineWidth',1.5);hold on
    plot(fc1,(gsignal(idx)),'ro', 'MarkerSize',10,'MarkerEdgeColor','k','MarkerFaceColor','g');
    str = ['f_c= ',fcstr1,' Hz'];
    text(double(tx)*1.1,double(ty),str,'FontSize',24)
    xlabel('Frequency (Hz)');ylabel('(Count/Hz)^2');title('Power Spectrum')
    set(gca, 'XLim', [1 1/(2*dt)]);    
    set(gca, 'XTick', [1 5 10 50]);
    set(gca,'FontSize',22);
    
    ps_2=strcat(GetExecutableFolder(),'\Bin\Power_Spectra\',station_name,'.xlsx');
    if exist(ps_2, 'file') == 2
        [~,~,rawst3] = xlsread(ps_2) ;
        powspec=cell2table(rawst3);
        [~, powspec_cnt]=size(powspec);
        if powspec_cnt>1
            x1=powspec{:,1};
            y1=powspec{:,2};
            pl1=loglog(x1,y1,'r--','LineWidth',1.5);hold on            
            legend(pl1,{'Natural'},'Location','southwest');
        end
        if powspec_cnt>3
            x2=powspec{:,3};
            y2=powspec{:,4};
            pl2=loglog(x2,y2,'r--','LineWidth',1.5);hold on
            legend(pl2,{'Natural'},'Location','southwest');
        end
        if powspec_cnt>5
            x3=powspec{:,5};
            y3=powspec{:,6};
            pl3=loglog(x3,y3,'b--','LineWidth',1.5);hold on
        end;
        if powspec_cnt>7
            x4=powspec{:,7};
            y4=powspec{:,8};
            pl4=loglog(x4,y4,'b--','LineWidth',1.5);hold on
            legend([pl1 pl4],{'Natural','Artificial'},'Location','southwest');
        end
    end    
    
    hold off;    
    print(figu7, '-dtiff', file);
    close(figu7);    
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

function figure1_CloseRequestFcn(hObject, eventdata, handles)
global process_status;

if(process_status==0)
    delete(hObject);
else
    return;
end;
