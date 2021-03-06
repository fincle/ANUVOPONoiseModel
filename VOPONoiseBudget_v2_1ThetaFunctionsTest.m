%% NOISE BUDGET SCRIPT FOR ANU VOPO PROJECT

% Authors: Andrew Wade
% Date: 6 Nov 2015
%
% Notes: 
% -All units in standard SI unless otherwise stated
% - fluctating components writeen as x_delta
% - Steady state components written as x_ss
%
% Previous Versions: NA
%
%
% Comments: The idea is to build this script out to the point where
% indivual noise models can be spun out into indivdual functions that can
% be called from the main script.  This way new and updated models can
% easly be added/modified and swapped out.
%
% This test is combining THETA matrices and Chi/X vectors in the driver
% program rather than wrapped in a function. Then quadtrature rotating

clear all  %Clear the decks
close all

%Standard physical constants
c = 3e8; %[m/s]
h = 6.626e-34; %[J.s]
n = 1; %Refractive index of medium
lambdaFund = 1064e-9; %[m] wave length of light
lambdaHarm = 532e-9; %[m] wave length of light


%%%%%%%%%%%%%%%%%%%%% Cavity parameters %%%%%%%%%%%%%%%%%%%%%%%
L = 0.345+0.01*0.83; %[m] total effective cavity round trip length

%Fundamental field parameters
Rain = 0.845;%+0.0001; %Input coupler reflectivity
Raout = 1; %Output (transmission) coupler reflectivity
Lossa = 1-0.989; %Intra-cavity loss

% Harmonic field parameters
Rbin = 0.7;
Rbout = 1;  %Assume no outcoupling in other mirrors
Lossb = 0.046; %Estimate of intracavity loss


%Derived quantities
tau = L./c; % Cavity round trip time

ka_in = (1-sqrt(Rain))./(tau); %Front coupler decay rate
ka_out = (1-sqrt(Raout))./(tau); %Front coupler decay rate
ka_l = (1-sqrt(1-Lossa))./(tau); %Front coupler decay rate
ka_total = ka_in + ka_out + ka_l; %The total decay rate of the whole cavity


kb_in = (1-sqrt(Rbin))./(tau); %Front coupler decay rate
kb_out = (1-sqrt(Rbout))./(tau); %Front coupler decay rate
kb_l = (1-sqrt(1-Lossb))./(tau); %Front coupler decay rate
kb_total = kb_in + kb_out + kb_l; %The total decay rate of the whole cavity

% Output some useful cavity values
% FSR = 1/tau;
% FundFinesse = (pi.*(Rain.*Raout.*(1-Lossa))^0.25)./(1-(Rain.*Raout.*(1-Lossa))^0.5);
% FundLineWidth = FSR./Finesse;

