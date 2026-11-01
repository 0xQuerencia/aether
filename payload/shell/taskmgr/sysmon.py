#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import math
import os
import re
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any

import psutil


PROCESS_ATTRS = [
    "pid", "name", "username", "cpu_percent", "memory_info", "memory_percent",
    "num_threads", "status", "cmdline", "io_counters",
]
SORT_KEYS = {"cpu", "mem", "name", "pid", "io"}
INTERVAL_MIN = 0.25
INTERVAL_MAX = 10.0

SESSION_CRITICAL = {
    "Hyprland", "systemd", "dbus-daemon", "dbus-broker", "dbus-broker-launch",
    "Xwayland", "quickshell", "pipewire", "wireplumber",
}


def _read_text(path: Path) -> str | None:
    try:
        return path.read_text().strip()
    except (OSError, UnicodeError):
        return None


def _finite(value: Any) -> float | None:
    try:
        number = float(value)
        return number if math.isfinite(number) else None
    except (TypeError, ValueError):
        return None


def _counter(value: Any, key: str) -> int:
    if value is None:
        return 0
    try:
        return int(value[key] if isinstance(value, dict) else getattr(value, key))
    except (KeyError, AttributeError, TypeError, ValueError):
        return 0


def _counter_map(values: Any) -> dict[str, tuple[int, int]]:
    if not values:
        return {}
    result: dict[str, tuple[int, int]] = {}
    for name, counters in values.items():
        result[str(name)] = (_counter(counters, "read_bytes"), _counter(counters, "write_bytes"))
    return result


def _rate(current: int, previous: int | None, elapsed: float) -> float | None:
    if previous is None or elapsed <= 0:
        return None
    return max(0.0, (current - previous) / elapsed)


def _sysfs_temperature(sys_root: Path) -> float | None:
    for hwmon in (sys_root / "class/hwmon").glob("hwmon*"):
        if _read_text(hwmon / "name") != "k10temp":
            continue
        for label_path in hwmon.glob("temp*_label"):
            if _read_text(label_path) == "Tctl":
                raw = _read_text(hwmon / label_path.name.replace("_label", "_input"))
                value = _finite(raw)
                return value / 1000 if value is not None else None
        for input_path in sorted(hwmon.glob("temp*_input")):
            value = _finite(_read_text(input_path))
            if value is not None:
                return value / 1000
    return None


def _fans(sys_root: Path) -> list[dict[str, Any]]:
    found = []
    for hwmon in sorted((sys_root / "class/hwmon").glob("hwmon*")):
        name = _read_text(hwmon / "name") or ""
        if not name.lower().startswith("asus"):
            continue
        for input_path in sorted(hwmon.glob("fan*_input")):
            rpm = _finite(_read_text(input_path))
            if rpm is None:
                continue
            index = re.search(r"fan(\d+)_input", input_path.name)
            label = _read_text(hwmon / f"fan{index.group(1)}_label") if index else None
            found.append({"name": label or f"Fan {index.group(1) if index else ''}".strip(), "rpm": rpm})
    return found


def _battery(sys_root: Path) -> dict[str, Any] | None:
    root = sys_root / "class/power_supply/BAT1"
    if not root.exists():
        return None

    def number(name: str) -> float | None:
        return _finite(_read_text(root / name))

    percent = number("capacity")
    status = _read_text(root / "status")
    energy_now = number("energy_now")
    energy_full = number("energy_full")
    energy_design = number("energy_full_design")
    power_uw = number("power_now")
    if power_uw is None:
        current_ua = number("current_now")
        voltage_uv = number("voltage_now")
        power_uw = current_ua * voltage_uv / 1_000_000 if current_ua is not None and voltage_uv is not None else None
    power_w = power_uw / 1_000_000 if power_uw is not None else None

    remaining_s = None
    if power_uw and power_uw > 0 and energy_now is not None:
        if status == "Charging" and energy_full is not None:
            energy = max(0.0, energy_full - energy_now)
        else:
            energy = energy_now
        remaining_s = energy / power_uw * 3600
    health = energy_full / energy_design * 100 if energy_full is not None and energy_design else None
    return {
        "percent": percent,
        "status": status,
        "power_w": power_w,
        "time_remaining_s": remaining_s,
        "health_percent": health,
        "energy_now_wh": energy_now / 1_000_000 if energy_now is not None else None,
        "energy_full_wh": energy_full / 1_000_000 if energy_full is not None else None,
        "energy_design_wh": energy_design / 1_000_000 if energy_design is not None else None,
    }


