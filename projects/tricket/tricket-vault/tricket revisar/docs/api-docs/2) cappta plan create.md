### POST Criar Plano
```
https://{base_url}/plan
```

**Este** _**endpoint**_ **é utilizado para cadastrar os planos que deverão estar associados a cada estabelecimento comercial. Portanto,** **é necessário especificar todas as taxas por bandeira. Cada bandeira tem suas próprias taxas e, ao inserir as taxas, estas serão utilizadas como parâmetros de comparação para validação.**

**Informações importantes:**

- O nome do plano deve ser único;
    
- Todo novo plano precisa de um plano base (que já está cadastrado e pode ser consultado);
    
- Os planos bases (divididos por produto e prazo de antecipação) são gerados no seu cadastro e podem ser acessados pelo _endpoint_ de consulta;
    
- O produto e o prazo de antecipação devem ser especificados, caso sejam divergentes do plano base, um erro será apresentado;
    
- O campo `'schemes'`representa um arranjo de pagamento (Tipo de pagamento + Bandeira) e o Id de cada um deles são fornecidos pelo _endpoint_ **OPTIONS**;
    
- Todas as taxas por bandeiras devem ser informadas. Na ausência de alguma, um erro será apresentado;
    
- As taxas são do tipo _decimal_, ou seja, é possível informar por exemplo: 1.90(1.90%) ou 2(2%);
    
- (deprecated) O plano base é consultado automaticamente no cadastro. ~~Para criar uma tabela para do tipo Merchant, é necessário criar uma do tipo Reseller antes e utilizá-la como base 'basePlanId';~~
    
- Incluir todos os parâmetros obrigatórios que compõem o corpo dessa requisição (_Request Body_), conforme observado no exemplo ao lado;
    
