# Atalhos para o sistema de testes

PY=python
ROOT=testing-tricket

install:
	$(PY) -m pip install -r $(ROOT)/requirements.txt

run:
	$(PY) $(ROOT)/main.py

list-profiles:
	$(PY) $(ROOT)/scripts/approve_profile.py --list

approve:
	@if [ -z "$(id)" ]; then echo "Uso: make approve id=<UUID>"; exit 1; fi; \
	$(PY) $(ROOT)/scripts/approve_profile.py --id $(id)

.PHONY: install run list-profiles approve
