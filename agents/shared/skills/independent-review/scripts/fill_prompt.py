#!/usr/bin/env python3
"""Fill a reviewer prompt template from references/reviewer-prompt.md.

Usage: fill_prompt.py <initial|verification> <out-file> key=value key=@file ...

A value that starts with @ is read from that file, so multi-line values such as
the ledger need no shell quoting. The script refuses to write a prompt that
still contains a {{placeholder}}, and refuses keys the template does not use.
"""
import re
import sys
from pathlib import Path

HEADINGS = {
    "initial": "## Initial review prompt",
    "verification": "## Verification prompt",
}
PLACEHOLDER = re.compile(r"\{\{([a-z_]+)\}\}")


def template(kind: str) -> str:
    source = Path(__file__).resolve().parent.parent / "references" / "reviewer-prompt.md"
    text = source.read_text()
    after_heading = text.split(HEADINGS[kind] + "\n", 1)[1]
    return after_heading.split("```text\n", 1)[1].split("\n```", 1)[0] + "\n"


def main(argv: list[str]) -> int:
    if len(argv) < 3 or argv[1] not in HEADINGS:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    kind, out_file = argv[1], Path(argv[2])
    values = {}
    for arg in argv[3:]:
        key, sep, value = arg.partition("=")
        if not sep:
            print(f"not key=value: {arg}", file=sys.stderr)
            return 2
        values[key] = Path(value[1:]).read_text().rstrip("\n") if value.startswith("@") else value

    text = template(kind)
    wanted = set(PLACEHOLDER.findall(text))
    unknown = sorted(set(values) - wanted)
    missing = sorted(wanted - set(values))
    if unknown or missing:
        if unknown:
            print(f"keys the {kind} template does not use: {', '.join(unknown)}", file=sys.stderr)
        if missing:
            print(f"missing keys: {', '.join(missing)}", file=sys.stderr)
        return 1

    # One pass over the template, so a value that contains {{...}} is never expanded again.
    out_file.write_text(PLACEHOLDER.sub(lambda m: values[m.group(1)], text))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
