# extended benchmark results

raw data from all 68 benchmark runs. for analysis and recommendations see [configuration_evaluation.md](configuration_evaluation.md).

## evreth-latest_evnode-unknown

| file | test | objective | block_time | gas_limit | spammers | Mgas/s | TPS | pb_avg (ms) | pb_max (ms) | overhead (%) | non-empty (%) | steady_state (s) | sent | failed |
|------|------|-----------|-----------|-----------|----------|--------|-----|-------------|-------------|-------------|--------------|-----------------|------|--------|
| TestGasBurner_baseline_100m_100ms_20260325T140708 | GasBurner | baseline_100m_100ms | 100ms | 0x5F5E100 | 2 | 223.09 | 225.1 | 74 | 112.1 | 1.9 | 95.5 | 41 | 20004 | 0 |
| TestGasBurner_baseline_30m_100ms_20260325T140346 | GasBurner | baseline_30m_100ms | 100ms | 0x1C9C380 | 2 | 148.35 | 149.7 | 59.8 | 108.7 | 2.1 | 98.7 | 63 | 20004 | 0 |
| TestGasBurner_fast_blocks_50ms_100m_20260325T151207 | GasBurner | fast_blocks_50ms_100m | 50ms | 0x5F5E100 | 4 | 281.07 | 290.8 | 93.1 | 315.1 | 1.4 | 100 | 72 | 133336 | 0 |
| TestGasBurner_high_gas_per_tx_100m_20260325T141008 | GasBurner | high_gas_per_tx_100m | 100ms | 0x5F5E100 | 2 | 326.12 | 65.3 | 124.2 | 243.3 | 0.8 | 97.4 | 94 | 15044 | 0 |
| TestGasBurner_large_burn_low_volume_300m_20260325T150810 | GasBurner | large_burn_low_volume_300m | 100ms | 0x11E1A300 | 2 | 397.66 | 79.7 | 125.4 | 209.9 | 0.9 | 100 | 92 | 18708 | 0 |
| TestGasBurner_max_mgas_1g_20260325T142623 | GasBurner | max_mgas_1g | 100ms | 0x3B9ACA00 | 10 | 132.56 | 90.8 | 73.2 | 20025.8 | 24.1 | 80.6 | 370 | 426620 | 0 |
| TestGasBurner_max_mgas_300m_20260325T141423 | GasBurner | max_mgas_300m | 100ms | 0x11E1A300 | 6 | 406.74 | 204.3 | 340.3 | 10349.9 | 11.7 | 100 | 184 | 302460 | 0 |
| TestGasBurner_max_mgas_500m_20260325T142012 | GasBurner | max_mgas_500m | 100ms | 0x1DCD6500 | 8 | 371.66 | 186.7 | 317.7 | 10368.2 | 16.6 | 100 | 199 | 390328 | 0 |
| TestGasBurner_slow_blocks_1s_500m_20260325T144931 | GasBurner | slow_blocks_1s_500m | 1s | 0x1DCD6500 | 8 | 62.45 | 31.4 | 166.9 | 274.4 | 0.9 | 100 | 346 | 93088 | 0 |
| TestGasBurner_slow_blocks_250ms_100m_20260325T143554 | GasBurner | slow_blocks_250ms_100m | 250ms | 0x5F5E100 | 4 | 98.86 | 99.8 | 89 | 132.4 | 1.5 | 100 | 128 | 61984 | 0 |
| TestGasBurner_slow_blocks_500ms_300m_20260325T144158 | GasBurner | slow_blocks_500ms_300m | 500ms | 0x11E1A300 | 6 | 119.71 | 60.1 | 159.4 | 215.6 | 0.9 | 100 | 194 | 80208 | 0 |
| TestGasBurner_small_burn_high_volume_100m_20260325T145841 | GasBurner | small_burn_high_volume_100m | 100ms | 0x5F5E100 | 6 | 63.05 | 226 | 36.2 | 147.3 | 3.6 | 98 | 127 | 236370 | 0 |

## evreth-latest_evnode-v1.0.0

