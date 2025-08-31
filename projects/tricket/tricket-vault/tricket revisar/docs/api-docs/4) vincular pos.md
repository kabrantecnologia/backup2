
### PATCH Cadastrar Lojista
```
https://{base_url}/pos/device/{id}/bind
```

**Este** _**endpoint**_ **é utilizado para vincular um dispositivo POS a um lojista. Esta ação associa o dispositivo POS específico a um lojista específico, permitindo que ele seja utilizado para transações comerciais.**

- Essa requisição possui como parâmetro de caminho (_Path Param_) o `'{id}'` do dispositivo POS a ser vinculado - obrigatório;
    
- E possui como parâmetros que compõem o corpo da requisição (_Request Body_), os valores:
    
    - `'resellerDocument'` - documento do revendedor associado ao lojista - obrigatório;
        
    - `'merchantDocument'`- documento do lojista ao qual o POS será vinculado - obrigatório;
        
    
- Incluir os cabeçalhos `'Authorization'`no formato _Bearer_ e '`accept'`com o valor `application/json` ;
    

A resposta da requisição retornará o _token_ gerado após a vinculação do dispositivo POS. Este _token_ pode ser utilizado para futuras autenticações ou validações. Em caso de insucesso, será retornada uma mensagem com o respectivo erro.

```json
{
    "resellerDocument": "{resellerDocument}", // (string)[required] Documento do Revendedor
    "merchantDocument": "{merchantDocument}" // (string)[required] Documento do Lojista
}
```
