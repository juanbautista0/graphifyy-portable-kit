from __future__ import annotations

import json
import os
import signal
import sys
from pathlib import Path

from graphify.analyze import god_nodes, suggest_questions, surprising_connections
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.detect import save_manifest
from graphify.export import to_json
from graphify.extract import extract
from graphify.report import generate

CODE_EXTENSIONS = {
    ".c",
    ".cc",
    ".cpp",
    ".cs",
    ".cxx",
    ".f",
    ".f03",
    ".f08",
    ".f90",
    ".f95",
    ".go",
    ".gradle",
    ".groovy",
    ".h",
    ".hpp",
    ".java",
    ".js",
    ".json",
    ".jsx",
    ".kt",
    ".kts",
    ".lua",
    ".php",
    ".py",
    ".rb",
    ".rs",
    ".scala",
    ".swift",
    ".ts",
    ".tsx",
}

EXCLUDED_DIRS = {
    ".agents",
    ".git",
    ".gradle",
    ".idea",
    ".sonar",
    ".sonarlint",
    ".vscode",
    "bin",
    "build",
    "coverage",
    "generated",
    "generated-sources",
    "graphify-out",
    "node_modules",
    "out",
    "reports",
    "target",
    "test-results",
    "vendor",
}


class ExtractionTimeoutError(RuntimeError):
    pass


def timeout_handler(_signum: int, _frame: object) -> None:
    raise ExtractionTimeoutError("Graphifyy AST extraction timed out")


def collect_code_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for current_root, dir_names, file_names in os.walk(root):
        dir_names[:] = [
            dir_name
            for dir_name in dir_names
            if dir_name not in EXCLUDED_DIRS
        ]
        current_path = Path(current_root)
        for file_name in file_names:
            path = current_path / file_name
            if path.suffix.lower() in CODE_EXTENSIONS:
                files.append(path)
    return sorted(files)


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    out_dir = root / "graphify-out"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"Collecting code files under {root}", flush=True)
    code_files = collect_code_files(root)
    relative_code_files = [str(path.relative_to(root)) for path in code_files]
    detection = {
        "files": {"code": relative_code_files},
        "total_files": len(relative_code_files),
        "total_words": 0,
        "skipped_sensitive": [],
        "needs_graph": True,
    }

    if not code_files:
        print("ERROR: Graphifyy detected no code files to extract.", file=sys.stderr)
        return 1

    print(f"Extracting AST from {len(code_files)} code files", flush=True)
    ast = {"nodes": [], "edges": [], "hyperedges": [], "input_tokens": 0, "output_tokens": 0}
    skipped: list[str] = []
    signal.signal(signal.SIGALRM, timeout_handler)

    for index, file_path in enumerate(code_files, start=1):
        relative_path = str(file_path.relative_to(root))
        print(f"  {index}/{len(code_files)} {relative_path}", flush=True)
        try:
            signal.alarm(20)
            partial = extract([file_path], root=root, parallel=False)
        except ExtractionTimeoutError:
            skipped.append(relative_path)
            print(f"  skipped after timeout: {relative_path}", flush=True)
            continue
        finally:
            signal.alarm(0)
        ast["nodes"].extend(partial.get("nodes", []))
        ast["edges"].extend(partial.get("edges", []))
        ast["hyperedges"].extend(partial.get("hyperedges", []))

    extraction = {
        "nodes": ast.get("nodes", []),
        "edges": ast.get("edges", []),
        "hyperedges": ast.get("hyperedges", []),
        "input_tokens": 0,
        "output_tokens": 0,
    }

    print(
        f"Building graph from {len(extraction['nodes'])} nodes and {len(extraction['edges'])} edges",
        flush=True,
    )
    graph = build_from_json(extraction, root=root, directed=False)
    if graph.number_of_nodes() == 0:
        print("ERROR: Graphifyy extraction produced an empty graph.", file=sys.stderr)
        return 1

    print("Clustering graph", flush=True)
    communities = cluster(graph)
    cohesion = score_all(graph, communities)
    labels = {community_id: f"Community {community_id}" for community_id in communities}
    gods = god_nodes(graph)
    surprises = surprising_connections(graph, communities)
    questions = suggest_questions(graph, communities, labels)

    graph_path = out_dir / "graph.json"
    print(f"Writing {graph_path}", flush=True)
    if not to_json(graph, communities, str(graph_path), force=True, community_labels=labels):
        print("ERROR: Graphifyy refused to write graph.json.", file=sys.stderr)
        return 1

    print("Writing report and manifest", flush=True)
    report = generate(
        graph,
        communities,
        cohesion,
        labels,
        gods,
        surprises,
        detection,
        {"input": 0, "output": 0},
        str(root),
        suggested_questions=questions,
    )
    (out_dir / "GRAPH_REPORT.md").write_text(report, encoding="utf-8")
    save_manifest(detection.get("files", {}), str(out_dir / "manifest.json"), root=root)

    summary = {
        "graphifyy_version": "0.9.22",
        "mode": "code-only-local",
        "nodes": graph.number_of_nodes(),
        "edges": graph.number_of_edges(),
        "communities": len(communities),
        "skipped_files": skipped,
    }
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

