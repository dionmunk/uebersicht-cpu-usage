import Darwin.Mach

var cpuInfo: processor_info_array_t!
var numCpuInfo: mach_msg_type_number_t = 0
var numCpus: natural_t = 0
let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
guard kr == KERN_SUCCESS else { exit(1) }

var user: UInt64 = 0, system: UInt64 = 0, idle: UInt64 = 0, nice: UInt64 = 0
for i in 0..<Int(numCpus) {
    let base = i * Int(CPU_STATE_MAX)
    user   &+= UInt64(cpuInfo[base + Int(CPU_STATE_USER)])
    system &+= UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
    idle   &+= UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)])
    nice   &+= UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
}
print("\(user) \(system) \(idle) \(nice)")
