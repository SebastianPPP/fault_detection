% Parametry systemu
clear all;
close all;
clc;

params.klm = 15.86;         % przepływ L -> M
params.klb = 7.04;          % przepływ L -> B
params.kmr = 10.48;         % przepływ M -> R
params.krb = 6.93;          % przepływ R -> B (normalny)

params.kl = 6.04;       % lewa pompa (normalna)
params.kr = 6.04;           % prawa pompa 

params.al = 64.00;
params.am = 64.00;
params.ar = 64.00;
params.ab = 1044.00;
params.vol = 15990.00;

% Warunki początkowe
x0 = [41; 39; 40.39];            % początkowe poziomy wody
u = [4.35; 8.76];                 % napięcia dla pomp
tspan = [0 200];            % zakres czasu symulacji

% Symulacja normalna (brak awarii)
[t_normal, x_real_normal] = ode45(@(t, x_real) three_tank_model(t, x_real, u, params), tspan, x0);

% Symulacja z awariami (logika zawarta w funkcji)
[t_fault, x_real_fault] = ode45(@(t, x_real) three_tank_model_faulty(t, x_real, u, params), tspan, x0);

% Obliczanie przepływów – normalna
Q_LM_normal = calc_flow_LM(x_real_normal(:,1), x_real_normal(:,2), params.klm);
Q_LB_normal = calc_flow_LB(x_real_normal(:,1), x_real_normal(:,3), params.klb);
Q_MR_normal = calc_flow_MR(x_real_normal(:,2), x_real_normal(:,3), params.kmr);
Q_RB_normal = calc_flow_RB(x_real_normal(:,3), x_real_normal(:,3), params.krb);

% Obliczanie przepływów – z awarią
Q_LM_fault = calc_flow_LM(x_real_fault(:,1), x_real_fault(:,2), params.klm);
Q_LB_fault = calc_flow_LB(x_real_fault(:,1), x_real_fault(:,3), params.klb);
Q_MR_fault = calc_flow_MR(x_real_fault(:,2), x_real_fault(:,3), params.kmr);
Q_RB_fault = calc_flow_RB(x_real_fault(:,3), x_real_fault(:,3), params.krb);

% Interpolacja danych z awarii do czasu normalnego
Q_LM_fault_interp = interp1(t_fault, Q_LM_fault, t_normal, 'linear', 'extrap');
Q_LB_fault_interp = interp1(t_fault, Q_LB_fault, t_normal, 'linear', 'extrap');
Q_MR_fault_interp = interp1(t_fault, Q_MR_fault, t_normal, 'linear', 'extrap');
Q_RB_fault_interp = interp1(t_fault, Q_RB_fault, t_normal, 'linear', 'extrap');
x_fault_interp = interp1(t_fault, x_real_fault, t_normal, 'linear', 'extrap');

sensor_noise = zeros(size(x_fault_interp)); % inicjalizacja szumu

for i = 1:length(t_normal)
    if t_normal(i) >200
        % Zepsuty czujnik w zbiorniku R – szum rośnie do wartości ±10
        noise_amplitude = 10; % np. 0 -> 10 przez 100 sekund
        sensor_noise(i, 3) = noise_amplitude * randn(); % tylko R
    end
end

x_fault_interp_with_noise = x_fault_interp + sensor_noise;


% Dodanie szumu biały do poziomów i przepływów
noise_level = 0.2; % Zmienna określająca intensywność szumu
Q_LM_fault_with_noise = Q_LM_fault_interp + noise_level * randn(length(t_normal), 1);
Q_LB_fault_with_noise = Q_LB_fault_interp + noise_level * randn(length(t_normal), 1);
Q_MR_fault_with_noise = Q_MR_fault_interp + noise_level * randn(length(t_normal), 1);
Q_RB_fault_with_noise = Q_RB_fault_interp + noise_level * randn(length(t_normal), 1);

% Dodanie szumu do interpolowanych poziomów z awarią
x_fault_with_noise = x_fault_interp_with_noise + noise_level * randn(length(t_normal), 3);

% Obliczanie residuów (różnice) z szumem dla poziomów
residuals_level_L = x_real_normal(:,1) - x_fault_with_noise(:,1);
residuals_level_M = x_real_normal(:,2) - x_fault_with_noise(:,2);
residuals_level_R = x_real_normal(:,3) - x_fault_with_noise(:,3);


% Obliczanie residuów przepływów z awarią
residuals_flow_LM = Q_LM_normal - Q_LM_fault_with_noise;
residuals_flow_LB = Q_LB_normal - Q_LB_fault_with_noise;
residuals_flow_MR = Q_MR_normal - Q_MR_fault_with_noise;
residuals_flow_RB = Q_RB_normal - Q_RB_fault_with_noise;

% === WYKRESY ===

% Poziomy wody - figura 1
figure;
plot(t_normal, x_real_normal(:,1), 'r', ...
     t_normal, x_real_normal(:,2), 'g', ...
     t_normal, x_real_normal(:,3), 'b');
hold on;
plot(t_normal, x_fault_with_noise(:,1), 'r--', ...
     t_normal, x_fault_with_noise(:,2), 'g--', ...
     t_normal, x_fault_with_noise(:,3), 'b--');
legend('h_L normal', 'h_M normal', 'h_R normal', 'h_L fault', 'h_M fault', 'h_R fault');
xlabel('Time [s]');
ylabel('Water level [cm]');
title('Water Levels: Normal vs Faulty System');
grid on;

% Residuła poziomów - figura 2
figure;
plot(t_normal, residuals_level_L, 'r', ...
     t_normal, residuals_level_M, 'g', ...
     t_normal, residuals_level_R, 'b');
hold on;
yline(2, 'k--', 'Threshold +2cm');
yline(-2, 'k--', 'Threshold -2cm');
legend('Residual h_L', 'Residual h_M', 'Residual h_R', 'Threshold');
xlabel('Time [s]');
ylabel('Residual [cm]');
title('Water Level Residuals');
grid on;

% Residuła przepływów - figura 3
figure;
plot(t_normal, residuals_flow_LM, 'r', ...
     t_normal, residuals_flow_LB, 'g', ...
     t_normal, residuals_flow_MR, 'b', ...
     t_normal, residuals_flow_RB, 'k');
hold on;
yline(3, 'm--', 'Threshold +3cm^3/s');
yline(-3, 'm--', 'Threshold -3cm^3/s');
legend('Residual Q_LM', 'Residual Q_LB', 'Residual Q_MR', 'Residual Q_RB', 'Threshold');
xlabel('Time [s]');
ylabel('Residual [cm^3/s]');
title('Flow Rate Residuals (Fault Detection)');
grid on;


% Funkcje przepływów

function Q = calc_flow_LM(hL, hM, klm)
    Q = klm * max(hL - hM, 0);
end

function Q = calc_flow_LB(hL, hB, klb)
    Q = klb * max(hL - hB, 0);
end

function Q = calc_flow_MR(hM, hR, kmr)
    Q = kmr * max(hM - hR, 0);
end

function Q = calc_flow_RB(hR, hB, krb)
    Q = krb * max(hR - hB, 0);
end
