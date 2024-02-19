cmake_minimum_required(VERSION 3.10)
project(PyPokerEvalBinding)

# Détecter le système d'exploitation
if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    # Chemins personnalisés pour Anaconda si CMake ne trouve pas automatiquement Python sur Windows
    set(Python3_EXECUTABLE "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/python.exe")
    set(Python3_LIBRARY "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/libs/python311.lib")
    set(Python3_INCLUDE_DIR "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/include")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # Chemins pour macOS
    set(Python3_EXECUTABLE "$ENV{HOME}/anaconda3/bin/python")
    set(Python3_LIBRARY "$ENV{HOME}/anaconda3/lib/libpython3.11.dylib") # Remplacer 3.11 par votre version de Python
    set(Python3_INCLUDE_DIR "$ENV{HOME}/anaconda3/include/python3.11") # Remplacer 3.11 par votre version de Python
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    # Chemins pour Linux
    set(Python3_EXECUTABLE "$ENV{HOME}/anaconda3/bin/python")
    set(Python3_LIBRARY "$ENV{HOME}/anaconda3/lib/libpython3.11.so") # Remplacer 3.11 par votre version de Python
    set(Python3_INCLUDE_DIR "$ENV{HOME}/anaconda3/include/python3.11") # Remplacer 3.11 par votre version de Python
endif()

# Essayez de trouver une installation de Python 3.x
find_package(Python3 COMPONENTS Interpreter Development)
if(Python3_FOUND)
    message(STATUS "Python 3.x trouvé : Version ${Python3_VERSION}, Librairies : ${Python3_LIBRARIES}, Include : ${Python3_INCLUDE_DIRS}")
    include_directories(${Python3_INCLUDE_DIRS})

    # Chemin vers la bibliothèque poker-eval construite, adapté en fonction de l'OS
    if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
        set(POKER_EVAL_LIB_PATH "$ENV{USERPROFILE}/Documents/GitHub/poker-eval/build/Debug/poker_lib_static.lib")
    else()
        set(POKER_EVAL_LIB_PATH "$ENV{HOME}/Documents/GitHub/poker-eval/build/Debug/poker_lib_static.a") # Pour macOS et Linux
    endif()

    # Incluez les en-têtes de poker-eval si vous les avez
    include_directories("$ENV{HOME}/Documents/GitHub/poker-eval/include")
    include_directories("$ENV{HOME}/Documents/GitHub/poker-eval/lib")

    # Définissez le module Python
    add_library(pypokereval MODULE pypokereval.c)
    target_link_libraries(pypokereval ${Python3_LIBRARIES} ${POKER_EVAL_LIB_PATH})
    set_target_properties(pypokereval PROPERTIES PREFIX "")
else()
    message(WARNING "Python 3.x n'a pas été trouvé, le binding Python ne sera pas construit.")
endif()
