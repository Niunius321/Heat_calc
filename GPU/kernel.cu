#ifdef __INTELLISENSE__
#define __global__
#define __device__
#define __host__
#define threadIdx threadIdx
#define blockIdx blockIdx
#define blockDim blockDim
#endif
#include "Header.h"
#include <cuda_runtime.h>
#include <iostream>

__global__ void helloKernel() {
    printf("Hello from GPU thread %d!\n", threadIdx.x);
}

extern "C" void test_gpu() {
    helloKernel << <1, 5 >> > (); // 1 blok, 5 wątków
    cudaDeviceSynchronize(); // czekamy aż kernel zakończy
}
