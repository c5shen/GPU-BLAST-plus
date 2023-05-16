#ifndef __GPU_BLASTN_SMALL_SCAN_KERNEL_V3_H__
#define __GPU_BLASTN_SMALL_SCAN_KERNEL_V3_H__

#include <stdio.h>

#define SHARE_MEM_SMALL_SIZE 512

#define USE_SMALL_TEXTURE 1

#if(USE_SMALL_TEXTURE)
texture<Int2,1,cudaReadModeElementType> tx_backbone;
#define   LOAD_INT2(i) tex1Dfetch(tx_backbone, i)
#define  SET_INT2_BASE checkCudaErrors( cudaBindTexture(0, tx_backbone, d_backbone) )
#else
#define  LOAD_INT2(i) d_backbone[i]
#define SET_INT2_BASE
#endif

//////////////////////////////////////////////////////////////////////////
__constant__ Uint4 cn_small_tb[1024];
//////////////////////////////////////////////////////////////////////////

__global__ void gpu_blastn_scan_8_1mod4_v3(const Uint4* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit /*max_hits*/,
    Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ BlastOffsetPair sh_offsetpair[SHARE_MEM_SMALL_SIZE];
    __shared__ Uint4 sh_cnt;
    __shared__ Uint4 sh_global_i;

    if (threadIdx.x == 0)
    {
        sh_cnt = 0;
        sh_global_i = 0;
    }
    __syncthreads();

    while(s_index < scan_range)
    {
        Uint4  s_temp_1 = subject[s_index];
        Uint1* s = (Uint1*)&s_temp_1;

        Uint4 s_temp = s[0] << 8 | s[1];		
        Int2 s_temp_value = LOAD_INT2(s_temp);		

        Uint4 s_global_offset = scan_range_0 + s_index << 4;
        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(&sh_cnt, 1);
            sh_offsetpair[index_offset].qs_offsets.q_off = s_temp_value;
            sh_offsetpair[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }

        __syncthreads();

        if (sh_cnt >= blockDim.x)
        {  
            int offset_id = threadIdx.x;

            if (offset_id == 0)
            {
                sh_global_i = atomicAdd(total_hit, sh_cnt);

            }
            __syncthreads();			

            while (offset_id < sh_cnt)
            { 
                offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
                offset_id += blockDim.x;
            }
            if (threadIdx.x == 0)
            {
                sh_cnt = 0; 
            } 
            __syncthreads();
        }

        s_index += global_size;
    }

    if (sh_cnt > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);

        }
        __syncthreads();
        if (offset_id < sh_cnt)
        {
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
        }
    }
}


//const Int4 kLutWordLength = 8;
#define kLutWordLength_8_4 8
__constant__ Int4 kLutWordMask_8_4 = (1 << (2 * kLutWordLength_8_4)) - 1;


__device__ __inline__ void checkData(
    Uint4 &sh_cnt,
    BlastOffsetPair* sh_offsetpair,
    Uint4 *over_total_hit,
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs,
    Uint4 s_global_offset,
    Uint4 &sh_global_i,
    Uint1 s,
    Int4& init_index,
    Uint4* total_hit
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & kLutWordMask_8_4;		
    Int2 s_temp_value = LOAD_INT2(index);

    if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(&sh_cnt, 1);
            sh_offsetpair[index_offset].qs_offsets.q_off = s_temp_value;
            sh_offsetpair[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }

        __syncthreads();

        if (sh_cnt >= blockDim.x)
        {  
            int offset_id = threadIdx.x;

            if (offset_id == 0)
            {
                sh_global_i = atomicAdd(total_hit, sh_cnt);
            }
            __syncthreads();			

            while (offset_id < sh_cnt)
            { 
                offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
                offset_id += blockDim.x;
            }
            if (threadIdx.x == 0)
            {
                sh_cnt = 0; 
            } 
            __syncthreads();
        }
}
__global__ void gpu_blastn_scan_8_4(const Uint8* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit /*max_hits*/,
    Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ BlastOffsetPair sh_offsetpair[SHARE_MEM_SMALL_SIZE];
    __shared__ Uint4 sh_cnt;
    __shared__ Uint4 sh_global_i;

    if (threadIdx.x == 0)
    {
        sh_cnt = 0;
        sh_global_i = 0;
    }
    __syncthreads();

    Int4 init_index;
    //Int4 index;
    //Int2 s_temp_value;

    while(s_index < scan_range)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 5;
        Uint8  s_temp_1 = subject[s_index];
        Uint1* s = (Uint1*)&s_temp_1;

        init_index = s[0];
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[1], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[2], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[3], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[4], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[5], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[6], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[7], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[8], init_index, total_hit);		
        
        s_index += global_size;
    }

    if (sh_cnt > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);

        }
        __syncthreads();
        if (offset_id < sh_cnt)
        {
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
        }
    }
}

