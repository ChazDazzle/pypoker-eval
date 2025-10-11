#!/usr/bin/env python3
"""
Windows-specific setup.py for pypoker-eval

This is a legacy setup script for Windows builds.
For modern builds, use build.sh which supports Windows, macOS, and Linux.

Usage:
    python setup_win.py build_ext --inplace
    python setup_win.py bdist_wheel

Note: This script now supports the new version-specific naming convention
and can use static libraries built by build.sh.
"""

import sys
import os
from setuptools import setup, Extension

def read_file(name):
    dir_name = os.path.dirname(os.path.abspath(__file__))
    file_name = os.path.join(dir_name, name)
    with open(file_name) as f_obj:
        return f_obj.read()

# Get full Python version (e.g., "3.11.4")
PYTHON_VERSION_FULL = f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}'
PYTHON_VERSION_UNDERSCORE = f'{sys.version_info.major}_{sys.version_info.minor}_{sys.version_info.micro}'
C_NAME = f'_pokereval_{PYTHON_VERSION_UNDERSCORE}'

# Path to the built static library and includes
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
POKER_EVAL_INCLUDE = os.path.join(BASE_DIR, 'poker-eval', 'include')
POKER_EVAL_LIB_PATH = os.path.join(BASE_DIR, 'poker-eval', 'build', 'libpoker_lib_static.a')

setup(
    name='pokereval',
    py_modules=['pokereval'],
    version=PYTHON_VERSION_FULL,
    description='Python poker hand evaluator (Windows build)',
    author='pypoker-eval',
    author_email='',
    url='',
    license=read_file('COPYING'),
    package_data={'pokereval': ["README"]},
    classifiers=[
        'Development Status :: 4 - Beta',
        'Programming Language :: Python :: 3',
        f'Programming Language :: Python :: {PYTHON_VERSION_FULL[:3]}',
        'Operating System :: Microsoft :: Windows',
    ],
    ext_modules=[
        Extension(
            C_NAME,
            ['pypokereval.c'],
            include_dirs=[
                POKER_EVAL_INCLUDE,
                'include',
            ],
            # Use static library if available, otherwise try to find poker-eval
            extra_objects=[POKER_EVAL_LIB_PATH] if os.path.exists(POKER_EVAL_LIB_PATH) else [],
            libraries=[] if os.path.exists(POKER_EVAL_LIB_PATH) else ['poker_eval'],
            library_dirs=[] if os.path.exists(POKER_EVAL_LIB_PATH) else [
                # Common poker-eval installation paths on Windows
                'C:\\msys64\\usr\\local\\lib',
                'C:\\poker-eval\\lib',
                os.path.join(BASE_DIR, 'poker-eval', 'lib'),
            ],
            define_macros=[
                ('PYTHON_VERSION', PYTHON_VERSION_UNDERSCORE),
                ('VERSION_NAME(w)', f'w ## {PYTHON_VERSION_UNDERSCORE}'),
                ('WIN32', None),
            ],
        )
    ],
)
