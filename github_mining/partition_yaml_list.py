import pathlib
import yaml
import sys
import urllib.parse

input_path = pathlib.Path(sys.argv[1])

assert input_path.exists()

outputs = [pathlib.Path(arg) for arg in sys.argv[2:]]

inputs = yaml.safe_load(input_path.read_text())

assert isinstance(inputs, list)

for output_i, output in enumerate(outputs):
    start = int(len(inputs) * output_i / len(outputs))
    stop = int(len(inputs) * (output_i + 1) / len(outputs))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(yaml.dump(inputs[start:stop]))
