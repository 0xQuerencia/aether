#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import select
import signal
import subprocess
import sys
import time
from typing import Any


MAC_RE = re.compile(r"^(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")
DEVICE_LINE_RE = re.compile(r"^Device\s+([^\s]+)\s+(.+?)\s*$")
DEVICE_PATH_RE = re.compile(
    r"(?P<path>/org/bluez/[A-Za-z0-9_/-]+/dev_(?:[0-9A-Fa-f]{2}_){5}[0-9A-Fa-f]{2})"
)
STOPPING = False


class WatcherError(Exception):
    pass


def _run(argv: list[str], *, timeout: int = 10) -> str:
    env = os.environ.copy()
    env["LC_ALL"] = "C"
    try:
        result = subprocess.run(
            argv,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
            check=False,
        )
    except FileNotFoundError as exc:
        raise WatcherError(f"{argv[0]} is not installed") from exc
    except subprocess.TimeoutExpired as exc:
        raise WatcherError(f"{argv[0]} timed out") from exc

    if result.returncode:
        detail = (result.stderr or result.stdout or f"{argv[0]} failed").strip().replace("\n", " ")
        raise WatcherError(detail)
    return result.stdout or ""


def _connected_macs(output: str) -> list[str]:
    devices = []
    for line in output.splitlines():
        match = DEVICE_LINE_RE.fullmatch(line.strip())
        if match and MAC_RE.fullmatch(match.group(1)):
            devices.append(match.group(1).upper())
    return devices


def _battery_from_info(value: str) -> int | None:
    match = re.search(r"\((\d{1,3})\)", value)
    if match:
        level = int(match.group(1))
        return level if level <= 100 else None
    match = re.search(r"0x([0-9a-fA-F]{1,2})", value)
    if match:
        level = int(match.group(1), 16)
        return level if level <= 100 else None
    match = re.fullmatch(r"\s*(\d{1,3})\s*", value)
    if match:
        level = int(match.group(1))
        return level if level <= 100 else None
    return None


def _parse_info(mac: str, output: str) -> dict[str, Any]:
    fields: dict[str, str] = {}
    uuids: list[str] = []
    for line in output.splitlines():
        if ":" not in line:
            continue
        key, value = line.strip().split(":", 1)
        key = key.strip()
        value = value.strip()
        if key == "UUID":
            uuids.append(value)
        else:
            fields[key] = value

    icon = fields.get("Icon", "").lower()
    audio_profile = re.compile(
        r"audio|headset|hands.?free|headphone|a2dp|le audio", re.IGNORECASE
    )
    audio = icon.startswith("audio-") or any(audio_profile.search(uuid) for uuid in uuids)
    label = " ".join((icon, fields.get("Name", ""), fields.get("Alias", ""))).lower()
    icon_name = "earbuds" if re.search(r"\b(?:earbuds?|buds?|airpods?|airdopes|tws|pods)\b", label) else "headphones"
    return {
        "mac": mac,
        "name": fields.get("Alias") or fields.get("Name") or mac,
        "icon": icon_name,
        "battery": _battery_from_info(fields.get("Battery Percentage", "")),
        "connected": fields.get("Connected", "no").lower() == "yes",
        "audio": audio,
    }


def _mac_for_path(path: str) -> str | None:
    match = re.search(r"/dev_((?:[0-9A-Fa-f]{2}_){5}[0-9A-Fa-f]{2})$", path)
    if not match:
        return None
    mac = match.group(1).replace("_", ":").upper()
    return mac if MAC_RE.fullmatch(mac) else None