| file | test | objective | block_time | gas_limit | spammers | Mgas/s | TPS | pb_avg (ms) | pb_max (ms) | overhead (%) | non-empty (%) | steady_state (s) | sent | failed |
|------|------|-----------|-----------|-----------|----------|--------|-----|-------------|-------------|-------------|--------------|-----------------|------|--------|
| TestERC20Throughput_100m_10pct_20260326T101053 | ERC20Throughput | 100m_10pct | 100ms | 0x5F5E100 | 8 | 6.52 | 200.3 | 33.9 | 10047.4 | 47 | 35.7 | 151 | 146936 | 0 |
| TestERC20Throughput_100m_20pct_20260326T101551 | ERC20Throughput | 100m_20pct | 100ms | 0x5F5E100 | 10 | 3.46 | 107.8 | 41.9 | 10085.6 | 68.1 | 18.6 | 457 | 318940 | 0 |
| TestERC20Throughput_100m_40pct_20260326T102612 | ERC20Throughput | 100m_40pct | 100ms | 0x5F5E100 | 10 | 3.65 | 122 | 51.6 | 10041.2 | 71.9 | 25.7 | 633 | 607830 | 0 |
| TestERC20Throughput_30m_10pct_20260326T092151 | ERC20Throughput | 30m_10pct | 100ms | 0x1C9C380 | 4 | 27.85 | 703.1 | 32.6 | 96.1 | 4.9 | 92.8 | 53 | 48016 | 0 |
| TestERC20Throughput_30m_20pct_20260326T092537 | ERC20Throughput | 30m_20pct | 100ms | 0x1C9C380 | 6 | 15.23 | 400.7 | 41.3 | 10013.6 | 42.2 | 60.2 | 70 | 94578 | 0 |
| TestERC20Throughput_30m_40pct_1s_20260326T105242 | ERC20Throughput | 30m_40pct_1s | 1s | 0x1C9C380 | 8 | 6.24 | 146.4 | 50 | 156.6 | 3.2 | 98.9 | 182 | 177136 | 0 |
| TestERC20Throughput_30m_40pct_20260326T092903 | ERC20Throughput | 30m_40pct | 100ms | 0x1C9C380 | 8 | 13.82 | 364.8 | 58.3 | 10056 | 57.3 | 67.9 | 79 | 183664 | 0 |
| TestERC20Throughput_30m_40pct_250ms_20260326T104445 | ERC20Throughput | 30m_40pct_250ms | 250ms | 0x1C9C380 | 8 | 28.52 | 715.6 | 144.8 | 10097.8 | 52.5 | 86.9 | 87 | 199976 | 0 |
| TestERC20Throughput_30m_40pct_500ms_20260326T104830 | ERC20Throughput | 30m_40pct_500ms | 500ms | 0x1C9C380 | 8 | 12.01 | 285.5 | 52.8 | 188.7 | 3.3 | 95.6 | 110 | 176800 | 0 |
| TestERC20Throughput_30m_40pct_50ms_20260326T103939 | ERC20Throughput | 30m_40pct_50ms | 50ms | 0x1C9C380 | 8 | 8.92 | 292.5 | 40.1 | 20143.9 | 61.8 | 55 | 151 | 189272 | 0 |
| TestERC20Throughput_30m_80pct_20260326T093248 | ERC20Throughput | 30m_80pct | 100ms | 0x1C9C380 | 10 | 3.81 | 128 | 59.3 | 10142.2 | 74.6 | 38.8 | 359 | 361270 | 0 |

## evreth-v0.3.0-beta_evnode-v1.0.0

