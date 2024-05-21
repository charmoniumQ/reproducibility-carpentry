import pathlib
import yaml
import sys
import urllib.parse

input_path = pathlib.Path(sys.argv[1])

assert input_path.exists()

output_dir = pathlib.Path(sys.argv[2])

inputs = yaml.safe_load(input_path.read_text())

assert isinstance(inputs, list)

for elem in inputs:
    name = elem.get("name", None)
    assert isinstance(name, str), name
    assert name

assert len(set(elem["name"] for elem in inputs)) == len([elem["name"] for elem in inputs])

output_dir.mkdir(exist_ok=True, parents=True)

for elem in inputs:
    (output_dir / (urllib.parse.quote_plus(elem["name"]) + ".yaml")).write_text(yaml.dump(elem))
