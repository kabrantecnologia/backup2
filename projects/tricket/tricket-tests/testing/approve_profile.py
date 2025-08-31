#!/usr/bin/env python3
"""
CLI para aprovar profiles usando as operações existentes.

Uso:
  - Listar perfis pendentes: python scripts/approve_profile.py --list
  - Aprovar por ID:          python scripts/approve_profile.py --id <UUID>
  - Interativo:              python scripts/approve_profile.py
"""
import os
import sys
import argparse
from rich.console import Console

# Garantir import relativo a partir da raiz de testing-tricket/
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from operations.profile_approval import (
    approve_user_profile,
    approve_user_profile_interactive,
    get_profiles_for_approval,
)

PROJECT_NAME = "tricket"
console = Console()


def main():
    parser = argparse.ArgumentParser(description="Aprovação de Profiles (Admin)")
    parser.add_argument("--id", dest="profile_id", help="ID do profile a aprovar (UUID)")
    parser.add_argument("--list", action="store_true", help="Listar profiles pendentes para aprovação")
    args = parser.parse_args()

    if args.list:
        get_profiles_for_approval(PROJECT_NAME)
        return

    if args.profile_id:
        approve_user_profile(PROJECT_NAME, args.profile_id)
        return

    # Modo interativo
    approve_user_profile_interactive(PROJECT_NAME)


if __name__ == "__main__":
    main()