__global__ void gpu_blastn_scan_8_4_v1(Uint1* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit,
    Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ BlastOffsetPair sh_offsetpair[SHARE_MEM_SMALL_SIZE];
    __shared__ Uint4 sh_cnt;
    __shared__ Uint4 sh_global_i;

    if (threadIdx.x == 0)
    {
        sh_cnt = 0;
        sh_global_i = 0;
    }
    __syncthreads();

    Int4 init_index;
    //Int4 index;
    //Int2 s_temp_value;

    while(s_index < scan_range)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 2;
        Uint1  *s = subject + s_index;

        init_index = s[0];
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[1], init_index, total_hit);			

        s_index += global_size;
    }

    if (sh_cnt > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);

        }
        __syncthreads();
        if (offset_id < sh_cnt)
        {
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
        }
    }
}


__global__ void gpu_blastn_scan_8_4_v2(Uint4* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit,
    Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ BlastOffsetPair sh_offsetpair[SHARE_MEM_SMALL_SIZE];
    __shared__ Uint4 sh_cnt;
    __shared__ Uint4 sh_global_i;

    if (threadIdx.x == 0)
    {
        sh_cnt = 0;
        sh_global_i = 0;
    }
    __syncthreads();

    Int4 init_index;
//	Int4 index;
//	Int2 s_temp_value;

    while(s_index < scan_range)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 4;
        Uint1  *s = (Uint1 *)(subject + s_index);

        init_index = s[0];
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[1], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[2], init_index, total_hit);		
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[3], init_index, total_hit);
        s_global_offset += 4;
        checkData(sh_cnt, sh_offsetpair, over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[4], init_index, total_hit);


        s_index += global_size;
    }

    if (sh_cnt > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);

        }
        __syncthreads();
        if (offset_id < sh_cnt)
        {
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
        }
    }
}

struct ShortOffsetPair
{
    Int2 q_off;
    Uint2 s_off;
};


__device__ __inline__ void checkDataOpt(
    BlastOffsetPair* op_1,
    BlastOffsetPair* op_2,
    int& len_op_1,
    int& len_op_2,
    Uint1 s,
    Int4 &init_index,
    Uint2 s_off
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & kLutWordMask_8_4;		
    Int2 s_temp_value = LOAD_INT2(index);

    if (s_temp_value > -1)
    {  
        op_1[len_op_1].qs_offsets.q_off = s_temp_value;
        op_1[len_op_1++].qs_offsets.s_off = s_off;
    }
    if(s_temp_value < -1)
    {
        op_2[len_op_2].qs_offsets.q_off = -s_temp_value;
        op_2[len_op_2++].qs_offsets.s_off = s_off;
    }
}

__global__ void gpu_blastn_scan_8_4_v3(Uint4* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit,
    Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ Uint4 sh_cnt;
    __shared__ Uint4 sh_global_i;
    __shared__ BlastOffsetPair sh_offsetpair[256*4];

    BlastOffsetPair op_1[4];//={0,0,0,0,0,0,0,0};
    BlastOffsetPair op_2[4];

    while(s_index < scan_range)
    {
        int op_len_1 = 0;
        int op_len_2 = 0;
        Uint1  *s = (Uint1 *)(subject + s_index);

//		Uint4 s_global_offset = scan_range_0 + (blockIdx.x*blockDim.x) << 4;
        Uint2 s_off = threadIdx.x <<4;
        Int4 init_index = s[0];
        checkDataOpt(op_1, op_2,op_len_1, op_len_2, s[1], init_index, s_off);
        checkDataOpt(op_1, op_2,op_len_1, op_len_2, s[2], init_index, s_off+4);
        checkDataOpt(op_1, op_2,op_len_1, op_len_2, s[3], init_index, s_off+8);
        checkDataOpt(op_1, op_2,op_len_1, op_len_2, s[4], init_index, s_off+12);


        if (threadIdx.x == 0)
        {
            sh_cnt = 0;
        }
        __syncthreads();
        //////////////////////////////////////////////////////////////////////////

        for (int i = 0; i < op_len_1; i++)
        {
            Uint4 index_offset = atomicAdd(&sh_cnt, 1);
            sh_offsetpair[index_offset] = op_1[i];
        }							 
        __syncthreads();
        int offset_id = threadIdx.x;
        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);
            sh_cnt = 0; 
        }
        __syncthreads();			

        while (offset_id < sh_cnt)
        { 		
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
            offset_id += blockDim.x;
        }
        //////////////////////////////////////////////////////////////////////////
        for (int i = 0; i < op_len_2; i++)
        {
            Uint4 index_offset = atomicAdd(&sh_cnt, 1);
            sh_offsetpair[index_offset] = op_2[i];
        }

        __syncthreads();
        offset_id = threadIdx.x;
        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(over_total_hit, sh_cnt);
        }
        __syncthreads();			

        while (offset_id < sh_cnt)
        { 
            over_offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
            offset_id += blockDim.x;
        }

        s_index += global_size;
    }
}
//////////////////////////////////////////////////////////////////////////

