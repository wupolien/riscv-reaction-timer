# RISC-V Three-Round Reaction Timer on Basys 3
以 RISC-V CPU 為核心之三回合反應時間累計與七段顯示系統

## 1. 使用開發板

Basys 3 FPGA Development Board

本專題使用 Basys 3 FPGA 開發板實作三回合反應時間測試系統，主要使用 button、LED、七段顯示器與 100MHz clock。

## 2. 使用工具版本

| 工具               | 版本 / 說明                                                    |
| ---------------- | ---------------------------------------------------------- |
| Vivado           | Vivado 2091                                 |
| Verilog HDL      | 用於撰寫 CPU、MMIO、Timer、LED、七段顯示器控制模組                          |
| RISC-V Toolchain | 本版本未另外使用外部 toolchain，RISC-V 程式以機器碼形式寫入 InstructionMemory.v |
| FPGA Board       | Basys 3                                                    |

## 3. 專案資料夾結構

```text
riscv-reaction-timer/
├── README.md
├── src/
│   ├── top.v
│   ├── SingleCycleCPU.v
│   ├── InstructionMemory.v
│   └── mmio.v
├── constraints/
    └── Basys3.xdc

```

## 4. 如何產生 bitstream

1. 開啟 Vivado。
2. 建立新的 RTL Project。
3. 將 `src/` 資料夾中的 Verilog 檔案加入 Design Sources。

   * `top.v`
   * `SingleCycleCPU.v`
   * `InstructionMemory.v`
   * `mmio.v`
4. 將 `constraints/Basys3.xdc` 加入 Constraints。
5. 確認 top module 為 `top.v`。
6. 點選 Run Synthesis。
7. Synthesis 完成後點選 Run Implementation。
8. Implementation 完成後點選 Generate Bitstream。
9. 完成後會產生 `.bit` 檔案，可用於燒錄到 Basys 3 FPGA 開發板。

## 5. 如何載入或修改 RISC-V 程式

本專題的 RISC-V 程式不是由外部 `.hex` 或 `.txt` 檔案載入，而是直接寫在 `InstructionMemory.v` 中。

若要修改 RISC-V 程式流程，需要修改：

```text
src/InstructionMemory.v
```

程式以 address 對應 instruction 的方式儲存，例如：

```verilog
32'd0: inst = 32'h00400293; // addi x5,x0,4
32'd4: inst = 32'h01400413; // addi x8,x0,20
```

每一行代表 CPU 在不同 PC address 讀到的 RISC-V instruction。
若要改變遊戲流程，例如改變回合順序、修改等待流程或修改顯示方式，需要更改 `InstructionMemory.v` 中對應的機器碼。

目前 CPU 支援的主要指令包含：

```text
addi
andi
add
lw
sw
beq
jal
```

## 6. 如何燒錄到 FPGA 開發板

1. 使用 USB 線將 Basys 3 連接到電腦。
2. 開啟 Vivado。
3. 點選 Open Hardware Manager。
4. 點選 Open Target。
5. 選擇 Auto Connect。
6. 點選 Program Device。
7. 選擇產生的 `.bit` 檔案。
8. 按下 Program。
9. 燒錄完成後，Basys 3 會開始執行本專題系統。

## 7. 如何操作與測試

### I/O 功能

| I/O      | 功能                         |
| -------- | -------------------------- |
| BTNU     | Reset，讓系統回到初始狀態            |
| BTND     | 玩家反應按鈕                     |
| LED[0]   | 提示燈，亮起代表可以按下 BTND          |
| LED[2:1] | 顯示目前回合數                    |
| LED[7]   | 提早按下錯誤提示                   |
| 七段顯示器    | 顯示單回合反應時間或三回合總時間，格式為 S.mmm |

### 操作流程

1. 燒錄完成後，按下 BTNU 進行 reset。
2. 放開 BTNU 後，系統會自動進入 Round 1。
3. 系統會先等待一段隨機時間。
4. 當 LED[0] 亮起時，代表玩家可以按下 BTND。
5. 玩家按下 BTND 後，系統停止計時。
6. Round 1 與 Round 2 結束後，七段顯示器會顯示該回合反應時間 10 秒。
7. Round 3 結束後，七段顯示器會先顯示第三回合反應時間 5 秒。
8. 最後七段顯示器會顯示三回合總反應時間。
9. 若 LED[0] 尚未亮起就按下 BTND，LED[7] 會亮起，七段顯示器會顯示 9.999，並重新開始同一回合。

### 測試項目

| 測試項目       | 操作方式               | 預期結果                    |
| ---------- | ------------------ | ----------------------- |
| Reset 測試   | 按下 BTNU            | 系統回到初始狀態，七段顯示器回到 0.000  |
| Round 顯示測試 | 系統進入不同回合           | LED[2:1] 顯示目前回合         |
| 隨機等待測試     | 進入回合後不按按鈕          | 等待一段時間後 LED[0] 亮起       |
| 反應時間測試     | LED[0] 亮起後按下 BTND  | 七段顯示器顯示該回合秒數            |
| 三回合總時間測試   | 完成三回合              | 最後顯示三回合總反應時間            |
| 提早按下測試     | LED[0] 尚未亮起前按 BTND | LED[7] 亮起，七段顯示器顯示 9.999 |

## 8. 已知問題

1. 目前 memory-mapped I/O address 使用低位址版本，例如 `4`、`8`、`16`、`20`，未使用原本規劃的 `0x80000000` 開頭位址。
2. 目前未加入完整 button debounce 電路，因此實機操作時可能受到按鈕彈跳影響。
3. 七段顯示器格式為 `S.mmm`，最大顯示範圍為 `0.000` 到 `9.999` 秒。
4. RISC-V 程式目前直接寫在 `InstructionMemory.v` 中，尚未改成外部 `.hex` 或 `.txt` 檔案載入。
5. 目前使用 polling 方式偵測按鈕狀態，尚未使用 interrupt。
6. 隨機等待使用 LFSR 產生，屬於 pseudo-random，不是真正的硬體亂數。

## 9. 外部來源與授權說明

本專題使用課堂提供的 RISC-V CPU core 觀念作為基礎，並依照本專題需求進行修改與整合。

| 模組 / 內容                       | 來源               | 是否修改 |
| ----------------------------- | ---------------- | ---- |
| RISC-V CPU core               | 課堂提供版本 / 課堂架構觀念  | 是    |
| Instruction Memory            | 自行修改             | 是    |
| Memory-Mapped I/O             | 自行設計             | 是    |
| Timer Module                  | 自行設計             | 是    |
| Seven-Segment Display Control | 自行設計             | 是    |
| Random Wait Logic             | 自行設計             | 是    |
| Basys 3 XDC                   | 依 Basys 3 腳位設定整理 | 是    |

本專題沒有直接下載完整開源專案後展示成果，而是依照課程中 RISC-V CPU 與 FPGA I/O 的概念，自行完成 memory-mapped I/O、timer、七段顯示器、LED 控制與三回合反應時間流程。

## AI 協作說明

本專題過程中有使用 AI 協助整理專題方向、分析錯誤訊息、協助修改 Verilog 架構、整理 README 與報告文字。
所有 AI 產生的內容皆有經過自行檢查、修改，並透過 Vivado synthesis、implementation 與 Basys 3 實機測試確認功能。
