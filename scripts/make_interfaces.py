import re
import yaml
import json
import requests
from pathlib import Path

import jsbeautifier


ERC4626_URL = "https://raw.githubusercontent.com/ethereum/EIPs/master/EIPS/eip-4626.md"


def main():
    yaml_string = requests.get(ERC4626_URL).content.decode("utf-8")
    yaml_sections = [
        s.split("```")[0]
        for s in yaml_string.split("```yaml")
        if "```" in s  # Skip first section
    ]
    spec = yaml.safe_load("".join(yaml_sections))
    interface_file = Path("contracts") / "ERC4626.json"
    print(f"Writing {interface_file}")

    opts = jsbeautifier.default_options()
    opts.indent_size = 2
    interface_file.write_text(jsbeautifier.beautify(json.dumps(spec), opts))
