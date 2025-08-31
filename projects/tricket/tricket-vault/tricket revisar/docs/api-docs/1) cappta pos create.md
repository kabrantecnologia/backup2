### POST Cadastrar POS
```
https://{base_url}/pos/device
```


**Este** _**endpoint**_ **é utilizado para cadastrar um novo dispositivo POS no sistema. O cadastro de um POS inclui informações como o documento do revendedor, chave serial do dispositivo e o modelo do dispositivo.**

- Essa requisição possui como parâmetros compõem o corpo da requisição (_Request Body_), os valores:
    
    - `'resellerDocument'` - Documento do revendedor associado à POS - obrigatório;
        
    - `'serialKey'` - Chave serial da POS - obrigatório;
        
    - `'modelId'` - Identificador do modelo da POS - obrigatório;
        
    - `'keys'` - Chaves adicionais para configuração do dispositivo - opcional;
        
    
- Incluir os cabeçalhos `'Authorization'`no formato _Bearer_ e '`accept'`com o valor `application/json` ;
    

A resposta da requisição devolverá o `'id'` da POS cadastrada, ou erro em caso de insucesso.

```json
{
    "resellerDocument": "{resellerDocument}", // (string)[required] Documento do Revendedor
    "serialKey": "", // (string)[required] código serial da POS
    "modelId":  // (int32) [required] Identificador único do moedelo de POS
}
```