def _parse_signal_block(block: str) -> dict[str, Any] | None:
    header = re.search(
        r"^signal .*?path=(?P<path>/[^;]+); interface=org\.freedesktop\.DBus\.Properties; "
        r"member=PropertiesChanged\s*$",
        block.splitlines()[0] if block.splitlines() else "",
    )
    if not header:
        return None
    path = header.group("path")
    mac = _mac_for_path(path)
    if not mac:
        return None

    body = "\n".join(block.splitlines()[1:])
    interface_match = re.search(r'string\s+"(org\.bluez\.(?:Device1|Battery1))"', body)
    if not interface_match:
        return None
    interface = interface_match.group(1)
    changes: dict[str, Any] = {}
    connected = re.search(r'string\s+"Connected"\s+variant\s+boolean\s+(true|false)', body)
    if connected:
        changes["Connected"] = connected.group(1) == "true"
    percentage = re.search(r'string\s+"Percentage"\s+variant\s+byte\s+(\d+)', body)
    if percentage:
        value = int(percentage.group(1))
        if value <= 100:
            changes["Percentage"] = value
    return {"path": path, "mac": mac, "interface": interface, "changes": changes}


def _parse_battery_added(block: str) -> tuple[str, str] | None:
    """(path, mac) when an InterfacesAdded signal adds org.bluez.Battery1 to a device."""
    lines = block.splitlines()
    if not lines or "member=InterfacesAdded" not in lines[0] or '"org.bluez.Battery1"' not in block:
        return None
    match = re.search(r'object path\s+"(/org/bluez/[^"]+)"', block)
    if not match:
        return None
    mac = _mac_for_path(match.group(1))
    return (match.group(1), mac) if mac else None


def _path_map(output: str) -> dict[str, str]:
    paths: dict[str, str] = {}
    for match in DEVICE_PATH_RE.finditer(output):
        path = match.group("path")
        mac = _mac_for_path(path)
        if mac:
            paths[mac] = path
    return paths


class BatteryWatcher:
    def __init__(self) -> None:
        self.devices: dict[str, dict[str, Any]] = {}
        self.paths: dict[str, str] = {}
        self.last_json: str | None = None

    def _info(self, mac: str) -> dict[str, Any] | None:
        if not MAC_RE.fullmatch(mac):
            return None
        try:
            return _parse_info(mac, _run(["bluetoothctl", "info", mac]))
        except WatcherError as exc:
            _log(str(exc))
            return None

    def _busctl_battery(self, path: str) -> int | None:
        try:
            output = _run(
                [
                    "busctl",
                    "--system",
                    "get-property",
                    "org.bluez",
                    path,
                    "org.bluez.Battery1",
                    "Percentage",
                ],
                timeout=5,
            )
        except WatcherError:
            return None
        match = re.search(r"(?:^|\s)(\d{1,3})\s*$", output)
        if not match:
            return None
        value = int(match.group(1))
        return value if value <= 100 else None

    def snapshot(self) -> None:
        try:
            connected = _connected_macs(_run(["bluetoothctl", "devices", "Connected"]))
        except WatcherError as exc:
            _log(str(exc))
            connected = []

        if connected:
            try:
                self.paths = _path_map(_run(["busctl", "--system", "tree", "org.bluez"], timeout=5))
            except WatcherError:
                self.paths = {}
        else:
            self.paths = {}

        devices: dict[str, dict[str, Any]] = {}
        for mac in connected:
            info = self._info(mac)
            if not info or not info["connected"] or not info["audio"]:
                continue
            path = self.paths.get(mac) or "/org/bluez/hci0/dev_" + mac.replace(":", "_")
            battery = self._busctl_battery(path)
            if battery is None:
                battery = info["battery"]
            devices[mac] = {
                "mac": mac,
                "name": info["name"],
                "icon": info["icon"],
                "battery": battery,
            }
        self.devices = devices

    def _refresh_device(self, mac: str, path: str) -> None:
        if not MAC_RE.fullmatch(mac):
            return
        info = self._info(mac)
        if not info or not info["connected"] or not info["audio"]:
            self.devices.pop(mac, None)
            return
        if path.startswith("/org/bluez/") and _mac_for_path(path) == mac:
            self.paths[mac] = path
        device_path = self.paths.get(mac) or "/org/bluez/hci0/dev_" + mac.replace(":", "_")
        battery = self._busctl_battery(device_path)
        if battery is None:
            battery = info["battery"]
        self.devices[mac] = {
            "mac": mac,
            "name": info["name"],
            "icon": info["icon"],
            "battery": battery,
        }

    def handle_signal(self, block: str) -> None:
        
        added = _parse_battery_added(block)
        if added:
            self._refresh_device(added[1], added[0])
            self.publish()
            return
        signal_data = _parse_signal_block(block)
        if not signal_data:
            return
        mac = signal_data["mac"]
        changes = signal_data["changes"]
        if signal_data["interface"] == "org.bluez.Device1":
            connected = changes.get("Connected")
            if not isinstance(connected, bool):
                return
            if connected:
                self._refresh_device(mac, signal_data["path"])
            else:
                self.devices.pop(mac, None)
            self.publish()
            return

        if signal_data["interface"] == "org.bluez.Battery1" and "Percentage" in changes:
            if mac not in self.devices:
                self._refresh_device(mac, signal_data["path"])
            if mac in self.devices:
                updated = dict(self.devices[mac])
                updated["battery"] = changes["Percentage"]
                self.devices[mac] = updated
                self.publish()

    def publish(self) -> None:
        payload = {
            "devices": [self.devices[mac] for mac in sorted(self.devices)],
        }
        line = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
        if line != self.last_json:
            print(line, flush=True)
            self.last_json = line


