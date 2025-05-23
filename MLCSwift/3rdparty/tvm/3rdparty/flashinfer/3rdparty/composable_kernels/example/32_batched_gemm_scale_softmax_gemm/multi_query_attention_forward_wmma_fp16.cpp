// SPDX-License-Identifier: MIT
// Copyright (c) 2018-2022, Advanced Micro Devices, Inc. All rights reserved.

/*
Multi-Query Attention
Shazeer, Noam. “Fast Transformer Decoding: One Write-Head Is All You Need.” arXiv.org, November 6,
2019. https://arxiv.org/abs/1911.02150v1.

*/

#include <iostream>
#include <numeric>
#include <initializer_list>
#include <cstdlib>

#include "ck/ck.hpp"
#include "ck/tensor_operation/gpu/device/gemm_specialization.hpp"
#include "ck/tensor_operation/gpu/device/tensor_specialization.hpp"
#include "ck/tensor_operation/gpu/device/impl/device_multi_query_attention_forward_wmma.hpp"
#include "ck/tensor_operation/gpu/element/element_wise_operation.hpp"

#include "ck/library/utility/check_err.hpp"
#include "ck/library/utility/device_memory.hpp"
#include "ck/library/utility/host_tensor.hpp"
#include "ck/library/utility/host_tensor_generator.hpp"
#include "ck/library/utility/literals.hpp"
#include "ck/library/reference_tensor_operation/cpu/reference_batched_gemm.hpp"
#include "ck/library/reference_tensor_operation/cpu/reference_softmax.hpp"

template <ck::index_t... Is>
using S = ck::Sequence<Is...>;

using F16 = ck::half_t;
using F32 = float;

using PassThrough = ck::tensor_operation::element_wise::PassThrough;

using ADataType        = F16;
using B0DataType       = F16;
using B1DataType       = F16;
using Acc0DataType     = F32;
using Acc1DataType     = F32;
using CShuffleDataType = F32;
using CDataType        = F16;
using Acc0BiasDataType = ck::Tuple<>;
using Acc1BiasDataType = ck::Tuple<>;

static constexpr ck::index_t NumDimG = 2;
static constexpr ck::index_t NumDimM = 1;
static constexpr ck::index_t NumDimN = 1;
static constexpr ck::index_t NumDimK = 1;
static constexpr ck::index_t NumDimO = 1;

using AElementOp    = PassThrough;
using B0ElementOp   = PassThrough;
using Acc0ElementOp = ck::tensor_operation::element_wise::Scale;
using B1ElementOp   = PassThrough;
using CElementOp    = PassThrough;

static constexpr auto GemmSpec = ck::tensor_operation::device::GemmSpecialization::MNKOPadding;
static constexpr auto MaskingSpec =
    ck::tensor_operation::device::MaskingSpecialization::MaskDisabled;

static constexpr auto TensorSpecA  = ck::tensor_operation::device::TensorSpecialization::Default;
static constexpr auto TensorSpecB0 = ck::tensor_operation::device::TensorSpecialization::Default;
static constexpr auto TensorSpecB1 = ck::tensor_operation::device::TensorSpecialization::Default;
static constexpr auto TensorSpecC  = ck::tensor_operation::device::TensorSpecialization::Default;

// clang-format off
// #define CK_MHA_USE_WAVE_1
// #define CK_MHA_USE_WAVE_2
// #define CK_MHA_USE_WAVE_4
#define CK_MHA_USE_WAVE_8
using DeviceMHAFactory = 
    std::tuple<
#ifdef CK_MHA_USE_WAVE_1
        // 1 wave, mrepeat = 1, nrepeat = 2, k/o repeat = 1~5
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            32,
            //      Gemm 0
            16, 128, 64, 8,  8,
            //      Gemm 1
                64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 8, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<2, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2, 2, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 8, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 16, 1, 2>, 8,             
            MaskingSpec>,
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            32,
            //      Gemm 0
            16, 64, 64, 8,  8,
            //      Gemm 1
                64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 4, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<2, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2, 2, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 8, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 16, 1, 2>, 8,             
            MaskingSpec>,