__global__ void gpu_blastn_scan_8_4_v4(Uint1* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit,
    //Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ Uint4 sh_cnt[2];
    __shared__ Uint4 sh_global_i[2];
    __shared__ Int2 sh_qoff[2][512];

    int offset_id = threadIdx.x;

    while(s_index < scan_range)
    {
        if (threadIdx.x < 2)
        {
            sh_cnt[threadIdx.x] = 0;
        }
        __syncthreads();

        Uint1  *s = (Uint1 *)(subject + s_index);

        Uint4 s_global_offset = scan_range_0 + s_index << 2;
        Int4 init_index = s[0];
        init_index = init_index << 8 | s[1];
        Int4 index = init_index & kLutWordMask_8_4;		
        Int2 s_temp_value = LOAD_INT2(index);

        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(&sh_cnt[0], 1);
            sh_qoff[0][index_offset] = s_temp_value;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(&sh_cnt[1], 1);
            sh_qoff[1][index_offset] = -s_temp_value;
        }
        __syncthreads();
        //////////////////////////////////////////////////////////////////////////
        if (offset_id < 2)
        {
            sh_global_i[threadIdx.x] = atomicAdd(&total_hit[threadIdx.x], sh_cnt[threadIdx.x]);
        }
        __syncthreads();			

        BlastOffsetPair t_off;
        t_off.qs_offsets.s_off = s_global_offset;
        if (offset_id < sh_cnt[0])
        {		
            t_off.qs_offsets.q_off = sh_qoff[0][offset_id];			
            offset_pairs[sh_global_i[0] + offset_id] = t_off;
        }
        if (offset_id < sh_cnt[1])
        { 
            t_off.qs_offsets.q_off = sh_qoff[1][offset_id];
            over_offset_pairs[sh_global_i[1] + offset_id] = t_off;
        }

        s_index += global_size;
    }
}

