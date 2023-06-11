import sys
import os
from distutils import core
from distutils.core import Extension
from distutils.command.build_ext import build_ext

def read_file(name):
    dir_name = os.path.dirname(os.path.abspath(__file__))
    file_name = os.path.join(dir_name, name)
    with open(file_name) as f_obj:
        return f_obj.read()

PYTHON_VERSION = f'{sys.version[0]}_{sys.version[2]}'
C_NAME = f'_pokereval_{PYTHON_VERSION}'

core.setup(
    name='pokereval',
    py_modules=['pokereval'],
    version='3.11',
    description='',
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
                'include',
                'C:\\msys64\\home\\jd\\poker-eval',
                'C:\\Users\\jd\\anaconda3\\envs\\fpdb311\\Lib\\site-packages',
            ],
            libraries=['poker_eval'],
            extra_link_args=[
                '/LIBPATH:C:\\msys64\\home\\jd\\poker-eval\\lib',
            ],
            define_macros=[
                ("PYTHON_VERSION", f'"{PYTHON_VERSION}"'),
                ("VERSION_NAME(w)", f'w ## {PYTHON_VERSION}'),
            ],
        )
    ],
)
