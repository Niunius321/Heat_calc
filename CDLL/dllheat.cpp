#include "pch.h"
#include <iostream>
const int liczba_wierszy = 20000;
const int liczba_kolumn = 20000;
const double alpha = 0.1;
const double dt = 0.01;
const double delta = 1.0;
const double four = 4.0;
extern "C" __declspec(dllexport) void Calculate_heat(double* map, double* map_new, int start_row, int end_row) {
    double delta_square = delta * delta;
    double alpha_dt = alpha * dt;

    // Obliczenia tylko dla wierszy w zakresie [start_row, end_row]
    for (int i = start_row; i < end_row; ++i) {

            for (int j = 0; j < liczba_kolumn; ++j) {
                int index = i * liczba_kolumn + j;
                if (j > 0 && j < liczba_kolumn - 1 && i > 0 && i < liczba_wierszy - 1) {
                    
                    double T_ij = map[index];
                    double T_i1j = map[(i + 1) * liczba_kolumn + j];
                    double T_i_1j = map[(i - 1) * liczba_kolumn + j];
                    double T_ij1 = map[i * liczba_kolumn + (j + 1)];
                    double T_ij_1 = map[i * liczba_kolumn + (j - 1)];

                    // Obliczenia w C++ odpowiadaj¹ce operacjom w assemblerze
                    double temp_x = T_i1j + T_i_1j;
                    double temp_y = T_ij1 + T_ij_1;
                    double result = (temp_x + temp_y - four * T_ij) / delta_square;
                    result = result * alpha_dt + T_ij;  // (alpha * dt) * [(temp_x + temp_y - 4*T[i][j]) / (delta*delta)] + T[i][j]

                    map_new[index] = result;
                }
                else {
                    map_new[index] = map[index];
                }
            }
    }

}