def _log(message: str) -> None:
    print(f"btbattery: {message}", file=sys.stderr, flush=True)


def _dispatch_block(lines: list[str], watcher: BatteryWatcher) -> None:
    if lines:
        watcher.handle_signal("\n".join(lines))


def _consume_monitor(proc: subprocess.Popen[bytes], watcher: BatteryWatcher) -> None:
    if proc.stdout is None:
        return
    stream = proc.stdout
    buffered = b""
    block: list[str] = []

    def accept_line(raw: bytes) -> None:
        nonlocal block
        line = raw.decode("utf-8", errors="replace").rstrip("\r")
        if line.startswith("signal "):
            _dispatch_block(block, watcher)
            block = [line]
        elif not line.strip():
            _dispatch_block(block, watcher)
            block = []
        elif block:
            block.append(line)

    while not STOPPING:
        try:
            readable, _, _ = select.select([stream], [], [], 0.5)
        except InterruptedError:
            continue
        if not readable:
            if proc.poll() is not None:
                break
            continue
        chunk = os.read(stream.fileno(), 4096)
        if not chunk:
            break
        buffered += chunk
        while b"\n" in buffered:
            raw, buffered = buffered.split(b"\n", 1)
            accept_line(raw)

    if buffered:
        accept_line(buffered)
    _dispatch_block(block, watcher)


def _stop_monitor(proc: subprocess.Popen[bytes]) -> None:
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
    if proc.stdout:
        proc.stdout.close()


def _pause(seconds: float) -> None:
    deadline = time.monotonic() + seconds
    while not STOPPING and time.monotonic() < deadline:
        time.sleep(min(0.25, deadline - time.monotonic()))


def _monitor(watcher: BatteryWatcher) -> None:
    argv = [
        "dbus-monitor",
        "--system",
        "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'",
        "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded'",
    ]
    while not STOPPING:
        try:
            proc = subprocess.Popen(
                argv,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                bufsize=0,
            )
        except OSError as exc:
            _log(f"cannot start dbus-monitor: {exc}")
            _pause(2)
            continue
        try:
            _consume_monitor(proc, watcher)
        finally:
            _stop_monitor(proc)
        if not STOPPING:
            watcher.snapshot()
            watcher.publish()
            _pause(2)


def _request_stop(_signum: int, _frame: Any) -> None:
    global STOPPING
    STOPPING = True


def main() -> int:
    signal.signal(signal.SIGTERM, _request_stop)
    signal.signal(signal.SIGINT, _request_stop)
    watcher = BatteryWatcher()
    watcher.snapshot()
    watcher.publish()
    _monitor(watcher)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
