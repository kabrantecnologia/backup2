# 📚 Wiki - Guias de Implementação WeWeb

Este diretório contém guias práticos para implementação das funcionalidades do Tricket no front-end WeWeb.

## 📋 Estrutura dos Guias

Cada guia segue um padrão consistente para facilitar a implementação:

### 🎯 **Formato Padrão:**

```markdown
# Nome do Sistema

## Funcionalidades Implementadas
- Lista das funcionalidades principais
- Benefícios e melhorias

## Funções Disponíveis no WeWeb

**Nome da Função**
```json
Função: nome_da_funcao_rpc
Payload: {
  "parametro1": "valor",
  "parametro2": 123
}
```

## Exemplos Práticos
- Cenários de uso comum
- Payloads específicos
- Respostas esperadas

## Para o Front-end WeWeb
- Orientações específicas de implementação
- Campos para exibir na interface
- Validações necessárias
```

## 📖 **Guias Disponíveis:**

### 🛒 [Sistema de Carrinho](./sistema-de-carrinho-marketplace.md)
- Gerenciamento completo do carrinho de compras
- Validação de fornecedor único
- Controle de quantidades
- Troca de fornecedores

### 🚨 [Sistema de Rastreamento de Erros](./sistema-rastreamento-erros-produtos.md)
- Reportar produtos com problemas
- Inativação automática
- Resolução de erros
- Reativação de produtos

## 🔧 **Como Usar no WeWeb:**

### 1. **Node "Call a Postgres Function"**
- **Name:** Nome da ação (ex: "Update Cart Quantity")
- **Type:** Call a Postgres function
- **Function name:** Nome exato da função RPC
- **Arguments:** Payload JSON conforme documentado

### 2. **Estrutura de Argumentos**
```json
{
  "parametro_obrigatorio": "valor",
  "parametro_opcional": "valor"
}
```

### 3. **Tratamento de Respostas**
- Sempre verificar `success: true/false`
- Tratar erros específicos (ex: `error_type`)
- Exibir mensagens apropriadas ao usuário

## 📝 **Padrões de Nomenclatura:**

### **Funções RPC:**
- `rpc_cart_*` - Funções do carrinho
- `rpc_product_*` - Funções de produtos
- `inactivate_product_with_error` - Funções específicas

### **Parâmetros:**
- `p_*` - Parâmetros de entrada (ex: `p_item_id`, `p_quantity`)
- `*_id` - Identificadores UUID
- `*_cents` - Valores monetários em centavos

### **Respostas:**
- `success` - Boolean indicando sucesso/falha
- `message` - Mensagem descritiva
- `error_type` - Tipo específico de erro
- `*_data` - Dados retornados (ex: `cart_data`)

## 🎨 **Boas Práticas WeWeb:**

### **1. Validação de Entrada**
```javascript
// Sempre validar dados antes de enviar
if (!itemId || !newQuantity) {
  // Exibir erro para o usuário
  return;
}
```

### **2. Tratamento de Erros**
```javascript
// Verificar resposta da função
if (response.success) {
  // Atualizar interface
} else {
  // Exibir erro específico
  if (response.error_type === 'DIFFERENT_SUPPLIER') {
    // Mostrar modal de confirmação
  }
}
```

### **3. Feedback Visual**
- Loading states durante chamadas
- Mensagens de sucesso/erro
- Atualizações em tempo real

### **4. Dados Dinâmicos**
```javascript
// Usar dados do contexto/variáveis
{
  "p_item_id": "{{item.id}}",
  "p_quantity": "{{newQuantity}}"
}
```

## 🚀 **Fluxo de Implementação:**

1. **Identificar a funcionalidade** necessária
2. **Consultar o guia** correspondente
3. **Copiar a função e payload** exatos
4. **Configurar o node** no WeWeb
5. **Testar com dados** reais
6. **Implementar tratamento** de erros
7. **Adicionar feedback** visual

## 📞 **Suporte:**

Para dúvidas ou problemas:
1. Consulte primeiro o guia específico
2. Verifique os exemplos práticos
3. Teste com payloads mínimos
4. Valide os tipos de dados (UUID, INT, etc.)

---

**Última atualização:** 2025-08-17  
**Versão:** 1.0  
**Compatibilidade:** WeWeb + Supabase PostgreSQL
