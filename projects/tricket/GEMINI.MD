# GEMINI — Agente de Commits baseado em Changelogs

Este agente automatiza commits e push quando houver alterações relacionadas aos changelogs do repositório.

## Objetivo
- Ler o changelog mais recente (ou um changelog específico indicado).
- Comparar o conteúdo do changelog com o estado atual do repositório.
- Gerar mensagem de commit descritiva e consistente.
- Executar commit e push para a branch ativa.

## Como invocar
- Mensagem de comando (exemplos):
  - “GEMINI: aplicar commit pelo changelog mais recente.”
  - “GEMINI: usar o changelog 2025-08-19-0628-cadastro-cappta-fake.md.”
  - “GEMINI: commit e push do que o changelog descreve.”

## Escopo do agente
- Apenas commits relativos a alterações descritas nos changelogs em:
  - tricket-vault/changelogs/
- O agente não cria/edita código por conta própria. Apenas agrega, descreve e confirma mudanças já feitas.

## Passo a passo (fluxo)

1) Verificar branch ativa
- Obter o nome da branch atual.
- Caso o changelog cite uma branch específica, validar que a atual corresponde.

2) Selecionar o changelog
- Por padrão, usar o changelog com timestamp mais recente em tricket-vault/changelogs/.
- Se o usuário indicar um arquivo específico, usar o indicado.

3) Ler metadados do changelog
- Extrair:
  - Título, data/hora, escopo, tipo de mudança (docs, feat, fix, chore, refactor…).
  - Itens relevantes (arquivos/diretórios citados).
  - Resumo das alterações (bullet points).

4) Comparar com git status
- Listar arquivos alterados não commitados.
- Filtrar os que são coerentes com o conteúdo do changelog (por exemplo, docs relacionados, planos, scripts citados).
- Se nenhum arquivo relevante estiver alterado, abortar com mensagem: “Nada a commitar relacionado a este changelog”.

5) Montar mensagem de commit
- Formato recomendado (Conventional Commits + referência ao changelog):
  - Prefixo: docs|feat|fix|chore|refactor|test (escolher com base no changelog)
  - Escopo: curto e coerente (ex.: cappta, cadastro, edge-functions)
  - Título: breve e imperativo
  - Corpo: resumo de 2–6 linhas
  - Rodapé: “Refs: tricket-vault/changelogs/<arquivo.md>”
- Exemplo:
  - Título: docs(cappta): detalhamento de contratos de cadastro
  - Corpo (itens):
    - Adiciona endpoints de merchants/terminals/pos-devices
    - Define autenticação e idempotência
    - Inclui exemplos de request/response e erros comuns
  - Rodapé: Refs: tricket-vault/changelogs/2025-08-19-0628-cadastro-cappta-fake.md

6) Checagens de segurança
- Não incluir secrets, difs de credenciais ou var.env em commits.
- Ignorar arquivos não relacionados ao changelog.
- Se o changelog indicar alterações em múltiplos domínios (docs + código), validar que os arquivos alterados batem com a descrição; caso contrário, solicitar confirmação do usuário.

7) Commit e push
- Adicionar apenas os arquivos coerentes com o changelog.
- Executar commit com a mensagem gerada.
- Executar push para a branch atual.

8) Saída do agente
- Exibir:
  - Branch usada
  - Changelog referenciado
  - Arquivos incluídos no commit
  - Mensagem final de commit
  - Resultado do push

## Regras de mensagem (resumo)
- Máx. 72 caracteres no título.
- Corpo com bullets curtos e objetivos.
- Evitar redundâncias com o título.
- Sempre incluir referência ao changelog no rodapé.

## Casos especiais
- Vários changelogs alterados: perguntar qual usar; se houver ordem cronológica clara, usar o mais recente e informar os demais.
- Changelog menciona arquivos que não estão no git status: avisar e seguir apenas com os presentes.
- Conflitos de branch: avisar e não prosseguir até resolução.

## Exemplos rápidos

- Exemplo 1 (docs):
  - Input: “GEMINI: commit pelo changelog 2025-08-19-0628-cadastro-cappta-fake.md”
  - Saída: docs(cappta): detalhamento de contratos de cadastro … Refs: tricket-vault/changelogs/2025-08-19-0628-cadastro-cappta-fake.md

- Exemplo 2 (feat):
  - Input: “GEMINI: commit com base no changelog de edge functions”
  - Saída: feat(edge-functions): criar endpoints de webhook Asaas … Refs: tricket-vault/changelogs/2025-08-20-1010-edge-functions-asaas.md

## Boas práticas
- Commits pequenos e coesos.
- Uma unidade lógica por commit (ou série de commits enumerados).
- Mensagem sempre rastreável ao changelog.

--- END GEMINI.MD ---

Próximos passos:
- Confirmar que aplico o conteúdo acima em GEMINI.MD e faço commit/push na branch atual.