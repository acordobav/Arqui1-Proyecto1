clc; clear; close all;

% Solicitar ruta de la imagen codificada
path = input("Ingrese ruta de la imagen codificada: ", "s");
exp = input("Ingrese exponente (d): ", "s");
mod = input("Ingrese modulo (n): ", "s");
command = ["./decoder " path " " exp " " mod];
disp("Procesando en ejecutable de x86-64...");
system(command);
disp("Procesamiento finalizado!");
%}
% Imagen codificada
codificada = load("-ascii",path);
A = reshape(codificada,[960,640]);
A = uint8(A);
A = A';
subplot(1,2,1);
imshow(A);
title("Imagen codificada");

% Imagen decodificada
decodificada = load('-ascii','decodedimage.txt');
B = reshape(decodificada,[480,640]);
B = uint8(B);
B = B';
subplot(1,2,2);
imshow(B);
title("Imagen decodificada");
imwrite(B,"decodificada.png");