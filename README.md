# Mechanical-Braille-Cell-using-FPGA-Board
Developed an FPGA-based refreshable mechanical Braille cell that converts ASCII characters into tactile Braille patterns. The system uses Verilog for Braille conversion and PWM control of servo-driven braille cells and integrates the FPGA with the hardware to generate and validate Braille characters in real time.


### How it works

***Input:*** Eight DIP switches on the FLEX 10K section of the board supply the 8-bit binary ASCII code of a character. 

***ASCII to Braille:*** A Braille cell is six dots, each either raised or lowered, so every character maps to a 6-bit pattern.

***Driving the dots:*** Each dot is an SG90 servo. A servo's angle is set by the high time of a 50 Hz PWM signal: 1 ms holds it at 0° (dot lowered) and 1.5 ms rotates it to 90° (dot raised). 

***Clock:*** The board's internal 25.175 MHz clock peaks at only about 200 mV, too low to drive the servos. A 555 timer circuit was built instead, giving a measured 51.282 kHz at roughly 4 V peak - enough to generate a usable PWM signal.

### Hardware

- Altera UP2 Education Kit (EPF10K70)
- SG90 micro servo × 6
- NE555 timer IC
- DIP switches × 8

### Software

- Verilog HDL
- Quartus II
- [Karnaugh Map Solver](https://www.charlie-coleman.com/experiments/kmap/)

### Course

EEE 304 — Digital Electronics Laboratory

Department of EEE

Bangladesh University of Engineering and Technology (BUET)
