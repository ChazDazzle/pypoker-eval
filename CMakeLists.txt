cmake_minimum_required(VERSION 3.10)
project(PyPokerEvalBinding)

# Chemins personnalisés pour Anaconda si CMake ne trouve pas automatiquement Python
set(Anaconda_PATH "/home/jd/anaconda3") # Remplacer par le chemin réel d'installation d'Anaconda
set(Python3_EXECUTABLE "${Anaconda_PATH}/bin/python")
set(Python3_LIBRARY "${Anaconda_PATH}/lib/libpython3.11.so") # Remplacer x par votre version de Python
set(Python3_INCLUDE_DIR "${Anaconda_PATH}/include/python3.11") # Remplacer x par votre version de Python

# Essayez de trouver une installation de Python 3.x
find_package(Python3 COMPONENTS Interpreter Development)
if(Python3_FOUND)
    message(STATUS "Python 3.x trouvé : Version ${Python3_VERSION}, Librairies : ${Python3_LIBRARIES}, Include : ${Python3_INCLUDE_DIRS}")
    include_directories(${Python3_INCLUDE_DIRS})

    # Chemin vers la bibliothèque poker-eval construite
    set(POKER_EVAL_LIB_PATH "/home/jd/Documents/github/poker-eval/build/libpoker_lib.so")

    # Incluez les en-têtes de poker-eval si vous les avez
    include_directories("/home/jd/Documents/github/poker-eval/include")
    include_directories("/home/jd/Documents/github/poker-eval/lib")

    # Définissez le module Python
    add_library(pypokereval MODULE pypokereval.c)
    target_link_libraries(pypokereval ${Python3_LIBRARIES} ${POKER_EVAL_LIB_PATH})
    set_target_properties(pypokereval PROPERTIES PREFIX "")
else()
    message(WARNING "Python 3.x n'a pas été trouvé, le binding Python ne sera pas construit.")
endif()
