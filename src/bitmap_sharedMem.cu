#include <cuda_runtime.h>
#include "../inc/image.cuh"

#define DIM 512
#define PI 3.1415926535f

__global__ void kernel(unsigned char *ptr) {
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;
    int offset = x + y * blockDim.x * gridDim.x;
    __shared__ float shared[16][16];
    const float period = 128.0f;

    shared[threadIdx.x][threadIdx.y] = 255 * (sinf(x * 2.0f * PI / period) + 1.0f) * (sinf(y * 2.0f * PI / period) + 1.0f) / 4.0f;

    __syncthreads();

    ptr[offset * 4 + 0] = 0;
    ptr[offset * 4 + 1] = shared[15 - threadIdx.x][15 - threadIdx.y];
    ptr[offset * 4 + 2] = 0;
    ptr[offset * 4 + 3] = 255;
}

int main(int argc, char **argv) {
    IMAGE<float> image(DIM, DIM);
    unsigned char *dev_bitmap;

    cudaMalloc((void**)&dev_bitmap, image.image_size());

    dim3 grid(DIM / 16, DIM / 16);
    dim3 threads(16, 16);

    kernel<<<grid, threads>>>(dev_bitmap);
    cudaMemcpy(image.get_ptr(), dev_bitmap, image.image_size(), cudaMemcpyDeviceToHost);
    image.show_image();

    cudaFree(dev_bitmap);
}