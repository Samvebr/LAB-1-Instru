# LAB-1 Monitoreo del patrón y frecuencia respiratoria

  
## INTRODUCCIÓN: 
La frecuencia respiratoria es el número de respiraciones que una persona realiza por minuto y constituye un signo vital importante que permite evaluar la eficiencia del sistema respiratorio y su adecuado funcionamiento. En adultos sanos en reposo, el rango normal se sitúa aproximadamente entre 12 y 20 respiraciones por minuto, aunque este valor puede variar con la edad, siendo generalmente mayor en recién nacidos y niños. La respiración normal, denominada eupnea, es rítmica y sin esfuerzo, y alteraciones en su frecuencia, profundidad o patrón pueden comprometer la ventilación y la oxigenación, además de servir como indicios clínicos de enfermedades sistémicas, neurológicas o metabólicas.}

<p align="center">
<img width="474" height="206" alt="Image" src="https://github.com/user-attachments/assets/eaebf699-c5db-4b9b-886b-4a9733961098" />
</p>  
<p align="center">
Figura 1. Ciclo respiratorio.
</p>
  
El control del ritmo respiratorio depende del centro respiratorio localizado en el tronco encefálico, especialmente en la médula oblonga, el cual procesa información proveniente de distintos receptores y ajusta la ventilación para mantener un intercambio gaseoso adecuado. Entre los principales factores que regulan esta respuesta se encuentran los niveles de dióxido de carbono y oxígeno en la sangre, así como la actividad física, permitiendo conservar el equilibrio fisiológico del organismo. Asimismo, múltiples condiciones como enfermedades pulmonares, infecciones, alteraciones del sistema nervioso central, estrés o ejercicio intenso pueden modificar la frecuencia respiratoria, por lo que su análisis resulta fundamental para la valoración del estado de salud y la detección temprana de posibles alteraciones.

## OBJETIVOS: 

- Objetivo General:
  
Evaluar la influencia del habla o la verbalización sobre el patrón respiratorio mediante el análisis de los cambios en la frecuencia respiratoria, con el fin de comprender cómo distintas condiciones fisiológicas pueden modificar la dinámica normal de la respiración.

- Objetivos Especificos:

  
Reconocer y analizar las principales variables físicas involucradas en el proceso respiratorio para comprender su relación con el comportamiento del patrón respiratorio.


Desarrollar un sistema capaz de obtener el patrón respiratorio y calcular la frecuencia respiratoria, permitiendo observar su comportamiento bajo diferentes condiciones.


Identificar y comparar las variaciones del patrón respiratorio durante tareas de verbalización frente a estados de reposo, con el propósito de interpretar posibles cambios fisiológicos.


## MATERIALES Y PROCEDIMIENTO: 

### Materiales
- Módulo SP32
- Sensor de presión FSR40 
- Interfaz Matlab 
- Regleta de Proto-Board
- Cables y resistencias adecuadas.
- Amplificador de instrumentación INA60

### Procedimiento.

- Tomando en cuenta las caracteristica resistiva del sensor de presión se toma la decisión de usar un amplificador de instrumentación INA60 con fin de amplificar
la señal aproximadamente 100 veces. A continuación se muestra el montaje donde se evidencia la ESP32 y la conexiones hechas.

<p align="center">
<img width="474" height="206" alt="Image" src="https://github.com/user-attachments/assets/2bbd953c-863a-4d3c-a8c5-084fa8e70434" />
<p/>

<p align="center">
Figura 2. Montaje físico donde se observa la implementación de los elementos anteriormente mencionados.
<p/>

- La toma de la señal es en el epigastrio, más especificamente en el area del diafragma, el principio de captura del sensor es detectar los cambios de presión que se genera al inhalar y exhalar aire, donde se ve una clara distensión y contracción del diafragma al respirar, Se pega el sensor en el area anteriormente mencionada con cinta micropore para evitar lastimar la piel del sujeto en cuestion. Siguiente a esto se inicia la medición de datos en dos partes:
  
- En reposo durante 30 segundos.
- Mientras se sostiene una conversación durante 30 segundos.



## Adquisición y gráficas

