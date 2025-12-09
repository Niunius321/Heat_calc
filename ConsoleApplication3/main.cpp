#include <iostream>
#include <cstdlib>
#include <fstream>
#include <thread>
#include <vector>
#include <chrono>
#include <condition_variable>
#include <atomic>
#include <SFML/Graphics.hpp>
#include <optional>
#include <cstdint>
#include <Windows.h>


// Sta³e dla rozmiaru mapy
const int liczba_wierszy = 20000;
const int liczba_kolumn = 20000;
const double alpha = 0.1;
const double dt = 0.01;
const double delta = 1.0;
const double four = 4.0;
// Deklaracja funkcji assemblerowej
extern "C" void calculate_heat(double* map, double* map_new, int start_row, int end_row);
extern "C" void Calculate_heat_GPU(int rows, int cols);
extern "C" void Init_GPU(double* map, int rows, int cols);
extern "C" void CopyBack_GPU(double* map_new, int rows, int cols);
extern "C" void Free_GPU();
extern "C" __declspec(dllexport) void Calculate_heat(double* map, double* map_new, int start_row, int end_row);

typedef void (*CalculationFunction)(double*, double*, int, int);


using namespace sf;
// Synchronizacja w¹tków
std::condition_variable cv;
std::mutex cv_m;
bool start_work = false;    // Flaga rozpoczêcia pracy

void load_binary_map(const std::string& filename, std::vector<double>& map, int width, int height) {
    // Otwórz plik binarny do odczytu
    std::ifstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Nie mo¿na otworzyæ pliku!" << std::endl;
        return;
    }

    // Odczytaj szerokoœæ i wysokoœæ mapy
    file.read(reinterpret_cast<char*>(&width), sizeof(width));
    file.read(reinterpret_cast<char*>(&height), sizeof(height));

    // Zainicjalizuj wektor mapy odpowiedniej wielkoœci
    map.resize(width * height);

    // Odczytaj dane mapy (tablica double)
    file.read(reinterpret_cast<char*>(map.data()), map.size() * sizeof(double));

    file.close();
    std::cout << "Plik " << filename << " wczytany!" << std::endl;
}

void save_binary_map(const std::string& filename, const std::vector<double>& map, int width, int height) {
    // Otwórz plik binarny do zapisu
    std::ofstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Nie mo¿na zapisaæ pliku!" << std::endl;
        return;
    }

    // Zapisz szerokoœæ i wysokoœæ mapy
    file.write(reinterpret_cast<const char*>(&width), sizeof(width));
    file.write(reinterpret_cast<const char*>(&height), sizeof(height));

    // Zapisz dane mapy (tablica double)
    file.write(reinterpret_cast<const char*>(map.data()), map.size() * sizeof(double));

    file.close();
    std::cout << "Plik " << filename << " zapisany!" << std::endl;
}

void thread_worker(std::vector<double>& map, std::vector<double>& map_new, int start_row, int end_row, CalculationFunction func) {
    func(map.data(), map_new.data(), start_row, end_row);  // Wywo³anie odpowiedniej funkcji
}

void print_map(const std::vector<double>& map) {
    for (int i = 0; i < liczba_wierszy; ++i) {
        for (int j = 0; j < liczba_kolumn; ++j) {
            std::cout << map[i * liczba_kolumn + j] << " ";
        }
        std::cout << std::endl;
    }
}

void showHeatmapSFML(const std::vector<double>& map, int rows, int cols, int windowSize = 800) {
    sf::RenderWindow window(sf::VideoMode({ 800u,  800u }), "Heatmap");

    double min_val = *std::min_element(map.begin(), map.end());
    double max_val = *std::max_element(map.begin(), map.end());

    // Tworzymy obraz w oknie
    sf::Image image(sf::Vector2u(windowSize, windowSize), sf::Color::Black);

    // Skala: ile komórek mapy przypada na jeden piksel w oknie
    int scaleX = std::max(1, cols / windowSize);
    int scaleY = std::max(1, rows / windowSize);

    for (int y = 0; y < windowSize; ++y) {
        for (int x = 0; x < windowSize; ++x) {
            double sum = 0.0;
            int count = 0;
            for (int j = 0; j < scaleY && (y * scaleY + j) < rows; ++j) {
                for (int i = 0; i < scaleX && (x * scaleX + i) < cols; ++i) {
                    sum += map[(y * scaleY + j) * cols + (x * scaleX + i)];
                    count++;
                }
            }
            double avg = sum / count;
            double norm = (avg - min_val) / (max_val - min_val);

            unsigned char r = static_cast<unsigned char>(norm * 255);
            unsigned char g = 0;
            unsigned char b = static_cast<unsigned char>((1.0 - norm) * 255);

            image.setPixel({ static_cast<unsigned int>(x), static_cast<unsigned int>(y) }, sf::Color(r, g, b));

        }
    }

    sf::Texture texture;
    texture.loadFromImage(image);
    sf::Sprite sprite(texture);

    // Skalowanie sprite’a do pe³nego okna (w razie potrzeby)
    sprite.setScale({
     static_cast<float>(windowSize) / static_cast<float>(cols),
     static_cast<float>(windowSize) / static_cast<float>(rows)
        });

    // Pêtla wyœwietlania
    while (window.isOpen()) {
        while (auto event = window.pollEvent()) {
            if (event->is<sf::Event::Closed>())
                window.close();
        }
        window.clear(sf::Color::Black);
        window.draw(sprite);
        window.display();
    }
}

int main() {
    int rows = liczba_wierszy;
    int cols = liczba_kolumn;

    std::vector<double> map(rows * cols);
    std::vector<double> map_new(rows * cols);

    load_binary_map("map40k.bin", map, rows, cols);

    char choice;
    std::cout << "Select calculation method: (C=CPU, A=ASM, G=GPU): ";
    std::cin >> choice;

    bool useGPU = false;
    CalculationFunction calculation_func = nullptr;

    if (choice == 'A' || choice == 'a') {
        calculation_func = calculate_heat;
    }
    else if (choice == 'C' || choice == 'c') {
        calculation_func = Calculate_heat;
    }
    else {
        useGPU = true;
    }

    if (useGPU) {
        std::cout << "[GPU] Initializing...\n";
        Init_GPU(map.data(), rows, cols); // wczytanie do GPU raz

        auto start = std::chrono::high_resolution_clock::now();

        Calculate_heat_GPU(rows, cols); // wywo³anie kernela tylko

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        std::cout << "[GPU] Kernel execution time: " << duration.count() << " ms\n";

        CopyBack_GPU(map_new.data(), rows, cols); // kopiowanie wyniku do RAM
        Free_GPU(); // zwalnianie pamiêci GPU
    }
    else
    {
        int num_threads = 2;
        int rows_per_thread = rows / num_threads;

        std::vector<std::thread> threads;

        auto start = std::chrono::high_resolution_clock::now();

        for (int i = 0; i < num_threads; i++)
        {
            int start_row = i * rows_per_thread;
            int end_row = (i == num_threads - 1) ? rows : start_row + rows_per_thread;

            threads.emplace_back(
                thread_worker,
                std::ref(map),
                std::ref(map_new),
                start_row,
                end_row,
                calculation_func
            );
        }

        for (auto& t : threads) t.join();

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

        std::cout << "[CPU/ASM] Execution time: " << duration.count() << " ms\n";
    }

    //showHeatmapSFML(map_new, cols, rows);
    //std::swap(map, map_new);
    //save_binary_map("result.bin", map, rows, cols);


    return 0;
}
