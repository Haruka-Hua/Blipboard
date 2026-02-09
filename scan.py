import asyncio
from bleak import BleakScanner

async def main():
    print("Searching for bluetooth devices, please wait ...")
    devices = await BleakScanner.discover()
    for d in devices:
        print(f"Found device: {d.name}, address: {d.address}")

asyncio.run(main())