# NeoZygisk v2.3
This version focuses on enhancing the stealth capabilities for **APatch** and **KernelSU**, and fixes potential crashes and memory leaks in the core hooking mechanism.

### 🛡️ Stealth Mechanism Upgrades
*   **Enhanced APatch and KSU Stealth**
    *   Reconstructed the unmount (Unmount) logic, now able to more accurately identify and handle the module mounting sources (Loop Device) of **APatch** and KernelSU.
*   **Hide Bootloader Properties**
    *   Added logic to hide or spoof sensitive Bootloader properties
*   **Optimized Raw Code Hiding**
    *   Improved the `hide_map` mechanism to ensure that the injected raw code (Raw Code) is properly hidden and cleaned up in memory mapping, reducing the risk of being detected by anti-cheat systems.

### 🐛 Bug Fixes & Stability
*   **Fix Memory Leak**
    *   Fixed a leak issue caused by incorrect release of old memory regions (`munmap`) when performing the hidden operation of memory remapping (Remap).
*   **Fix Invalid Address Access**
    *   Fixed a potential illegal memory access (Segmentation Fault) during the PLT (Procedure Linkage Table) Hook process if the backup data is invalid or has a length of 0, improving the stability of the Zygote process.

### ⚡ Other Changes (Misc)
*   Optimized `/proc/self/mountinfo` parsing performance.
*   Reduced unnecessary error log output, making Logcat cleaner.