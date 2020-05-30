%macro BENCHMARK_BEGIN 0
    .bench:
%endmacro

%macro BENCHMARK_END 0
    adc dword [benchmark_count], 0
    jmp .bench
%endmacro
