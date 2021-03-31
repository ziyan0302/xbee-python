#!/usr/bin/env python3

from digi.xbee.devices import XBeeDevice

PORT = '/dev/ttyUSB0'
BAUD = 115200

def main():
    device = XBeeDevice(PORT,BAUD)

    try:
        device.open()
        xbee_network = device.get_network()
        
        # remote_device = xbee_network.discover_device()
        print(device.get_node_id())
    
    finally:
        if device is not None and device.is_open():
            device.close()

if __name__ == '__main__':
    main()