//////////////////////////////////////////////////////////////////////////
//opt 5
//////////////////////////////////////////////////////////////////////////
__device__ __inline__ void checkDataOpt_v1(
    Uint4 &sh_cnt1,
    BlastOffsetPair* sh_1,
    Uint4 &sh_cnt2,
    BlastOffsetPair* sh_2,
    Uint4 *over_total_hit,
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs,
    Uint4 s_global_offset,
    Uint4 &sh_global_i,
    Uint1 s,
    Int4& init_index,
    Uint4* total_hit
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & kLutWordMask_8_4;		
    Int2 s_temp_value = LOAD_INT2(index);

    if (s_temp_value > -1)
    {  
        Uint4 index_offset = atomicAdd(&sh_cnt1, 1);
        sh_1[index_offset].qs_offsets.q_off = s_temp_value;
        sh_1[index_offset].qs_offsets.s_off = s_global_offset;
    }
    if(s_temp_value < -1)
    {
        Uint4 index_offset = atomicAdd(&sh_cnt2, 1);
        sh_2[index_offset].qs_offsets.q_off = -s_temp_value;
        sh_2[index_offset].qs_offsets.s_off = s_global_offset;
    }

    __syncthreads();

    if (sh_cnt1 >= blockDim.x)
    {  
        //printf("%d,%d,%d",blockIdx.xsh_cnt1);
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt1);
        }
        __syncthreads();			

        while (offset_id < sh_cnt1)
        { 
            offset_pairs[sh_global_i + offset_id] = sh_1[offset_id];
            offset_id += blockDim.x;
        }
        if (threadIdx.x == 0)
        {
            sh_cnt1 = 0; 
        } 
        __syncthreads();
    }
    if (sh_cnt2 >= blockDim.x)
    {  
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(over_total_hit, sh_cnt2);
        }
        __syncthreads();			

        while (offset_id < sh_cnt1)
        { 
            over_offset_pairs[sh_global_i + offset_id] = sh_2[offset_id];
            offset_id += blockDim.x;
        }
        if (threadIdx.x == 0)
        {
            sh_cnt2 = 0; 
        } 
        __syncthreads();
    }
}
#define SHARE_MEM_SMALL_SIZE_V5 256
__global__ void gpu_blastn_scan_8_4_v5(Uint8* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    Uint4* total_hit /*max_hits*/,
    Uint4* over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ BlastOffsetPair sh_off[2][SHARE_MEM_SMALL_SIZE_V5];
    __shared__ Uint4 sh_cnt[2];
    __shared__ Uint4 sh_global_i;

    if (threadIdx.x < 2)
    {
        sh_cnt[threadIdx.x] = 0;
    }
    __syncthreads();

    Int4 init_index;
//	Int4 index;
//	Int2 s_temp_value;

    while(s_index < scan_range)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 5;
        Uint8  s_temp_1 = subject[s_index];
        Uint1* s = (Uint1*)&s_temp_1;
        

#if 1
        init_index = s[0];
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset, sh_global_i, s[1], init_index, total_hit);		
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+4, sh_global_i, s[2], init_index, total_hit);			
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+8, sh_global_i, s[3], init_index, total_hit);		
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+12, sh_global_i, s[4], init_index, total_hit);			
        
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+16, sh_global_i, s[5], init_index, total_hit);		
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+20, sh_global_i, s[6], init_index, total_hit);			
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+24, sh_global_i, s[7], init_index, total_hit);		
        checkDataOpt_v1(sh_cnt[0], sh_off[0], sh_cnt[1], sh_off[1], over_total_hit, over_offset_pairs, offset_pairs, s_global_offset+28, sh_global_i, s[8], init_index, total_hit);			
        
#endif	
        //Uint4* pt=(Uint4*)offset_pairs;
        //pt[s_index] = s_temp_1;//sh_off[0][threadIdx.x];
        s_index += global_size;
    }
#if 1

    if (sh_cnt[0] > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt[0]);

        }
        __syncthreads();
        if (offset_id < sh_cnt[0])
        {
            offset_pairs[sh_global_i + offset_id] = sh_off[0][offset_id];
        }
    }
    if (sh_cnt[1] > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(over_total_hit, sh_cnt[1]);
        }
        __syncthreads();
        if (offset_id < sh_cnt[1])
        {
            over_offset_pairs[sh_global_i + offset_id] = sh_off[1][offset_id];
        }
    }
#endif
}

