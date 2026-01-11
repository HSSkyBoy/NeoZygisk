#include <sys/sysmacros.h>  // For makedev
#include <sys/types.h>

#include <algorithm>  // For std::sort
#include <cerrno>     // For errno
#include <cstdio>     // For sscanf
#include <cstring>    // For strerror
#include <fstream>    // For std::ifstream
#include <sstream>    // For std::stringstream
#include <string>
#include <vector>

#include "logging.hpp"
#include "module.hpp"
#include "zygisk.hpp"

static bool starts_with(const std::string& str, const std::string& prefix) {
    return str.rfind(prefix, 0) == 0;
}

std::vector<mount_info> parse_mount_info(const char* pid) {
    std::string path = "/proc/";
    path += pid;
    path += "/mountinfo";

    std::ifstream file(path);
    if (!file.is_open()) {
        PLOGE("open %s", path.c_str());
        return {};
    }

    std::vector<mount_info> result;
    std::string line;
    while (std::getline(file, line)) {
        // The " - " separator is the only guaranteed, unambiguous delimiter on a valid line.
        size_t separator_pos = line.find(" - ");
        if (separator_pos == std::string::npos) {
            LOGE("malformed line (no ' - ' separator): %s", line.c_str());
            continue;
        }

        // Split the line into the part before the separator and the part after.
        std::string part1_str = line.substr(0, separator_pos);
        std::string part2_str = line.substr(separator_pos + 3);

        std::stringstream p1_ss(part1_str);
        mount_info info = {};
        std::string device_str;

        // Parse the fixed-format fields from the first part of the line.
        p1_ss >> info.id >> info.parent >> device_str >> info.root >> info.target;
        if (p1_ss.fail()) continue;

        unsigned int maj = 0, min = 0;
        if (sscanf(device_str.c_str(), "%u:%u", &maj, &min) == 2) {
            info.device = makedev(maj, min);
        }

        std::stringstream p2_ss(part2_str);
        p2_ss >> info.type >> info.source;

        info.raw_info = line;
        result.push_back(std::move(info));
    }
    return result;
}

std::vector<mount_info> check_zygote_traces(uint32_t info_flags) {
    std::vector<mount_info> traces;

    auto mount_infos = parse_mount_info("self");
    if (mount_infos.empty()) {
        return traces;
    }

    const char* mount_source_name = nullptr;
    bool is_ksu_or_apatch = false;

    if (info_flags & PROCESS_ROOT_IS_APATCH) {
        mount_source_name = "APatch";
        is_ksu_or_apatch = true;
    } else if (info_flags & PROCESS_ROOT_IS_KSU) {
        mount_source_name = "KSU";
        is_ksu_or_apatch = true;
    } else if (info_flags & PROCESS_ROOT_IS_MAGISK) {
        mount_source_name = "magisk";
    } else {
        return traces;
    }

    std::string ksu_module_source;

    if (is_ksu_or_apatch) {
        for (const auto& info : mount_infos) {
            if (info.target == "/data/adb/modules" && starts_with(info.source, "/dev/block/loop")) {
                ksu_module_source = info.source;
                LOGV("detected loop device source: %s", ksu_module_source.c_str());
                break;
            }
        }
    }

    for (const auto& info : mount_infos) {
        bool should_unmount = false;

        if (starts_with(info.root, "/adb/modules") ||
            starts_with(info.target, "/data/adb/modules")) {
            should_unmount = true;
        }
        else if (mount_source_name && info.source == mount_source_name) {
            should_unmount = true;
        }
        else if (!ksu_module_source.empty() && info.source == ksu_module_source) {
            should_unmount = true;
        }

        if (should_unmount) {
            traces.push_back(info);
        }
    }

    if (!traces.empty()) {
        std::sort(traces.begin(), traces.end(),
                  [](const mount_info& a, const mount_info& b) { return a.id > b.id; });
        LOGV("found %zu mounting traces in zygote.", traces.size());
    }

    return traces;
}