#endif
#ifdef CK_MHA_USE_WAVE_2
         ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            64,
            //      Gemm 0
            32, 128, 64, 8, 8,
            //      Gemm 1
                 64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 8, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 32, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<4, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2, 4, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 4, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 32, 1, 2>, 8,             
            MaskingSpec>,
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            64,
            //      Gemm 0
            32, 64, 64, 8, 8,
            //      Gemm 1
                64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 4, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 32, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<4, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2, 4, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 4, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 32, 1, 2>, 8,             
            MaskingSpec>,
#endif
#ifdef CK_MHA_USE_WAVE_4
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            128,
            //      Gemm 0
            64, 128, 64, 8, 8,
            //      Gemm 1
                64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 8, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 64, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<8, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2, 8, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 2, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 64, 1, 2>, 8,
            MaskingSpec>,
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            128,
            //      Gemm 0
            64, 64, 64, 8, 8,
            //      Gemm 1
                64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 4, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 64, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<8, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2, 8, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 2, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 64, 1, 2>, 8,             
            MaskingSpec>,
#endif
#ifdef CK_MHA_USE_WAVE_8
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            256,
            //      Gemm 0
            128, 128, 64, 8, 8,   
            //      Gemm 1
                  64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 8, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 128, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<8,  32, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2,  16, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 1, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 128, 1, 2>, 8,             
            MaskingSpec>,
        ck::tensor_operation::device::DeviceMultiQueryAttentionForward_Wmma<
            NumDimG, NumDimM, NumDimN, NumDimK, NumDimO,
            ADataType, B0DataType, B1DataType, CDataType, Acc0BiasDataType, Acc0DataType, Acc1BiasDataType, Acc1DataType, CShuffleDataType,
            AElementOp, B0ElementOp, Acc0ElementOp, B1ElementOp, CElementOp,
            GemmSpec, TensorSpecA, TensorSpecB0, TensorSpecB1, TensorSpecC, 1,
            256,
            //      Gemm 0
            128, 128, 64, 8, 8,   
            //      Gemm 1
                  64, 64, 8,  
            16, 16, 16, 
            // Per repeat = wave_m = wave_num, wave_n = 1
            1, 8, 4,
            // ABlockTransfer MK -> K0 M K1
            S<2, 128, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B0BlockTransfer LK -> K0 L K1
            S<8,  32, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, true,
            // B1BlockTransfer NL -> L0 N L1
            S<2,  16, 8>, S<0, 2, 1>, S<0, 2, 1>, 1, 1, 1, false,
            // CShuffleBlockTransfer MN
            1, 1, S<1, 128, 1, 2>, 8,             
            MaskingSpec>
#endif
    >;
// clang-format on
// Ref Gemm0: fp16 in, fp32 out
using ReferenceGemm0Instance = ck::tensor_operation::host::ReferenceBatchedGemm_MQA<ADataType,
                                                                                    B0DataType,
                                                                                    Acc0DataType,
                                                                                    Acc1DataType,
                                                                                    AElementOp,
                                                                                    B0ElementOp,
                                                                                    Acc0ElementOp>;

// Ref Softmax: fp32 in, fp16 out
using ReferenceSoftmaxInstance =
    ck::tensor_operation::host::ReferenceSoftmax<Acc0DataType, ADataType, Acc0DataType>;

// Ref Gemm1: fp16 in, fp16 out
using ReferenceGemm1Instance = ck::tensor_operation::host::ReferenceBatchedGemm_MQA<ADataType,
                                                                                    B1DataType,
                                                                                    CDataType,
                                                                                    Acc1DataType,
                                                                                    AElementOp,
                                                                                    B1ElementOp,
                                                                                    CElementOp>;

#include "run_multi_query_attention_forward_wmma.inc"

int main(int argc, char* argv[]) { return run(argc, argv); }
