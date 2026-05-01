# Asteroids-diag
Atari Asteroids diagnostic ROM

For more information, read the source code comments :)

* diagram:
This code only tests the CPU RAM and the Vector RAM areas. It outputs
the letter of the failing RAM position in morse code.
Its only real use case is when the built-in diagnostics don't find any error
but you still suspect a RAM problem. 
As of June 2023 this code never helped me on an actual Asteroids repair :)

* diagvec:
This code is intended to help in diagnosing stubborn DVG errors.
It's really all work in progress.

* asterock1k:
This code is intended to help in diagnosing problems on the SIDAM Asterock
PCBs. This bootleg is enough different from Asteroids. All EPROMs are 2708 and the diagnostic goes in place of ROM #7. 
Read the source code for more information.

USE AT YOUR OWN RISK
