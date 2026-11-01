import argparse
import json
import os
import re
import subprocess
import sys
from collections.abc import Sequence
from typing import Any


MAC_RE = re.compile(r"^(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")


class NetctlError(Exception):
    pass


def _run(argv: Sequence[str], *, input_text: str | None = None, timeout: int = 20, secret: str = "") -> str:
    env = os.environ.copy()
    env["LC_ALL"] = "C"
    try:
        result = subprocess.run(
            [str(part) for part in argv],
            input=input_text,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
            check=False,
        )
    except FileNotFoundError as exc:
        raise NetctlError(f"{argv[0]} is not installed") from exc
    except subprocess.TimeoutExpired as exc:
        raise NetctlError(f"{argv[0]} timed out") from exc

    stdout = result.stdout or ""
    stderr = result.stderr or ""
    if result.returncode:
        message = (stderr.strip() or stdout.strip() or f"{argv[0]} failed").replace("\n", " ")
        if secret:
            message = message.replace(secret, "[redacted]")
        raise NetctlError(message)
    return stdout.strip()


def _fields(line: str) -> list[str]:
    values: list[str] = []
    value: list[str] = []
    escaped = False
    for char in line:
        if escaped:
            value.append({"n": "\n", "r": "\r"}.get(char, char))
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            values.append("".join(value))
            value = []
        else:
            value.append(char)
    if escaped:
        value.append("\\")
    values.append("".join(value))
    return values


def _records(output: str, size: int) -> list[list[str]]:
    result = []
    for line in output.splitlines():
        fields = _fields(line)
        if len(fields) >= size:
            result.append(fields[:size])
    return result


def _wifi_device() -> list[str] | None:
    rows = _records(
        _run(["nmcli", "-t", "--escape", "yes", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]),
        4,
    )
    return next((row for row in rows if row[1] == "wifi" and row[2] == "connected"), None)


def _saved_wifi() -> list[tuple[str, str]]:
    """(uuid, ssid) for every saved Wi-Fi profile."""
    rows = _records(_run(["nmcli", "-t", "--escape", "yes", "-f", "UUID,TYPE,NAME", "connection", "show"]), 3)
    saved = []
    for uuid, kind, name in rows:
        if kind != "802-11-wireless":
            continue
        try:
            ssid = _run(["nmcli", "-g", "802-11-wireless.ssid", "connection", "show", "uuid", uuid])
        except NetctlError:
            ssid = ""
        saved.append((uuid, ssid or name))
    return saved


def wifi_status() -> dict[str, Any]:
    radio = _run(["nmcli", "radio", "wifi"]).lower() == "enabled"
    active = _wifi_device()
    connected = None
    if active:
        device, _, _, connection = active
        ssid = connection
        ip_output = _run(["nmcli", "-g", "IP4.ADDRESS", "device", "show", device])
        ip_address = next((line.strip() for line in ip_output.splitlines() if line.strip()), "")
        ap_rows = _records(
            _run(
                [
                    "nmcli",
                    "-t",
                    "--escape",
                    "yes",
                    "-f",
                    "IN-USE,SSID,SIGNAL",
                    "device",
                    "wifi",
                    "list",
                    "--rescan",
                    "no",
                ]
            ),
            3,
        )
        in_use = next((row for row in ap_rows if row[0] == "*"), None)
        if in_use and in_use[1]:
            ssid = in_use[1]
        signal = int(in_use[2]) if in_use and in_use[2].isdigit() else 0
        connected = {"ssid": ssid, "signal": signal, "ip": ip_address}
    return {"radio": radio, "connected": connected}


