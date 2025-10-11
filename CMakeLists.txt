cmake_minimum_required(VERSION 3.10)
project(PyPokerEvalBinding)

# Force CMake to use provided paths instead of automatic searching
set(Python3_FIND_STRATEGY LOCATION)
set(Python3_FIND_REGISTRY NEVER)

# Détecter le système d'exploitation et l'architecture
if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    if(EXISTS "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/python.exe")
        set(Python3_EXECUTABLE "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/python.exe")
        set(Python3_LIBRARY "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/libs/python311.lib")
        set(Python3_INCLUDE_DIR "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/include")
    elseif(EXISTS "$ENV{USERPROFILE}/Anaconda3/python.exe")
        set(Python3_EXECUTABLE "$ENV{USERPROFILE}/Anaconda3/python.exe")
        set(Python3_LIBRARY "$ENV{USERPROFILE}/Anaconda3/libs/python311.lib")
        set(Python3_INCLUDE_DIR "$ENV{USERPROFILE}/Anaconda3/include")
    else()
        set(Python3_EXECUTABLE "C:/hostedtoolcache/windows/Python/3.11.9/x64/python.exe")
        set(Python3_LIBRARY "C:/hostedtoolcache/windows/Python/3.11.9/x64/libs/python311.lib")
        set(Python3_INCLUDE_DIR "C:/hostedtoolcache/windows/Python/3.11.9/x64/include")
    endif()
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # Detect available Python versions dynamically on macOS
    foreach(PY_VERSION "3.12" "3.11" "3.10" "3.9")
        # Check system Python first (installed by CI via symlink)
        if(EXISTS "/usr/local/bin/python${PY_VERSION}")
            set(Python3_EXECUTABLE "/usr/local/bin/python${PY_VERSION}")
            # Let CMake auto-detect libraries for system Python
            break()
        # Check Homebrew Python
        elseif(EXISTS "/usr/local/opt/python@${PY_VERSION}/libexec/bin/python3")
            set(Python3_EXECUTABLE "/usr/local/opt/python@${PY_VERSION}/libexec/bin/python3")
            set(Python3_LIBRARY "/usr/local/opt/python@${PY_VERSION}/Frameworks/Python.framework/Versions/${PY_VERSION}/lib/libpython${PY_VERSION}.dylib")
            set(Python3_INCLUDE_DIR "/usr/local/opt/python@${PY_VERSION}/Frameworks/Python.framework/Versions/${PY_VERSION}/include/python${PY_VERSION}")
            break()
        endif()
    endforeach()

    # Fallback to anaconda if system Python not found
    if(NOT Python3_EXECUTABLE AND EXISTS "$ENV{HOME}/anaconda3/bin/python3")
        set(Python3_EXECUTABLE "$ENV{HOME}/anaconda3/bin/python3")
        # Get version from anaconda python
        execute_process(COMMAND "$ENV{HOME}/anaconda3/bin/python3" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
                       OUTPUT_VARIABLE ANACONDA_PY_VERSION
                       OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(Python3_LIBRARY "$ENV{HOME}/anaconda3/lib/libpython${ANACONDA_PY_VERSION}.dylib")
        set(Python3_INCLUDE_DIR "$ENV{HOME}/anaconda3/include/python${ANACONDA_PY_VERSION}")
    endif()
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    # Detect available Python versions dynamically
    foreach(PY_VERSION "3.12" "3.11" "3.10" "3.9")
        if(${CMAKE_SYSTEM_PROCESSOR} MATCHES "aarch64")
            if(EXISTS "/usr/bin/python${PY_VERSION}")
                set(Python3_EXECUTABLE "/usr/bin/python${PY_VERSION}")
                set(Python3_LIBRARY "/usr/lib/aarch64-linux-gnu/libpython${PY_VERSION}.so")
                set(Python3_INCLUDE_DIR "/usr/include/python${PY_VERSION}")
                break()
            endif()
        else()
            if(EXISTS "/usr/bin/python${PY_VERSION}")
                set(Python3_EXECUTABLE "/usr/bin/python${PY_VERSION}")
                set(Python3_LIBRARY "/usr/lib/x86_64-linux-gnu/libpython${PY_VERSION}.so")
                set(Python3_INCLUDE_DIR "/usr/include/python${PY_VERSION}")
                break()
            endif()
        endif()
    endforeach()

    # Fallback to anaconda if system Python not found
    if(NOT Python3_EXECUTABLE AND EXISTS "$ENV{HOME}/anaconda3/bin/python3")
        set(Python3_EXECUTABLE "$ENV{HOME}/anaconda3/bin/python3")
        # Get version from anaconda python
        execute_process(COMMAND "$ENV{HOME}/anaconda3/bin/python3" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
                       OUTPUT_VARIABLE ANACONDA_PY_VERSION
                       OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(Python3_LIBRARY "$ENV{HOME}/anaconda3/lib/libpython${ANACONDA_PY_VERSION}.so")
        set(Python3_INCLUDE_DIR "$ENV{HOME}/anaconda3/include/python${ANACONDA_PY_VERSION}")
    endif()
endif()

# Manual Python detection - bypass find_package to force use of our explicit paths
if(DEFINED Python3_EXECUTABLE AND DEFINED Python3_INCLUDE_DIR AND DEFINED Python3_LIBRARY)
    # Use explicitly provided Python paths
    set(Python3_FOUND TRUE)
    set(Python3_INCLUDE_DIRS ${Python3_INCLUDE_DIR})
    set(Python3_LIBRARIES ${Python3_LIBRARY})

    # Get version from the executable
    execute_process(
        COMMAND ${Python3_EXECUTABLE} -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
        OUTPUT_VARIABLE Python3_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    message(STATUS "Using explicit Python paths:")
    message(STATUS "Python 3.x version: ${Python3_VERSION}")
    message(STATUS "Python Interpreter: ${Python3_EXECUTABLE}")
    message(STATUS "Python Libraries: ${Python3_LIBRARIES}")
    message(STATUS "Python Include Dirs: ${Python3_INCLUDE_DIRS}")

    include_directories(${Python3_INCLUDE_DIRS})
else()
    # Fallback to find_package if no explicit paths provided
    find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

    if(Python3_FOUND)
        message(STATUS "Python 3.x trouvé : Version ${Python3_VERSION}")
        message(STATUS "Python Interpreter : ${Python3_EXECUTABLE}")
        message(STATUS "Python Libraries : ${Python3_LIBRARIES}")
        message(STATUS "Python Include Dirs : ${Python3_INCLUDE_DIRS}")

        include_directories(${Python3_INCLUDE_DIRS})
    endif()
endif()

if(Python3_FOUND)
    
    # Configurer les chemins pour poker-eval
    set(POKER_EVAL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/poker-eval/include")
    include_directories(${POKER_EVAL_INCLUDE_DIR})

    if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
        set(POKER_EVAL_LIB_PATH "${CMAKE_SOURCE_DIR}/poker-eval/build/Debug/poker_lib_static.lib")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        set(POKER_EVAL_LIB_PATH "${CMAKE_SOURCE_DIR}/poker-eval/build/libpoker_lib_static.a")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        set(POKER_EVAL_LIB_PATH "${CMAKE_SOURCE_DIR}/poker-eval/build/libpoker_lib_static.a")
    endif()

    # Vérifier l'existence de la bibliothèque poker-eval
    if(NOT EXISTS ${POKER_EVAL_LIB_PATH})
        message(FATAL_ERROR "La bibliothèque poker-eval n'a pas été trouvée à ${POKER_EVAL_LIB_PATH}. Assurez-vous de la construire d'abord.")
    endif()

    # Ajouter la cible pour pypokereval
    add_library(pypokereval MODULE pypokereval.c)
    target_link_libraries(pypokereval ${Python3_LIBRARIES} ${POKER_EVAL_LIB_PATH})
    
    # Configurer les propriétés de la cible
    set_target_properties(pypokereval PROPERTIES 
        PREFIX ""
        SUFFIX ".so"
    )

    # Définir le nom de sortie en fonction du système d'exploitation
    if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
        set_target_properties(pypokereval PROPERTIES SUFFIX ".pyd")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        set_target_properties(pypokereval PROPERTIES SUFFIX ".so")
    endif()

    # Afficher des informations de débogage
    message(STATUS "POKER_EVAL_INCLUDE_DIR: ${POKER_EVAL_INCLUDE_DIR}")
    message(STATUS "POKER_EVAL_LIB_PATH: ${POKER_EVAL_LIB_PATH}")

    # Configurer les flags de compilation
    if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        target_compile_options(pypokereval PRIVATE -fPIC)
    endif()

    # Define Python version for the C code
    string(REPLACE "." "_" PYTHON_VERSION_UNDERSCORE ${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR})
    target_compile_definitions(pypokereval PRIVATE PYTHON_VERSION=${PYTHON_VERSION_UNDERSCORE})

    # Définir les options de débogage si nécessaire
    if(CMAKE_BUILD_TYPE MATCHES Debug)
        target_compile_definitions(pypokereval PRIVATE DEBUG=1)
    endif()

else()
    message(FATAL_ERROR "Python 3.x n'a pas été trouvé. Le binding Python ne peut pas être construit.")
endif()
