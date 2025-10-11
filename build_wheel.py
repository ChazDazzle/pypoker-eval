#!/usr/bin/env python3
"""
Universal wheel build script for pypoker-eval
Compatible with both standard Python and uv
"""

import os
import sys
import shutil
import zipfile
import tempfile
import subprocess
from pathlib import Path
import io

def debug_subprocess(cmd, **kwargs):
    """Debug wrapper for subprocess calls"""
    print(f"DEBUG: Running command: {cmd}", file=sys.stderr)
    print(f"DEBUG: Working directory: {os.getcwd()}", file=sys.stderr)
    print(f"DEBUG: Subprocess kwargs: {kwargs}", file=sys.stderr)
    try:
        result = subprocess.run(cmd, **kwargs)
        print(f"DEBUG: Command completed with return code: {result.returncode}", file=sys.stderr)
        return result
    except FileNotFoundError as e:
        print(f"DEBUG: FileNotFoundError - Command not found: {cmd[0] if isinstance(cmd, list) else cmd}", file=sys.stderr)
        print(f"DEBUG: Error details: {e}", file=sys.stderr)
        print(f"DEBUG: Current PATH: {os.environ.get('PATH', 'NOT SET')}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"DEBUG: Unexpected error: {e}", file=sys.stderr)
        raise

# Fix UTF-8 encoding issues on Windows
if sys.platform.startswith('win') and hasattr(sys.stdout, 'buffer'):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def detect_python_manager():
    """Detect if we're using uv or standard Python"""
    # Check if build method is forced via environment variable
    forced_method = os.environ.get('FORCE_BUILD_METHOD')
    if forced_method:
        print(f"Build method forced to: {forced_method}")
        if forced_method == 'uv':
            # Verify uv is actually available
            try:
                result = debug_subprocess(['uv', '--version'], 
                                      capture_output=True, text=True, check=True)
                print(f"uv verified: {result.stdout.strip()}")
                return 'uv'
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("ERROR: uv forced but not available!")
                sys.exit(1)
        else:
            return 'python'
    
    # Auto-detect if no force
    try:
        result = debug_subprocess(['uv', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"uv detected: {result.stdout.strip()}")
        return 'uv'
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("uv not available, using standard Python")
        return 'python'

def get_python_info():
    """Get current Python information"""
    version = f"{sys.version_info.major}.{sys.version_info.minor}"
    version_short = f"{sys.version_info.major}{sys.version_info.minor}"
    
    # Expected extension name
    if sys.platform.startswith('win'):
        ext_name = f"_pokereval_{version_short}.pyd"
        platform_tag = "win_amd64"
    elif sys.platform.startswith('darwin'):
        ext_name = f"_pokereval_{version_short}.so"
        if 'arm64' in os.uname().machine.lower():
            platform_tag = "macosx_11_0_arm64"
        else:
            platform_tag = "macosx_10_15_x86_64"
    else:  # Linux
        ext_name = f"_pokereval_{version_short}.so"
        platform_tag = "linux_x86_64"
    
    return version, version_short, ext_name, platform_tag

def build_with_cmake(python_manager, python_version):
    """Build extension with CMake"""
    print(f"Building with {python_manager} Python {python_version}...")
    
    # Clean previous build
    if os.path.exists('build'):
        shutil.rmtree('build')
    os.makedirs('build')
    
    # Build poker-eval first
    print("Building poker-eval...")
    debug_subprocess(['git', 'submodule', 'update', '--init', '--recursive'], check=True)
    
    poker_eval_build = Path('poker-eval/build')
    poker_eval_build.mkdir(exist_ok=True)
    
    os.chdir('poker-eval/build')
    debug_subprocess(['cmake', '..', '-DCMAKE_POSITION_INDEPENDENT_CODE=ON'], check=True)
    debug_subprocess(['cmake', '--build', '.'], check=True)
    os.chdir('../..')
    
    # Build pypoker-eval
    print("Building pypoker-eval...")
    os.chdir('build')
    
    # Determine the correct Python executable
    if python_manager == 'uv':
        # Use uv Python if available
        python_exe = debug_subprocess(['uv', 'run', f'--python', python_version, 'which', 'python'], 
                                  capture_output=True, text=True, check=True).stdout.strip()
    else:
        # Try to find the right Python version
        python_exe = find_python_executable(python_version)
    
    print(f"Using Python: {python_exe}")
    
    # Verify Python version
    result = debug_subprocess([python_exe, '--version'], capture_output=True, text=True, check=True)
    actual_version = result.stdout.strip().split()[1][:3]  # e.g. "3.11" from "Python 3.11.9"
    
    if actual_version != python_version:
        print(f"WARNING: Expected Python {python_version}, got {actual_version}")
    
    # Force CMake to use the specific Python
    cmake_cmd = [
        'cmake', '..',
        f'-DPython3_EXECUTABLE={python_exe}',
    ]
    
    debug_subprocess(cmake_cmd, check=True)
    debug_subprocess(['cmake', '--build', '.'], check=True)
    
    os.chdir('..')
    return True

def find_python_executable(version):
    """Find the correct Python executable for the given version"""
    # Common Python executable patterns
    candidates = [
        f'python{version}',
        f'python{version[0]}.{version[2]}',
        f'/usr/bin/python{version}',
        f'/usr/local/bin/python{version}',
        sys.executable  # Fallback to current
    ]
    
    for candidate in candidates:
        try:
            result = debug_subprocess([candidate, '--version'], 
                                  capture_output=True, text=True, check=True)
            actual_version = result.stdout.strip().split()[1][:3]
            if actual_version == version:
                return candidate
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    
    # If no exact match, return current Python as fallback
    print(f"Warning: Could not find Python {version}, using {sys.executable}")
    return sys.executable

def create_wheel(python_version, version_short, ext_name, platform_tag):
    """Create wheel with compiled extension"""
    print(f"Creating wheel for {ext_name}...")
    
    # Find compiled extension
    possible_extensions = [
        f'build/{ext_name}',
        f'build/pypokereval.so',
        f'build/pypokereval.pyd',
        f'build/Release/pypokereval.pyd',
        f'build/Debug/pypokereval.pyd'
    ]
    
    extension_file = None
    for ext_path in possible_extensions:
        if os.path.exists(ext_path):
            extension_file = ext_path
            break
    
    if not extension_file:
        print("ERROR: Compiled extension not found!")
        return False
    
    print(f"Extension found: {extension_file}")
    
    # Copy with correct name
    target_ext = f"_pokereval_{version_short}"
    if sys.platform.startswith('win'):
        target_ext += ".pyd"
    else:
        target_ext += ".so"
    
    shutil.copy2(extension_file, target_ext)
    
    # Wheel version with build method suffix
    build_method = os.environ.get('FORCE_BUILD_METHOD', 'auto')
    version_number = python_version.replace('.', '')
    if build_method == 'uv':
        wheel_version = f"3.{version_number}.0+uv"
    elif build_method == 'python':
        wheel_version = f"3.{version_number}.0+python"
    else:
        wheel_version = f"3.{version_number}.0"
    
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # Copy files
        shutil.copy2('pokereval.py', temp_path / 'pokereval.py')
        shutil.copy2(target_ext, temp_path / target_ext)
        
        # Create metadata
        metadata_dir = temp_path / f'pypoker_eval-{wheel_version}.dist-info'
        metadata_dir.mkdir()
        
        # METADATA
        with open(metadata_dir / 'METADATA', 'w') as f:
            f.write(f"""Metadata-Version: 2.1
Name: pypoker-eval
Version: {wheel_version}
Summary: Python poker hand evaluator (uv compatible)
Author: pypoker-eval
License: GPL-2.0+
Platform: {platform_tag}
Classifier: Development Status :: 4 - Beta
Classifier: Programming Language :: Python :: {python_version}
Requires-Python: >={python_version}
""")
        
        # WHEEL
        with open(metadata_dir / 'WHEEL', 'w') as f:
            f.write(f"""Wheel-Version: 1.0
Generator: build_wheel.py
Root-Is-Purelib: false
Tag: py3-none-any
""")
        
        # top_level.txt
        with open(metadata_dir / 'top_level.txt', 'w') as f:
            f.write('pokereval\n')
        
        # RECORD
        with open(metadata_dir / 'RECORD', 'w') as f:
            f.write(f"""pokereval.py,,
{target_ext},,
pypoker_eval-{wheel_version}.dist-info/METADATA,,
pypoker_eval-{wheel_version}.dist-info/WHEEL,,
pypoker_eval-{wheel_version}.dist-info/top_level.txt,,
pypoker_eval-{wheel_version}.dist-info/RECORD,,
""")
        
        # Create wheel
        os.makedirs('dist', exist_ok=True)
        wheel_name = f'pypoker_eval-{wheel_version}-py3-none-any.whl'
        wheel_path = f'dist/{wheel_name}'
        
        with zipfile.ZipFile(wheel_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(temp_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arc_name = os.path.relpath(file_path, temp_path)
                    zf.write(file_path, arc_name)
        
        print(f"Wheel created: {wheel_path}")
        return wheel_path

def main():
    print("PyPoker-Eval Wheel Builder")
    print("=" * 40)
    
    # Get target Python version from environment (passed by CI matrix)
    target_python_version = os.environ.get('MATRIX_PYTHON_VERSION')
    if not target_python_version:
        # Fallback to current Python version
        target_python_version = f"{sys.version_info.major}.{sys.version_info.minor}"
        print(f"No target version specified, using current: {target_python_version}")
    
    # Detect environment
    python_manager = detect_python_manager()
    
    # Use target version for naming - ensure proper format like "311" not "31"
    version_parts = target_python_version.split('.')
    version_short = f"{version_parts[0]}{version_parts[1]}"
    
    # Platform detection
    if sys.platform.startswith('win'):
        ext_name = f"_pokereval_{version_short}.pyd"
        platform_tag = "win_amd64"
    elif sys.platform.startswith('darwin'):
        ext_name = f"_pokereval_{version_short}.so"
        if 'arm64' in os.uname().machine.lower():
            platform_tag = "macosx_11_0_arm64"
        else:
            platform_tag = "macosx_10_15_x86_64"
    else:  # Linux
        ext_name = f"_pokereval_{version_short}.so"
        platform_tag = "linux_x86_64"
    
    print(f"Configuration:")
    print(f"   Manager: {python_manager}")
    print(f"   Target Python: {target_python_version}")
    print(f"   Extension: {ext_name}")
    print(f"   Platform: {platform_tag}")
    print()
    
    # Build
    if not build_with_cmake(python_manager, target_python_version):
        sys.exit(1)
    
    # Create wheel
    wheel_path = create_wheel(target_python_version, version_short, ext_name, platform_tag)
    if not wheel_path:
        sys.exit(1)
    
    print(f"\nSuccess! Wheel available: {wheel_path}")
    
    # Quick test if possible
    if python_manager == 'uv':
        print("\nQuick test with uv...")
        try:
            debug_subprocess(['uv', 'pip', 'install', wheel_path, '--force-reinstall'], 
                         check=True, capture_output=True)
            result = debug_subprocess(['uv', 'run', '--python', target_python_version, 
                                   'python', '-c', 'import pokereval; print("Import OK!")'], 
                                  capture_output=True, text=True, check=True)
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Quick test failed: {e}")

if __name__ == "__main__":
    main()