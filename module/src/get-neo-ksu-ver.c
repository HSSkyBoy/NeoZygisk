#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

// KernelSU Magic Constants (from ksucalls.rs)
#define KSU_INSTALL_MAGIC1 0xDEADBEEF
#define KSU_INSTALL_MAGIC2 0xCAFEBABE

// ioctl Commands (from ksucalls.rs)
// KSU_IOCTL_GET_INFO: _IOR('K', 2, struct ksu_get_info_cmd)
#define KSU_IOCTL_GET_INFO 0x80084b02

// Structure for Get Info Command
struct ksu_get_info_cmd {
    unsigned int version;
    unsigned int flags;
};

int init_driver_fd() {
    int fd = -1;
    if (syscall(SYS_reboot, KSU_INSTALL_MAGIC1, KSU_INSTALL_MAGIC2, 0, &fd) == -1) {
        return -1;
    }
    return fd;
}

int get_kernel_version() {
    int fd = init_driver_fd();
    if (fd < 0) {
        return 0;
    }

    struct ksu_get_info_cmd cmd = {0};

    if (ioctl(fd, KSU_IOCTL_GET_INFO, &cmd) < 0) {
        close(fd);
        return 0;
    }

    close(fd);
    return cmd.version;
}

int main() {
    int version = get_kernel_version();
    printf("%d", version);
    return 0;
}
