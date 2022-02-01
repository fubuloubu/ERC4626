import re
import yaml
import json
from pathlib import Path

import jsbeautifier


README_FILE = Path(__file__).parent.parent / "README.md"

YAML_CONTENT_PATTERN = r"```yaml([.\n]*)```"


def main():
    yaml_sections = [
        s.split("```")[0]
        for s in README_FILE.read_text().split("```yaml")
        if "```" in s  # Skip first section
    ]
    spec = yaml.safe_load("".join(yaml_sections))
    interface_file = Path("contracts") / "ERC4626.json"
    print(f"Writing {interface_file}")

    opts = jsbeautifier.default_options()
    opts.indent_size = 2
    interface_file.write_text(jsbeautifier.beautify(json.dumps(spec), opts))
