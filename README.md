# FPGA_Falling_Sand_Game

## About

The purpose of this project is to implement a falling sand simulation onto a
Xilinx FPGA (specifically the Digilent Basys 3). I'm using this project as a
learning experience to hone in my skills with FSMs, video data, and particular
communication protocols.

## Usage

### Testing

To view waveforms from testbenches, I used Icarus Verilog and GTKWave.

### Falling Sand Game

A VGA compatiable monitor, Ps2 USB mouse, and a Digilent Basys3 FPGA is required
to use the Falling Sand Game. A different FPGA may be used, but the IO
constraint file (.xdc file) must be changed to accomodate the new platform.

## Game

### Programming the FPGA

1. Move into the FPGA_FALLING_SAND_GAME directory
2. Follow the commands below.

```bash
cd src/

make program_fpga_vivado
```

### Gameplay

Use left click to place a sand particle.

Use right click to change between sand, water, gas, and destroy cursor.

## Troubleshooting

Sometimes while initially flashing the bitstream to the FPGA the mouse may not
be properly initialized. Take the mouse out of the USB port on the FPGA and
click the reset button on the FPGA (center pushbuttom); plug the mouse back in
and you should be good to go.

## Feedback

I would greatly appreciate any feedback on this project as I'm relatively new to
FPGA development!
