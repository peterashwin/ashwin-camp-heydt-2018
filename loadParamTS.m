% loadParamTS
%       loads control parameters for time-series run
%
runNumber = 562;
userNumber = 2;
fullRunNumber = userNumber*10.^4+runNumber;
%
plotfigs = true;        % set to true to plot figures
savefigs = true;        % set to true to save figures to file
savedata = true;        % set to true to save output data to file
%
pfpath = './Params/TSruns/';     % location for saved parameter files
sfpath = './SavedData/TSruns/';  % location for date save files
ffpath = './Figures/TSruns/';    % location for figure save files
%
% Uncomment to seed random number generator for reproducibility
seed = 136;
rng(seed,'twister'); 
%
p.model=5;
[p, mname] = loadModel(p);
% model options are
%   1=Palliard Parrenin 2004
%   2=Saltzmann Maasch 1991
%   3=van der Pol as in de Saedleleer et al 2013
%   4=van der Pol - Duffing
%   5=Tziperman-Gildor2003 %% added by AH
%   6=phase oscillator - Mitsui et al 2015
%   7=LY
%   8=A06
%
p.forcing=1;
normflg = 1; % normalization choice for DCW forcing
% forcing options are
%   1=(quasi) periodic (sum of 2 sinusoids)
%   2=Integrated Summer Insolation
%   3=de Saedeleer et al forcing with sum of obliquity and precession
%       normflg choses normalization option:
%           1 - absolute maximum = 1
%           2 - standard deviation = 1
%
% detuning
p.tau=1.0;
% integration transient time, maximum time, reporting timestep (kyr)
%tstart=-1500
%ttrans=-1000;  % time (kyr) for transient
%tmax=0;  % for integrated summer forcing, need tmax < 5000
tstart=0;
ttrans=1000;  % time (kyr) for transient
tmax=2500;  % for integrated summer forcing, need tmax < 5000
plotpoinc=false;
%plotpoinc=true; % to only plot p-section
dt = 1;     % time step (kyr) for returned solution
%
% Initial Conditions
% FIXED FOR ONE IC!
nIC = 4;      % number of runs - different ICs
% Initial state vector
yinit=zeros(2*p.N+1,nIC);
%yinit(1,:)=rand(1, nIC);
yinit(1,:)=(p.vrange1(2)-p.vrange1(1))*rand(1, nIC)+p.vrange1(1);
yinit(2,:)=(p.vrange2(2)-p.vrange2(1))*rand(1, nIC)+p.vrange2(1);
% Random unit vector for Ly.Exp. IC
for iIC = 1:nIC
  temp = rand(p.N,1);
  yinit(p.N+1:2*p.N,iIC)= temp./norm(temp,2);
  % for SM 
  %yinit(1,iIC)=yinit(1,iIC)*50;
end
%
% forcing dependent parameters
switch p.forcing
    case 1
        fname = 'QP';
        % periodic: 2-frequency
        % obliquity frequency
        p.omega1=2*pi/41.0;
        % precession frequency
        p.omega2=2*pi/23.0;
        % select forcing parameter values from scan
        p.kt1 = 0.0;     % amplitude - 41 kyr     
        p.kt2 = 0.0;     % amplitude - 23 kyr
    case 2
        % summer integrated insolation
        fname = 'IS';
        % latitude for integrated insolation
        insol_lat = 65;
        % select forcing parameter values from scan
        p.kt1 = 0.2727;     % amplitude - 41 kyr     
        p.kt2 = 275;        % threshold
        %
        % ---- don't edit below here for this forcing ----
        % get  % get interpolant coeff
        p.insolcf = get_integrated_insol(insol_lat, p.kt2, ttrans);
    case 3
        % de Saedeleer forcing: load coeffs
        fname0 = 'DCW';
        %
        % select forcing parameter values from scan
        p.kt1 = 0.25;     % amplitude - obliquity modes     
        p.kt2 = 0.75;        % amplitude - precession modes
        %
        % ---- don't edit below here for this forcing ----
        % get obliquity & precession coefficients and setup normalization 
        load('./Insolation/DCW/dcwcoeffs.txt','dcwc')
        p.dcwcoeffs=dcwcoeffs;
        % normalization constants for obliquity and precession components
        n_obl=15;	% number of obliquity modes
        c_obl = sqrt(dcwcoeffs(1:n_obl,2).^2+dcwcoeffs(1:n_obl,3).^2);
        c_prc = sqrt(dcwcoeffs(n_obl+1:end,2).^2+dcwcoeffs(n_obl+1:end,3).^2);
        switch normflg
            case 1  % max.abs.value=1
                p.f1norm=norm(c_obl,1);
                p.f2norm=norm(c_prc,1);
                fname = sprintf('%sn1',fname0);
            case 2 % std.dev = 1;
                p.f1norm=norm(c_obl,2)/sqrt(2);
                p.f2norm=norm(c_prc,2)/sqrt(2);
                fname = sprintf('%sn2',fname0); 
            case 3 % no normalization
                p.f1norm=(norm(c_obl,2)+norm(c_prc,2))/sqrt(2);
                p.f2norm=p.f1norm;
            otherwise
                disp(sprintf('DCW normalization option not known'));
                keyboard
        end % switch normflg
    otherwise
        sprintf('Forcing option not known')
        keyboard
end % switch p.forcing
% core of save and figure filenames
basefilename = sprintf('IceAgeTS_%s_%s_r%i',mname,fname,fullRunNumber);
%
if (savefigs | savedata)
    pfile = sprintf('%s%s_param.m',pfpath,basefilename);
    copyfile('loadParamTS.m',pfile,'f');  %saves (overwrites) parameter file 
end %if

