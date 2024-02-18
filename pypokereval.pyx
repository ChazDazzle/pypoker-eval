# Importation des types nécessaires depuis la bibliothèque standard C et Cython
from libc.stdint cimport int32_t, uint32_t
from cpython.ref cimport PyObject
from libcpp cimport bool

# Déclaration des types externes et des fonctions depuis les fichiers d'en-tête C
cdef extern from "poker_defs.h":
    ctypedef struct StdDeck_CardMask:
        """
        Cette structure représente un masque de cartes pour un jeu de cartes standard.
        Elle peut représenter un ensemble de cartes à l'aide de champs pour chaque couleur.
        """
        union:
            uint64 cards_n  # Pour les systèmes qui utilisent des entiers 64 bits
            struct:
                uint32 n1, n2  # Pour les systèmes qui ne le font pas
            struct:
                uint32 spades:13  # 13 bits pour les piques
                uint32 :3  # 3 bits de remplissage
                uint32 clubs:13  # 13 bits pour les trèfles
                uint32 :3  # 3 bits de remplissage
                uint32 diamonds:13  # 13 bits pour les carreaux
                uint32 :3  # 3 bits de remplissage
                uint32 hearts:13  # 13 bits pour les cœurs
                uint32 :3  # 3 bits de remplissage


cdef extern from "enumerate.h":
    ctypedef struct enum_result_t:
        pass  # À remplir avec les champs réels de la structure

    int enumExhaustive(...)
    int enumSample(...)
    void enumResultClear(enum_result_t* result)
    void enumResultPrint(enum_result_t* result)
    void enumResultPrintTerse(enum_result_t* result)

cdef extern from "eval.h":
    # Déclarations des fonctions d'évaluation

cdef extern from "eval_low.h":
    # Déclarations des fonctions d'évaluation pour les mains basses

cdef extern from "eval_low8.h":
    # Déclarations pour les évaluations spécifiques

cdef extern from "eval_joker_low.h":
    # Déclarations pour les évaluations avec jokers

cdef extern from "eval_omaha.h":
    # Déclarations pour l'évaluation des mains d'Omaha

# Déclaration des fonctions Python qui seront exposées
def pyEnumExhaustive(...):
    # Implémentation de l'énumération exhaustive en utilisant enumExhaustive

def pyEnumSample(...):
    # Implémentation de l'échantillonnage Monte Carlo en utilisant enumSample

def pyEnumResultClear(result):
    # Wrapper pour nettoyer les résultats d'énumération

def pyEnumResultPrint(result):
    # Wrapper pour imprimer les résultats d'énumération

def pyEnumResultPrintTerse(result):
    # Wrapper pour imprimer les résultats d'énumération de manière concise

# Implémentations supplémentaires des fonctions utilitaires si nécessaire
