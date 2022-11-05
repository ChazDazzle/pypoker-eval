from ctypes import *
# must install poker-eval first -testing wrapping c lib poker-eval
_pokereval = cdll.LoadLibrary("/home/xx/Documents/poker-eval/lib/.libs/libpoker-eval.so.1.0.0")

test = _pokereval.StdDeck_cardToString("2h")
print(test)