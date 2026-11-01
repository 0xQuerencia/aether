#!/usr/bin/env python3
import json
import subprocess
from typing import Any


def run_cmd(command: list[str]) -> str:
    try:
        return subprocess.check_output(
            command,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return ""


def parse_pactl(output: str) -> Any:
    try:
        return json.loads(output)
    except (json.JSONDecodeError, TypeError):
        return []


def get_valid_string(*values: Any) -> str:
    for value in values:
        if value and str(value).strip().lower() not in ("null", "none", ""):
            return str(value)
    return ""


def get_wpctl_default(node_target: str) -> str:
    output = run_cmd(["wpctl", "inspect", node_target])
    for line in output.splitlines():
        if "node.name" in line:
            parts = line.split("=", 1)
            if len(parts) == 2:
                return parts[1].strip().strip('"')
    return ""


def node_properties(node: dict[str, Any]) -> dict[str, Any]:
    properties = node.get("properties", {})
    return properties if isinstance(properties, dict) else {}


def node_volume(node: dict[str, Any]) -> int:
    channels = node.get("volume", {})
    if not isinstance(channels, dict):
        return 0
    channel = channels.get("front-left") or channels.get("mono")
    if not isinstance(channel, dict):
        return 0
    value = str(channel.get("value_percent", "0%")).strip().rstrip("%")
    try:
        return int(float(value))
    except ValueError:
        return 0


def format_node(
    node: dict[str, Any],
    is_default: bool = False,
    is_app: bool = False,
    sink_names: dict[str, str] | None = None,
) -> dict[str, Any]:
    properties = node_properties(node)
    if is_app:
        process_binary = get_valid_string(properties.get("application.process.binary"))
        display_name = get_valid_string(
            properties.get("application.name"), process_binary, "Unknown App"
        )
        sub_desc = get_valid_string(
            properties.get("media.name"),
            properties.get("window.title"),
            properties.get("media.role"),
            "Audio Stream",
        )
        icon = get_valid_string(
            properties.get("application.icon_name"),
            process_binary,
            str(properties.get("application.name", "")).lower(),
            "audio-x-generic",
        )
    else:
        display_name = get_valid_string(
            properties.get("device.description"), node.get("name"), "Unknown Device"
        )
        sub_desc = get_valid_string(node.get("name"), "Unknown")
        icon = get_valid_string(properties.get("device.icon_name"), "audio-card")

    result = {
        "id": str(node.get("index")),
        "name": sub_desc,
        "description": display_name,
        "volume": node_volume(node),
        "mute": bool(node.get("mute", False)),
        "is_default": bool(is_default),
        "icon": icon,
    }

    if is_app:
        sink_index = node.get("sink")
        sink_names = sink_names or {}
        result.update(
            {
                "media_name": get_valid_string(properties.get("media.name")),
                "sink_index": sink_index,
                "sink_name": sink_names.get(str(sink_index), ""),
                "corked": bool(node.get("corked", False)),
            }
        )
    return result


def get_data() -> None:
    sinks = parse_pactl(run_cmd(["pactl", "-f", "json", "list", "sinks"]))
    sources = parse_pactl(run_cmd(["pactl", "-f", "json", "list", "sources"]))
    sink_inputs = parse_pactl(run_cmd(["pactl", "-f", "json", "list", "sink-inputs"]))
    if not isinstance(sinks, list):
        sinks = []
    if not isinstance(sources, list):
        sources = []
    if not isinstance(sink_inputs, list):
        sink_inputs = []

    sink_names = {
        str(sink.get("index")): sink.get("name", "")
        for sink in sinks
        if isinstance(sink, dict)
    }

    default_sink = get_wpctl_default("@DEFAULT_AUDIO_SINK@")
    default_source = get_wpctl_default("@DEFAULT_AUDIO_SOURCE@")

    if not default_sink or not default_source:
        info = parse_pactl(run_cmd(["pactl", "-f", "json", "info"]))
        if isinstance(info, dict):
            if not default_sink:
                default_sink = info.get("default_sink_name", "")
            if not default_source:
                default_source = info.get("default_source_name", "")

    apps = []
    for stream in sink_inputs:
        if not isinstance(stream, dict):
            continue
        properties = node_properties(stream)
        if properties.get("application.id") != "org.PulseAudio.pavucontrol":
            apps.append(format_node(stream, is_app=True, sink_names=sink_names))

    real_inputs = []
    for source in sources:
        if not isinstance(source, dict):
            continue
        properties = node_properties(source)
        if properties.get("device.class") == "monitor" or str(
            source.get("name", "")
        ).endswith(".monitor"):
            continue
        real_inputs.append(
            format_node(source, source.get("name") == default_source)
        )

    output = {
        "outputs": [
            format_node(sink, sink.get("name") == default_sink)
            for sink in sinks
            if isinstance(sink, dict)
        ],
        "inputs": real_inputs,
        
        "apps": sorted(apps, key=lambda app: app.get("corked", False)),
    }
    print(json.dumps(output))


if __name__ == "__main__":
    get_data()
