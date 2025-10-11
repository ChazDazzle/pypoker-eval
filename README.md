What is pypoker-eval ?  

This package is python adaptor for the poker-eval toolkit for writing
programs which simulate or analyze poker games as found at
<http://gna.org/projects/pokersource/>. The python interface is
somewhat simpler than the C API of poker-eval. It assumes that the
caller is willing to have a higher level API and is not interested in
a one to one mapping of the poker-eval API.

For more information about the functions provided, check the
documentation of the PokerEval class in the pokereval.py file.

Loic Dachary <loic@dachary.org>

## Building Locally

This project includes an enhanced build script that supports multiple Python versions and virtual environments.

### Requirements

- **uv** (recommended): Fast Python package manager - [Installation guide](https://astral.sh/uv/install.sh)
- **CMake**: For building the C library
- **Git**: For submodule management
- **Python**: Target version for building

### Quick Start

```bash
# Build with default Python version (3.11.10)
./build.sh

# Build with specific Python version
./build.sh 3.11.4
./build.sh 3.12.0
```

### Advanced Usage

#### Using Virtual Environments

```bash
# Build with uv virtual environment (recommended)
./build.sh 3.11.4 --use-venv
./build.sh 3.12.0 --use-venv

# This will:
# - Install Python 3.11.4 via uv if not available
# - Create a .venv virtual environment
# - Build the extension for the specific Python version
# - Create a Python wheel package
```

#### Command Options

```bash
Usage: ./build.sh [python_version] [--use-venv]

Examples:
  ./build.sh                    # Uses Python 3.11.10 by default
  ./build.sh 3.11.4            # Uses Python 3.11.4
  ./build.sh 3.12.0 --use-venv # Uses Python 3.12.0 in a uv virtual environment
  ./build.sh --use-venv        # Uses default Python 3.11.10 in a uv virtual environment

Options:
  --use-venv           Create and use a uv virtual environment
  -h, --help           Show help message

Output:
  - Shared library: _pokereval_X_Y_Z.so (where X_Y_Z is Python version)
  - Python wheel: dist/pokereval-*.whl

Note: If Python version is not found locally, uv will attempt to install it
```

### Installation

After building, you can install the package:

```bash
# If using virtual environment
source .venv/bin/activate
pip install dist/pokereval-*.whl

# Or install directly
pip install dist/pokereval-*.whl
```

### Version-Specific Builds

The build system creates version-specific extensions to avoid compatibility issues:

- Python 3.11.4 → `_pokereval_3_11_4.so`
- Python 3.11.10 → `_pokereval_3_11_10.so`
- Python 3.12.0 → `_pokereval_3_12_0.so`

This ensures each Python patch version has its own compatible binary.

## WIP 2022-2025 jejellyroll

update from Tzerjen Wei github <https://github.com/tjwei>
