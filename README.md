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

USE AT YOUR OWN RISK
