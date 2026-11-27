function [MDij, FMDij] = una_coppia3(iL, jL, da, de, omb, ll, cc, a0, e0)
    if nargin < 5; omb = 3.13; end   % omega_base dell'originale
    if nargin < 6; ll = 1; end       % p.ll dell'originale (p.l non e' usato da nessuna formula)
    if nargin < 7; cc = 0.1; end     % p.c (smorzamento) dell'originale
    if nargin < 8; a0 = .5; end      % origine della griglia in a (originale: AL = .5 + jL*da)
    if nargin < 9; e0 = .1; end      % origine della griglia in E (originale: ED = iL*de + .1)
% Corpo del doppio for di Luigi3.m per una coppia (iL,jL). Formule invariate;
% unica differenza di esecuzione: p passato per closure invece che come global.
    ED = iL*de + e0;
    AL = a0 + jL*da;
    p.c = cc;  p.a = AL;  p.b = 1.0;  p.g = 9.8;  p.l = 1;
    p.E = ED;   p.ll = ll;  p.e = 1.0;  p.omega_base = omb;

    w_forward  = linspace(1.0, 8.0, 150);
    w_backward = fliplr(w_forward);
    amp_fwd = zeros(size(w_forward));
    amp_bwd = zeros(size(w_backward));
    T_max = 300;
    tspan = [0 T_max];

    y0 = [0.05; 0.0];
    for i = 1:length(w_forward)
        p.wf = w_forward(i);
        [t, y] = ode45(@(t,y) ode_system(t, y, p), tspan, y0);
        phi  = y(:,1);
        t_ss = t > (T_max - 100);
        amp_fwd(i) = get_harmonic_amplitude(t(t_ss), phi(t_ss), p.wf);
        y0 = y(end,:)';
    end
    [MF, KKF] = max(amp_fwd);

    for i = 1:length(w_backward)
        p.wf = w_backward(i);
        [t, y] = ode45(@(t,y) ode_system(t, y, p), tspan, y0);
        phi  = y(:,1);
        t_ss = t > (T_max - 100);
        amp_bwd(i) = get_harmonic_amplitude(t(t_ss), phi(t_ss), p.wf);
        y0 = y(end,:)';
    end
    [MB, KKB] = max(amp_bwd);

    MDij  = abs(MF - MB);                                    % DM   di Luigi3.m
    FF    = w_forward(1, KKF);
    FB    = w_backward(1, KKB);
    FMDij = abs(FF - FB);                                    % FFDM di Luigi3.m
end

function dydt = ode_system(t, y, p)
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

function A_harm = get_harmonic_amplitude(t, phi_ss, wf)
    omega_resp = wf / 2;
    signal = phi_ss - mean(phi_ss);
    cos_component = (2 / length(signal)) * sum(signal .* cos(omega_resp * t));
    sin_component = (2 / length(signal)) * sum(signal .* sin(omega_resp * t));
    A_harm = sqrt(cos_component^2 + sin_component^2);
end
