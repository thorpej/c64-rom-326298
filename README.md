# ROM replacer module for Commodore 64s

This is a module that replaces the 3 mask ROMs in a Commodore 64 with a
single parallel NOR flash ROM chip that's extremely reliable and still,
as of October 2023, being manufactured.  Why would you want to do this?
Well, sometimes these old MOS mask ROMs fail, and when they do, you have
to replace them with a newer part.  And to do *that*, you will probably
have to use some sort of adapter to fit a newer EPROM or EEPROM chip into
the socket.  Well, if you're going install an adapter anyway, why not just
do it once?

In addition to improved reliability, this module draws less power and
produces less heat than the original mask ROMs.  Furthermore, because
the flash ROM is a larger capacity (128KB) and reprogrammable, it can
also hold 3 alternate ROM images for each ROM in addition to the
standard ROM image (for a total of 4 each).  3 sets of DIP switches are
provided to select between the ROM images.

While originally designed for my 326298 Rev A board, this will work
in the other Commodore 64 longboards that have 3 24-pin ROM sockets.

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
few parts.  Most of the parts can be purchased from [Jameco Electronics](https://www.jameco.com),
a small business located in the San Francisco Bay Area that's been serving
the elctronics hobbyist community for decades.  Alas, there are a few items
on the list that Jameco doesn't have, so I've provided links to the parts on
Mouser, as well, at least for one parts that Mouser carries (alas, Mouser
does not carry all of these parts, either).

* One of the **c64-rom-326298** PCBs.  The Gerber files are provided
here and I have set up a shared project on PCBWay [here](https://www.pcbway.com/project/shareproject/ROM_Replacer_board_for_Commodore_64W55451ASS34_c64_rom_326298_1_0_gerbers_e5988f98.html).
* A standard DIP-32 0.6 inch socket for the flash chip.  I prefer the
machined type (Jameco part number [**105381**](https://www.jameco.com/z/ICM-632-1-GT-James-Electronics-32-Pin-Machine-Tooled-Low-Profile-IC-Socket-0-6-Inch-Wide_105381.html)).
* A standard DIP-24 0.3 inch socket for the GAL22V10.  Again, I prefer
the machined type (Jameco part number [**39386**](https://www.jameco.com/z/24MTLP-3-Jameco-ValuePro-Socket-IC-24-Pin-Machine-Tooled-Slimline-Low-Profile-Soldertail-3-Width_39386.html)).
* *Only if your ROM are not already in sockets*, 3 standard DIP-24 0.6 inch
sockets to receive the ROM replacer board.  For these, the dual-leaf type
sockets are actually better because they're a little more tolerant of pins
that are not perfectly-aligned (Jameco part number [**112264**](https://www.jameco.com/z/6000-24W-James-Electronics-24-Pin-Dual-Wipe-Low-Profile-IC-Socket-0-6-Inch-Wide_112264.html)).
* 2 100nF / 0.1uF ceramic capacitors with 2.54mm lead spacing that
fits into a 4mm x 2.6mm footprint (Jameco part number [**25523**](https://www.jameco.com/z/MD-1-James-Electronics-Monolithic-Ceramic-Capacitor-0-1-micro-F-50V-20-_25523.html) or Mouser part number [**594-K104K15X7RF5UL2**](https://www.mouser.com/ProductDetail/Vishay-BC-Components/K104K15X7RF5UL2?qs=rLgk8CAOBHbCqsnkGO2HJA%3D%3D) are good candidates).
* 1 7-pin 4.7K ohm bussed 6-resistor array in a SIP package (Jameco part number [**24660**](https://www.jameco.com/z/10BRN4-7K-4310R-101-472--James-Electronics-10-Pin-125-mWatt-4-7k-Ohm-2-Bussed-Resistor-Network_24660.html) or Mouser part
numbers [**279-SIL07E472J**](https://www.mouser.com/ProductDetail/TE-Connectivity-AMP/SIL07E472J?qs=8G8kQhBkhGgEfy%2FI59SPVQ%3D%3D) or [**652-4607X-1LF-4.7K**](https://www.mouser.com/ProductDetail/Bourns/4607X-101-472LF?qs=s5SGu2UNbPR%252Bh5Zd6JQ4tg%3D%3D)).
* A Microchip **SST39SF010A** 128k x 8 flash ROM chip, DIP-32 package
(Mouser part number [**804-39SF010A7CPHE**](https://www.mouser.com/ProductDetail/Microchip-Technology/SST39SF010A-70-4C-PHE?qs=QvO7Tx5jqMVuuIOitIyveA%3D%3D)).
* A Lattice **GAL22V10** (-15 or -25) or Atmel / Microchip **ATF22V10C-15PU**.  Lattice GAL22V10s can be acquired on the secondary electronics market (eBay, AliExpress, etc.).  ATF22V10Cs can be acquired
from the usual electronics suppliers (Mouser part number
[**556-AF22V10C15PU**](https://www.mouser.com/ProductDetail/Microchip-Technology/ATF22V10C-15PU?qs=2mdvTlUeTfCr46ZvfjTtAg%3D%3D)).
* 3 2-position SPST DIP switches (Jameco part number [**109059**](https://www.jameco.com/z/KAS1102E-JVP-Jameco-ValuePro-2-Position-Raised-Slide-DIP-Switch-On-Off-SPST-PC-Pins-2-54mm-Through-Hole_109059.html) or Mouser part number [**653-A6E2104N**](https://www.mouser.com/ProductDetail/Omron-Electronics/A6E-2104-N?qs=vyIerDHf%2Fml%252BIzczbpFO%252Bw%3D%3D)).
* Round (machine tooled) pin headers to populate 42 pins.  I usually buy
these on AliExpress in bulk and have them on-hand,
[here](https://www.aliexpress.us/item/3256801585843343.html), for example.
I have been told that these pin headers can be found on Mouser with Mouser
part number [**200-MTSW15007TS180**](https://www.mouser.com/ProductDetail/Samtec/MTSW-150-07-T-S-180?qs=Cqqh%252BS766wn5xlRZ3985zg%3D%3D), although I have not
verified this myself!  Anyway, you must use this type because the usual square
pin headers will damage the sockets on the C64 main board.

You must use sockets for the ICs for two reasons:
* There must be clearance for the pins that face downward towards the
C64 main board, some of which are below the ICs on the board.
* You probably want to be able to remove the flash chip at some point to
reprogram it with additional ROM images.

(I suppose you *could* solder the GAL to the board after programming it
if you really wanted to, but really it's best practice to put it in a socket,
in my opinion.)

You will also need a programmer to program the GAL and the flash ROM chip.
I use a TL866II Plus, which can program both the Lattice and Atmel / Microchip
versions of the 22V10.  You want to program the 22V10 with the file
[gal-files/c64-128k-rom-mux.jed](gal-files/c64-128k-rom-mux.jed).  I do not
supply ROM images for the flash chip.  You'll need to provide those yourself,
either by dumping your existing ROMs or by getting ROM images another way
(e.g. from [zimmers.net](http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/c64/index.html)).

If the mask ROMs are not socketed in your Commodore 64, then you need
to de-solder the orignal ROMs and install the DIP-24 sockets mentioned
in the parts list above.  Do this first!

When assembling the board, you want to get the downward-facing pin headers
that insert into the ROM sockets as vertically aligned as possible.  One
way to doing this is to insert the pins into a breadboard, set the board
down on top of the pins, and hold the board flat as you tack a couple of
the pins to the board to keep it still while you finish the rest.  Other
option is to insert the header into the board, tack one pin to the board
and then, while heating that one solder joint, carefully moving the header
around until it is perfectly perpindicular.  Just be careful not to burn
your fingers!

Next, place the chip sockets on the PCB, flip the PCB over, and solder
the sockets to the PCB from the bottom side.

Next, populate the ceramic capacitors and resistor array and solder
them into place.

Finally, populate the 3 2-position DIP switches with the "ON" position
being towards the flash ROM socket and solder them into place.

I've provided a small command line tool, [mkflashimg.sh](mkflashimg.sh), to
make it easy to assemble a flash ROM image.  It's a shell script that should
run just fine on Linux, NetBSD/FreeBSD, macOS, and maybe even Cygwin.  Here
is an example of how to run the tool:

    dhcp-194:thorpej$ ./mkflashimg.sh -k kernal.901227-02.bin -k kernal.901227-03.bin -k JiffyDOS_C64_6.01.bin -k JiffyDOS_C64_6.01.bin -b basic.901226-01.bin -c characters.901225-01.bin c64-rom-326298.bin
    $KERNAL_0='kernal.901227-02.bin'
    $KERNAL_1='kernal.901227-03.bin'
    $KERNAL_2='JiffyDOS_C64_6.01.bin'
    $KERNAL_3='JiffyDOS_C64_6.01.bin'
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
slot 0, the rev 3 KERNAL in KERNAL slot 1, and JiffyDOS in slots 2 and 3 (so
that no matter the setting of the "0" bit of the KERNAL selector switch, if
the "1" bit is set, I will always get JiffyDOS).  Once you've assembled
the flash ROM image, use the programmer of your choice to write it to the
flash ROM chip.

And that's it!  Just pop the programmed flash chip and GAL into the sockets,
set the DIP switches to select the ROM images of your choice, insert the
module into the C64, and enjoy!

There are other ways you can use this board, too!  For example, if you
buy a JiffyDOS ROM chip, a switch is provided to let you select JiffyDOS
or the stock KERNAL.  If you want to install such a switch, all you need
to do is tack the wires from the switch to the appropriate DIP switch solder
pads on the board; if either the DIP switch or external switch for that
position is set to "on", then that switch position will be "on".  It's up to
you to decide if you want to drill a hole in your precious Commodore 64 to do
this!

If you have any questions about the board, you can reach out to me on
Twitter (*[@thorpej](https://twitter.com/thorpej)*) or Mastodon
(*[@thorpej@mastodon.sdf.org](https://mastodon.sdf.org/@thorpej)*).  You
can also check out my [YouTube channel](https://www.youtube.com/@thorpejsf),
which has this and other retrocomputing related content.
