## **UART-Based FPGA Command and Control System**



#### **Project Overview**



A synthesizable UART-based command and control system implemented in Verilog HDL for an Artix-7 FPGA. The system receives commands from a host through UART, decodes them using an FSM, controls an 8-bit LED register and PWM output, and returns status/acknowledgment responses.



This project demonstrates a complete RTL-to-synthesis FPGA design flow:



* UART receiver and transmitter design



* UART command decoding



* FSM-based control



* 8-bit LED control



* PWM generation



* Error handling



* Self-checking functional verification



* Vivado synthesis



* FPGA resource utilization analysis



* Timing analysis



* Power estimation



The design targets the Basys 3 / Artix-7 FPGA device xc7a35tcpg236-1.



**Project scope**: Simulation and synthesis only. The design was not physically programmed onto the FPGA as part of this project.



#### **Key Specifications**



|Parameter|Value|
|-|-|
|HDL|Verilog|
|FPGA Family|Xilinx Artix-7|
|Target Device|xc7a35tcpg236-1|
|Development Tool|Vivado 2026.1|
|System Clock|100 MHz|
|UART Baud Rate|9600 baud|
|UART Format|8-N-1|
|PWM Frequency|1 kHz|
|LED Width|8-bit|
|Verification Tests|11|
|Test Result|11/11 Passed|





#### System Architecture



&#x20;                Host / PC

&#x20;                   |

&#x20;                   | UART 9600 baud

&#x20;                   v

&#x20;            +-------------+

&#x20;            |   UART RX   |

&#x20;            +-------------+

&#x20;                   |

&#x20;                   v

&#x20;            +-------------+

&#x20;            |   Command   |

&#x20;            |   Control   |

&#x20;            |     FSM     |

&#x20;            +-------------+

&#x20;             |           |

&#x20;             v           v

&#x20;      +-----------+   +-----------+

&#x20;      | LED Reg.  |   | PWM Gen.  |

&#x20;      |   8-bit   |   | 0-100 %   |

&#x20;      +-----------+   +-----------+

&#x20;             |           |

&#x20;             v           v

&#x20;           LED\[7:0]    PWM Output

&#x20;                   |

&#x20;                   v

&#x20;            +-------------+

&#x20;            |   UART TX   |

&#x20;            +-------------+

&#x20;                   |

&#x20;                   v

&#x20;                Host / PC



#### Functional Description



The host sends a command byte followed by an optional argument. The FPGA receives the UART data, decodes the command, performs the requested operation, generates a two-byte response, and sends the response back through UART.



##### Command Set

|Command|Description|Response|
|-|-|-|
|01 XX|Set 8-bit LED value|A1 XX|
|02|Clear LEDs|A2 00|
|03|Read LED status|A3 LED|
|04 XX|Set PWM duty cycle|A4 XX|
|Invalid command|Invalid command byte|E2 XX|
|Invalid PWM value|PWM > 100|E2 XX|
|UART framing error|Invalid stop bit|E1 00|

XX represents an 8-bit argument/value.



#### UART Configuration



* 9600 baud



* 8 data bits



* No parity



* 1 stop bit



* LSB-first transmission



For a 100 MHz system clock:



&#x09;CLKS\_PER\_BIT = 10417



This gives an actual baud rate of approximately 9600 baud.



The UART receiver also uses a two-flop synchronizer for the asynchronous RX input.



#### RTL Modules



uart\_rx.v — Implements the UART receiver: detects the start bit, samples UART data, receives 8 data bits, checks the stop bit, and generates rx\_valid and framing\_error.



uart\_tx.v — Implements the UART transmitter: generates the start bit, transmits 8 data bits, generates the stop bit, and provides tx\_busy status.



pwm\_gen.v — Generates the PWM output with a parameterized PWM period and 0–100% duty-cycle control. The default 1 kHz configuration uses optimized arithmetic.



uart\_command\_top.v — Top-level integration module connecting UART RX, UART TX, the command-control FSM, LED register, PWM generator, and error handling.



#### Verification



