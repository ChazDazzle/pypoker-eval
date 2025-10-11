#!/bin/bash

# Stop script if any command fails
set -e

# Parse arguments
USE_VENV=false
PYTHON_VERSION=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --use-venv)
            USE_VENV=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$PYTHON_VERSION" ]; then
                PYTHON_VERSION="$1"
            else
                echo "Error: Unknown argument '$1'"
                usage
            fi
            shift
            ;;
    esac
done

# Set default Python version if not specified
DEFAULT_PYTHON_VERSION="3.11.10"
PYTHON_VERSION="${PYTHON_VERSION:-$DEFAULT_PYTHON_VERSION}"

# Help function
usage() {
    echo "Usage: $0 [python_version] [--use-venv]"
    echo "Examples:"
    echo "  $0                    # Uses Python 3.11.10 by default"
    echo "  $0 3.11.4            # Uses Python 3.11.4"
    echo "  $0 3.12.0 --use-venv # Uses Python 3.12.0 in a uv virtual environment"
    echo "  $0 --use-venv        # Uses default Python 3.11.10 in a uv virtual environment"
    echo ""
    echo "Options:"
    echo "  --use-venv           Create and use a uv virtual environment"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Output:"
    echo "  - Shared library: _pokereval_X_Y.so (where X_Y is Python version)"
    echo "  - Python wheel: dist/pokereval-*.whl"
    echo ""
    echo "Note: If Python version is not found locally, uv will attempt to install it"
    exit 1
}

echo "Using Python version: $PYTHON_VERSION"
if [ "$USE_VENV" = true ]; then
    echo "Using uv virtual environment: enabled"
fi

