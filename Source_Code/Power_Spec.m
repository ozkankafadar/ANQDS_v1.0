function [ Fr,PS,CF,Idx ] = Power_Spec(Data,Freq)
    
    N=length(Data);
    FFT_Data=fft(Data,N);
    PS = (2*abs(FFT_Data(1:floor(N/2+1)))).^2;
    Fr= Freq/2*linspace(0,1,N/2+1);

    t1=PS.*(2*pi*Fr').^2.5;
    index2=find(abs(t1)==max(abs(t1)));
    
    Fcw=Fr(1:index2);
    Lfc=length(Fcw);    
    
    for i=1:Lfc
        CF=Fcw(i);
    end
  
    [~, Idx] = min( abs(Fr - CF) );
end