| file | test | objective | block_time | gas_limit | spammers | Mgas/s | TPS | pb_avg (ms) | pb_max (ms) | overhead (%) | non-empty (%) | steady_state (s) | sent | failed |
|------|------|-----------|-----------|-----------|----------|--------|-----|-------------|-------------|-------------|--------------|-----------------|------|--------|
| TestDeFiSimulation_100m_10pct_20260326T145119 | DeFiSimulation | 100m_10pct | 100ms | 0x5F5E100 | 4 | 12.85 | 218.1 | 27.8 | 86 | 5.2 | 96.7 | 190 | 217084 | 0 |
| TestDeFiSimulation_100m_10pct_20260330T110527 | DeFiSimulation | 100m_10pct | 100ms | 0x5F5E100 | 4 | 2.43 | 53.1 | 18.5 | 105.5 | 7.7 | 99.7 | 708 | 200800 | 0 |
| TestDeFiSimulation_100m_20pct_20260326T145726 | DeFiSimulation | 100m_20pct | 100ms | 0x5F5E100 | 8 | 5.4 | 116.4 | 19 | 176.4 | 7.2 | 98.1 | 330 | 387200 | 0 |
| TestDeFiSimulation_100m_20pct_20260330T112102 | DeFiSimulation | 100m_20pct | 100ms | 0x5F5E100 | 8 | 7.16 | 115 | 23.6 | 173.9 | 6.2 | 97.7 | 332 | 375336 | 0 |
| TestDeFiSimulation_100m_40pct_20260330T112948 | DeFiSimulation | 100m_40pct | 100ms | 0x5F5E100 | 10 | 3.36 | 98.9 | 29 | 10137.3 | 28.6 | 96.2 | 620 | 650340 | 0 |
| TestDeFiSimulation_100m_80pct_20260330T114335 | DeFiSimulation | 100m_80pct | 100ms | 0x5F5E100 | 10 | 2.01 | 74.4 | 29.6 | 10276.3 | 39.2 | 73.4 | 1386 | 1171310 | 0 |
| TestDeFiSimulation_30m_100pct_20260326T142429 | DeFiSimulation | 30m_100pct | 100ms | 0x1C9C380 | 10 | 6.51 | 117 | 19.3 | 90.7 | 7.5 | 99.2 | 402 | 545250 | 0 |
| TestDeFiSimulation_30m_100pct_20260330T103950 | DeFiSimulation | 30m_100pct | 100ms | 0x1C9C380 | 10 | 14.29 | 256.9 | 30.9 | 105.3 | 5.3 | 96.1 | 200 | 751660 | 0 |
| TestDeFiSimulation_30m_10pct_20260326T134910 | DeFiSimulation | 30m_10pct | 100ms | 0x1C9C380 | 2 | 33.08 | 373.2 | 32.5 | 59.1 | 5 | 100 | 84 | 81666 | 0 |
| TestDeFiSimulation_30m_10pct_20260330T094147 | DeFiSimulation | 30m_10pct | 100ms | 0x1C9C380 | 2 | 22.91 | 284.7 | 29.8 | 68.3 | 5.5 | 94.7 | 103 | 81666 | 0 |
| TestDeFiSimulation_30m_10pct_20260330T095723 | DeFiSimulation | 30m_10pct | 100ms | 0x1C9C380 | 2 | 33.06 | 373.5 | 35.3 | 66.7 | 4.8 | 100 | 84 | 81666 | 0 |
| TestDeFiSimulation_30m_10pct_20260330T100429 | DeFiSimulation | 30m_10pct | 100ms | 0x1C9C380 | 2 | 23.87 | 288.1 | 30.8 | 61.3 | 5.3 | 95.7 | 103 | 81662 | 0 |
| TestDeFiSimulation_30m_120pct_20260330T104638 | DeFiSimulation | 30m_120pct | 100ms | 0x1C9C380 | 10 | 2.42 | 56.6 | 16.1 | 224.4 | 9.3 | 99.1 | 882 | 575060 | 0 |
| TestDeFiSimulation_30m_20pct_20260326T135257 | DeFiSimulation | 30m_20pct | 100ms | 0x1C9C380 | 3 | 19.77 | 341.2 | 32.8 | 137.7 | 4.8 | 91.7 | 123 | 178623 | 0 |
| TestDeFiSimulation_30m_20pct_20260330T100903 | DeFiSimulation | 30m_20pct | 100ms | 0x1C9C380 | 3 | 16.85 | 237.9 | 30 | 102.2 | 5.5 | 95.4 | 156 | 151785 | 0 |
| TestDeFiSimulation_30m_40pct_20260326T135746 | DeFiSimulation | 30m_40pct | 100ms | 0x1C9C380 | 6 | 2.8 | 74 | 17.8 | 10019.6 | 21.3 | 98.6 | 423 | 265200 | 0 |
| TestDeFiSimulation_30m_40pct_20260330T101443 | DeFiSimulation | 30m_40pct | 100ms | 0x1C9C380 | 6 | 3.47 | 84.3 | 17.1 | 164.2 | 8.7 | 99 | 438 | 333924 | 0 |
| TestDeFiSimulation_30m_80pct_1s_20260330T122247 | DeFiSimulation | 30m_80pct_1s | 1s | 0x1C9C380 | 8 | 0.56 | 16.1 | 19.4 | 102.9 | 8.4 | 97.9 | 1230 | 165736 | 0 |
| TestDeFiSimulation_30m_80pct_20260330T102535 | DeFiSimulation | 30m_80pct | 100ms | 0x1C9C380 | 8 | 2.21 | 70.1 | 19.5 | 10144.9 | 23.9 | 97.2 | 640 | 425024 | 0 |
| TestDeFiSimulation_30m_80pct_250ms_20260330T121104 | DeFiSimulation | 30m_80pct_250ms | 250ms | 0x1C9C380 | 8 | 3.94 | 90.1 | 23.7 | 229.2 | 6.7 | 95.7 | 509 | 412488 | 0 |
| TestDeFiSimulation_30m_80pct_multi_pair_20260326T161227 | DeFiSimulation | 30m_80pct_multi_pair | 100ms | 0x1C9C380 | 8 | 3.93 | 103.7 | 24 | 10289 | 36.1 | 98.9 | 447 | 435352 | 0 |
| TestMixedWorkload_100m_10pct_20260330T132140 | MixedWorkload | 100m_10pct | 100ms | 0x5F5E100 | 6 | 245.2 | 491.3 | 78.1 | 285.2 | 1.7 | 89.1 | 45 | 143616 | 0 |
| TestMixedWorkload_100m_20pct_20260330T132452 | MixedWorkload | 100m_20pct | 100ms | 0x5F5E100 | 8 | 237.39 | 468.7 | 115.5 | 10085.8 | 19.5 | 100 | 62 | 385000 | 0 |
| TestMixedWorkload_100m_40pct_20260330T132832 | MixedWorkload | 100m_40pct | 100ms | 0x5F5E100 | 10 | 233.01 | 393.5 | 116 | 10035.7 | 15 | 100 | 93 | 548204 | 0 |
| TestMixedWorkload_100m_80pct_20260330T133247 | MixedWorkload | 100m_80pct | 100ms | 0x5F5E100 | 10 | 55.81 | 163.9 | 53 | 10030.1 | 26.5 | 64.4 | 273 | 632428 | 0 |
| TestMixedWorkload_30m_100pct_20260330T131158 | MixedWorkload | 30m_100pct | 100ms | 0x1C9C380 | 10 | 110.82 | 164.5 | 86.1 | 10119 | 32.9 | 51 | 95 | 236914 | 0 |
| TestMixedWorkload_30m_10pct_20260330T125906 | MixedWorkload | 30m_10pct | 100ms | 0x1C9C380 | 4 | 70.29 | 109.1 | 42.5 | 83.9 | 3.4 | 100 | 52 | 30953 | 0 |
| TestMixedWorkload_30m_120pct_20260330T131617 | MixedWorkload | 30m_120pct | 100ms | 0x1C9C380 | 10 | 122.75 | 174.4 | 84 | 10061.1 | 20.6 | 100 | 144 | 387692 | 0 |
| TestMixedWorkload_30m_20pct_20260330T130208 | MixedWorkload | 30m_20pct | 100ms | 0x1C9C380 | 4 | 140.4 | 214.5 | 65.9 | 129.9 | 2.1 | 100 | 50 | 59818 | 0 |
| TestMixedWorkload_30m_40pct_20260330T130522 | MixedWorkload | 30m_40pct | 100ms | 0x1C9C380 | 6 | 135.46 | 289.4 | 60 | 233.5 | 2 | 96.8 | 41 | 104211 | 0 |
| TestMixedWorkload_30m_80pct_1s_20260330T134910 | MixedWorkload | 30m_80pct_1s | 1s | 0x1C9C380 | 8 | 20.93 | 42.7 | 83.6 | 228.9 | 1.8 | 75.4 | 295 | 107974 | 0 |
| TestMixedWorkload_30m_80pct_20260330T130828 | MixedWorkload | 30m_80pct | 100ms | 0x1C9C380 | 8 | 116.1 | 221.6 | 79.9 | 10023.9 | 27.6 | 57.1 | 59 | 163540 | 0 |
| TestMixedWorkload_30m_80pct_250ms_20260330T134028 | MixedWorkload | 30m_80pct_250ms | 250ms | 0x1C9C380 | 8 | 88.59 | 163.9 | 78.5 | 173.6 | 1.7 | 79.5 | 94 | 148732 | 0 |
| TestMixedWorkload_30m_80pct_500ms_20260330T134422 | MixedWorkload | 30m_80pct_500ms | 500ms | 0x1C9C380 | 8 | 46.98 | 91 | 95.2 | 172.6 | 1.6 | 84.7 | 150 | 120972 | 0 |
| TestStatePressure_100m_10pct_20260330T082807 | StatePressure | 100m_10pct | 100ms | 0x5F5E100 | 2 | 237.28 | 227.6 | 76.8 | 153.1 | 1.5 | 95.3 | 40 | 20004 | 0 |
| TestStatePressure_100m_20pct_20260330T083044 | StatePressure | 100m_20pct | 100ms | 0x5F5E100 | 4 | 291.4 | 279.5 | 93.5 | 198.2 | 1.3 | 100 | 44 | 67720 | 0 |
| TestStatePressure_100m_40pct_20260330T083326 | StatePressure | 100m_40pct | 100ms | 0x5F5E100 | 4 | 252.03 | 241.7 | 158.3 | 10034.5 | 28.4 | 63.4 | 46 | 63492 | 0 |
| TestStatePressure_100m_80pct_20260330T083608 | StatePressure | 100m_80pct | 100ms | 0x5F5E100 | 8 | 261.64 | 259.2 | 104.3 | 403.6 | 1.4 | 94.1 | 72 | 187824 | 0 |
| TestStatePressure_30m_100pct_20260330T082229 | StatePressure | 30m_100pct | 100ms | 0x1C9C380 | 6 | 185.32 | 177.7 | 60.4 | 261.7 | 1.7 | 64.5 | 46 | 68244 | 0 |
| TestStatePressure_30m_10pct_20260330T080802 | StatePressure | 30m_10pct | 100ms | 0x1C9C380 | 2 | 73.5 | 70.5 | 36.3 | 68.6 | 3.9 | 96.7 | 53 | 8004 | 0 |
| TestStatePressure_30m_120pct_20260330T082518 | StatePressure | 30m_120pct | 100ms | 0x1C9C380 | 6 | 174.45 | 167.3 | 54.6 | 195.7 | 1.9 | 73.6 | 38 | 54636 | 0 |
| TestStatePressure_30m_20pct_20260330T081313 | StatePressure | 30m_20pct | 100ms | 0x1C9C380 | 2 | 98.15 | 94.1 | 42.8 | 84 | 3.2 | 98.1 | 60 | 12004 | 0 |
| TestStatePressure_30m_40pct_20260330T081625 | StatePressure | 30m_40pct | 100ms | 0x1C9C380 | 3 | 190.83 | 183 | 63.8 | 182.2 | 1.8 | 65.7 | 41 | 30081 | 0 |
| TestStatePressure_30m_80pct_1s_20260330T084345 | StatePressure | 30m_80pct_1s | 1s | 0x1C9C380 | 4 | 19.9 | 19.1 | 58.8 | 101.6 | 2.4 | 68 | 336 | 26560 | 0 |
| TestStatePressure_30m_80pct_20260330T081904 | StatePressure | 30m_80pct | 100ms | 0x1C9C380 | 4 | 145.18 | 139.2 | 60.7 | 196.2 | 2 | 100 | 74 | 56912 | 0 |
| TestStatePressure_30m_80pct_250ms_20260330T083926 | StatePressure | 30m_80pct_250ms | 250ms | 0x1C9C380 | 4 | 58.39 | 56 | 56 | 173.9 | 2.6 | 100 | 136 | 34864 | 0 |
| TestStatePressure_30m_80pct_heavy_write_20260330T085117 | StatePressure | 30m_80pct_heavy_write | 100ms | 0x1C9C380 | 3 | 141.99 | 69.7 | 61.7 | 111.3 | 2 | 100 | 86 | 23472 | 0 |