def wifi_scan() -> list[dict[str, Any]]:
    rows = _records(
        _run(
            [
                "nmcli",
                "-t",
                "--escape",
                "yes",
                "-f",
                "SSID,SIGNAL,SECURITY,IN-USE",
                "device",
                "wifi",
                "list",
                "--rescan",
                "yes",
            ],
            timeout=30,
        ),
        4,
    )
    saved = {ssid for _, ssid in _saved_wifi()}
    networks: dict[str, dict[str, Any]] = {}
    for ssid, signal, security, in_use in rows:
        if not ssid or not signal.isdigit():
            continue
        item = {
            "ssid": ssid,
            "signal": int(signal),
            "locked": bool(security and security not in ("--", "")),
            "active": in_use == "*",
            "saved": ssid in saved,
        }
        previous = networks.get(ssid)
        if previous is None or item["signal"] > previous["signal"]:
            networks[ssid] = item
    return sorted(networks.values(), key=lambda item: (-item["signal"], item["ssid"].casefold()))


def wifi_connect(ssid: str, password: str | None = None) -> dict[str, Any]:
    if not ssid:
        raise NetctlError("SSID must not be empty")
    if password is None:
        _run(["nmcli", "--wait", "30", "device", "wifi", "connect", ssid], timeout=35)
    else:
        before = set(_wifi_profile_uuids(ssid))
        try:
            _run(
                ["nmcli", "--ask", "--wait", "30", "device", "wifi", "connect", ssid],
                input_text=password + "\n",
                timeout=35,
                secret=password,
            )
        except NetctlError:
            for uuid in set(_wifi_profile_uuids(ssid)) - before:
                _run(["nmcli", "connection", "delete", "uuid", uuid])
            raise
    return wifi_status()


def _wifi_profile_uuids(ssid: str) -> list[str]:
    try:
        return [uuid for uuid, saved_ssid in _saved_wifi() if saved_ssid == ssid]
    except NetctlError:
        return []


def wifi_disconnect() -> dict[str, Any]:
    active = _wifi_device()
    if active:
        _run(["nmcli", "device", "disconnect", active[0]])
    return wifi_status()


def wifi_forget(ssid: str) -> dict[str, Any]:
    uuids = [uuid for uuid, saved_ssid in _saved_wifi() if saved_ssid == ssid]
    for uuid in uuids:
        _run(["nmcli", "connection", "delete", "uuid", uuid])
    return {"forgotten": ssid, "removed": len(uuids)}


def wifi_radio(state: str) -> dict[str, Any]:
    _run(["nmcli", "radio", "wifi", state])
    return wifi_status()


def _device_rows(output: str) -> dict[str, str]:
    devices = {}
    for line in output.splitlines():
        parts = line.split(maxsplit=2)
        if len(parts) == 3 and parts[0] == "Device" and MAC_RE.fullmatch(parts[1]):
            devices[parts[1].upper()] = parts[2]
    return devices


def _info(mac: str) -> dict[str, Any]:
    output = _run(["bluetoothctl", "info", mac])
    fields = {}
    for line in output.splitlines():
        if ":" in line:
            key, value = line.strip().split(":", 1)
            fields[key.strip()] = value.strip()
    battery = None
    raw_battery = fields.get("Battery Percentage", "")
    match = re.search(r"\((\d{1,3})\)", raw_battery)
    if match:
        battery = min(100, int(match.group(1)))
    else:
        hex_value = re.search(r"0x([0-9a-fA-F]{1,2})", raw_battery)
        if hex_value:
            battery = min(100, int(hex_value.group(1), 16))
    return {
        "mac": mac,
        "name": fields.get("Name", ""),
        "icon": fields.get("Icon", "bluetooth"),
        "battery": battery,
        "connected": fields.get("Connected", "no").lower() == "yes",
        "paired": fields.get("Paired", "no").lower() == "yes",
    }


def bt_status() -> dict[str, Any]:
    show = _run(["bluetoothctl", "show"])
    adapter = {}
    for line in show.splitlines():
        if ":" in line:
            key, value = line.strip().split(":", 1)
            adapter[key.strip()] = value.strip()
    paired_names = _device_rows(_run(["bluetoothctl", "devices", "Paired"]))
    all_names = _device_rows(_run(["bluetoothctl", "devices"]))
    paired = []
    discovered = []
    for mac, listed_name in all_names.items():
        item = _info(mac)
        if not item["name"]:
            item["name"] = listed_name
        if mac in paired_names or item["paired"]:
            item["paired"] = True
            paired.append(item)
        else:
            discovered.append(item)
    return {
        "powered": adapter.get("Powered", "no").lower() == "yes",
        "discoverable": adapter.get("Discoverable", "no").lower() == "yes",
        "paired": paired,
        "discovered": discovered,
    }