//////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////
__device__ __inline__ void checkData_v2_1(
    Uint4 &sh_cnt,
    BlastOffsetPair* sh_offsetpair,
    Uint4 *over_total_hit,
    BlastOffsetPair* NCBI_RESTRICT over_offset_pairs,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs,
    Uint4 s_global_offset,
    Uint4 &sh_global_i,
    Uint1 s,
    Int4& init_index,
    Uint4* total_hit
    )
{
    init_index = init_index << 8 | s;
    //Int4 index = init_index & kLutWordMask_8_4;	

    Int4 index = init_index & 65535;//kLutWordMask_8_4;		

    //Uint4 small_hash_value = cn_small_tb[index/32];
    //Uint4 mask_value = 1 <<(index%32);

    //if ((small_hash_value&mask_value) > 0)
    {
        Int2 s_temp_value = LOAD_INT2(index);

        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(&sh_cnt, 1);
            sh_offsetpair[index_offset].qs_offsets.q_off = s_temp_value;
            sh_offsetpair[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
            //over_total_hit++;
        }
    }

    __syncthreads();

    if (sh_cnt >= blockDim.x)
    {  
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);
        }
        __syncthreads();			

        while (offset_id < sh_cnt)
        { 
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
            offset_id += blockDim.x;
        }
        if (threadIdx.x == 0)
        {
            sh_cnt = 0; 
        } 
        __syncthreads();
    }
}
__global__ void gpu_blastn_scan_8_4_v2_1(Uint4* subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT l_off,//over_offset_pairs,
    Uint4* total_hit,
    Uint4* l_len,//over_total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;

    __shared__ BlastOffsetPair sh_offsetpair[512];
    __shared__ Uint4 sh_cnt;
    __shared__ Uint4 sh_global_i;

    if (threadIdx.x == 0)
    {
        sh_cnt = 0;
        sh_global_i = 0;
    }
    __syncthreads();

    Int4 init_index;

    while(s_index < scan_range)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 4;
        Uint4 s1 = subject[s_index];
        Uint4 s2 = subject[s_index+1];
        Uint1  *s = (Uint1 *)&s1;

        init_index = s[0];
        checkData_v2_1(sh_cnt, sh_offsetpair, l_len, l_off, offset_pairs, s_global_offset, sh_global_i, s[1], init_index, total_hit/*, sh_small_tb*/);		
        s_global_offset += 4;
        checkData_v2_1(sh_cnt, sh_offsetpair, l_len, l_off, offset_pairs, s_global_offset, sh_global_i, s[2], init_index, total_hit/*, sh_small_tb*/);		
        s_global_offset += 4;
        checkData_v2_1(sh_cnt, sh_offsetpair, l_len, l_off, offset_pairs, s_global_offset, sh_global_i, s[3], init_index, total_hit/*, sh_small_tb*/);
        s_global_offset += 4;
        checkData_v2_1(sh_cnt, sh_offsetpair, l_len, l_off, offset_pairs, s_global_offset, sh_global_i, s2&255, init_index, total_hit/*, sh_small_tb*/);

        s_index += global_size;
    }

    if (sh_cnt > 0)
    {
        int offset_id = threadIdx.x;

        if (offset_id == 0)
        {
            sh_global_i = atomicAdd(total_hit, sh_cnt);

        }
        __syncthreads();
        if (offset_id < sh_cnt)
        {
            offset_pairs[sh_global_i + offset_id] = sh_offsetpair[offset_id];
        }
    }
}

//////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////
__device__ __inline__ void checkData_v2_2(
    Uint4 *sh_cnt,
    BlastOffsetPair* offset_pairs,
    Uint4 s_global_offset,
    Uint1 s,
    Int4& init_index,
    BlastOffsetPair* over_offset_pairs,
    Uint4* over_total_hit,	Uint4* small_tb
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & 65535;//kLutWordMask_8_4;		
    
    Uint4 small_hash_value = small_tb[index >> 6];
    Uint4 mask_value = 1 << ( (index & 63) >> 1 );
    if ((small_hash_value&mask_value) > 0)

    //Uint4 mask_value = (small_hash_value >> ( (index & 63) >> 1 )) &1;
    //if (mask_value)
    {
        Int4 s_temp_value = LOAD_INT2(index);
        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(sh_cnt, 1);
            offset_pairs[index_offset].qs_offsets.q_off = s_temp_value;
            offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
    }
}
__global__ void gpu_blastn_scan_8_4_v2_2(Uint4* __restrict__ subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT l_off,
    Uint4* total_hit,
    Uint4* l_len,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;
    __shared__ Uint4 sh_small_tb[1024];

#pragma unroll
    for (int i = 0; i < 2; i++)
    {
        sh_small_tb[i*blockDim.x+threadIdx.x] = cn_small_tb[i*blockDim.x+threadIdx.x];
    }
    __syncthreads();

    Int4 init_index;

    while(s_index < scan_range)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 4;
        Uint4  s1 = subject[s_index];
        Uint4  s2 = subject[s_index+1];
        Uint1* s= (Uint1*)&s1;

        init_index = s[0];
        checkData_v2_2(total_hit, offset_pairs, s_global_offset, s[1], init_index, l_off, l_len, sh_small_tb);		
        s_global_offset += 4;
        checkData_v2_2(total_hit, offset_pairs, s_global_offset, s[2], init_index, l_off, l_len, sh_small_tb);
        s_global_offset += 4;
        checkData_v2_2(total_hit, offset_pairs, s_global_offset, s[3], init_index, l_off, l_len, sh_small_tb);
        s_global_offset += 4;
        checkData_v2_2(total_hit, offset_pairs, s_global_offset, s2 &255, init_index, l_off, l_len, sh_small_tb);

        s_index += global_size;
    }
}


