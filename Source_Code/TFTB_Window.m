function W=TFTB_Window(Lw,Name,Param,Param2)
%   tftb_window	Window generation.
%	H=tftb_window(N,NAME,PARAM,PARAM2)
%	yields a window of length N with a given shape.
%
%	N      : length of the window
%	NAME   : name of the window shape (default : Hamming)
%	PARAM  : optional parameter
%	PARAM2 : second optional parameters
%
%	Possible names are :
%	'Hamming', 'Hanning', 'Nuttall',  'Papoulis', 'Harris',
%	'Rect',    'Triang',  'Bartlett', 'BartHann', 'Blackman'
%	'Gauss',   'Parzen',  'Kaiser',   'Dolph',    'Hanna'.
%	'Nutbess', 'spline',  'Flattop'
%
%	For the gaussian window, an optionnal parameter K
%	sets the value at both extremities. The default value is 0.005
%
%	For the Kaiser-Bessel window, an optionnal parameter
%	sets the scale. The default value is 3*pi.
%
%	For the Spline windows, h=tftb_window(N,'spline',nfreq,p)
%	yields a spline weighting function of order p and frequency
%	bandwidth proportional to nfreq.
%
%       Example: 
%        h=tftb_window(256,'Gauss',0.005); 
%        plot(0:255, h); axis([0,255,-0.1,1.1]); grid
%
%	See also DWINDOW.

%	F. Auger, June 1994 - November 1995.
%	Copyright (c) 1996 by CNRS (France).
%
%	------------------- CONFIDENTIAL PROGRAM -------------------- 
%	This program can not be used without the authorization of its
%	author(s). For any comment or bug report, please send e-mail to 
%	f.auger@ieee.org 
%
%	References : 
%	- F.J. Harris, "On the use of windows for harmonic
%	analysis with the discrete Fourier transform",
%	Proceedings of the IEEE, Vol 66, n¡1, pp 51-83, 1978.
%	- A.H. Nuttal, "A two-parameter class of Bessel weighting 
%	functions for spectral analysis or array processing", 
%	IEEE Trans on ASSP, Vol 31, pp 1309-1311, Oct 1983.
%	- Y. Ho Ha, J.A. Pearce, "A New window and comparison to
%	standard windows", Trans IEEE ASSP, Vol 37, No 2, 
%	pp 298-300, February 1989.
%	- C.S. Burrus, Multiband Least Squares FIR Filter Design,
%	Trans IEEE SP, Vol 43, No 2, pp 412-421, February 1995.

if (nargin==0), error ( 'at least 1 parameter is required' ); end;
if (Lw<=0), error('N should be strictly positive.'); end;
if (nargin==1), Name= 'Hamming'; end ;
Name=upper(Name);
if strcmp(Name,'RECTANG') | strcmp(Name,'RECT'), 
 W=ones(Lw,1);
elseif strcmp(Name,'HAMMING'),
 W=0.54 - 0.46*cos(2.0*pi*(1:Lw)'/(Lw+1));
elseif strcmp(Name,'HANNING') | strcmp(Name,'HANN'),
 W=0.50 - 0.50*cos(2.0*pi*(1:Lw)'/(Lw+1));
elseif strcmp(Name,'KAISER'),
 if (nargin==3), beta=Param; else beta=3.0*pi; end;
 ind=(-(Lw-1)/2:(Lw-1)/2)' *2/Lw; beta=3.0*pi;
 W=bessel(0,j*beta*sqrt(1.0-ind.^2))/real(bessel(0,j*beta));
elseif strcmp(Name,'NUTTALL'),
 ind=(-(Lw-1)/2:(Lw-1)/2)' *2.0*pi/Lw;
 W=+0.3635819 ...
   +0.4891775*cos(    ind) ...
   +0.1363995*cos(2.0*ind) ...
   +0.0106411*cos(3.0*ind) ;
elseif strcmp(Name,'BLACKMAN'),
 ind=(-(Lw-1)/2:(Lw-1)/2)' *2.0*pi/Lw;
 W= +0.42 + 0.50*cos(ind) + 0.08*cos(2.0*ind) ;
elseif strcmp(Name,'HARRIS'),
 ind=(1:Lw)' *2.0*pi/(Lw+1);
 W=+0.35875 ...
   -0.48829 *cos(    ind) ...
   +0.14128 *cos(2.0*ind) ...
   -0.01168 *cos(3.0*ind);
elseif strcmp(Name,'BARTLETT') | strcmp(Name,'TRIANG'),
 W=2.0*min((1:Lw),(Lw:-1:1))'/(Lw+1);
elseif strcmp(Name,'BARTHANN'),
 W=  0.38 * (1.0-cos(2.0*pi*(1:Lw)/(Lw+1))') ...
   + 0.48 * min((1:Lw),(Lw:-1:1))'/(Lw+1);
elseif strcmp(Name,'PAPOULIS'),
 ind=(1:Lw)'*pi/(Lw+1); W=sin(ind);
elseif strcmp(Name,'GAUSS'),
 if (nargin==3), K=Param; else K=0.005; end;
 W= exp(log(K) * linspace(-1,1,Lw)'.^2 );
elseif strcmp(Name,'PARZEN'),
 ind=abs(-(Lw-1)/2:(Lw-1)/2)'*2/Lw; temp=2*(1.0-ind).^3;
 W= min(temp-(1-2.0*ind).^3,temp);
elseif strcmp(Name,'HANNA'),
 if (nargin==3), L=Param; else L=1; end;
 ind=(0:Lw-1)';W=sin((2*ind+1)*pi/(2*Lw)).^(2*L);
elseif strcmp(Name,'DOLPH') | strcmp(Name,'DOLF'),
 if (rem(Lw,2)==0), oddN=1; Lw=2*Lw+1; else oddN=0; end;
 if (nargin==3), A=10^(Param/20); else A=1e-3; end;
 K=Lw-1; Z0=cosh(acosh(1.0/A)/K); x0=acos(1/Z0)/pi; x=(0:K)/Lw; 
 indices1=find((x<x0)|(x>1-x0));
 indices2=find((x>=x0)&(x<=1-x0));
 W(indices1)= cosh(K*acosh(Z0*cos(pi*x(indices1))));
 W(indices2)= cos(K*acos(Z0*cos(pi*x(indices2))));
 W=fftshift(real(ifft(A*real(W))));W=W'/W(K/2+1);
 if oddN, W=W(2:2:K); end;
elseif strcmp(Name,'NUTBESS'),
 if (nargin==3), beta=Param; nu=0.5; 
 elseif (nargin==4), beta=Param; nu=Param2;
 else beta=3*pi; nu=0.5;
 end;
 ind=(-(Lw-1)/2:(Lw-1)/2)' *2/Lw; 
 W=sqrt(1-ind.^2).^nu .* ...
   real(bessel(nu,j*beta*sqrt(1.0-ind.^2)))/real(bessel(nu,j*beta));
elseif strcmp(Name,'SPLINE'),
 if (nargin < 3),
  error('Three or four parameters required for spline windows');
 elseif (nargin==3),
  nfreq=Param; p=pi*Lw*nfreq/10.0;
 else nfreq=Param; p=Param2;
 end;
  ind=(-(Lw-1)/2:(Lw-1)/2)'; 
  W=sinc((0.5*nfreq/p)*ind) .^ p;
elseif strcmp(Name,'FLATTOP'),
 ind=(-(Lw-1)/2:(Lw-1)/2)' *2.0*pi/(Lw-1);
 W=+0.2810639 ...
   +0.5208972*cos(    ind) ...
   +0.1980399*cos(2.0*ind) ;
else error('unknown window name');
end;
