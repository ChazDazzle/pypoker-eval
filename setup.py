#!/usr/bin/env python

from __future__ import with_statement

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

# Determine the correct library path based on platform
if sys.platform.startswith('win'):
    # Windows: poker_lib_static.lib in Debug folder
    POKER_EVAL_LIB_PATH = os.path.join(BASE_DIR, 'poker-eval', 'build', 'Debug', 'poker_lib_static.lib')
else:
    # Unix: libpoker_lib_static.a
    POKER_EVAL_LIB_PATH = os.path.join(BASE_DIR, 'poker-eval', 'build', 'libpoker_lib_static.a')


setup(
    name='pokereval',
    py_modules=['pokereval'],
    version=PYTHON_VERSION_FULL,
    description='Python poker hand evaluation library',
    author='',
    author_email='',
    url='',
    license=read_file('COPYING'),
    package_data={'pokereval': ["README"]},
    classifiers=[],
    ext_modules=[
        Extension(
            C_NAME,
            ['pypokereval.c'],
            include_dirs=[
                POKER_EVAL_INCLUDE,
                'include',
            ],
            extra_objects=[POKER_EVAL_LIB_PATH] if os.path.exists(POKER_EVAL_LIB_PATH) else [],
            define_macros=[
                ('PYTHON_VERSION', PYTHON_VERSION_UNDERSCORE),
                ('VERSION_NAME(w)', f'w ## {PYTHON_VERSION_UNDERSCORE}'),
            ],
        )
    ],
)