//////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////
// TODO: Optimize this!!! - ZX
/*
__device__ __inline__ void checkData_v2_3(
    Uint4 *sh_cnt,
    BlastOffsetPair* offset_pairs,
    Uint4 s_global_offset,
    Uint1 s,
    Int4& init_index,
    BlastOffsetPair* over_offset_pairs,
    Uint4* over_total_hit,	Uint4* small_tb
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & 65535;
    
    Uint4 small_hash_value = small_tb[index >> 5];

    Uint4 mask_value = (small_hash_value >> ( index & 31)) &1;
    if (mask_value)
    {
        Int4 s_temp_value = LOAD_INT2(index);
        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(sh_cnt, 1);
            offset_pairs[index_offset].qs_offsets.q_off = s_temp_value;
            offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
    }
}
*/

/*
__device__ __inline__ void checkData_v2_3(
    Uint4 *sh_cnt,
    BlastOffsetPair* offset_pairs,
    Uint4 s_global_offset,
    Uint1 s,
    Int4& init_index,
    BlastOffsetPair* over_offset_pairs,
    Uint4* over_total_hit,	Uint4* small_tb,
    Uint4 *mask_one_count, Uint4 *mask_one_buf
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & 65535;
    
    Uint4 small_hash_value = small_tb[index >> 5];

    Uint4 mask_value = (small_hash_value >> ( index & 31)) &1;

    // Instead of immediately checking if the warp has mask_value of 1, 
    // synchronize this information across the entire block and 
    // compact the mask_value 1.
    // Repeat this technique for s_temp_value > -1 and for
    // s_temp_value < -1
    Uint4 maskscan = mask_value;
    Uint4 tempreg;
    unsigned tidxp1_w = (threadIdx.x % 32) + 1;
    // Inclusive scan
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 1);
    __syncwarp();
    if (tidxp1_w % 2 == 0) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 2);
    __syncwarp();
    if (tidxp1_w % 4 == 0) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 4);
    __syncwarp();
    if (tidxp1_w % 8 == 0) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 8);
    __syncwarp();
    if (tidxp1_w % 16 == 0) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 16);
    __syncwarp();
    if (tidxp1_w % 32 == 0) maskscan += tempreg;
    __syncwarp();
    // Uint4 0;
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 8);
    __syncwarp();
    if(tidxp1_w > 16 && (tidxp1_w % 16 == 8)) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 4);
    __syncwarp();
    if(tidxp1_w > 8 && (tidxp1_w % 8 == 4)) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 2);
    __syncwarp();
    if(tidxp1_w > 4 && (tidxp1_w % 4 == 2)) maskscan += tempreg;
    __syncwarp();
    tempreg = __shfl_up_sync(0xffffffff, maskscan, 1);
    __syncwarp();
    if(tidxp1_w > 2 && (tidxp1_w % 2 == 1)) maskscan += tempreg;
    __syncwarp();
    Uint4 sh_buf_0;
    if (tidxp1_w % 32 == 0) {
        // Last thread in warp has total value of masks
        sh_buf_0 = atomicAdd(mask_one_count, maskscan);
    }
    __syncwarp();
    sh_buf_0 = __shfl_sync(0xffffffff, sh_buf_0, 31);
    __syncwarp();
    // Make scan exclusive
    maskscan -= mask_value;
    if (mask_value) {
        // Write all index values into the buffer, it will be used later.
        mask_one_buf[sh_buf_0 + maskscan] = index;
    }
    __syncthreads(); // Entire block must write into buffer before next phase

    Uint4 tidx = blockIdx.x * blockDim.x + threadIdx.x;
    if (tidx < *mask_one_count) {
        Int4 s_temp_value = LOAD_INT2(mask_one_buf[tidx]);
        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(sh_cnt, 1);
            offset_pairs[index_offset].qs_offsets.q_off = s_temp_value;
            offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
    }
}
*/

