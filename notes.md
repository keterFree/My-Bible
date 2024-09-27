# COMP 454

## Course Outline

### General introduction to microproccessors

### Z80 microcomputer system

- components
- Block Diagramn
- Memory address decoding

### Data communication

- Serial data communication
- Synchronous and asynchronous data communication
- direct memory access interface
- I/O devices
- memory mapped I/O interfacing
- peripheral mapped I/O interfacing
- I/O interface circuits
- Core and special purpose interfacing

### Z80 Instruction set

- instruction set groups
- Instruction format
- Instruction sizes
- Z80 addressing modes
- Z80 assembly language programming
- Time delay subroutines

## General architecture of a microproccessor

***This refers to the internal circuits building blocks that implemets hardware and software functions of the system***

### Hardware Architecture

- 8-bit microproccessor
- 40 I/O pins
- +5v power supply
- clock frequency 4-20 mhz

***Pin out diagram***

#### **Pin out desciption:** The 40 pis are classified into six functional groups

1) ***Address bus lines(16)***

   - A0-A15 : used to provide the address from memory and identifying input /output devices
   - They are unidirectional ranging from 0000H to FFFFH

2) ***Data bus lines(8)***

    - D0-D7 : used for sending and recieving data between memory and I/O devices
    - They are bidirectional ranging from 00H to FFH

3) ***Power supply and frequency signal lines***

    - Two power lines : **+5v** and **GND**.
    - One frequency signal line **CLOCK**(8). 
    - The proccessor executes instructions by stepping through a precise set of basic oparations with each oparation taking a number of clock(time) periods.
        ***timing diagramn for Z80***

4) ***System control signal lines(6)***

    - Used to control different system oparations.
    - All are active LOW

5) ***CPU control signal lines(5)***

    - These signals are  solely used to control the functions of the microprocessor

6) ***CPU bus control signal lines(2)***

    - BUSRQ , BUSAK.

#### **Z80 interrupt response**

Interrupts are sigals that allow peripheral devices to suspend microproccessor oparations forcing it ito start a peripheral service routine.
There are two types of iterupts:

1. ***Non-maskable interrupt:*** hardware related thus always acknowledged when it occurs
2. ***Maskable interrupt:*** software related thus the microproccesor can be programmed to respond either in Mode 0(Any address space) or mode 1(moves to 0038 address space) or Mode 2(Indirect address call).
