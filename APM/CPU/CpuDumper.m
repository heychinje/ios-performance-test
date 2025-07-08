//
//  CpuProfiler.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/27.
//

#import "CpuDumper.h"
#include <mach/mach.h>
#include <pthread.h>

@implementation CpuDumper
+ (void)cpuUsage
{
    double total_cpu_usage = 0;
    double total_user_time = 0;
    double total_system_time = 0;
    
    // operation
    kern_return_t           operation_code;
    
    // all threads
    thread_array_t          thrd_lst;
    mach_msg_type_number_t  thrd_cnt;
    double                  dvc_cpu_usage;
    
    // get device cpu usage
    dvc_cpu_usage = device_cpu_usage();
    
    // get all threads
    operation_code = task_threads(mach_task_self(), &thrd_lst, &thrd_cnt);
    if (operation_code != KERN_SUCCESS) {
        NSLog(@"CpuProfiler: failed to capture thread list, code: %d", operation_code);
        return;
    }
    
    // get each thread details
    printf("The current cpu usage:\n");
    printf("-----------------------------------------------------------------------------------------------------------------------------------------------\n");
    printf("%-10s %-40s %-10s %-10s %-10s %-10s %-10s %-10s %-14s %-10s\n", "id", "name", "user_time", "sys_time", "cpu_usage", "policy", "run_state", "flags", "suspend_count", "sleep_time");
    printf("-----------------------------------------------------------------------------------------------------------------------------------------------\n");
    
    for (uint i = 0; i < thrd_cnt; i++) {
        thread_t                thrd;
        thread_info_data_t      thrd_info;
        mach_msg_type_number_t  thrd_info_cnt;
        thread_basic_info_t     thrd_bsc_info;
        
        char                    name[256];
        integer_t               user_time;
        integer_t               sys_time;
        integer_t               cpu_usage;
        policy_t                policy;
        integer_t               run_state;
        integer_t               flags;
        integer_t               suspend_count;
        integer_t               sleep_time;
        
        thrd = thrd_lst[i];

        // parse thread name
        int exit_code = pthread_getname_np(pthread_from_mach_thread_np(thrd), name, sizeof(name));
        if (exit_code != 0) {
            strcpy(name, "unknown");
        }
        
        // parse thread basic info
        thrd_info_cnt = THREAD_INFO_MAX;
        operation_code = thread_info(thrd, THREAD_BASIC_INFO, (thread_info_t)&thrd_info, &thrd_info_cnt);
        if (operation_code != KERN_SUCCESS) {
            NSLog(@"CpuProfiler: failed to capture thread info, code: %d", operation_code);
            return;
        }
        thrd_bsc_info = (thread_basic_info_t)thrd_info;
        user_time = thrd_bsc_info->user_time.seconds * TIME_MICROS_MAX + thrd_bsc_info->user_time.microseconds;
        sys_time = thrd_bsc_info->system_time.seconds * TIME_MICROS_MAX + thrd_bsc_info->system_time.microseconds;
        cpu_usage = thrd_bsc_info->cpu_usage;
        policy = thrd_bsc_info->policy;
        run_state = thrd_bsc_info->run_state;
        flags = thrd_bsc_info->flags;
        suspend_count = thrd_bsc_info->suspend_count;
        sleep_time = thrd_bsc_info->sleep_time;
        
        printf("%-10u %-40s %-10d %-10d %-10d %-10d %-10d %-10d %-14d %-10d\n", thrd, name, user_time, sys_time, cpu_usage, policy, run_state, flags, suspend_count, sleep_time);
        
        total_cpu_usage += cpu_usage;
        total_user_time += user_time;
        total_system_time += sys_time;
    }
    
    // table summary
    printf("-----------------------------------------------------------------------------------------------------------------------------------------------\n");
    printf("total: app-cpu = %f%%, device-cpu = %f%%, user-time = %fs, system-time = %fs\n", dvc_cpu_usage, total_cpu_usage/TH_USAGE_SCALE*100, total_user_time/TIME_MICROS_MAX, total_system_time/TIME_MICROS_MAX);
    printf("-----------------------------------------------------------------------------------------------------------------------------------------------\n");
    
    // release
    operation_code = vm_deallocate(mach_task_self(), (vm_offset_t)thrd_lst, thrd_cnt * sizeof(thread_t));
    assert(operation_code == KERN_SUCCESS);
}


static double device_cpu_usage(void) {
    kern_return_t kr;
    mach_msg_type_number_t count;
    static host_cpu_load_info_data_t previous_info = {0, 0, 0, 0};
    host_cpu_load_info_data_t info;
    
    count = HOST_CPU_LOAD_INFO_COUNT;
    
    kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&info, &count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    natural_t user   = info.cpu_ticks[CPU_STATE_USER] - previous_info.cpu_ticks[CPU_STATE_USER];
    natural_t nice   = info.cpu_ticks[CPU_STATE_NICE] - previous_info.cpu_ticks[CPU_STATE_NICE];
    natural_t system = info.cpu_ticks[CPU_STATE_SYSTEM] - previous_info.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t idle   = info.cpu_ticks[CPU_STATE_IDLE] - previous_info.cpu_ticks[CPU_STATE_IDLE];
    natural_t total  = user + nice + system + idle;
    previous_info    = info;
    
    return (user + nice + system) * 100.0 / total;
}


@end