__device__ __inline__ void checkData_v2_3_part2(
    Uint4 *sh_cnt,
    BlastOffsetPair* offset_pairs,
    BlastOffsetPair* over_offset_pairs,
    Uint4* over_total_hit,
    Uint4 *mask_one_count, Int4 *mask_one_buf, Uint4 *s_global_offset_buf
    )
{
    __syncthreads();
    // No looping necessary since 1 thread produces up to 1 mask_value of 1
    // So there cannot be more threads needed than block size
    Uint4 ones = *mask_one_count;
    __syncthreads();
    for (Uint4 tidx = threadIdx.x; tidx < ones; tidx += blockDim.x) {
        Int4 s_temp_value = LOAD_INT2(mask_one_buf[tidx]);
        Uint4 s_global_offset = s_global_offset_buf[tidx];
        if (s_temp_value > -1)
        {  
            Uint4 index_offset = atomicAdd(sh_cnt, 1);
            offset_pairs[index_offset].qs_offsets.q_off = s_temp_value;
            offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
        if(s_temp_value < -1)
        {
            Uint4 index_offset = atomicAdd(over_total_hit, 1);
            over_offset_pairs[index_offset].qs_offsets.q_off = -s_temp_value;
            over_offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        }
    }
    if (threadIdx.x == 0) {
        *mask_one_count = 0;
    }
    __syncthreads();
}

__device__ __inline__ void checkData_v2_3(
    Uint4 *sh_cnt,
    BlastOffsetPair* offset_pairs,
    Uint4 s_global_offset,
    Uint1 s,
    Int4& init_index,
    BlastOffsetPair* over_offset_pairs,
    Uint4* over_total_hit,	Uint4* small_tb,
    Uint4 *mask_one_count, Int4 *mask_one_buf, Uint4 *s_global_offset_buf
    )
{
    init_index = init_index << 8 | s;
    Int4 index = init_index & 65535;
    Uint4 small_hash_value = small_tb[index >> 5];
    Uint4 mask_value = (small_hash_value >> ( index & 31)) &1;

    Uint4 qidx;
    if (mask_value) {
        qidx = atomicAdd(mask_one_count, 1);
        // Write all index values into the buffer, it will be used later.
        mask_one_buf[qidx] = index;
        s_global_offset_buf[qidx] = s_global_offset;
    }
}

__constant__ Uint4 cn_big_tb[2048];

// TODO: Optimize this!!! - ZX
__global__ void gpu_blastn_scan_8_4_v2_3(Uint4* __restrict__ subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    BlastOffsetPair* NCBI_RESTRICT l_off,
    Uint4* total_hit,
    Uint4* l_len,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x + threadIdx.x;
    __shared__ Uint4 sh_small_tb[2048];


#pragma unroll
    for (int i = 0; i < 4; i++)
    {
        sh_small_tb[i*blockDim.x+threadIdx.x] = cn_big_tb[i*blockDim.x+threadIdx.x];
    }
    __shared__ Uint4 mask_one_count;
    __shared__ Int4 mask_one_buf[2048];
    __shared__ Uint4 s_global_offset_buf[2048];
    if (threadIdx.x == 0) {
        mask_one_count = 0;
    }

    __syncthreads();

    Int4 init_index;

    for(;s_index < scan_range; s_index += global_size)
    {
        Uint4 s_global_offset = scan_range_0 + s_index << 4;
        s_global_offset_buf[threadIdx.x] = subject[s_index];
        Uint4  s2;
        if (threadIdx.x == blockDim.x - 1) {
            s2 = subject[s_index + 1];
        }
        __syncthreads();
        Uint4  s1 = s_global_offset_buf[threadIdx.x];
        if (threadIdx.x != blockDim.x - 1) {
            s2 = s_global_offset_buf[threadIdx.x+1];
        }
        Uint1* s= (Uint1*)&s1;

        init_index = s[0];
        checkData_v2_3(total_hit, offset_pairs, s_global_offset, s[1], init_index, l_off, l_len, sh_small_tb, &mask_one_count, mask_one_buf, s_global_offset_buf);		
        s_global_offset += 4;
        checkData_v2_3(total_hit, offset_pairs, s_global_offset, s[2], init_index, l_off, l_len, sh_small_tb, &mask_one_count, mask_one_buf, s_global_offset_buf);
        s_global_offset += 4;
        checkData_v2_3(total_hit, offset_pairs, s_global_offset, s[3], init_index, l_off, l_len, sh_small_tb, &mask_one_count, mask_one_buf, s_global_offset_buf);
        s_global_offset += 4;
        checkData_v2_3(total_hit, offset_pairs, s_global_offset, s2 &255, init_index, l_off, l_len, sh_small_tb, &mask_one_count, mask_one_buf, s_global_offset_buf);
        
        checkData_v2_3_part2(total_hit, offset_pairs, l_off, l_len, &mask_one_count, mask_one_buf, s_global_offset_buf);
    }
}

////
//////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////
__device__ __inline__ void checkData_v2_4(
    Uint4 *sh_cnt,
    BlastOffsetPair* offset_pairs,
    Uint4 s_global_offset,
    Uint1 s,
    Int4& init_index,
    Uint4* small_tb,
    clock_t* t
    )
{
    t[3]= clock();
    init_index = init_index << 8 | s;
    t[4]=clock();
    Int4 index = init_index & 65535;
    t[5]= clock();
    Uint4 small_hash_value = small_tb[index >> 5];
    t[6]= clock();

    Uint4 mask_value = (small_hash_value >> ( index & 31)) &1;
    if (!mask_value)
    {
        t[7] = clock();
        Uint4 index_offset = atomicAdd(sh_cnt, 1);
        t[8] = clock();
        offset_pairs[index_offset].qs_offsets.q_off = index;
        offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
        t[9]= clock();
    }
}

__global__ void gpu_blastn_scan_8_4_v2_4(Uint4* __restrict__ subject,
    BlastOffsetPair* NCBI_RESTRICT offset_pairs, 
    Uint4* total_hit,
    Uint4 scan_range,
    Uint4 scan_range_0,
    Uint4 global_size,
    Int2* d_backbone)
{
    Uint4 s_index = blockIdx.x*blockDim.x +threadIdx.x;
    __shared__ Uint4 sh_small_tb[512];

    clock_t t[12]={0};
    //if(threadIdx.x == 0)
        t[0]=clock();//printf("start:%d\n",clock());
    //if(s_index < 32)
        sh_small_tb[threadIdx.x] = cn_big_tb[threadIdx.x];
//#pragma unroll
    //for (int i = 0; i < 1; i++)
    //{
    //	sh_small_tb[i*blockDim.x+threadIdx.x] = cn_big_tb[i*blockDim.x+threadIdx.x];
    //}
    //__syncthreads();
    //if(threadIdx.x == 0)
        t[1]=clock();//printf("start:%d\n",clock());

    Int4 init_index;
    Int4 index[4]={0};
    Uint4 small_hash_value;
    Uint4 mask_value[4]={0};
    Uint4 index_offset;
    //while(s_index < scan_range)
    //{
        Uint4 s_global_offset = scan_range_0 + s_index << 4;
        Uint4  s_t = subject[s_index];
        Uint4  s_t2 = subject[s_index+1];
        Uint1* s= (Uint1*)&s_t;
        Uint1 s1 = s[1];
        Uint1 s2 = s[2];
        Uint1 s3 = s[3];
        Uint1 s4 = (Uint1)s_t2;

        //if(threadIdx.x == 0)
        t[2]=clock();//printf("start:%d\n",clock());

        init_index = s[0];
        init_index = init_index * 256 + s1;//[1];
        index[0] = init_index & 65535;

        init_index = s[0];
        init_index = init_index * 256 + s2;//[1];
        index[1] = init_index & 65535;

        init_index = s[0];
        init_index = init_index * 256 + s3;//[1];
        index[2] = init_index & 65535;

        init_index = s[0];
        init_index = init_index * 256 + s4;//[1];
        index[3] = init_index & 65535;

        t[3]= clock();
        
        for(int i = 0; i < 4; i++)
        {
            small_hash_value = sh_small_tb[index[i] >> 5];
            mask_value[i] = (small_hash_value >> ( index[i] & 31)) &1;
        }

        t[4] = clock();

        for(int i = 0; i < 4; i++)
        //if (!mask_value[i])
        {
            index_offset = atomicAdd(total_hit, 1);
            offset_pairs[index_offset].qs_offsets.q_off = index[i];
            offset_pairs[index_offset].qs_offsets.s_off = s_global_offset;
            s_global_offset += 4;
        }

        //checkData_v2_4(total_hit, offset_pairs, s_global_offset, s[1], init_index, sh_small_tb, t);		
        //s_global_offset += 4;
        //checkData_v2_4(total_hit, offset_pairs, s_global_offset, s[2], init_index, sh_small_tb, t);
        //s_global_offset += 4;
        //checkData_v2_4(total_hit, offset_pairs, s_global_offset, s[3], init_index, sh_small_tb, t);
        //s_global_offset += 4;
        //checkData_v2_4(total_hit, offset_pairs, s_global_offset, s2 &255, init_index, sh_small_tb,t );
        
        t[5]=clock();

        if(threadIdx.x == 0)
        {
            //printf("start:%d\n",clock());
        
            for(int i = 1; i < 6; i++)
                printf("%d\t", t[i]-t[i-1]);
            //printf("\n");
        }
        s_index += global_size;
    //}
}



#endif //__GPU_BLASTN_SMALL_SCAN_KERNEL_H__
