What is pypoker-eval ?  

This package is python adaptor for the poker-eval toolkit for writing
programs which simulate or analyze poker games as found at
http://gna.org/projects/pokersource/. The python interface is
somewhat simpler than the C API of poker-eval. It assumes that the
caller is willing to have a higher level API and is not interested in
a one to one mapping of the poker-eval API.

For more information about the functions provided, check the
documentation of the PokerEval class in the pokereval.py file.

Loic Dachary <loic@dachary.org>

## WIP 2022-2023

update from Tzerjen Wei github https://github.com/tjwei

rework makefiles for python3.8,  ...

work with python3.11 but this is bug to track (manually edit configure file: replace $PYTHON_VERSION per 3.11 in the dedicated code section )

configure autoconf
```sh
autoconf
```

compiling for python3
```sh
./configure
make
sudo make install
```

Some tips:

The error message "gcc -shared .libs/_pokereval_3_8_la-pypokereval.o -L/home/jd/anaconda3/envs/pypoker-eval3.8/lib/python3.8/config-3.8-x86_64-linux-gnu -lpython3.8 -L/usr/local/lib /usr/local/lib/libpoker-eval.so -Wl,-soname -Wl,_pokereval_3_8.so.1 -o .libs/_pokereval_3_8.so.1.0.0 /usr/bin/ld: cannot find -lpython3.8: No such file or directory"  => think to install  install the development package exemple on ubuntu sudo apt-get install libpython3.8-dev













