# RISC-V Three-Round Reaction Timer on Basys 3

## Project Name

以 RISC-V CPU 為核心之三回合反應時間累計與七段顯示系統

## Board

Basys 3 FPGA Development Board

## Tools

- Vivado
- Verilog HDL
- RISC-V instruction memory

## Project Description

This project implements a three-round reaction time measurement system on the Basys 3 FPGA board. The system uses a RISC-V CPU core to control the game flow through memory-mapped I/O.

After reset, the system enters Round 1 automatically. In each round, the system waits for a random delay, then turns on LED[0]. The player presses BTND after seeing LED[0]. The reaction time is measured from the moment LED[0] turns on to the moment BTND is pressed.

Round 1 and Round 2 results are displayed for 10 seconds. Round 3 result is displayed for 5 seconds. Finally, the seven-segment display shows the total reaction time of all three rounds.

## Features

- RISC-V CPU controlled game flow
- Memory-mapped I/O
- Random waiting time
- 1 ms timer
- LED[0] reaction prompt
- LED[2:1] round display
- LED[7] early press error indicator
- Seven-segment display in S.mmm format
- Three-round reaction time accumulation

## I/O Mapping

| I/O | Function |
|---|---|
| BTNU | Reset |
| BTND | Reaction button |
| LED[0] | Prompt LED |
| LED[2:1] | Current round display |
| LED[7] | Early press error |
| Seven-segment display | Reaction time / total time |

## Memory-Mapped I/O Address Map

| Address | Register | Function |
|---|---|---|
| 4 | BUTTON_REG | Read button state |
| 8 | LED_REG | LED control |
| 16 | TIMER_REG | Read timer value |
| 20 | TIMER_CTRL | Start / stop / clear timer |
| 24 | DISPLAY_REG | Seven-segment display value |
| 28 | WAIT_CTRL | Start random wait |
| 32 | WAIT_STATUS | Random wait status |
| 36 | ROUND_REG | Current round |
| 40 | HOLD_CTRL | Start result hold |
| 44 | HOLD_STATUS | Result hold status |

## Folder Structure

```text
riscv-reaction-timer/
├── README.md
├── src/
│   ├── top.v
│   ├── SingleCycleCPU.v
│   ├── InstructionMemory.v
│   └── mmio.v
├── constraints/
│   └── Basys3.xdc
├── images/
│   ├── system_architecture.png
│   └── round_flowchart.png
├── report/
│   └── s1120447_final_project_report.pdf
└── demo/
    └── demo_link.txt