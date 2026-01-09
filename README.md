# PEARL-V 🐾

PEARL-V is a modular implementation of the **RV32I** ISA in System Verilog by Yannik Osterholzer.  
I developed this design for my Master’s in Integrated Systems at CUAS. 
My goal was to build a pipelined RISC-V processor with a focus on clarity, using a modular and well-structured SystemVerilog coding style.

---

### Architecture

The PEARL-V core implements a **5-stage pipeline** (Fetch, Decode, Execute, Memory, Writeback), with the following characteristics:

* **Data Flow & Pipeline Control:**
  * **Forwarding:** Data is passed directly between pipeline stages to reduce stalls.
  * **Stall Logic:** Load-use hazards are resolved by automatically inserting a single-cycle stall.

* **Control Flow & Traps:**
  * **Branch Handling:** Branch decisions are resolved in the EX stage. Without active branch prediction, every taken branch currently results in a 2-cycle penalty.
  * **Trap System:** Includes support for`ECALL` and `EBREAK`, with return from traps via `MRET`. On a single-core in-order processor like PEARL-V, `FENCE` acts as a `NOP` since all memory accesses are already executed in program order.

### Instruction Set Coverage 

| Category              | Instructions                          | Status       |
|-----------------------|---------------------------------------|--------------|
| **Arithmetic & Logic** | `ADD(I)`, `SUB`, `AND(I)`, `OR(I)`, `XOR(I)`, `SLT(I)U` | 🟢 Implemented |
| **Shift Operations**  | `SLL(I)`, `SRL(I)`, `SRA(I)`          | 🟢 Implemented |
| **Memory Accesses**   | `LB(U)`, `LH(U)`, `LW`, `SB`, `SH`, `SW` | 🟢 Implemented |
| **Control Flow**      | `JAL`, `JALR`, `B(EQ/NE/LT/GE)(U)`    | 🟢 Implemented |
| **System & Traps**    | `ECALL`, `EBREAK`, `MRET`, `FENCE`    | 🟢 Implemented       |
| **CSR Handling**      | `CSRRW`, `CSRRS`, `CSRRC`             | 🔴 In Progress  |

### Inspiration

I built PEARL-V after studying several tutorials and small open-source RISC-V cores.
Some of the works that helped shape the design:

* **Bruno Levy:** *"From Blinker to RISC-V"*.
* **Harris & Harris:** *"Digital Design and Computer Architecture (RISC-V Edition)"*.
* **Li-Wen Li (TinyRISCV):** Inspiration for the CSR interface.

---

### Current Limitations & Roadmap

* **CSR Access:** Status registers are not yet accessible to software.
* **Interrupts:** Currently only synchronous traps are supported, but external interrupts are planned.
* **Branch Prediction:** Future extension with a simple prediction unit to reduce branch penalties.
* **Performance Counters:** Future implementation of basic hardware counters (e.g., cycle and instruction retired counters) to enable benchmarking and performance analysis.
---

> *PEARL-V is named in loving memory of Pearl, a small but spirited dachshund. Much like its namesake, this core aims to be compact and loyal.* 🐾
