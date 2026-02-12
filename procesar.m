clc;
clear;
close all;


[file, path] = uigetfile("*.mat", "Seleccione el archivo de señal respiratoria");

if isequal(file,0)
    error("No se seleccionó ningún archivo");
end

filename = fullfile(path, file);
load(filename);

disp("Archivo cargado:");
disp(filename);

whos


if ~exist("t","var") || ~exist("resp_raw","var") || ~exist("Fs","var")
    error("El archivo no contiene las variables necesarias");
end

N = length(resp_raw);

figure;

subplot(2,1,1)
plot(t, resp_raw, 'r', 'LineWidth', 0.8); hold on;

if exist("resp_f","var")
    plot(t, resp_f, 'b', 'LineWidth', 1.5);
    legend("Cruda","Filtrada");
else
    legend("Cruda");
end

xlabel("Tiempo [s]");
ylabel("Señal respiratoria");
title("Señal respiratoria en el tiempo");
grid on;




if exist("resp_f","var")
    x = resp_f - mean(resp_f);
else
    x = resp_raw - mean(resp_raw);
end

X = fft(x);
f = (0:N-1)*(Fs/N);

% Magnitud unilateral
X_mag = abs(X)/N;
X_mag = X_mag(1:floor(N/2));
f     = f(1:floor(N/2));

subplot(2,1,2)
plot(f, X_mag, 'g', 'LineWidth', 1.2);
xlim([0 2]);   % respiración está aquí
xlabel("Frecuencia [Hz]");
ylabel("Magnitud");
title("Transformada de Fourier (FFT)");
grid on;
