# 🚀 NeoZygisk-Fork v2.3-288 更新發佈

### 🛡️ 隱藏與反偵測機制強化
*   **升級 APatch & KSU 隱藏**：新增 Bootloader 屬性隱藏與偽裝邏輯。
*   **深度記憶體隱藏 (hide_map)**：確保注入模組在記憶體映射中被徹底清理。原本 `memfd` 載入的 zygisk-module 現在會偽裝成私有匿名記憶體 (Private Anonymous Memory)，進一步降低被反作弊系統掃描的風險。
*   **VBMeta 隨機化**：改用 `/dev/urandom` 生成 VBMeta digest，大幅提升特徵隨機性。

### ⚙️ 核心注入與相容性升級
*   **支援階層式 Zygote 啟動 (Stub Process)**：重構 `ptrace` 監控邏輯，現在完美支援 `init` -> `stub_zygote` -> `zygote` 的啟動鏈（不再受限於只能是 init 的直接子進程）。這讓模組在各種魔改系統上的注入更具韌性！
*   **重構掛載命名空間 (Mount Namespace) 傳輸**：棄用舊版的 PID/FD 整數傳輸，改用 Unix Domain Sockets (`SCM_RIGHTS`) 直接傳遞 FD。徹底解決部分裝置（特別是 Android 12 / arm32 架構）上出現的 `Permission denied` 錯誤。
*   **SELinux 規則補全**：允許 zygote 讀取 mount namespace，修復了在 AVD 模擬器 (qemu) 上因 SELinux 攔截導致命名空間更新失敗的問題。

### 🐛 崩潰修復與底層優化
*   **修復特定內核設備崩潰 (SIGSEGV)**：針對 Redmi Note 10 Pro (Kernel 4.14) 等設備，在讀取主執行緒堆疊時新增了 `PROT_READ` 權限檢查，跳過不可讀的 Stack Guard Pages，解決開機或執行時的隨機崩潰。
*   **修復緩衝區覆寫 Bug**：修正了 `recv_fds` 在處理 Rust 守護進程傳遞的 Dummy Payload 時，錯誤覆寫控制訊息長度的問題。
*   **編譯與程式碼健壯性修復**：
    *   新增 `g_art_inode` 與 `g_art_dev` 全域變數快取，徹底解決 `/libart.so` 相關的 undeclared identifier 編譯報錯。
    *   修復指標轉型報錯（補上 `reinterpret_cast`），解決 C++ 嚴格型別檢查問題。
    *   修復記憶體洩漏與非法地址訪問問題。
*   **效能與日誌優化**：優化 `/proc/self/mountinfo` 解析效能，並減少不必要的錯誤日誌干擾。
