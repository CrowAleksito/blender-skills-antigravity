#!/usr/bin/env python3
"""
blender_bridge.py — Diagnostic & Tier-2 Fallback TCP Client for Blender MCP.

Communicates directly with the 'MCP for Blender' addon socket server (default localhost:9876).
Prefer native Antigravity MCP tools (`call_mcp_tool` on ServerName="blender") whenever available;
use this script to diagnose socket health or execute commands if the MCP stdio host has not reloaded.
"""

import argparse
import json
import os
import socket
import sys
from typing import Any, Dict


def send_blender_command(
    cmd_type: str,
    params: Dict[str, Any] | None = None,
    host: str = "localhost",
    port: int = 9876,
    timeout: float = 30.0,
) -> Dict[str, Any]:
    """Send a JSON command to the Blender MCP addon TCP socket and return the parsed JSON response."""
    payload = {"type": cmd_type}
    if params:
        payload["params"] = params

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
        sock.sendall(json.dumps(payload).encode("utf-8"))

        chunks: list[bytes] = []
        while True:
            chunk = sock.recv(16384)
            if not chunk:
                break
            chunks.append(chunk)
            try:
                return json.loads(b"".join(chunks).decode("utf-8"))
            except (json.JSONDecodeError, UnicodeDecodeError):
                continue

        if not chunks:
            return {"status": "error", "message": "Empty response from Blender socket."}
        return json.loads(b"".join(chunks).decode("utf-8"))
    finally:
        try:
            sock.close()
        except Exception:
            pass


def main() -> int:
    parser = argparse.ArgumentParser(description="Blender MCP TCP Diagnostic & Fallback Bridge")
    parser.add_argument("--host", default=os.environ.get("BLENDER_HOST", "localhost"), help="Socket host (default: localhost)")
    parser.add_argument("--port", type=int, default=int(os.environ.get("BLENDER_PORT", "9876")), help="Socket port (default: 9876)")
    parser.add_argument("--timeout", type=float, default=30.0, help="Socket timeout in seconds")

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--ping", action="store_true", help="Check if Blender MCP socket responds with pong")
    group.add_argument("--scene-info", action="store_true", help="Fetch basic scene object summary")
    group.add_argument("--addon-info", action="store_true", help="Fetch Blender & addon version metadata")
    group.add_argument("--exec", dest="code", help="Execute inline Python code in Blender")
    group.add_argument("--script", help="Execute a Python file in Blender")
    group.add_argument("--screenshot", help="Capture viewport screenshot to the specified output file path")

    parser.add_argument("--max-size", type=int, default=800, help="Max screenshot dimension in pixels (default: 800)")
    args = parser.parse_args()

    try:
        if args.ping:
            res = send_blender_command("ping", host=args.host, port=args.port, timeout=5.0)
        elif args.scene_info:
            res = send_blender_command("get_scene_info", host=args.host, port=args.port, timeout=args.timeout)
        elif args.addon_info:
            res = send_blender_command("get_addon_info", host=args.host, port=args.port, timeout=args.timeout)
        elif args.code:
            res = send_blender_command("execute_code", {"code": args.code}, host=args.host, port=args.port, timeout=args.timeout)
        elif args.script:
            with open(args.script, "r", encoding="utf-8") as f:
                script_code = f.read()
            res = send_blender_command("execute_code", {"code": script_code}, host=args.host, port=args.port, timeout=args.timeout)
        elif args.screenshot:
            abs_out = os.path.abspath(args.screenshot)
            os.makedirs(os.path.dirname(abs_out), exist_ok=True)
            ext = os.path.splitext(abs_out)[1].lstrip(".").lower() or "png"
            res = send_blender_command(
                "get_viewport_screenshot",
                {"filepath": abs_out, "max_size": args.max_size, "format": ext},
                host=args.host,
                port=args.port,
                timeout=args.timeout,
            )
        else:
            return 2
    except (ConnectionRefusedError, TimeoutError, socket.timeout, OSError) as exc:
        print(json.dumps({"status": "disconnected", "host": args.host, "port": args.port, "error": str(exc)}, indent=2))
        return 1

    print(json.dumps(res, indent=2, ensure_ascii=False))
    return 0 if res.get("status") == "success" else 2


if __name__ == "__main__":
    sys.exit(main())
