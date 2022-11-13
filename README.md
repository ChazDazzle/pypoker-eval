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

## WIP 2022

rework makefiles for python3.8, python3.9

compiling for python3
```sh
./configure
make
sudo make install
```

update from minmax github 

add anaconda dir :
```sh
 sudo python setup.py build for inst on conda env
```

tested ok on python3.9