%Crystal Parameters
L_c = 10e-3; % [m]Crystal length (This may need to be tweeked to get the effective length of a gaussian focused beam through a crystal
epsilon_0 = 1090.5; % [s^-1] Non-linear coupling strength
nKTP_a = 1.830; % RI of fundamental
nKTP_b = 1.889; %RI of harmonic 
dndT_a = 1.4774*10^-5; % [1/K]Temp gradient of fundamental
dndT_b = 2.4188*10^-5;% [1/K]Temp gradient of harmonic
alpha_KTP = 6.7e-6; % [m/(m.K)] First order expation rate of KTP

%%%%%%%%%%%%%%%%%%%%%%%

% Speificies of input power etc
Delta_a0 = [0 0]; % On resonance with no fluctuations in harmonic and fundamental
Delta_b0 = [0 0];

epsilon = [epsilon_0 0];

Ain = 0;
Bin = sqrt(105e-3/(h*c/lambdaHarm)); %[W] Incident pump amplitude put in units of sqrt(photon/s)

%%%%%%%%%%%%%%%%%%%%

%Lambda matrix for converting Chi to X

LambdaMat = [1 1 0 0;1i -1i 0 0;0 0 1 1; 0 0 1i -1i]; %Defining transfer matrix that converts the creation anihilation form of 4x1 Fourier domain matrixes to 4x1 quadtrature terms

%% Example scanning measuring quadrature, and comparing detuned and undetuned

Omega = 0;
phi = linspace(0,pi,1000);
Vin = [1;1;1;1]; % Assume input port fields are vacuum
Vout = [1;1;1;1]; % Assume out port fields are vacuum
Vl = [1;1;1;1];

THETA_in = THETA_in(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a0,Delta_b0);
THETA_out = THETA_out(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a0,Delta_b0);
THETA_l = THETA_loss(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a0,Delta_b0);
THETA_Delta = THETA_Delta(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a0,Delta_b0);
THETA_epsilon = THETA_epsilon(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a0,Delta_b0);
%Setting offset for Delta_a_ss [ka_total*0.01 0] and then again for zero offset to compair; 

X_in = sqrt(Vin);
X_out = sqrt(Vout);
X_l = sqrt(Vl);
X_Delta = LambdaMat*[Delta_a0(2);Delta_a0(2);Delta_b0(2);Delta_b0(2)];
X_epsilon = LambdaMat*[epsilon(2);conj(epsilon(2));epsilon(2);conj(epsilon(2))];

for jj = 1:length(phi)
     [Vrefl1(jj),Vrefl2(jj)] = VTheta(THETA_in,X_in,THETA_out,X_out,THETA_l,X_l,THETA_Delta,X_Delta,THETA_epsilon,X_epsilon,phi(jj));
end
%% 


figure(1)
NP = plot(phi,10*log10(Vrefl1),phi,10*log10(Vrefl2),'--');
%NP(1).LineWidth = 2;
% axis([min(Omega/2/pi),max(Omega/2/pi),-30,30])
legend('V1','V2')
xlabel('Frequency from Resonance [MHz]')
ylabel('V_{relf} [dBm rel SN]')
set(gca,'FontSize',18)

%%


% THETA_in = THETA_in(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a,Delta_b)
% THETA_out = THETA_out(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a,Delta_b)
% THETA_loss = THETA_loss(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a,Delta_b)
% THETA_epsilon = THETA_epsilon(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a,Delta_b)
% THETA_Delta = THETA_Delta(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a,Delta_b)
% 
% phi = 0;
% 
% THETA_in_phi = quadRotation(phi)*THETA_in
% THETHA_out_phi = quadRotation(phi)*THETA_out
% THETHA_loss_phi = quadRotation(phi)*THETA_loss
% THETHA_epsilon_phi = quadRotation(phi)*THETA_epsilon
% THETHA_Delta_phi = quadRotation(phi)*THETA_Delta
% 


% 




% %% Example length noise parameter
% Omega = 0; %zero sideband detuning
% lengthnoise = logspace(-16,1,17); %going from 10^-16-10 m/rt(Hz)
% FFreq = logspace(1,5,1000); %looking at 1Hz to 100kHz
% 
% for i = 1:length(lengthnoise)  %with length noise
%     [Delta_a_PSD(:,:,i),Delta_b_PSD(:,:,i),lengthNoiseRMS(i,:),lengthNoiseSpect(i,:)] = cavityLengthNoise(FFreq,lambdaFund,lambdaHarm,L,lengthnoise(i)); %trying out my shitty length noise stuff
%     
%     [Vrefl1_LN(i),Vrefl2_LN(i)] = VreflTransfer(Omega,Ain,Bin,epsilon,ka_in,ka_out,ka_l,kb_in,kb_out,kb_l,Delta_a_PSD(:,:,i).',Delta_b_PSD(:,:,i).',Vin,Vout);
% 
% end
% 
% theta = linspace(0,4*pi,10000);
% for ii = 1:length(theta)
%     Voutput1(ii,:,:) = sin(theta(ii)/2).^2.*Vrefl1_LN+cos(theta(ii)/2).^2.*Vrefl2_LN;
%     Voutput2(ii,:,:) = cos(theta(ii)/2).^2.*Vrefl1_LN+sin(theta(ii)/2).^2.*Vrefl2_LN;
% 
% end
% 
% figure(1)
% loglog(FFreq,lengthNoiseRMS)
% 
%  figure(2)
% NP = plot(theta,10*log10(Voutput1),theta,10*log10(Voutput2),'--');
% %NP(1).LineWidth = 2;
% % axis([min(Omega/2/pi),max(Omega/2/pi),-30,30])
% legend('V1','V2')
% xlabel('Pump phase')
% ylabel('V_{relf} [dBm rel SN]')
% set(gca,'FontSize',18)