Nuestra interfaz y adquisición se ve desarrollada en Matlab, a continuación se explica el funcionamiento del codigo:


```bash
clc;
clear;
close all;

Fs = 100;   

answer = inputdlg("Ingrese el tiempo de adquisición (s):", ...
                  "Tiempo de adquisición", 1, {"30"});
if isempty(answer)
    error("Adquisición cancelada");
end

T = str2double(answer{1});
if isnan(T) || T <= 0
    error("Tiempo inválido");
end
```
Definimos una frecuencia de muestreo de 100 Hz y un imput donde podemos ingresar el tiempo que deseamos para capturar la señal, en este caso 30 segundos.
```bash 

N = Fs * T;


f_low  = 0.1;   % Hz
f_high = 1.0;   % Hz

[b,a] = butter(2, [f_low f_high]/(Fs/2), 'bandpass');
zf = zeros(max(length(a),length(b))-1,1);
```
Procedemos a diseñar nuestro filtro, en este caso un Butterworth pasa-banda de entre 0.1 y 1 Hz
```bash 

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

k = 1;   % índice real de muestras válidas}
```
Se habilita el puerto COM para la lectura de la señal procedente del ADC de la ESP32 y adicionalmente la señal procesada.

```bash

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

    linea = readline(s);              
    linea = strtrim(linea);          


    nums = regexp(linea, '[-+]?\d*\.?\d+', 'match');

    if isempty(nums)
        continue                      
    end

    y = str2double(nums{1});

    if isnan(y)
        continue
    end

    resp_raw(k) = y;

  
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
```
Se grafíca la señal y se aplica el filtro, teniendo de color azul la señal filtrada y roja la señal sin procesamiento.

```bash 

filename = sprintf("senal_respiratoria_filtrada_%ds.mat", round(T));
save(filename, "t", "resp_raw", "resp_f", "Fs");

disp("Archivo guardado:");
disp(filename);
```
Finalmente se almacena la señal en la carpeta correspondiente

## Procesamiento de la señal (FFT)

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
```
Se cargan las señales desde la carpeta, teniendo la posibilidad de escoger que señal se desea procesar.
```bash

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
```
Se cargan las señales anteriormente graficadas.

```bash

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
Se le hace la FFT a la señal y se grafica.

## GRÁFICAS : 

- Esta es la gráfica de una persona en resposo sin realizar ninguna verbalilzación:
  
<p align="center">
<img width="757" height="497" alt="image" src="https://github.com/user-attachments/assets/63a077c7-ba8f-4228-905e-3208580b7b0f" />
<p/>
  
- Esta es la gráfica de una persona que se encuentra realizando una verbalilzación:
  
<p align="center">
<img width="752" height="505" alt="image" src="https://github.com/user-attachments/assets/4875e8b8-e838-40e3-9ddb-14e0fe81ea3e" />
<p/>


## ANALÍSIS: 

Al observar las señales respiratorias, se identifican semejanzas importantes: en ambos casos la respiración mantiene un patrón periódico y la frecuencia dominante se ubica aproximadamente entre 0.2 y 0.22 Hz las que corresponden a 12 RPM y en el caso de la verbalización a 14 RPM , lo cual es consistente con valores normales en adultos sanos. Sin embargo, las diferencias son más notorias en la regularidad del ciclo. En reposo, la relación entre inhalación y exhalación es más estable y simétrica, con transiciones suaves que indican un control automático principalmente mediado por el sistema nervioso autónomo. Por el contrario, durante la verbalización la señal se vuelve más irregular: las exhalaciones tienden a prolongarse porque el aire se utiliza para producir el habla, mientras que las inhalaciones son más rápidas y profundas para reponer el volumen pulmonar. Esto también explica el ligero aumento en la magnitud de ciertas componentes en la FFT, asociado a variaciones del ritmo respiratorio y a microajustes fisiológicos necesarios para coordinar respiración y fonación.

