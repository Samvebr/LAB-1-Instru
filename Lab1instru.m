clc;
clear;
close all;


Fs = 100;   % Frecuencia de muestreo [Hz]

answer = inputdlg("Ingrese el tiempo de adquisición (s):", ...
                  "Tiempo de adquisición", 1, {"30"});
if isempty(answer)
    error("Adquisición cancelada");
end

T = str2double(answer{1});
if isnan(T) || T <= 0
    error("Tiempo inválido");
end

N = Fs * T;


f_low  = 0.1;   % Hz
f_high = 1.0;   % Hz

[b,a] = butter(2, [f_low f_high]/(Fs/2), 'bandpass');
zf = zeros(max(length(a),length(b))-1,1);


puerto = "COM3";
baud   = 115200;

s = serialport(puerto, baud);
configureTerminator(s,"LF");
flush(s);
pause(2);

disp("Iniciando adquisición...");

resp_raw = zeros(N,1);
resp_f   = zeros(N,1);
t        = (0:N-1)/Fs;

k = 1;   % índice real de muestras válidas


figure;

h1 = animatedline('Color','r','LineWidth',0.8);
h2 = animatedline('Color','b','LineWidth',1.5);

xlabel("Tiempo [s]");
ylabel("Señal respiratoria");
title("Señal respiratoria cruda y filtrada");
legend("Cruda","Filtrada (0.1–1 Hz)");
grid on;
xlim([0 T]);


while k <= N

    linea = readline(s);              % leer línea del ESP32
    linea = strtrim(linea);           % quitar espacios

    % Extraer número aunque venga con texto
    nums = regexp(linea, '[-+]?\d*\.?\d+', 'match');

    if isempty(nums)
        continue                      % descarta líneas inválidas
    end

    y = str2double(nums{1});

    if isnan(y)
        continue
    end

    resp_raw(k) = y;

    % Filtrado pasa-banda
    [yf, zf] = filter(b, a, y, zf);
    resp_f(k) = yf;

    addpoints(h1, t(k), y);
    addpoints(h2, t(k), yf);

    if mod(k,5) == 0
        drawnow limitrate
    end

    k = k + 1;
end

disp("Adquisición finalizada.");
clear s


filename = sprintf("senal_respiratoria_filtrada_%ds.mat", round(T));
save(filename, "t", "resp_raw", "resp_f", "Fs");

disp("Archivo guardado:");
disp(filename);