# Function to setup uv environment
setup_uv_environment() {
    local version=$1

    echo "Setting up uv environment for Python $version..."

    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        echo "Error: uv is not installed. Please install it first:"
        echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi

    # Install Python version if not available
    echo "Ensuring Python $version is available..."
    uv python install "$version" || {
        echo "Error: Failed to install Python $version with uv"
        exit 1
    }

    # Create or update virtual environment
    local venv_name="pypoker-eval-${version}"
    echo "Creating/updating virtual environment: $venv_name"

    if [ -d ".venv" ]; then
        echo "Removing existing .venv directory..."
        rm -rf .venv
    fi

    uv venv --python "$version" .venv || {
        echo "Error: Failed to create virtual environment"
        exit 1
    }

    # Activate virtual environment (handle Windows vs Unix paths)
    if [[ "$OS" == "Windows" ]]; then
        source .venv/Scripts/activate
        PYTHON_EXEC="$(pwd)/.venv/Scripts/python.exe"
    else
        source .venv/bin/activate
        PYTHON_EXEC="$(pwd)/.venv/bin/python"
    fi

    # Get Python paths from the virtual environment
    PYTHON_INCLUDE=$($PYTHON_EXEC -c "from sysconfig import get_paths as gp; print(gp()['include'])")
    if [[ "$OS" == "Windows" ]]; then
        # For Windows, use a more robust approach to find the library
        PYTHON_LIBRARY=$($PYTHON_EXEC -c "
import sys
import os
import sysconfig

# Get the base prefix (installation directory)
base_prefix = sys.base_prefix
version = sysconfig.get_python_version().replace('.', '')

# Try different possible locations for the library
possible_paths = [
    os.path.join(base_prefix, 'libs', f'python{version}.lib'),
    os.path.join(base_prefix, 'lib', f'python{version}.lib'),
    os.path.join(base_prefix, f'python{version}.lib')
]

for path in possible_paths:
    if os.path.exists(path):
        print(path)
        break
else:
    # Fallback: construct standard path
    print(os.path.join(base_prefix, 'libs', f'python{version}.lib'))
")
    else
        # For macOS/Linux, use a more robust approach to find the library
        PYTHON_LIBRARY=$($PYTHON_EXEC -c "
import sys
import os
import sysconfig

# Get the base prefix (installation directory)
base_prefix = sys.base_prefix
version = sysconfig.get_python_version()

# First try sysconfig approach (works for most standard installations)
libdir = sysconfig.get_config_var('LIBDIR')
if libdir and libdir != '/install/lib':  # Skip broken uv path
    ext = '.dylib' if sys.platform == 'darwin' else '.so'
    sysconfig_path = os.path.join(libdir, f'libpython{version}{ext}')
    if os.path.exists(sysconfig_path):
        print(sysconfig_path)
        exit()

# If sysconfig failed, try different possible locations
possible_paths = [
    os.path.join(base_prefix, 'lib', f'libpython{version}.dylib'),
    os.path.join(base_prefix, 'lib', f'libpython{version}.so'),
    os.path.join(base_prefix, 'lib', f'libpython{version}.a'),
    os.path.join('/usr/lib', f'libpython{version}.dylib'),
    os.path.join('/usr/lib', f'libpython{version}.so'),
    os.path.join('/usr/local/lib', f'libpython{version}.dylib'),
    os.path.join('/usr/local/lib', f'libpython{version}.so')
]

# Add system-specific paths
if sys.platform == 'darwin':
    # macOS: try framework locations
    possible_paths.extend([
        f'/usr/local/opt/python@{version}/Frameworks/Python.framework/Versions/{version}/lib/libpython{version}.dylib',
        f'/System/Library/Frameworks/Python.framework/Versions/{version}/lib/libpython{version}.dylib'
    ])
elif sys.platform.startswith('linux'):
    # Linux: try distribution-specific paths
    possible_paths.extend([
        f'/usr/lib/x86_64-linux-gnu/libpython{version}.so',
        f'/usr/lib/aarch64-linux-gnu/libpython{version}.so'
    ])

for path in possible_paths:
    if os.path.exists(path):
        print(path)
        break
else:
    # Very last resort: construct a reasonable guess
    ext = '.dylib' if sys.platform == 'darwin' else '.so'
    print(os.path.join(base_prefix, 'lib', f'libpython{version}{ext}'))
")
    fi

    echo "Virtual environment Python: $PYTHON_EXEC"
    echo "Include directory: $PYTHON_INCLUDE"
    echo "Library path: $PYTHON_LIBRARY"

    # Debug: check if paths exist
    echo "Debug - Python executable exists: $([ -f "$PYTHON_EXEC" ] && echo 'YES' || echo 'NO')"
    echo "Debug - Include directory exists: $([ -d "$PYTHON_INCLUDE" ] && echo 'YES' || echo 'NO')"
    echo "Debug - Library exists: $([ -f "$PYTHON_LIBRARY" ] && echo 'YES' || echo 'NO')"
}

# Function to find Python executable and paths
find_python_paths() {
    local version=$1
    local major_minor=$(echo $version | cut -d. -f1,2)

    # Try to find Python executable
    PYTHON_EXEC=""
    PYTHON_INCLUDE=""
    PYTHON_LIBRARY=""

    # Check uv managed Python first
    if [ -f "$HOME/.local/share/uv/python/cpython-${version}-macos-x86_64-none/bin/python" ]; then
        PYTHON_EXEC="$HOME/.local/share/uv/python/cpython-${version}-macos-x86_64-none/bin/python"
        PYTHON_INCLUDE="$HOME/.local/share/uv/python/cpython-${version}-macos-x86_64-none/include/python${major_minor}"
        PYTHON_LIBRARY="$HOME/.local/share/uv/python/cpython-${version}-macos-x86_64-none/lib/libpython${major_minor}.dylib"
    # Check Homebrew
    elif [ -f "/usr/local/opt/python@${major_minor}/libexec/bin/python3" ]; then
        PYTHON_EXEC="/usr/local/opt/python@${major_minor}/libexec/bin/python3"
        PYTHON_INCLUDE="/usr/local/opt/python@${major_minor}/Frameworks/Python.framework/Versions/${major_minor}/include/python${major_minor}"
        PYTHON_LIBRARY="/usr/local/opt/python@${major_minor}/Frameworks/Python.framework/Versions/${major_minor}/lib/libpython${major_minor}.dylib"
    # Check system Python
    elif command -v python${major_minor} &> /dev/null; then
        PYTHON_EXEC=$(which python${major_minor})
        PYTHON_INCLUDE=$(python${major_minor} -c "from sysconfig import get_paths as gp; print(gp()['include'])")
        PYTHON_LIBRARY=$(python${major_minor} -c "from sysconfig import get_config_var as gcv; import os; print(os.path.join(gcv('LIBDIR'), f'libpython${major_minor}.dylib'))")
    else
        echo "Error: Python ${version} not found"
        echo "Available options:"
        echo "- Install via uv: uv python install ${version}"
        echo "- Install via Homebrew: brew install python@${major_minor}"
        exit 1
    fi

    # Verify paths exist
    if [ ! -f "$PYTHON_EXEC" ]; then
        echo "Error: Python executable not found at $PYTHON_EXEC"
        exit 1
    fi

    # Get actual version to confirm
    ACTUAL_VERSION=$($PYTHON_EXEC --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    echo "Found Python executable: $PYTHON_EXEC (version $ACTUAL_VERSION)"
    echo "Include directory: $PYTHON_INCLUDE"
    echo "Library path: $PYTHON_LIBRARY"
}

# Fonction pour détecter l'OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "MacOS";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "Windows";;
        *)          echo "unknown"
    esac
}

OS=$(detect_os)
echo "Detected OS: $OS"

# Setup Python environment
if [ "$USE_VENV" = true ]; then
    setup_uv_environment "$PYTHON_VERSION"
else
    find_python_paths "$PYTHON_VERSION"
fi

WORK_DIR=$(pwd)
echo "Working directory: $WORK_DIR"

BASE_PATH="$WORK_DIR"
echo "Base path: $BASE_PATH"

# path to base for Windows
if [ "$OS" = "Windows" ]; then
    BASE_PATH2=$(cygpath -w "$BASE_PATH")
else
    BASE_PATH2="$BASE_PATH"
fi

echo "Adjusted BASE_PATH2 for OS: $BASE_PATH2"

# Initialize submodules
echo "Initializing submodules..."
if [ -d "${BASE_PATH}/poker-eval" ]; then
    echo "Removing existing poker-eval directory"
    rm -rf "${BASE_PATH}/poker-eval"
fi
git submodule update --init --recursive



# Build poker-eval
echo "Building poker-eval..."
cd "${BASE_PATH}/poker-eval"
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: CMakeLists.txt not found in $(pwd)"
    exit 1
fi
mkdir -p build
cd build
if [[ "$OS" == "Windows" ]]; then
    cmake .. -G "Visual Studio 17 2022"
    cmake --build .
elif [[ "$OS" == "Linux" || "$OS" == "MacOS" ]]; then
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    make
fi
cd "${BASE_PATH}"

# Build pypoker-eval
echo "Building pypoker-eval..."
cd "${BASE_PATH}"
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: CMakeLists.txt not found in $(pwd)"
    exit 1
fi
mkdir -p build
cd build
if [[ "$OS" == "Windows" ]]; then
    cmake .. -G "Visual Studio 17 2022"
    cmake --build .
elif [[ "$OS" == "MacOS" ]]; then
    echo "Debug: Configuring CMake with:"
    echo "  Python3_EXECUTABLE=$PYTHON_EXEC"
    echo "  Python3_INCLUDE_DIR=$PYTHON_INCLUDE"
    echo "  Python3_LIBRARY=$PYTHON_LIBRARY"

    # Get the Python installation prefix for CMAKE_PREFIX_PATH
    PYTHON_PREFIX=$($PYTHON_EXEC -c "import sys; print(sys.prefix)")
    echo "  Python prefix: $PYTHON_PREFIX"

    # Clear CMake cache to avoid interference
    rm -f CMakeCache.txt

    echo "Running CMake with verbose output..."
    cmake --debug-find \
    -DCMAKE_PREFIX_PATH="$PYTHON_PREFIX" \
    -DPython3_EXECUTABLE="$PYTHON_EXEC" \
    -DPython3_INCLUDE_DIR="$PYTHON_INCLUDE" \
    -DPython3_LIBRARY="$PYTHON_LIBRARY" \
    -DPython3_FIND_STRATEGY=LOCATION \
    -DPython3_FIND_REGISTRY=NEVER \
    -DPython3_FIND_VIRTUALENV=ONLY \
    ..
    make
elif [[ "$OS" == "Linux" ]]; then
    cmake -DPython3_EXECUTABLE="$PYTHON_EXEC" \
    -DPython3_INCLUDE_DIR="$PYTHON_INCLUDE" \
    -DPython3_LIBRARY="$PYTHON_LIBRARY" \
    ..
    make
fi

cd "${BASE_PATH}"

# Generate filename based on Python version (format: 3_11_4)
MAJOR_MINOR_MICRO=$(echo $PYTHON_VERSION | tr '.' '_')

if [[ "$OS" == "Windows" ]]; then
    echo "Renaming and moving pypokereval.dll..."
    mv "${BASE_PATH}/build/Debug/pypokereval.pyd" "${BASE_PATH}/_pokereval_${MAJOR_MINOR_MICRO}.pyd"
elif [[ "$OS" == "Linux" ]]; then
    echo "Copying and renaming pypokereval.so..."
    cp "${BASE_PATH}/build/pypokereval.so" "${BASE_PATH}/_pokereval_${MAJOR_MINOR_MICRO}.so"
elif [[ "$OS" == "MacOS" ]]; then
    echo "Copying and renaming pypokereval.so..."
    cp "${BASE_PATH}/build/pypokereval.so" "${BASE_PATH}/_pokereval_${MAJOR_MINOR_MICRO}.so"
fi

# Build wheel package
echo "Building wheel package..."
cd "${BASE_PATH}"

# Install build dependencies if using venv
if [ "$USE_VENV" = true ]; then
    echo "Installing build dependencies in virtual environment..."
    uv pip install build wheel setuptools
else
    echo "Note: Make sure you have 'build' and 'wheel' packages installed"
    echo "Install with: pip install build wheel setuptools"
fi

# Copy the built shared library to the expected location for setup.py
if [[ "$OS" == "MacOS" || "$OS" == "Linux" ]]; then
    cp "${BASE_PATH}/_pokereval_${MAJOR_MINOR}.so" "${BASE_PATH}/_pokereval_${MAJOR_MINOR}.so.bak" 2>/dev/null || true
fi

# Build the wheel
echo "Creating wheel package..."
if [ "$USE_VENV" = true ]; then
    # Use uv to build
    uv pip install -e . || echo "Warning: Failed to install in development mode"
    python -m build --wheel
else
    # Use standard build
    python -m build --wheel 2>/dev/null || {
        echo "Falling back to setup.py bdist_wheel..."
        python setup.py bdist_wheel
    }
fi

# Create dist directory if it doesn't exist and move wheel there
mkdir -p dist
WHEEL_FILE=$(find . -name "*.whl" -not -path "./dist/*" | head -1)
if [ -n "$WHEEL_FILE" ]; then
    mv "$WHEEL_FILE" dist/ 2>/dev/null || cp "$WHEEL_FILE" dist/
    WHEEL_NAME=$(basename "$WHEEL_FILE")
    echo "Wheel created: dist/$WHEEL_NAME"
else
    echo "Warning: No wheel file found"
fi

echo "Build process completed."

# Show final information
echo ""
echo "=== Build Summary ==="
echo "Python version used: $ACTUAL_VERSION"
if [ "$USE_VENV" = true ]; then
    echo "Virtual environment: .venv (created with uv)"
    echo "To activate: source .venv/bin/activate"
fi
echo "Output shared library: _pokereval_${MAJOR_MINOR_MICRO}.so"
if [ -n "$WHEEL_NAME" ]; then
    echo "Output wheel: dist/$WHEEL_NAME"
    echo ""
    echo "To install the wheel:"
    if [ "$USE_VENV" = true ]; then
        echo "  source .venv/bin/activate  # if not already activated"
    fi
    echo "  pip install dist/$WHEEL_NAME"
fi
echo "Build completed successfully!"
