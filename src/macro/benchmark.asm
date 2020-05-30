%macro BENCHMARK_BEGIN 0
%if BENCHMARK_MODE_ENABLED
.bench:
%endif
%endmacro

%macro BENCHMARK_END 0
%if BENCHMARK_MODE_ENABLED
    inc dword [benchmark_count]
    jmp .bench
%endif
%endmacro

; Constant macro used to toggle the benchmark mode.
; When the benchmark mode is enabled, the benchmark code runs
; in an infinite loop instead of jumping to the shell loop.
BENCHMARK_MODE_ENABLED equ 0

%macro BENCHMARK_CODE 0
    ; <<< code to be benchmarked >>>
%endmacro
