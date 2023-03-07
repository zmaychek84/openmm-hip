__device__ inline real3 headSegmentedSum(real3 input, unsigned int key, bool& head) {
    const unsigned int laneId = (threadIdx.x & (warpSize - 1));
    const unsigned int prevLaneKey = __shfl(key, laneId - 1);
    head = laneId == 0 || key != prevLaneKey;

#if defined(AMD_RDNA)
    const unsigned int n = __popc(__ballot(1));
    unsigned int flags = __ballot(head);
    flags >>= 1;
    flags &= ~((static_cast<unsigned int>(1) << laneId) - 1);
    flags |= static_cast<unsigned int>(1) << (n - 1);
    const unsigned int nextSegmentStart = __ffs(flags);
#else
    const unsigned int n = __popcll(__ballot(1));
    unsigned long long flags = __ballot(head);
    flags >>= 1;
    flags &= ~((static_cast<unsigned long long>(1) << laneId) - 1);
    flags |= static_cast<unsigned long long>(1) << (n - 1);
    const unsigned int nextSegmentStart = __ffsll(flags);
#endif

    real3 output = input;
    for (unsigned int offset = 1; offset < warpSize; offset *= 2) {
        real3 value = make_real3(__shfl(output.x, laneId + offset),
                                 __shfl(output.y, laneId + offset),
                                 __shfl(output.z, laneId + offset));
        if (laneId + offset < nextSegmentStart) {
            output += value;
        }
        if (__ballot(laneId + offset < nextSegmentStart) == 0)
            break;
    }
    return output;
}
