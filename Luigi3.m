  
clear; clc;
    da=2/10
    de=.2/10
    for iL=1:10;
        for jL=1:10

global p
    %% PARAMETERS
    ED=iL*de+.1;
    AL=.5+jL*da;
    p.c = 0.1;           % Damping coefficient
    p.a =AL;           % Parameter a
    p.b = 1.0;           % Parameter b
    p.g = 9.8;           % Gravity / restoring term coefficient
    p.l = 1;             % Length l
    p.E = ED;           % Parameter E
    p.ll  = 1;           % Parameter ll 
    p.e   = 1.0;         % Scaling parameter e
    p.omega_base = 3.13; % Base frequency omega

    %% FREQUENCY SWEEP SETTINGS
    % Extended range to properly cover the principal parametric resonance
    w_forward = linspace(1.0, 8.0, 150); 
    w_backward = fliplr(w_forward);

    amp_fwd = zeros(size(w_forward));
    amp_bwd = zeros(size(w_backward));

    T_max  = 300;        % Integration time per step (ensures steady state)
    tspan  = [0 T_max];
    %options = odeset('RelTol', 1e-7, 'AbsTol', 1e-9);

    %% ===== FORWARD SWEEP =====
    y0 = [0.05; 0.0]; % Initial conditions [phi(0); phi_dot(0)] for the very start
    fprintf('Processing Forward Sweep...\n');

    for i = 1:length(w_forward)
        p.wf = w_forward(i);
        % Solve ODE using ode45
        %[t,y] = ode45(@(t, y)ode_system(t, y, p), tspan, y0);
        [t, y] = ode45(@ode_system, tspan, y0);
        
        % Analyze the last 100 seconds (Steady State)
        phi = y(:,1);
        t_ss = t > (T_max - 100);
        phi_ss = phi(t_ss);
        t_ss_time = t(t_ss);
        
        % Extract fundamental harmonic amplitude cleanly
        amp_fwd(i) = get_harmonic_amplitude(t_ss_time, phi_ss, p.wf);
        
        % Continuation: use last state as starting point for next frequency
        [MF, KKF]=max(amp_fwd);
        y0 = y(end,:)';
    end


    %% ===== BACKWARD SWEEP =====
    fprintf('Processing Backward Sweep...\n');
    % y0 currently holds the final state of the forward sweep at w = 8.0, 
    % which serves as the correct starting point for the backward sweep!

    for i = 1:length(w_backward)
        p.wf = w_backward(i);
        
        % Solve ODE using ode45
        %[t, y] = ode45(@ode_system(t, y, p), tspan, y0, options);
        [t, y] = ode45(@ode_system, tspan, y0);
        
        % Analyze the last 100 seconds (Steady State)
        phi = y(:,1);
        t_ss = t > (T_max - 100);
        phi_ss = phi(t_ss);
        t_ss_time = t(t_ss);
        
        amp_bwd(i) = get_harmonic_amplitude(t_ss_time, phi_ss, p.wf);
        
        % Continuation: use last state for next frequency step
        [MB, KKB]=max(amp_bwd);
        y0 = y(end,:)';
    end
    
        DM=abs(MF-MB);
        MD(iL,jL)=DM
   
        FF=w_forward(1,KKF)
        FB=w_backward(1, KKB)
        
        FFDM=abs(FF-FB);
        FMD(iL,jL)=FFDM

end
end

    %% ===== PLOT =====
    %figure('Color', 'w');
    %plot(w_forward, amp_fwd, 'b-o', 'MarkerSize', 3, 'LineWidth', 1.5); hold on;
    %plot(w_backward, amp_bwd, 'r-o', 'MarkerSize', 3, 'LineWidth', 1.5);

    %xlabel('Forcing Frequency \omega_f');
    %ylabel('Steady-State Harmonic Amplitude of \phi');
    %title('Nonlinear Parametric Governor: Jumping Resonance & Hysteresis');
    %legend('Forward Sweep', 'Backward Sweep', 'Location', 'NorthEast');
    %grid on;
    SI
    M=SI


%% ===== ODE SYSTEM FUNCTION =====
function dydt = ode_system(t, y)
global p
    phi  = y(1);
    dphi = y(2);

    term_omega     = (p.omega_base)^2;
    forcing_term   = (term_omega + p.a * p.b * cos(p.wf * t));
    nonlinear_term = ((p.E / p.ll) * cos(phi) + 0.5 * sin(2 * phi));
    restoring_term = (p.g / p.ll) * sin(phi);

    dphi_dt  = dphi;
    ddphi_dt = -p.c * dphi + (forcing_term * nonlinear_term) - restoring_term;

    dydt = [dphi_dt; ddphi_dt];
end

%% ===== HARMONIC AMPLITUDE EXTRACTION HELPER =====
function A_harm = get_harmonic_amplitude(t, phi_ss, wf)
    % Extracts the fundamental harmonic component corresponding to the parametric response
    omega_resp = wf / 2; 
    
    % Discrete Fourier Transform projection onto sin and cos components
    dt = mean(diff(t));
    signal = phi_ss - mean(phi_ss); % Remove any DC bias
    
    cos_component = (2 / length(signal)) * sum(signal .* cos(omega_resp * t));
    sin_component = (2 / length(signal)) * sum(signal .* sin(omega_resp * t));
    
    A_harm = sqrt(cos_component^2 + sin_component^2);
end