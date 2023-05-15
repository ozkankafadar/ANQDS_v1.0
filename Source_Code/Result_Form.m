function varargout = Result_Form(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Result_Form_OpeningFcn, ...
                   'gui_OutputFcn',  @Result_Form_OutputFcn, ...
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

function Result_Form_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

guidata(hObject, handles);
movegui(gcf,'center');

function varargout = Result_Form_OutputFcn(hObject, eventdata, handles)
global results;
varargout{1} = handles.output;

[results_row_cnt, ~]=size(results);

if results_row_cnt>0
if ~isempty(results)
    total=0;
    for i=1:results_row_cnt
        row14=results{i,14};
        if row14=='A'                
            if results{i,2}~='UN'
                total=total+results{i,15};
            end
            if results{i,3}~='UN'
                total=total+results{i,16};
            end
            if results{i,4}~='UN'
                total=total+results{i,17};
            end
            if results{i,5}~='UN'
                total=total+results{i,18};
            end
            if results{i,6}~='UN'
                total=total+results{i,19};
            end
            if results{i,7}~='UN'
                total=total+results{i,20};
            end
        end
    end

    natural=0;
    artificial=0;
    for i=1:results_row_cnt
        row14=results{i,14};
        if row14=='A'
            if results{i,2}=='EQ'
                natural=natural+100*results{i,15}/total;
            elseif results{i,2}=='QB'
                artificial=artificial+100*results{i,15}/total;
            end
            if results{i,3}=='EQ'
                natural=natural+100*results{i,16}/total;
            elseif results{i,3}=='QB'
                artificial=artificial+100*results{i,16}/total;
            end;
            if results{i,4}=='EQ'
                natural=natural+100*results{i,17}/total;
            elseif results{i,4}=='QB'
                artificial=artificial+100*results{i,17}/total;
            end
            if results{i,5}=='EQ'
                natural=natural+100*results{i,18}/total;
            elseif results{i,5}=='QB'
                artificial=artificial+100*results{i,18}/total;
            end
            if results{i,6}=='EQ'
                natural=natural+100*results{i,19}/total;
            elseif results{i,6}=='QB'
                artificial=artificial+100*results{i,19}/total;
            end
            if results{i,7}=='EQ'
                natural=natural+100*results{i,20}/total;
            elseif results{i,7}=='QB'
                artificial=artificial+100*results{i,20}/total;
            end
        end
    end
    
    a=sprintf('%.2f',natural);
    b=sprintf('%.2f',artificial);
        
    set(handles.text1,'string',strcat('Natural (%):',a));
    set(handles.text2,'string',strcat('Artificial (%):',b));
end
else
    set(handles.text1,'string',strcat('Natural (%): 0.00'));
    set(handles.text2,'string',strcat('Artificial (%): 0.00'));
end
