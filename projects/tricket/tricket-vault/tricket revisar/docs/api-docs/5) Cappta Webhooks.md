
### GET Consultar Webhook
```
https://{base_url}/webhook?ResellerDocument={resellerDocument}
```

**Endpoint para Consultar um Webhook**  
Este endpoint permite consultar informações detalhadas sobre o webhook cadastrado, caso informado `ResellerDocument` será retornado webhook correspondente. **É necessário estar autenticado para realizar a requisição.**

- A estrutura da requisição possui parâmetros de consulta (_Query Params_) que podem ser incluídos, como filtros, para permitir que o retorno desejado seja obtido dentre os resultados possíveis;
    
- Adicione outros parâmetros opcionais conforme necessário. Por exemplo, para filtrar por `ResellerDocument`;
    
- **Cabeçalhos**:
    
    - `Authorization`: Token no formato Bearer.
    

A resposta será um JSON contendo os detalhes do webhook. Consulte os exemplos para entender a estrutura de sucesso ou erro.


```json
{
    "resellerDocument": "{resellerDocument}", // (string)[required] Documento do Revendedor
    "merchantDocument": "{merchantDocument}" // (string)[required] Documento do Lojista
}
```


---
### POST Cadastrar Webhook
```
https://{base_url}/webhook
```

**Endpoint para Cadastrar um Webhook**  
Este endpoint permite cadastrar o webhook, caso informado `ResellerDocument` será cadastrado para o revendedor correspondente e portanto, só receberá notificações que estejam vinculados ao mesmo. **É necessário estar autenticado para realizar a requisição.**

- Essa requisição possui em corpo (_Request Body_) os seguintes valores:
    
    - **`'ResellerDocument'`** **-** [OPICIONAL] Número do documento do Revendedor (sem pontuação);
        
        - **OBS:** Caso seja informado o documento de revendedor será cadastrado e apenas notificado quando houver movimentações vinculadas a esta persona.
        
    - **`'URL'`** - URL do endpoint para qual a chamada webhook será enviada;
        
    - **`'Type'`** - Tipo do webhook que será enviado;
        
        - **mentmerchantAccreditation**: Credenciamento do lojista
            
        - **transaction**: Transações
            
        
    
- Incluir também os cabeçalhos `'Authorization'`no formato _Bearer_ e '`accept'`com o valor `application/json` ;
    
- **ATENÇÃO:** A chamada webhook é do tipo **POST** portanto, esteja preparado e ciente que receberá está requisição com o método corretamente.
    

A resposta será um JSON contendo os detalhes do webhook cadastrado. Consulte os exemplos para entender a estrutura de sucesso ou erro.

```json
{
    "resellerDocument": "{resellerDocument}", // (string)[required] Documento do Revendedor
    "merchantDocument": "{merchantDocument}" // (string)[required] Documento do Lojista
}
```

---
### POST Inativar Webhook
```
https://{base_url}/webhook/inactive
```

**Endpoint para Inativar um Webhook**  
Este endpoint permite inativar o webhook, caso informado `ResellerDocument` será inativado para o revendedor correspondente e portanto, **não** receberá notificações que estejam vinculados ao mesmo. **É necessário estar autenticado para realizar a requisição.**

- Essa requisição possui em corpo (_Request Body_) os seguintes valores:
    
    - **`'ResellerDocument'`** **-** [OPICIONAL] Número do documento do Revendedor (sem pontuação);
        
        - **OBS:** Caso seja informado o documento de revendedor será cadastrado e apenas notificado quando houver movimentações vinculadas a esta persona.
        
    - **`'Type'`** - Tipo do webhook que será inativado;
        
        - **mentmerchantAccreditation**: Credenciamento do lojista
            
        - **transaction**: Transações
            
        
    
- Incluir também os cabeçalhos `'Authorization'`no formato _Bearer_ e '`accept'`com o valor `application/json` ;
    

A resposta será um JSON contendo os detalhes do webhook cadastrado. Consulte os exemplos para entender a estrutura de sucesso ou erro.

```json
{
    "ResellerDocument": "{resellerDocument}", // (string) Documento do Revendedor (sem pontuação)
    "Type": "merchantAccreditation" // (string) [required] Tipo de webhook (merchantAccreditation: Credenciamento do lojista | transaction: Transações)
}
```
