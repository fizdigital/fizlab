#!/usr/bin/env python3
"""Diagnóstico somente leitura da superfície de acesso do FizLab."""

from __future__ import annotations

import ipaddress
import json
import os
import shutil
import socket
from pathlib import Path
from typing import Any


def _decode_address(raw: str, family: int) -> str:
    address, _port = raw.split(":", 1)
    packed = bytes.fromhex(address)
    if family == socket.AF_INET:
        return socket.inet_ntop(family, packed[::-1])
    chunks = b"".join(packed[index:index + 4][::-1] for index in range(0, 16, 4))
    return socket.inet_ntop(family, chunks)


def listeners() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for name, family in (("tcp", socket.AF_INET), ("tcp6", socket.AF_INET6)):
        try:
            lines = Path(f"/proc/net/{name}").read_text(encoding="utf-8").splitlines()[1:]
        except OSError:
            continue
        for line in lines:
            fields = line.split()
            if len(fields) < 4 or fields[3] != "0A":
                continue
            host, port_hex = fields[1].split(":", 1)
            try:
                address = _decode_address(f"{host}:{port_hex}", family)
                port = int(port_hex, 16)
            except (OSError, ValueError):
                continue
            items.append({"protocol": "tcp6" if family == socket.AF_INET6 else "tcp", "address": address, "port": port})
    return sorted(items, key=lambda item: (item["port"], item["protocol"], item["address"]))


def exposure(address: str) -> str:
    ip = ipaddress.ip_address(address)
    if ip.is_loopback:
        return "local"
    if ip.is_unspecified:
        return "network"
    if isinstance(ip, ipaddress.IPv4Address) and ip in ipaddress.ip_network("100.64.0.0/10"):
        return "tailnet"
    if isinstance(ip, ipaddress.IPv6Address) and ip in ipaddress.ip_network("fd7a:115c:a1e0::/48"):
        return "tailnet"
    return "network"


def audit() -> dict[str, Any]:
    known = {8022: "ssh", 8080: "dashboard", 8765: "api"}
    entries = []
    warnings = []
    for listener in listeners():
        item = {**listener, "exposure": exposure(listener["address"]), "service": known.get(listener["port"], "unknown")}
        entries.append(item)
        if item["service"] == "api" and item["exposure"] != "local":
            warnings.append("A API está exposta fora do localhost.")
        if item["service"] == "dashboard" and item["exposure"] == "network":
            warnings.append("O dashboard aceita conexões de rede; habilite o modo tailnet após a homologação.")
        if item["service"] == "unknown" and item["exposure"] == "network":
            warnings.append(f"Porta desconhecida exposta na rede: {item['address']}:{item['port']}.")
    visibility = "complete" if entries else "limited"
    if not entries:
        warnings.append(
            "Não foi possível enumerar portas em escuta; no Android/Termux sem root "
            "o acesso a /proc pode ser limitado. Confirme SSH, dashboard e API pelos testes de homologação."
        )
    return {"listeners": entries, "warnings": sorted(set(warnings)), "visibility": visibility}


def status() -> dict[str, Any]:
    home = Path(os.environ.get("SERVER_HOME", str(Path.home() / "server")))
    hardening_file = home / "config" / "sshd_config"
    return {
        "dashboard_access": os.environ.get("FIZLAB_DASHBOARD_ACCESS", "lan"),
        "ssh_hardening": os.environ.get("FIZLAB_SSH_HARDENING", "disabled"),
        "ssh_access": os.environ.get("FIZLAB_SSH_ACCESS", "tailnet"),
        "tailscale_cli_available": shutil.which("tailscale") is not None,
        "ssh_config_managed": hardening_file.is_file(),
        "audit": audit(),
    }


def main() -> None:
    print(json.dumps(status(), ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
