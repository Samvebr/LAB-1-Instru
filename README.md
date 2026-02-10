# LAB-1 Monitoreo del patrón y frecuencia respiratoria

Laboratorio número 1 de Instrumentación Biomédica y Biosensores.  
- Samuel Esteban Velandia Briceño. 
- Daniel Guillermo Espinosa Parra.
  
## INTRODUCCIÓN: 
La frecuencia respiratoria es el número de respiraciones que una persona realiza por minuto y constituye un signo vital importante que permite evaluar la eficiencia del sistema respiratorio y su adecuado funcionamiento. En adultos sanos en reposo, el rango normal se sitúa aproximadamente entre 12 y 20 respiraciones por minuto, aunque este valor puede variar con la edad, siendo generalmente mayor en recién nacidos y niños. La respiración normal, denominada eupnea, es rítmica y sin esfuerzo, y alteraciones en su frecuencia, profundidad o patrón pueden comprometer la ventilación y la oxigenación, además de servir como indicios clínicos de enfermedades sistémicas, neurológicas o metabólicas. El control del ritmo respiratorio depende del centro respiratorio localizado en el tronco encefálico, especialmente en la médula oblonga, el cual procesa información proveniente de distintos receptores y ajusta la ventilación para mantener un intercambio gaseoso adecuado. Entre los principales factores que regulan esta respuesta se encuentran los niveles de dióxido de carbono y oxígeno en la sangre, así como la actividad física, permitiendo conservar el equilibrio fisiológico del organismo. Asimismo, múltiples condiciones como enfermedades pulmonares, infecciones, alteraciones del sistema nervioso central, estrés o ejercicio intenso pueden modificar la frecuencia respiratoria, por lo que su análisis resulta fundamental para la valoración del estado de salud y la detección temprana de posibles alteraciones.

## OBJETIVOS: 

- Objetivo General:
  
Evaluar la influencia del habla o la verbalización sobre el patrón respiratorio mediante el análisis de los cambios en la frecuencia respiratoria, con el fin de comprender cómo distintas condiciones fisiológicas pueden modificar la dinámica normal de la respiración.

- Objetivos Especificos:

  
Reconocer y analizar las principales variables físicas involucradas en el proceso respiratorio para comprender su relación con el comportamiento del patrón respiratorio.


Desarrollar un sistema capaz de obtener el patrón respiratorio y calcular la frecuencia respiratoria, permitiendo observar su comportamiento bajo diferentes condiciones.


Identificar y comparar las variaciones del patrón respiratorio durante tareas de verbalización frente a estados de reposo, con el propósito de interpretar posibles cambios fisiológicos.


## REQUERIMIENTOS: 

-Módulo SP32
-Sensor de presión FSR40 
-Interfaz Matlab 
-Regleta de Proto-Board
-Cables y resistencias adecuadas. 

## Captura de y graficación de la señal en Tiempo real. 

A partir de este código en Matlab se hace la captura de la señal y el filtrado de la misma:  

```bash
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
```
Este es el código en Matlab que se encarga de abrir la imagen y realiza la transformada de fourier FFT en esta: 


```bash

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
```

## GRÁFICAS : 

- Esta es la gráfica de una persona en resposo sin realizar ninguna verbalilzación:
<img width="757" height="497" alt="image" src="https://github.com/user-attachments/assets/63a077c7-ba8f-4228-905e-3208580b7b0f" />

- Esta es la gráfica de una persona que se encuentra realizando una verbalilzación:

<img width="752" height="505" alt="image" src="https://github.com/user-attachments/assets/4875e8b8-e838-40e3-9ddb-14e0fe81ea3e" />
