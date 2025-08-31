Para chamar a função `inactivate_product_with_error` no WeWeb, você precisa usar o seguinte formato de payload:

## 📋 Formato do Payload

```json
{
  "p_product_id": "uuid-do-produto",
  "p_error_type": "BROKEN_IMAGE",
  "p_error_description": "Descrição do erro (opcional)",
  "p_error_details": {
    "image_url": "https://exemplo.com/imagem-quebrada.jpg",
    "error_code": "IMG_404",
    "user_agent": "Mozilla/5.0...",
    "timestamp": "2025-08-17T09:04:08-03:00"
  }
}
```

## 🎯 Campos obrigatórios vs opcionais

**Obrigatórios:**
- `p_product_id` (UUID) - ID do produto
- `p_error_type` (string) - Tipo do erro

**Opcionais:**
- `p_error_description` (string) - Descrição legível
- `p_error_details` (object) - Detalhes técnicos em JSON

## 📝 Tipos de erro válidos

```javascript
const ERROR_TYPES = [
  'BROKEN_IMAGE',
  'INVALID_DATA', 
  'API_ERROR',
  'PROCESSING_ERROR',
  'OTHER'
];
```

## 🌐 Exemplo de chamada no WeWeb

```javascript
// Payload mínimo
const minimalPayload = {
  p_product_id: "123e4567-e89b-12d3-a456-426614174000",
  p_error_type: "BROKEN_IMAGE"
};

// Payload completo
const fullPayload = {
  p_product_id: "123e4567-e89b-12d3-a456-426614174000",
  p_error_type: "BROKEN_IMAGE",
  p_error_description: "Imagem do produto não carrega",
  p_error_details: {
    image_url: "https://example.com/produto.jpg",
    error_code: "404",
    browser: navigator.userAgent,
    reported_from: "product_detail_page"
  }
};
```

## 📤 Resposta esperada

**Sucesso:**
```json
{
  "success": true,
  "message": "Product inactivated successfully",
  "product_id": "uuid-do-produto",
  "error_id": "uuid-do-erro-criado",
  "previous_status": "ACTIVE",
  "new_status": "INACTIVE",
  "error_type": "BROKEN_IMAGE",
  "reported_at": "2025-08-17T12:04:08.000Z"
}
```

**Erro:**
```json
{
  "success": false,
  "error": "Product not found",
  "product_id": "uuid-do-produto"
}
```

A função automaticamente captura o `auth.uid()` do usuário logado para auditoria, então não precisa enviar essa informação no payload.