El uso del sensor de presión FSR40 demuestra ser útil para identificar parámetros básicos como frecuencia respiratoria, regularidad del ciclo y cambios en la amplitud de la señal. Estas variables pueden servir como indicadores preliminares de alteraciones, por ejemplo, respiraciones excesivamente rápidas, muy superficiales o patrones irregulares que podrían relacionarse con fatiga respiratoria, estrés o algunas enfermedades pulmonares, No obstante el alcance del sistema es principalmente de monitoreo y tamizaje, no diagnóstico. Entre sus limitaciones se encuentran la sensibilidad al movimiento, posibles interferencias por el habla u otras actividades, y la falta de variables complementarias como saturación de oxígeno o flujo de aire real.

## CONCLUSIONES

Durante la práctica se pudo entender que la respiración no siempre ocurre de la misma forma, sino que cambia dependiendo de lo que esté haciendo la persona. Cuando el individuo está en reposo, la respiración es más constante y tranquila, mientras que al hablar el patrón se vuelve un poco más irregular, ya que el aire debe controlarse para poder producir la voz. Esto hace que algunas exhalaciones sean más largas y que las inhalaciones ocurran más rápido.

También se observó que variables como la frecuencia respiratoria, la regularidad del ritmo y la profundidad de la respiración son muy útiles para notar si algo no está funcionando normalmente. Si estos parámetros cambian demasiado o pierden su estabilidad, podrían ser una señal de alerta.

Para finalizar, el sistema utilizado en la práctica es una buena herramienta para monitorear la respiración y detectar cambios importantes, pero no es suficiente por sí solo para diagnosticar una enfermedad. Aun así, permite tener una idea clara del comportamiento respiratorio de una persona y puede servir como apoyo para identificar cuándo es necesario hacer una evaluación más detallada.

## PREGUNTAS PARA LA DISCUSIÓN: 

1, ¿Son los patrones respiratorios y frecuencias respiratorias iguales o diferentes en cada caso? ¿A qué se debe esto?

Los patrones respiratorios no son iguales entre el estado de reposo y la verbalización. En reposo, la respiración se mantiene más estable y uniforme porque el cuerpo solo está cubriendo las necesidades básicas de oxígeno. En cambio, cuando la persona habla, el patrón cambia debido a que la respiración debe adaptarse para permitir la producción de la voz. Esto provoca que las exhalaciones sean un poco más largas, ya que el aire se utiliza para hablar, mientras que las inhalaciones suelen ser más rápidas para recuperar el aire perdido. Estas variaciones son normales y muestran cómo el sistema respiratorio puede ajustarse según la actividad que se esté realizando.

2. ¿Cuáles serían las ventajas y desventajas de emplear múltiples sensores para el monitoreo del proceso respiratorio? ¿Cuáles podrían ser las razones?

El uso de múltiples sensores puede mejorar la precisión del monitoreo respiratorio, ya que permite obtener más información y comparar diferentes señales al mismo tiempo. Esto ayuda a reducir errores y facilita la identificación de cambios reales en la respiración, haciendo que el análisis sea más confiable. Además, al contar con varias mediciones, es más fácil detectar patrones anormales que podrían pasar desapercibidos con un solo sensor.

Sin embargo, también existen algunas desventajas. Implementar varios sensores hace que el sistema sea más costoso y complejo, tanto en su montaje como en el procesamiento de los datos. Además, puede generar incomodidad en la persona monitoreada, lo que incluso podría alterar su respiración natural. Por esta razón, aunque utilizar múltiples sensores aumenta la calidad de la información, es importante encontrar un equilibrio entre precisión, practicidad y comodidad.

## BIBLIOGRAFÍA: 

-Interlink Electronics. (s. f.). FSR® 400 Series datasheet. Digi-Key Electronics

-Bhalla, A., Hambly, N., Szczeklik, W., & Jankowski, M. (2022). Respirations. McMaster Textbook of Internal Medicine. https://empendium.com/mcmtextbook/chapter/B31.I.1.24/

-Medical News Today. (2023). Frecuencia respiratoria normal. https://www.medicalnewstoday.com/articles/es/frecuencia-respiratoria-normal

-Healthline. (2022). Frecuencia respiratoria normal. https://www.healthline.com/health/es/frecuencia-respiratoria-normal

-MedlinePlus. (s. f.). Respiración rápida y superficial. Biblioteca Nacional de Medicina de EE. UU. https://medlineplus.gov/spanish/ency/article/007198.htm