def _validate_mac(mac: str) -> str:
    if not MAC_RE.fullmatch(mac):
        raise NetctlError("Invalid Bluetooth MAC address")
    return mac.upper()


def bt_power(state: str) -> dict[str, Any]:
    _run(["bluetoothctl", "power", state])
    return bt_status()


def bt_discoverable(state: str) -> dict[str, Any]:
    _run(["bluetoothctl", "discoverable", state])
    return bt_status()


def bt_scan(seconds: int) -> dict[str, Any]:
    seconds = max(1, min(int(seconds), 60))
    
    try:
        _run(["bluetoothctl", "--timeout", str(seconds), "scan", "on"], timeout=seconds + 10)
    except NetctlError:
        pass
    return bt_status()


def bt_connect(mac: str) -> dict[str, Any]:
    _run(["bluetoothctl", "connect", _validate_mac(mac)])
    return bt_status()


def bt_disconnect(mac: str) -> dict[str, Any]:
    _run(["bluetoothctl", "disconnect", _validate_mac(mac)])
    return bt_status()


def bt_pair(mac: str) -> dict[str, Any]:
    mac = _validate_mac(mac)
    _run(["bluetoothctl", "pair", mac], timeout=45)
    _run(["bluetoothctl", "trust", mac])
    _run(["bluetoothctl", "connect", mac], timeout=45)
    return bt_status()


def bt_remove(mac: str) -> dict[str, Any]:
    _run(["bluetoothctl", "remove", _validate_mac(mac)])
    return bt_status()


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("wifi-status", "wifi-scan", "wifi-disconnect", "bt-status"):
        commands.add_parser(name)
    connect = commands.add_parser("wifi-connect")
    connect.add_argument("ssid")
    connect.add_argument("--password-stdin", action="store_true")
    forget = commands.add_parser("wifi-forget")
    forget.add_argument("ssid")
    radio = commands.add_parser("wifi-radio")
    radio.add_argument("state", choices=("on", "off"))
    for name in ("bt-power", "bt-discoverable"):
        sub = commands.add_parser(name)
        sub.add_argument("state", choices=("on", "off"))
    scan = commands.add_parser("bt-scan")
    scan.add_argument("seconds", type=int)
    for name in ("bt-connect", "bt-disconnect", "bt-pair", "bt-remove"):
        sub = commands.add_parser(name)
        sub.add_argument("mac")
    return parser


def _dispatch(args: argparse.Namespace) -> Any:
    if args.command == "wifi-status":
        return wifi_status()
    if args.command == "wifi-scan":
        return wifi_scan()
    if args.command == "wifi-connect":
        password = sys.stdin.readline().rstrip("\r\n") if args.password_stdin else None
        return wifi_connect(args.ssid, password)
    if args.command == "wifi-disconnect":
        return wifi_disconnect()
    if args.command == "wifi-forget":
        return wifi_forget(args.ssid)
    if args.command == "wifi-radio":
        return wifi_radio(args.state)
    if args.command == "bt-status":
        return bt_status()
    if args.command == "bt-power":
        return bt_power(args.state)
    if args.command == "bt-discoverable":
        return bt_discoverable(args.state)
    if args.command == "bt-scan":
        return bt_scan(args.seconds)
    if args.command == "bt-connect":
        return bt_connect(args.mac)
    if args.command == "bt-disconnect":
        return bt_disconnect(args.mac)
    if args.command == "bt-pair":
        return bt_pair(args.mac)
    if args.command == "bt-remove":
        return bt_remove(args.mac)
    raise NetctlError("Unknown command")


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        result = _dispatch(args)
        print(json.dumps({"ok": True, "data": result}, ensure_ascii=False))
        return 0
    except NetctlError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False))
        return 1
    except Exception as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
