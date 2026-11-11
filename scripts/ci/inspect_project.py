#!/usr/bin/env python3
"""Build a machine-readable inventory of a Godot project for visual QA artifacts."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
OUT = Path(sys.argv[2] if len(sys.argv) > 2 else "artifacts/editor-inspection").resolve()
OUT.mkdir(parents=True, exist_ok=True)

def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()

def parse_scene(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    ext = {}
    for match in re.finditer(r'^\[ext_resource\s+([^\]]+)\]', text, re.M):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', match.group(1)))
        if "id" in attrs:
            ext[attrs["id"]] = attrs
    nodes = []
    for match in re.finditer(r'^\[node\s+([^\]]+)\]', text, re.M):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', match.group(1)))
        if not attrs.get("name"):
            continue
        has_parent = "parent" in attrs
        path_value = attrs.get("parent", ".")
        # The scene root has no parent attribute and is addressed as ".".
        # A direct child explicitly declares parent="." and must be addressed
        # by its own name, not mistaken for the scene root.
        if not has_parent:
            node_path = "."
            depth = 0
        elif path_value == ".":
            node_path = attrs["name"]
            depth = 1
        else:
            node_path = path_value + "/" + attrs["name"]
            depth = path_value.count("/") + 2
        nodes.append({
            "name": attrs["name"],
            "type": attrs.get("type", ""),
            "parent": path_value,
            "node_path": node_path,
            "depth": depth,
            "instance": attrs.get("instance", ""),
            "groups": [],
            "script": "",
        })
    # Preserve node properties and script resource references from each node block.
    starts = list(re.finditer(r'^\[node\s+([^\]]+)\]', text, re.M))
    for i, match in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(text)
        block = text[match.start():end]
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', match.group(1)))
        if not attrs.get("name"):
            continue
        item = next((n for n in nodes if n["name"] == attrs["name"] and n["parent"] == attrs.get("parent", ".")), None)
        if item is None:
            continue
        script_match = re.search(r'^script\s*=\s*ExtResource\("([^"]+)"\)', block, re.M)
        if script_match:
            item["script"] = ext.get(script_match.group(1), {}).get("path", "")
        group_match = re.search(r'^groups\s*=\s*\[([^\]]*)\]', block, re.M)
        if group_match:
            item["groups"] = re.findall(r'"([^"]+)"', group_match.group(1))
    return {
        "path": rel(path),
        "load_steps": int(re.search(r'load_steps=(\d+)', text).group(1)) if re.search(r'load_steps=(\d+)', text) else None,
        "external_resources": list(ext.values()),
        "nodes": nodes,
        "connections": re.findall(r'^\[connection\s+([^\]]+)\]', text, re.M),
        "node_count": len(nodes),
    }

def read_project_settings(path: Path) -> dict:
    result = {}
    section = ""
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            result.setdefault(section, {})
        elif "=" in line and section:
            key, value = line.split("=", 1)
            result[section][key.strip()] = value.strip()
    return result

scenes = sorted(ROOT.rglob("*.tscn"))
scripts = sorted(ROOT.rglob("*.gd"))
excluded = {".git", ".godot", "artifacts"}
scenes = [p for p in scenes if not any(part in excluded for part in p.parts)]
scripts = [p for p in scripts if not any(part in excluded for part in p.parts)]
scene_data = [parse_scene(p) for p in scenes]
project_file = ROOT / "project.godot"
settings = read_project_settings(project_file) if project_file.exists() else {}

inventory = {
    "project_root": str(ROOT),
    "scene_count": len(scene_data),
    "script_count": len(scripts),
    "scenes": scene_data,
    "scripts": [{"path": rel(p), "bytes": p.stat().st_size, "lines": len(p.read_text(encoding="utf-8", errors="replace").splitlines())} for p in scripts],
    "project_settings": settings,
}
(OUT / "project-inspection.json").write_text(json.dumps(inventory, indent=2, ensure_ascii=False), encoding="utf-8")
with (OUT / "scene-tree-index.txt").open("w", encoding="utf-8") as f:
    for scene in scene_data:
        f.write(f'\n## {scene["path"]} ({scene["node_count"]} nodes)\n')
        by_path = {n["node_path"]: n for n in scene["nodes"]}
        for node in scene["nodes"]:
            depth = node.get("depth", 0)
            extra = f' [{node["type"]}]' if node["type"] else ""
            script = f' — script: {node["script"]}' if node["script"] else ""
            f.write(f'{"  " * depth}- {node["name"]}{extra}{script}\n')
with (OUT / "scripts-index.txt").open("w", encoding="utf-8") as f:
    for p in scripts:
        f.write(f'{rel(p)}\t{p.stat().st_size} bytes\t{len(p.read_text(encoding="utf-8", errors="replace").splitlines())} lines\n')
with (OUT / "project-settings.txt").open("w", encoding="utf-8") as f:
    for section, values in settings.items():
        f.write(f'[{section}]\n')
        for key, value in values.items():
            f.write(f'{key} = {value}\n')
        f.write("\n")
# Include the complete project code as inspectable source files in the artifact.
code_root = OUT / "source-code"
for p in scripts:
    dest = code_root / rel(p)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(p.read_bytes())
print(f"[INSPECT] {len(scene_data)} scenes, {len(scripts)} GDScript files, {sum(s['node_count'] for s in scene_data)} scene nodes")
print(f"[INSPECT] Wrote project inventory, scene tree, settings and source code to {OUT}")
