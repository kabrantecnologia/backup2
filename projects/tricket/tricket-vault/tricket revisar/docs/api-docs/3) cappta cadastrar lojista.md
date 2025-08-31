
### POST Cadastrar Lojista
```
https://{base_url}/onboarding/merchant
```

Este endpoint é utilizado para cadastrar um novo lojista no sistema. O credenciamento é necessário para criar e adicionar produtos para os lojistas. Além disso, este recurso também é utilizado para conhece-los através da análise de risco. Após estarem devidamente cadastrados, poderão transacionar e utilizar os serviços oferecidos. O cadastro do lojista inclui informações detalhadas sobre a empresa, o responsável, o endereço e a conta bancária.

- Adicionar os parâmetros de corpo da requisição (_Request Body_) obrigatórios e opcionais conforme observado no exemplo ao lado;
    
- Incluir também os cabeçalhos `'Authorization'`no formato _Bearer,_ '`accept'`com o valor `application/json` e `content-type` com o valor `application/json`;

**Após o cadastro, o sistema retorna o** _**status**_ **do lojista indicando se ele foi habilitado, se está em processamento ou se houve algum erro.**

Possiveís valores de _status_:

- **Enabled (1):** O lojista está habilitado.
    
- **Processing (2):** O cadastro do lojista está em processamento.
    
- **InvalidBank (3):** Informações bancárias inválidas.
    
- **Disabled (4):** O lojista está desabilitado.
    
- **AnalyzingRisk (5):** O cadastro do lojista está em análise de risco.
    
- **Error (99):** Houve um erro no cadastro do lojista.

```json
curl --location -g 'https://{base_url}/onboarding/merchant' \
--data-raw '{
  "resellerDocument": "46946632000143",
  "bankAccount": {
    "account": "123456",
    "bankCode": "197",
    "branch": "0001",
    "accountType": 1
  },
  "merchant": {
    "document": "63314931000184",
    "companyName": "Empresa",
    "tradingName": "Empresa",
    "mccId": 1520,
    "legalNatureId": 2,
    "TpvExpected": 10000
  },
  "owner": {
    "name": "teste apenas",
    "gender": "female",
    "email": "exemplo@empresa.com",
    "phone": "00123451234",
    "cpf": "86126469011",
    "birthday": "1990-01-01"
  },
  "address": {
    "postalCode": "05425070",
    "streetName": "Av. Dra. Ruth Cardoso",
    "houseNumber": "7221",
    "complement": "Estação Pinheiros",
    "neighborhood": "Pinheiros",
    "city": "São Paulo",
    "State": "SP"
  },
  "planId": 512
}
```
