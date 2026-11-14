#!/usr/bin/env python3
import sys
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

AGENT_PATH = "/org/bluez/AutoAgent"

class AutoAgent(dbus.service.Object):
    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        return  # Automatically authorizes audio/HID services

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        return  # Returning without raising an exception confirms the passkey ("yes")

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        return

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: bt_pair.py <MAC_ADDRESS>")
        sys.exit(1)

    mac = sys.argv[1].upper().replace(":", "_")
    dev_path = f"/org/bluez/hci0/dev_{mac}"

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    loop = GLib.MainLoop()

    # 1. Register our silent auto-confirming agent
    agent = AutoAgent(bus, AGENT_PATH)
    manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
    manager.RegisterAgent(AGENT_PATH, "DisplayYesNo")
    manager.RequestDefaultAgent(AGENT_PATH)

    # 2. Grab the device interface
    dev_obj = bus.get_object("org.bluez", dev_path)
    props = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
    device = dbus.Interface(dev_obj, "org.bluez.Device1")

    # 3. Trust, Pair (async with callback), and Connect
    props.Set("org.bluez.Device1", "Trusted", True)

    def on_paired():
        device.Connect()
        print("Successfully paired and connected!")
        loop.quit()

    def on_error(err):
        print(f"Error: {err}")
        loop.quit()

    if not props.Get("org.bluez.Device1", "Paired"):
        device.Pair(reply_handler=on_paired, error_handler=on_error)
        loop.run()
    else:
        on_paired()
