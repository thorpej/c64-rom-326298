# ROM replacer module for Commodore 64s with the 326298 main board

This is a module that replaces the 3 mask ROMs on a Commodore 64
326298 mainboard with a single parallel NOR flash ROM chip that's
extremely reliable and still, as of October 2023, being manufactured.
In addition to improved reliability, this module draws less power and
produces less heat than the original mask ROMs.  Furthermore, because
the flash ROM is a larger capacity (128KB) and reprogrammable, it can
also hold 3 alternate ROM images for each ROM in addition to the
standard ROM image (for a total of 4 each).  3 sets of DIP switches
are provided to select between the ROM images.

This work is licensed under the [Creative Commons Attribution
ShareAlike 4.0 International license](https://creativecommons.org/licenses/by-sa/4.0/).

![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

## How it works

The theory of operation of the module is quite simple.  Each of the
3 mask ROMs are connected to the system address bus (A0-A12 for the
BASIC and KERNAL ROMs, A0-A11 for the Character ROM), the system data
bus, and their own individual chip select, which are controlled by
the PLA.  The module intercepts all of these signals at the ROM sockets.

The 128KB flash ROM is divided into 3 segments:

* A 32KB segment to hold up to 4 8KB KERNAL ROM images.
* A 32KB segment to hold up to 4 8KB BASIC ROM images.
* A 16KB segment to hold up to 4 4KB Character ROM images.

These segments are selected by decoding the mask ROM chip selects and
mapping them to the A15-A16 address inputs to the flash ROM:

* 00 - KERNAL
* 01 - BASIC
* 10 - Character
* 11 - (not used)

Within each segment, 2 DIP switches control the upper 2 bits of the
offset within the segment:

* A13-A14 for the KERNAL and BASIC segments.
* A12-A13 for the Character segment (A14 is always 0 in this case).

Because A12's behavior is dependent on which ROM segment is selected,
the decoding logic intercepts it and adjusts it as necessary.

The decoding, segment selection, and image selection logic is implemented
in a GAL22V10.  The logic equations can be found in
[gal-files/c64-128k-rom-mux.gal](gal-files/c64-128k-rom-mux.gal).  You can
read the comments in that file for a more detailed explanation of what's
going on, but here are the basic rules:

* The flash ROM CE# and OE# signals are asserted when exactly one of the
  3 mask ROM chip selects are asserted.
* Because the value of the A12 input to the flash ROM is dependent on
  which mask ROM is being selected, the assertion of CE# and OE# is delayed
  by one propagation delay through the GAL, ensuring that A12 will be stable
  before the output is enabled.
* The individual image selection within the selected segment follows the DIP
  switch setting corresponding to which of the 3 mask ROMs is being selected.

The module has pins that make the following connections to the mask ROM
sockets on the C64 board:

* U3 - 1-24 (all pins)
* U4 - 20, 21
* U5 - 9-24

## How to build it

Building the module is pretty simple.  I've used all through-hole parts
to make it easier to assemble for the casual hobbyist.  You only need a
few parts:

* One of the **c64-sram-326298** PCBs.  The Gerber files are provided
here and I will probably put this up as a shared project on PCBWay so
you can easily order your own.
* A standard DIP-32 0.6 inch socket for the flash chip.  I prefer the
machined type (Jameco part number **105381**).
* A standard DIP-24 0.3 inch socket for the GAL22V10.  Again, I prefer
the machined type (Jameco part number **39386**).
* 2 100nF / 0.1uF ceramic capacitors with 2.54mm lead spacing that
fits into a 4mm x 2.6mm footprint (Mouser part number
**594-K104K15X7RF5UL2** is a good candidate).
* 1 7-pin 4.7K ohm bussed 6-resistor array in a SIP package (Mouser part
number **279-SIL07E472J** or Mouser part number **652-4607X-1LF-4.7K**).
* A Microchip **SST39SF010A** 128k x 8 flash ROM chip, DIP-32 package
(Mouser part number **804-39SF010A7CPHE**).
* A Lattice **GAL22V10** (-15 or -25) or Atmel / Microchip **ATF22V10C-15PU**.  Lattice GAL22V10s can be acquired on the secondary electronics market (eBay, AliExpress, etc.).  ATF22V10Cs can be acquired
from the usual electronics suppliers (Mouser part number
**556-AF22V10C15PU**).
* 3 2-position SPST DIP switches (Mouser part number **653-A6E2104N** or
Jameco part number **109059**).
* Round (machine tooled) pin headers to populate 42 pins.  Unfortunately,
I have only found these on eBay and AliExpress.  They're usually gold
plated.  Search for "machined pin header".  I'm sure there's some equivalent
available from Mouser or Digikey, but finding it has prooved to be a real
challenge for me.  Anyway, you must use these type because the usual square
pin type will damage the sockets on the C64 nmain board.

Sockets are required for the ICs on the module because there needs to
be clearance for the pins that face downward towards the C64 main board.

You will also need a programmer to program the GAL22V10.  I use a
TL866II Plus, which can program both the Lattice and Atmel / Microchip
22V10s.  Program the 22V10 with the file
[gal-files/c64-128k-rom-mux.jed](gal-files/c64-128k-rom-mux.jed).

If the mask ROMs are not socketed in your Commodore 64, then you need
to de-solder the orignal ROMs and install standard DIP-24 0.6 inch
sockets (Jameco part number **39351**).  Do this first!

The easiest way to assemble the ROM module is to use the C64's ROM
sockets as a template.  Break off the pin headers from the strip, keeping
runs of adjacent pins connected together, and insert them into the C64
ROM sockets using the list of pin numbers above.  This will put the
pins in the correct locations for fitting into the module PCB while also
ensuring that they are straight (especially if you use the recommended
machined sockets).  Solder the pins to the PCB from the top side, and
then remove the module from the C64.

Next, place the chip sockets on the PCB, flip the PCB over, and solder
the sockets to the PCB from the bottom side.

Next, populate the ceramic capacitors and resistor array and solder
them into place.

Finally, populate the 3 2-position DIP switches with the "ON" position
being towards the flash ROM socket and solder them into place.

I've provided a small tool, [mkflashimg.sh](mkflashimg.sh), to make it easy
to assemble a flash ROM image.  Here is an example of how to run the tool:

    dhcp-194:thorpej$ ./mkflashimg.sh -k kernal.901227-02.bin -k kernal.901227-03.bin -b basic.901226-01.bin -c characters.901225-01.bin c64-rom-326298.bin
    $KERNAL_0='kernal.901227-02.bin'
    $KERNAL_1='kernal.901227-03.bin'
    $KERNAL_2='empty'
    $KERNAL_3='empty'
    $BASIC_0='basic.901226-01.bin'
    $BASIC_1='empty'
    $BASIC_2='empty'
    $BASIC_3='empty'
    $Character_0='characters.901225-01.bin'
    $Character_1='empty'
    $Character_2='empty'
    $Character_3='empty'

    Write flash image to 'c64-rom-326298.bin' (y/n)? y

    -rw-r--r--  1 thorpej  staff  81920 Dec 14 16:13 c64-rom-326298.bin
    dhcp-194:thorpej$

In this example, I've put the original rev 2 KERNAL for my machine in KERNAL
slot 0 and the and the rev 3 KERNAL in KERNAL slot 1.  Once you've assembled
the flash ROM image, use the programmer of your choice to write it to the
flash ROM chip.

And that's it!  Just pop the programmed flash chip and GAL into the sockets,
set the DIP switches to select the ROM images of your choice, insert the
module into the C64, and enjoy!

If you have any questions about the board, you can reach out to me on
Twitter (*[@thorpej](https://twitter.com/thorpej)*) or Mastodon
(*[@thorpej@mastodon.sdf.org](https://mastodon.sdf.org/@thorpej)*).  You
can also check out my [YouTube channel](https://www.youtube.com/@thorpejsf),
which has this and other retrocomputing related content.
