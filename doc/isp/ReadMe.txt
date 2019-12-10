The connection of the ISP pins should be made directly on the board, since these pins are not present on the external connector.

The Top.jpg and Bottom.jpg files have the relevant traces highlighted, with the exception of the ground one.

In order to program the board, either the VCC wire (directly connected to the uC power port) or the VBATT one (battery terminal) can be used.
Suggestions are:
- if you are using a programmer which forces 3.3V, connect to the VBATT wire (after removing the batteries)
- if you are using a programmer which senses the 3.3V, connect to the VCC wire (leaving the batteries in)

Remember to use a programmer able to program at 3.3V, since using a 5V one may damage the microcontroller and/or the wireless module.

Connector_1 and Connector_2 show a sample for a connection.
A 10x2 1.27mm pitch SMD connector is used, then 4 pins were removed and it was soldered on a piece of perfboard.
The lower height of the connector lets it sit under the display, so it is easy to reprogram the uC by removing only the screen.

Tested programmers:
- USBtinyISP: unable to program the EEPROM memory
- PicKit2 + voltage dividers on MOSI, SCK and RESET, without VCC connected: works correctly