A self-checking Verilog testbench was developed to verify the complete system. The testbench checks UART command reception, command decoding, LED control, LED readback, PWM operation, invalid PWM handling, invalid command handling, and UART response generation.



Total tests  : 11

Passed       : 11

Failed       : 0



ALL TESTS PASSED

UART SYSTEM VERIFIED



|#|Test|Result|
|-|-|-|
|1|Set LED = 55|Pass|
|2|Set LED = AA|Pass|
|3|Clear LEDs|Pass|
|4|Read LED status|Pass|
|5|Set LED = F0|Pass|
|6|Read LED = F0|Pass|
|7|PWM = 0%|Pass|
|8|PWM = 50%|Pass|
|9|PWM = 100%|Pass|
|10|Invalid PWM = 101|Pass|
|11|Invalid command|Pass|





#### Synthesis Results



The design was synthesized using Vivado 2026.1 for xc7a35tcpg236-1.



|Resource|	<br />Used|Available|	<br />Utilization|
|-|-|-|-|
|Slice LUTs|132|20,800|	<br />0.63%|
|Slice Registers|119|41,600|	<br />0.29%|
|Block RAM|0|50|0.00%|
|DSP|0|90|0.00%|
|Bonded IOB|13|106|	<br />12.26%|
|BUFG|1|32|	<br />3.13%|



The final design uses no Block RAM and no DSP resources.



#### Timing Results



Clock constraint:



create\_clock -name sys\_clk -period 10.000 \[get\_ports clk]



This corresponds to a 100 MHz clock.



WNS : +5.643 ns

TNS : 0 ns

WHS : +0.152 ns

Failing Endpoints : 0



All user-specified timing constraints were met.



#### PWM Optimization



The PWM implementation was optimized during synthesis analysis.



|Metric|Before Optimization|After Optimization|
|-|-|-|
|LUTs|412|132|
|DSP|1|0|
|WNS|-4.515 ns|+5.643 ns|



The optimization reduced LUT usage by approximately 68%, eliminated DSP utilization, and converted the timing violation into a positive timing margin.



#### Power Estimate



Total On-Chip Power ≈ 0.074 W

&#x20;                  = 74 mW



This is a Vivado power estimate and not a physical hardware measurement.



#### Project Structure



UART-FPGA-Command-Control/

├── rtl/

│   ├── uart\_rx.v

│   ├── uart\_tx.v

│   ├── pwm\_gen.v

│   └── uart\_command\_top.v

├── simulation/

│   └── tb\_uart\_command\_top.v

├── constraints/

│   └── uart\_command\_top.xdc

├── docs/

│   ├── architecture.png

│   ├── simulation\_results.png

│   ├── utilization\_report.png

│   ├── timing\_summary.png

│   └── power\_report.png

├── reports/

│   ├── utilization.txt

│   ├── timing\_summary.txt

│   └── power.txt

├── results/

│   └── verification\_results.txt

├── README.md

├── .gitignore

└── LICENSE



#### Tools Used



* Verilog HDL



* Xilinx Vivado 2026.1



* Vivado Simulator



* Artix-7 FPGA target



* Basys 3 development board target



#### Future Improvements



* Physical FPGA implementation and hardware testing



* PC-based UART GUI



* FIFO buffering for continuous commands



* CRC/checksum-based communication



* Additional control commands



* SPI/I2C peripheral control



* Sensor and actuator interfacing



* Motor control



* More robust communication error detection



#### References



1\. "FPGA based UART Design: Simulation, Synthesis \& System Verilog functional verification," IEEE GCON 2025, DOI: 10.1109/GCON65540.2025.11173388



2\. "Design and Analysis of UART Protocol with Sec-Ded and Implementation on FPGA," IEEE ICCCNT 2023, DOI: 10.1109/ICCCNT56998.2023.10306744



These references were used as background for FPGA-based UART design, simulation, synthesis, verification, and communication reliability.



#### Author



Poorna Chandra Sai Mekala



M.Tech | VLSI 



#### License



This project is intended for educational, academic, and portfolio purposes.





