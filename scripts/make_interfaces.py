import yaml
import json
from pathlib import Path

import jsbeautifier


SPEC_FILE = Path(__file__).parent.parent / "spec.yaml"


def main():
    opts = jsbeautifier.default_options()
    opts.indent_size = 2

    spec = yaml.safe_load(SPEC_FILE.read_text())
    for interface_name in spec:
        if interface_name == "implements":
            continue

        interface_file = Path("contracts") / f"{interface_name}.json"
        print(f"Writing {interface_file}")
        interface_file.write_text(
            jsbeautifier.beautify(json.dumps(spec[interface_name]), opts)
        )
