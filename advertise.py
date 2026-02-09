import asyncio
from bless import BlessServer

async def run():
    server = BlessServer(name="Blipboard-Test")

    await server.start()
    print("Server started, advertising signal named \"Blipboard-Test\" ...")

    await asyncio.sleep(60)
    await server.stop()
    print("Advertiser stopped")

asyncio.run(run())