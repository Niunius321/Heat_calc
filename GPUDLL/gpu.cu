#include <cuda_runtime.h>
#include <stdio.h>

__global__ void heatKernel(double* map, double* map_new, int rows, int cols) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    const double alpha = 0.1;
    const double dt = 0.01;
    const double delta = 1.0;
    const double four = 4.0;
    if (i >= rows || j >= cols) return;

    int index = i * cols + j;

    if (i > 0 && i < rows - 1 && j > 0 && j < cols - 1) {
        double T_ij = map[index];
        double T_i1j = map[(i + 1) * cols + j];
        double T_i_1j = map[(i - 1) * cols + j];
        double T_ij1 = map[i * cols + (j + 1)];
        double T_ij_1 = map[i * cols + (j - 1)];

        double temp_x = T_i1j + T_i_1j;
        double temp_y = T_ij1 + T_ij_1;

        double result = (temp_x + temp_y - 4.0 * T_ij) / (delta * delta);
        result = result * alpha * dt + T_ij;

        map_new[index] = result;
    }
    else {
        map_new[index] = map[index];
    }
}


double* dev_map = nullptr;
double* dev_map_new = nullptr;

extern "C" __declspec(dllexport)
void Init_GPU(double* map, int rows, int cols) {
    size_t size = (size_t)rows * cols * sizeof(double);
    cudaMalloc(&dev_map, size);
    cudaMalloc(&dev_map_new, size);
    cudaMemcpy(dev_map, map, size, cudaMemcpyHostToDevice);
}

extern "C" __declspec(dllexport)
void Calculate_heat_GPU(int rows, int cols) {
    dim3 threads(16, 16);
    dim3 blocks((cols + 15) / 16, (rows + 15) / 16);

    heatKernel << <blocks, threads >> > (dev_map, dev_map_new, rows, cols);
    cudaDeviceSynchronize();

    std::swap(dev_map, dev_map_new); // opcjonalnie, jeśli chcesz iterować
}

extern "C" __declspec(dllexport)
void CopyBack_GPU(double* map_new, int rows, int cols) {
    size_t size = (size_t)rows * cols * sizeof(double);
    cudaMemcpy(map_new, dev_map, size, cudaMemcpyDeviceToHost);
}

extern "C" __declspec(dllexport)
void Free_GPU() {
    cudaFree(dev_map);
    cudaFree(dev_map_new);
}