def _zram(sys_root: Path) -> list[dict[str, Any]]:
    result = []
    for device in sorted((sys_root / "block").glob("zram*")):
        values = _read_text(device / "mm_stat")
        if not values:
            continue
        try:
            parts = [int(value) for value in values.split()]
            result.append({
                "device": device.name,
                "original_bytes": parts[0],
                "compressed_bytes": parts[1],
                "memory_bytes": parts[2],
            })
        except (ValueError, IndexError):
            continue
    return result


def _cpu_model(proc_cpuinfo: Path) -> str | None:
    try:
        for line in proc_cpuinfo.read_text(errors="replace").splitlines():
            if line.lower().startswith("model name"):
                return line.partition(":")[2].strip() or None
    except OSError:
        pass
    return None


def _disk_base(device: str) -> str:
    base = os.path.basename(device)
    if base.startswith(("nvme", "mmcblk")):
        return re.sub(r"p\d+$", "", base)
    return re.sub(r"\d+$", "", base)


class Sampler:
    def __init__(
        self,
        ps_module: Any = psutil,
        *,
        sys_root: Path = Path("/sys"),
        proc_cpuinfo: Path = Path("/proc/cpuinfo"),
        monotonic=time.monotonic,
        wall_time=time.time,
        run=subprocess.run,
    ) -> None:
        self.ps = ps_module
        self.sys_root = Path(sys_root)
        self.proc_cpuinfo = Path(proc_cpuinfo)
        self.monotonic = monotonic
        self.wall_time = wall_time
        self.run = run
        self.previous_time = self.monotonic()
        self.previous_net = self._safe_call(self.ps.net_io_counters, pernic=True) or {}
        self.previous_disk = _counter_map(self._safe_call(self.ps.disk_io_counters, perdisk=True))
        self.previous_proc_io: dict[int, tuple[int, int]] = {}
        self.seen_pids: set[int] = set()
        self.gpu_checked_at = float("-inf")
        self.gpu_cache: dict[str, Any] | None = None
        self._safe_call(self.ps.cpu_percent, interval=None)
        self._safe_call(self.ps.cpu_percent, interval=None, percpu=True)

    @staticmethod
    def _safe_call(fn, *args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except Exception:
            return None

    def _gpu(self, now: float) -> dict[str, Any] | None:
        if now - self.gpu_checked_at < 2.0:
            return self.gpu_cache
        self.gpu_checked_at = now
        try:
            result = self.run(
                ["nvidia-smi", "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.gr",
                 "--format=csv,noheader,nounits"],
                capture_output=True, text=True, timeout=1.0, check=False,
            )
            if result.returncode != 0:
                self.gpu_cache = None
                return None
            row = next(csv.reader([result.stdout.strip()]))
            if len(row) < 7:
                self.gpu_cache = None
                return None
            self.gpu_cache = {
                "name": row[0].strip() or None,
                "utilization_percent": _finite(row[1]),
                "memory_used_mib": _finite(row[2]),
                "memory_total_mib": _finite(row[3]),
                "temperature_c": _finite(row[4]),
                "power_w": _finite(row[5]),
                "clock_mhz": _finite(row[6]),
            }
        except (OSError, subprocess.SubprocessError, StopIteration, csv.Error):
            self.gpu_cache = None
        return self.gpu_cache

    def _processes(self, elapsed: float, sort_key: str) -> dict[str, Any]:
        rows = []
        total_threads = 0
        count = 0
        try:
            iterator = self.ps.process_iter(attrs=PROCESS_ATTRS, ad_value=None)
            for process in iterator:
                try:
                    info = process.info
                    pid = int(info.get("pid"))
                    count += 1
                    threads = info.get("num_threads")
                    if threads is not None:
                        total_threads += int(threads)
                    mem = info.get("memory_info")
                    rss = getattr(mem, "rss", None) if mem is not None else None
                    io = info.get("io_counters")
                    read_bytes = _counter(io, "read_bytes") if io is not None else None
                    write_bytes = _counter(io, "write_bytes") if io is not None else None
                    old_io = self.previous_proc_io.get(pid)
                    io_read_rate = _rate(read_bytes, old_io[0] if old_io else None, elapsed) if read_bytes is not None else None
                    io_write_rate = _rate(write_bytes, old_io[1] if old_io else None, elapsed) if write_bytes is not None else None
                    if read_bytes is not None and write_bytes is not None:
                        self.previous_proc_io[pid] = (read_bytes, write_bytes)
                    cmdline = info.get("cmdline")
                    if isinstance(cmdline, (tuple, list)):
                        cmdline = " ".join(str(arg) for arg in cmdline)
                    cpu = _finite(info.get("cpu_percent")) if pid in self.seen_pids else None
                    self.seen_pids.add(pid)
                    rows.append({
                        "pid": pid,
                        "name": info.get("name") or "—",
                        "user": info.get("username"),
                        "cpu_percent": cpu,
                        "rss_bytes": int(rss) if rss is not None else None,
                        "mem_percent": _finite(info.get("memory_percent")),
                        "threads": int(threads) if threads is not None else None,
                        "state": info.get("status"),
                        "cmdline": str(cmdline)[:200] if cmdline is not None else None,
                        "io_read_bps": io_read_rate,
                        "io_write_bps": io_write_rate,
                    })
                except (AttributeError, KeyError, TypeError, ValueError, self.ps.Error):
                    continue
        except Exception:
            pass

        if sort_key == "name":
            rows.sort(key=lambda row: str(row["name"]).lower())
        elif sort_key == "pid":
            rows.sort(key=lambda row: row["pid"])
        elif sort_key == "mem":
            rows.sort(key=lambda row: row["rss_bytes"] or 0, reverse=True)
        elif sort_key == "io":
            rows.sort(key=lambda row: (row["io_read_bps"] or 0) + (row["io_write_bps"] or 0), reverse=True)
        else:
            rows.sort(key=lambda row: row["cpu_percent"] or 0, reverse=True)

        live_pids = {row["pid"] for row in rows}
        self.previous_proc_io = {pid: value for pid, value in self.previous_proc_io.items() if pid in live_pids}
        return {"count": count, "thread_count": total_threads, "sort": sort_key, "items": rows[:150]}

    def _disks(self, now: float, elapsed: float) -> dict[str, Any]:
        raw_counters = self._safe_call(self.ps.disk_io_counters, perdisk=True)
        counters = _counter_map(raw_counters)
        previous = self.previous_disk
        excluded = {"tmpfs", "overlay", "squashfs", "devtmpfs", "proc", "sysfs", "cgroup", "cgroup2", "ramfs", "autofs"}
        result = []
        seen = set()
        partitions = self._safe_call(self.ps.disk_partitions, all=False) or []
        for part in partitions:
            device = str(getattr(part, "device", "") or "")
            fs = str(getattr(part, "fstype", "") or "").lower()
            if not device or fs in excluded or device in seen:
                continue
            seen.add(device)
            usage = self._safe_call(self.ps.disk_usage, getattr(part, "mountpoint", ""))
            if usage is None:
                continue
            name = _disk_base(device)
            current = counters.get(name)
            old = previous.get(name)
            read_rate = _rate(current[0], old[0] if old else None, elapsed) if current else None
            write_rate = _rate(current[1], old[1] if old else None, elapsed) if current else None
            result.append({
                "device": device,
                "mountpoint": str(getattr(part, "mountpoint", "")),
                "filesystem": fs,
                "used_bytes": int(usage.used),
                "total_bytes": int(usage.total),
                "available_bytes": int(usage.free),
                "percent": _finite(usage.percent),
                "read_bps": read_rate,
                "write_bps": write_rate,
            })
        all_read = sum(max(0, current[0] - previous.get(name, current)[0]) for name, current in counters.items())
        all_write = sum(max(0, current[1] - previous.get(name, current)[1]) for name, current in counters.items())
        self.previous_disk = counters
        return {"devices": result, "read_bps": all_read / elapsed if raw_counters and elapsed > 0 else None,
                "write_bps": all_write / elapsed if raw_counters and elapsed > 0 else None}

    def _network(self, elapsed: float) -> dict[str, Any]:
        current = self._safe_call(self.ps.net_io_counters, pernic=True) or {}
        interfaces = []
        total_rx = total_tx = 0.0
        for name, counters in current.items():
            if name == "lo":
                continue
            rx = _counter(counters, "bytes_recv")
            tx = _counter(counters, "bytes_sent")
            old = self.previous_net.get(name)
            rx_rate = max(0.0, (rx - _counter(old, "bytes_recv")) / elapsed) if old is not None and elapsed > 0 else None
            tx_rate = max(0.0, (tx - _counter(old, "bytes_sent")) / elapsed) if old is not None and elapsed > 0 else None
            if rx_rate is not None:
                total_rx += rx_rate
            if tx_rate is not None:
                total_tx += tx_rate
            interfaces.append({"name": name, "rx_bps": rx_rate, "tx_bps": tx_rate,
                               "rx_bytes": rx, "tx_bytes": tx})
        self.previous_net = current
        return {"interfaces": interfaces, "rx_bps": total_rx if interfaces else None,
                "tx_bps": total_tx if interfaces else None}

    def sample(self, sort_key: str = "cpu") -> dict[str, Any]:
        now = self.monotonic()
        elapsed = max(0.001, now - self.previous_time)
        self.previous_time = now

        vm = self._safe_call(self.ps.virtual_memory)
        swap = self._safe_call(self.ps.swap_memory)
        freq = self._safe_call(self.ps.cpu_freq)
        try:
            per_core = self.ps.cpu_percent(interval=None, percpu=True)
        except Exception:
            per_core = None
        try:
            total_cpu = self.ps.cpu_percent(interval=None)
        except Exception:
            total_cpu = None
        try:
            load = list(os.getloadavg())
        except (AttributeError, OSError):
            load = None
        try:
            uptime = max(0.0, self.wall_time() - self.ps.boot_time())
        except Exception:
            uptime = None

        disks = self._disks(now, elapsed)
        network = self._network(elapsed)
        process_data = self._processes(elapsed, sort_key)
        memory = {
            "used_bytes": int(vm.used) if vm is not None else None,
            "total_bytes": int(vm.total) if vm is not None else None,
            "available_bytes": int(vm.available) if vm is not None else None,
            "cache_bytes": int(vm.cached) if vm is not None and getattr(vm, "cached", None) is not None else None,
            "buffers_bytes": int(vm.buffers) if vm is not None and getattr(vm, "buffers", None) is not None else None,
            "percent": _finite(getattr(vm, "percent", None)) if vm is not None else None,
            "swap_used_bytes": int(swap.used) if swap is not None else None,
            "swap_total_bytes": int(swap.total) if swap is not None else None,
            "zram": _zram(self.sys_root),
        }
        core_count = self._safe_call(self.ps.cpu_count, logical=True)
        cpu = {
            "total_percent": _finite(total_cpu),
            "per_core_percent": [_finite(value) for value in per_core] if per_core is not None else None,
            "logical_cores": core_count,
            "frequency_mhz": {"current": _finite(getattr(freq, "current", None)) if freq else None,
                               "max": _finite(getattr(freq, "max", None)) if freq else None},
            "load_avg": load,
            "model": _cpu_model(self.proc_cpuinfo),
            "temperature_c": _sysfs_temperature(self.sys_root),
            "uptime_s": uptime,
        }
        return {
            "type": "sample",
            "timestamp": self.wall_time(),
            "cpu": cpu,
            "memory": memory,
            "gpu": self._gpu(now),
            "disks": disks,
            "network": network,
            "battery": _battery(self.sys_root),
            "fans": _fans(self.sys_root),
            "processes": process_data,
        }


def protected_pid_chain(ps_module: Any = psutil, self_pid: int | None = None) -> set[int]:
    current = os.getpid() if self_pid is None else int(self_pid)
    protected = {current}
    try:
        process = ps_module.Process(current)
        for parent in process.parents():
            protected.add(int(parent.pid))
    except Exception:
        pass
    return protected


def safe_kill(
    pid: Any,
    sig: str,
    *,
    ps_module: Any = psutil,
    current_uid: int | None = None,
    self_pid: int | None = None,
    parent_pids: set[int] | None = None,
) -> dict[str, Any]:
    try:
        target = int(pid)
    except (TypeError, ValueError):
        return {"type": "error", "error": "invalid pid"}
    if target <= 1:
        return {"type": "error", "pid": target, "error": "refusing protected pid"}
    monitor_pid = os.getpid() if self_pid is None else int(self_pid)
    protected = set(parent_pids) if parent_pids is not None else protected_pid_chain(ps_module, monitor_pid)
    protected.add(monitor_pid)
    if target in protected:
        return {"type": "error", "pid": target, "error": "refusing monitor or parent process"}
    if sig not in {"TERM", "KILL"}:
        return {"type": "error", "pid": target, "error": "signal must be TERM or KILL"}
    uid = os.getuid() if current_uid is None else int(current_uid)
    try:
        process = ps_module.Process(target)
        owner = process.uids().real
        if owner != uid:
            return {"type": "error", "pid": target, "error": "process is not owned by current uid"}
        if process.name() in SESSION_CRITICAL:
            return {"type": "error", "pid": target, "error": "refusing session-critical process"}
        process.send_signal(signal.SIGTERM if sig == "TERM" else signal.SIGKILL)
        return {"type": "ack", "pid": target, "signal": sig}
    except ps_module.NoSuchProcess:
        return {"type": "error", "pid": target, "error": "process no longer exists"}
    except ps_module.AccessDenied:
        return {"type": "error", "pid": target, "error": "permission denied"}
    except (OSError, AttributeError, TypeError) as error:
        return {"type": "error", "pid": target, "error": str(error)}


def encode_line(payload: dict[str, Any]) -> str:
    return json.dumps(payload, separators=(",", ":"), allow_nan=False)


def main() -> None:
    state = {"interval": 1.0, "sort": "cpu"}
    state_lock = threading.Lock()
    output_lock = threading.Lock()
    stopped = threading.Event()
    parent_pids = protected_pid_chain(psutil)

    def emit(payload: dict[str, Any]) -> None:
        try:
            line = encode_line(payload)
        except (TypeError, ValueError):
            line = encode_line({"type": "error", "error": "could not encode sample"})
        with output_lock:
            sys.stdout.write(line + "\n")
            sys.stdout.flush()

    def read_commands() -> None:
        for line in sys.stdin:
            try:
                command = json.loads(line)
                if not isinstance(command, dict):
                    raise ValueError("command must be an object")
                name = command.get("cmd")
                if name == "sort":
                    key = command.get("key")
                    if key not in SORT_KEYS:
                        emit({"type": "error", "error": "unsupported sort key"})
                        continue
                    with state_lock:
                        state["sort"] = key
                    emit({"type": "ack", "cmd": "sort", "key": key})
                elif name == "interval":
                    seconds = _finite(command.get("s"))
                    if seconds is None or seconds <= 0:
                        emit({"type": "error", "error": "interval must be a positive number"})
                        continue
                    value = max(INTERVAL_MIN, min(INTERVAL_MAX, seconds))
                    with state_lock:
                        state["interval"] = value
                    emit({"type": "ack", "cmd": "interval", "s": value})
                elif name == "kill":
                    emit(safe_kill(command.get("pid"), command.get("sig"), parent_pids=parent_pids))
                else:
                    emit({"type": "error", "error": "unsupported command"})
            except (json.JSONDecodeError, ValueError) as error:
                emit({"type": "error", "error": str(error)})
        stopped.set()

    threading.Thread(target=read_commands, name="sysmon-stdin", daemon=True).start()
    sampler = Sampler()
    while not stopped.is_set():
        with state_lock:
            interval, sort_key = state["interval"], state["sort"]
        if stopped.wait(interval):
            break
        try:
            emit(sampler.sample(sort_key))
        except Exception as error:
            emit({"type": "error", "error": f"sample failed: {error}"})


if __name__ == "__main__":
    main()
