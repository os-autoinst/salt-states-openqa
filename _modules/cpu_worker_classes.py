#!/usr/bin/env python

x86_64_v2_flags = ['cx16', 'lahf', 'popcnt', 'sse4_1', 'sse4_2', 'ssse3']
x86_64_v3_flags = ['avx', 'avx2', 'bmi1', 'bmi2', 'f16c', 'fma', 'abm', 'movbe', 'xsave']
x86_64_v4_flags = ['avx512f', 'avx512bw', 'avx512cd', 'avx512dq', 'avx512vl']

def compute(cpu_arch, cpu_flags):
    prefix = "cpu-"
    worker_classes = [prefix + cpu_arch]
    if cpu_arch != "x86_64":
        return worker_classes
    if all(flag in cpu_flags for flag in x86_64_v2_flags):
        worker_classes.append(prefix + "x86_64-v2")
        if all(flag in cpu_flags for flag in x86_64_v3_flags):
            worker_classes.append(prefix + "x86_64-v3")
            if all(flag in cpu_flags for flag in x86_64_v4_flags):
                worker_classes.append(prefix + "x86_64-v4")
    return worker_classes