- Incluir também os cabeçalhos `'Authorization'`no formato _Bearer,_ '`accept'`com o valor `application/json` e `'content-type'` com o valor `application/json;`
    

🚧 **Plano base:** Para preencher o campo `'basePlanId'` basta consultar os planos e pegar o `Id` do plano cadastrado com o valor `'Partner'` do campo `'type'.`

A resposta da requisição retornará o id do plano criado indicando que a operação de cadastro foi realizada com sucesso. Ou em caso de falha, o erro ocorrido.


```json
{
    "Name": "Teste EC 1.0", // (string)[required] Nome do plano
    "product": "POS", // (string)[required] produto associado ao plano
    "type": "Merchant", // (string)[required] Reseller|Merchant 
    // (deprecated) o valor é buscado de forma automatica "basePlanId": , // (string)[required] Identificador único do plano base
    "resellerDocument": "documentoRevendedor", // (string)[optional] Documento do Revendedor
    "settlementDays": 1, // (string)[required] Dias de liquidação
    "schemes": [  // arranjo de pagamento (Tipo de pagamento + Bandeira) - id obtido pelo endpoint OPTIONS
        {
            "id": 2, // Id da bandeira obtido pelo endpoint OPTIONS
            "fees": [ // taxas
                {
                    "installments": 1, // Numero da Parcela (PIX e débito possuem apenas a parcela 1)
                    "rate": 2 // Percentual da taxa a ser cobrada
                }
            ]
        },
        {
            "id": 4,
            "fees": [
                {
                    "installments": 1,
                    "rate": 2
                }
            ]
        },
        {
            "id": 6,
            "fees": [
                {
                    "installments": 1,
                    "rate": 5
                },
                {
                    "installments": 2,
                    "rate": 6
                },
                {
                    "installments": 3,
                    "rate": 7
                },
                {
                    "installments": 4,
                    "rate": 8
                },
                {
                    "installments": 5,
                    "rate": 9
                },
                {
                    "installments": 6,
                    "rate": 10
                },
                {
                    "installments": 7,
                    "rate": 11
                },
                {
                    "installments": 8,
                    "rate": 12
                },
                {
                    "installments": 9,
                    "rate": 13
                },
                {
                    "installments": 10,
                    "rate": 14
                },
                {
                    "installments": 11,
                    "rate": 15
                },
                {
                    "installments": 12,
                    "rate": 16
                },
                {
                    "installments": 13,
                    "rate": 17
                },
                {
                    "installments": 14,
                    "rate": 18
                },
                {
                    "installments": 15,
                    "rate": 19
                },
                {
                    "installments": 16,
                    "rate": 20
                },
                {
                    "installments": 17,
                    "rate": 21
                },
                {
                    "installments": 18,
                    "rate": 22
                }
            ]
        },
        {
            "id": 7,
            "fees": [
                {
                    "installments": 1,
                    "rate": 4
                },
                {
                    "installments": 2,
                    "rate": 6
                },
                {
                    "installments": 3,
                    "rate": 7
                },
                {
                    "installments": 4,
                    "rate": 8
                },
                {
                    "installments": 5,
                    "rate": 9
                },
                {
                    "installments": 6,
                    "rate": 10
                },
                {
                    "installments": 7,
                    "rate": 11
                },
                {
                    "installments": 8,
                    "rate": 12
                },
                {
                    "installments": 9,
                    "rate": 13
                },
                {
                    "installments": 10,
                    "rate": 14
                },
                {
                    "installments": 11,
                    "rate": 15
                },
                {
                    "installments": 12,
                    "rate": 16
                },
                {
                    "installments": 13,
                    "rate": 17
                },
                {
                    "installments": 14,
                    "rate": 18
                },
                {
                    "installments": 15,
                    "rate": 19
                },
                {
                    "installments": 16,
                    "rate": 20
                },
                {
                    "installments": 17,
                    "rate": 20
                },
                {
                    "installments": 18,
                    "rate": 21
                }
            ]
        },
        {
            "id": 8,
            "fees": [
                {
                    "installments": 1,
                    "rate": 7
                },
                {
                    "installments": 2,
                    "rate": 8
                },
                {
                    "installments": 3,
                    "rate": 9
                },
                {
                    "installments": 4,
                    "rate": 10
                },
                {
                    "installments": 5,
                    "rate": 11
                },
                {
                    "installments": 6,
                    "rate": 12
                },
                {
                    "installments": 7,
                    "rate": 12
                },
                {
                    "installments": 8,
                    "rate": 13
                },
                {
                    "installments": 9,
                    "rate": 14
                },
                {
                    "installments": 10,
                    "rate": 15
                },
                {
                    "installments": 11,
                    "rate": 16
                },
                {
                    "installments": 12,
                    "rate": 17
                },
                {
                    "installments": 13,
                    "rate": 17
                },
                {
                    "installments": 14,
                    "rate": 18
                },
                {
                    "installments": 15,
                    "rate": 19
                },
                {
                    "installments": 16,
                    "rate": 20
                },
                {
                    "installments": 17,
                    "rate": 21
                },
                {
                    "installments": 18,
                    "rate": 22
                }
            ]
        },
        {
            "id": 9,
            "fees": [
                {
                    "installments": 1,
                    "rate": 4
                },
                {
                    "installments": 2,
                    "rate": 7
                },
                {
                    "installments": 3,
                    "rate": 7
                },
                {
                    "installments": 4,
                    "rate": 8
                },
                {
                    "installments": 5,
                    "rate": 9
                },
                {
                    "installments": 6,
                    "rate": 10
                },
                {
                    "installments": 7,
                    "rate": 11
                },
                {
                    "installments": 8,
                    "rate": 12
                },
                {
                    "installments": 9,
                    "rate": 13
                },
                {
                    "installments": 10,
                    "rate": 14
                },
                {
                    "installments": 11,
                    "rate": 15
                },
                {
                    "installments": 12,
                    "rate": 16
                },
                {
                    "installments": 13,
                    "rate": 17
                },
                {
                    "installments": 14,
                    "rate": 18
                },
                {
                    "installments": 15,
                    "rate": 19
                },
                {
                    "installments": 16,
                    "rate": 20
                },
                {
                    "installments": 17,
                    "rate": 21
                },
                {
                    "installments": 18,
                    "rate": 22
                }
            ]
        },
        {
            "id": 10,
            "fees": [
                {
                    "installments": 1,
                    "rate": 5
                },
                {
                    "installments": 2,
                    "rate": 7
                },
                {
                    "installments": 3,
                    "rate": 8
                },
                {
                    "installments": 4,
                    "rate": 9
                },
                {
                    "installments": 5,
                    "rate": 10
                },
                {
                    "installments": 6,
                    "rate": 11
                },
                {
                    "installments": 7,
                    "rate": 12
                },
                {
                    "installments": 8,
                    "rate": 13
                },
                {
                    "installments": 9,
                    "rate": 14
                },
                {
                    "installments": 10,
                    "rate": 15
                },
                {
                    "installments": 11,
                    "rate": 16
                },
                {
                    "installments": 12,
                    "rate": 17
                },
                {
                    "installments": 13,
                    "rate": 18
                },
                {
                    "installments": 14,
                    "rate": 19
                },
                {
                    "installments": 15,
                    "rate": 20
                },
                {
                    "installments": 16,
                    "rate": 21
                },
                {
                    "installments": 17,
                    "rate": 22
                },
                {
                    "installments": 18,
                    "rate": 23
                }
            ]
        },
        {
            "id": 5,
            "fees": [
                {
                    "installments": 1,
                    "rate": 6
                }
            ]
        }
    ]
}
``` 
