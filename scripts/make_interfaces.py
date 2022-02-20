import re
import yaml
import json
import requests
from pathlib import Path

import jsbeautifier


ERC4626_URL = "https://raw.githubusercontent.com/ethereum/EIPs/master/EIPS/eip-4626.md"


def make_solidity_interface(spec):
    interfaces = []
    for abi in spec:
        if abi["type"] == "function":
            inputs = ", ".join(f"{i['type']} {i['name']}" for i in abi["inputs"])
            interface = f"function {abi['name']}({inputs}) external"
            if abi["stateMutability"] != "nonpayable":
                interface += " " + abi["stateMutability"]
            if "outputs" in abi:
                outputs = ", ".join(f"{i['type']} {i['name']}" for i in abi["outputs"])
                interface += f" returns ({outputs})"
            interfaces.append(interface)

        elif abi["type"] == "event":
            inputs = ", ".join(
                f"{i['type']} indexed {i['name']}"
                if i["indexed"]
                else f"{i['type']} {i['name']}"
                for i in abi["inputs"]
            )
            interface = f"event {abi['name']}({inputs})"
            interfaces.append(interface)

        else:
            raise Exception(f"Can't handle '{abi['type']}'")
    return interfaces


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
    interface_text = jsbeautifier.beautify(json.dumps(spec), opts)
    # HACK: "caller" is illegal keyword in Vyper
    interface_text = interface_text.replace("caller", "_caller")
    interface_file.write_text(interface_text)

    # Write Solidity interface
    interface_file = Path("contracts") / "ERC4626.sol"
    print(f"Writing {interface_file}")
    interface_file.write_text(
        """interface IERC4626 {open}
    {interfaces};
{close}""".format(
            open="{",
            interfaces=";\n    ".join(make_solidity_interface(spec)),
            close="}",
        )
    )
