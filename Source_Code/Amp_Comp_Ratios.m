function [C,SR,PMax,SMax,AmpRatio,Slog,Int] = Amp_Comp_Ratios( PT,ST,FT,Data,FData1,FData2,dt )
    Int=ST(1)-PT(1);
    Cv=Data(round(PT(1)/dt):round((PT(1)+Int)/dt));
    Pu=round(PT(1)/dt):round((PT(1)+Int)/dt);
    Cvv=Data(Pu+round((Int)/dt));
    C=(sum(Cvv.^2))./(sum(Cv.^2)); %complexity
    Vx1=FData1(round(PT(1)/dt):round(FT(1)/dt));
    Vx2=FData2(round(PT(1)/dt):round(FT(1)/dt));
    SR=(sum(Vx1.^2))./(sum(Vx2.^2)); %spectral ratio
    PMax=max(abs(Data(round(PT(1)/dt):round(ST(1)/dt))));
    SMax=max(Data(round(ST(1)/dt):round(FT(1)/dt)));
    AmpRatio= SMax/PMax;
    Slog=log10(SMax);  
end

