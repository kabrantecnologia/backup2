---
id: 1ftUjUW14PH5p7iX55mWUMvYpzldsCfMUMhaEzz2PG2I
status: 
version: 1
source: NotebookLM
type: task
action: create
space: Projetos
folder: Tricket
list: Marketplace
parent_id: 
created: 2025-07-08 09:01
due_date: ""
start_date: 
tags:
  - projetos/tricket
summary: 
path: /home/joaohenrique/Obsidian/01-PROJETOS/tricket-revisar
---



# Manual de Uso da API Verified by GS1 R1.2

## VISÃO GERAL

O objetivo desta documentação é orientar o usuário sobre como integrar seus APPs com a API Verified by GS1.

Serão descritas as funcionalidades, os métodos a serem utilizados, listando informações a serem enviadas e recebidas, disponibilizando exemplos que facilitem a sua utilização pelo usuário.

A integração é realizada através de serviços disponibilizados como API. As URLs receberão as mensagens HTTPS através do método GET e POST.

- **POST:** O método POST será utilizado para obter o token de autenticação.
    
- **GET:** O método GET é utilizado para consultas de recursos já existentes, por exemplo, consulta de produtos.
    

Para autenticação e autorização utiliza-se o padrão Oauth 2.0 com o objetivo de garantir a segurança das informações mantidas na GS1 Brasil.

## ÍNDICE

1. CADASTRO DA EMPRESA
    
2. GERAÇÃO DO APP (CLIENT_ID E CLIENT_SECRET)
    
3. GERAÇÃO DE ACCESS TOKEN
    
4. CONSULTA
    
5. TABELAS DE REFERÊNCIA
    
    5.1. TABELA DE PADRÕES DE IDENTIFICAÇÃO
    
    5.2. TABELA DE ATRIBUTOS DE VERIFICAÇÃO
    
    5.3. TABELA DE ATRIBUTOS INTERNACIONAIS
    
    5.4. TABELA DE ATRIBUTOS NACIONAIS
    
    5.5. TABELA DE CÓDIGOS DE ERRO
    
6. TABELAS DE TIPOS DE DADOS
    
    6.1. UNIDADE DE MEDIDA - VOLUME, ÁREA E CONTAGEM
    
    6.2. UNIDADE DE MEDIDA - MASSA
    
    6.3. UNIDADE DE MEDIDA - DIMENSÕES
    
    6.4. UNIDADE DE MEDIDA - TEMPERATURA
    
    6.5. UNIDADE DE MEDIDA - ENERGIA
    
7. Perfis de Consulta
    
    7.1. Verificação
    
    7.2. Verificação + Dados Nacionais
    
    7.3. Verificação + Dados Internacionais
    
    7.4. Atributos Nacionais + Atributos Internacionais
    
8. CONTROLE DE REVISÕES
    

## API Verified by GS1

Para acesso à API Verified by GS1, será necessário concluir quatro etapas, sendo elas:

1. ACEITE DO TERMO DE USO
    
2. CADASTRO DA EMPRESA
    
3. CRIAÇÃO DE APP
    
4. GERAÇÃO DE ACCESS TOKEN
    

**Atenção:** As QUATRO ETAPAS DEVEM SER CONCLUÍDAS para que o usuário tenha acesso às consultas.

Abaixo cada uma das etapas serão detalhadas a fim de auxiliá-lo.

### 1. ACEITE DO TERMO DE USO

O primeiro passo é aceitar os termos de uso da API que ficarão disponíveis no primeiro acesso à plataforma Verified by GS1, acessível através do link:

[https://verifiedbygs1.gs1br.org/](https://verifiedbygs1.gs1br.org/ "null")

**PASSO A PASSO PARA ACEITE DO TERMO:**

1.1. Acesse o link acima em seu navegador e faça o login com o mesmo usuário do Cadastro Nacional de Produtos, caso não tenha usuário clique em “Não tenho acesso ao Verified by GS1".

1.2. Será apresentado um pop up com os meios de contato com a GS1 para solicitar acesso ao Verified by GS1.

**Atenção:** É necessário que o usuário cadastrado aceite o termo de uso, se não o fizer, não terá acesso futuro à consulta por API.

### 2. CADASTRO DA EMPRESA

A etapa seguinte é a realização de seu cadastro na plataforma de gestão de acessos à API da GS1 Brasil, esse cadastro deverá ser realizado no seguinte link:

[https://apicnp.gs1br.org/api-portal/](https://apicnp.gs1br.org/api-portal/ "null")

**PASSO A PASSO PARA CADASTRAR:**

2.1. Acesse o link acima em seu navegador.

2.2. Ao acessar a plataforma clique na opção Login, terceira opção dos cartões centrais.

2.3. Clique em Primeiro Acesso e preencha o formulário com as informações solicitadas.

2.4. Após o preenchimento e finalização do cadastro será enviado um e-mail de confirmação.

**Atenção:** É necessário que o usuário cadastrado seja um colaborador de uma empresa associada à GS1 Brasil (solicitante da API).

### 3. GERAÇÃO DO APP (CLIENT_ID E CLIENT_SECRET):

Após a conclusão da ETAPA 2 - CADASTRO DA EMPRESA, será possível gerar o seu APP, onde serão disponibilizados um Client_ID e Client_Secret para a autenticação com o sistema GS1 Brasil.

**PASSO A PASSO PARA GERAÇÃO DO APP:**

3.1. Após realizar seu cadastro na aba Primeiro Acesso, realize o login no mesmo link ([https://apicnp.gs1br.org](https://apicnp.gs1br.org/ "null")) clicando no cartão Login e a seguir na aba Entrar com as credenciais recebidas em seu e-mail.

3.2. Acesse no menu Dev Tools no rodapé a opção APPS.

3.3. Clique em Cadastrar Nova App.

3.4. Preencha os itens:

A. NOME DO APP

B. DESCRIÇÃO DO APP

C. Habilite a opção API OAUTH 2.0 e clique em REGISTRAR

3.5. Após a conclusão do registro, ainda na aba Dev Tools → Apps, será possível ver o APP que foi criado. Nele você poderá ter acesso ao seu CLIENT ID e CLIENT SECRET, que serão utilizados na autenticação para obtenção do Access Token na Etapa 4 - GERAÇÃO DE ACCESS TOKEN.

3.6. Após concluir o cadastro do APP, preencha o formulário: Liberação API VbG, para que a GS1 Brasil possa realizar a disponibilização do acesso necessário, para que você possa gerar seu ACCESS TOKEN, conforme a Etapa 3 GERAÇÃO DE ACCESS TOKEN a ser descrita.

O SLA para essa disponibilização de acesso por parte da GS1 Brasil é de 2 dias úteis.

**Atenção:**

1. Os nomes informados no exemplo são meramente ilustrativos. Orientamos que sejam cadastradas as próprias informações do APP da empresa.
    
2. Apesar do status estar com a mensagem "APROVADA", não será possível realizar consultas até que seja finalizado o processo de autorização do perfil do solicitante pela GS1 Brasil, que será enviado para o e-mail cadastrado, informando a liberação.
    

### 4. GERAÇÃO DE ACCESS TOKEN

Após liberação do APP pela GS1 Brasil na Etapa 2 - GERAÇÃO DO APP, será possível iniciar a consulta de dados. Para consumir os serviços é necessário gerar um token de acesso.

Para isso, é necessário fazer uma requisição através do método POST para o serviço `oauth/access-token` usando:

- Autorização Basic no HEADER
    
- Client_ID como usuário
    
- Client_Secret como senha
    

O campo `access_token` será usado nas demais chamadas ao serviço no header da requisição.

**REQUISIÇÃO:**

|   |   |
|---|---|
|**URL**|**https://api.gs1br.org/oauth/access-token**|
|Método da Requisição|`POST`|
|Basic-Auth||

**Headers:**

|   |   |
|---|---|
|**Header**|**Valor**|
|Authorization|Username: `Client_ID`|
||Password: `Client_Secret`|
|Content-type|`application/json`|

**Exemplo de Body:**

```
{
  "grant_type": "password",
  "username": "seu email cnp ou verified by gsl",
  "password": "sua_senha_cnp_ou_verified_by_gs1"
}
```

**Exemplo de Retorno:**

```
{
  "access_token": "d1f9846a-aldb-4366-8294-99b5c1a7f006",
  "refresh_token": "fb96993a-acbf-4f0a-8c70-ff68c785eb69",
  "token_type": "access token",
  "expires_in": 10800
}
```

**EXEMPLO DE GERAÇÃO DE TOKEN UTILIZANDO A PLATAFORMA POSTMAN (**[**https://www.postman.com/**](https://www.postman.com/ "null")**):**

3.1. Crie uma HTTP REQUEST utilizando o método POST inserindo a URL: `https://api.gs1br.org/oauth/access-token`

3.2. Na aba Authorization selecione o Type como Basic Auth, em Username insira seu Client Id (Obtido na Etapa 3 GERAÇÃO DO APP) e em Password insira seu Client Secret (Obtido na Etapa 3 - GERAÇÃO DO APP).

3.3. Na aba Headers inclua respectivamente: * `Content-Type`: `application/json` * `client_id`: seu client id (Obtido na Etapa 3 GERAÇÃO DO APP)

3.4. Na aba Body insira o exemplo de body abaixo, com suas credenciais e clique em Send para enviar a requisição.

**Atenção:**

Se receber a mensagem abaixo:

Mensagem: "It was not possible to validate user's credentials or connect to the specified URL."

Significa que o usuário e/ou senha utilizados não são os mesmos do Cadastro Nacional de Produtos e/ou Verified by GS1. Saiba mais na Etapa GERAÇÃO DO APP.

Após autenticação você poderá utilizar o access token pelo período de 3 horas. O refresh token também pode ser utilizado pelo mesmo período.

### 5. CONSULTA

Após a autenticação na Etapa 4 - GERAÇÃO DE ACCESS TOKEN, para realizar consultas é necessário fazer a request através do método GET com alguns parâmetros na URL e no HEADER.

Na URL é necessário inserir o GTIN da consulta e no HEADER deverá ser inserido os campos Authorization e Content-Type conforme a tabela abaixo.

**Requisição:**

|                      |                                                                                                     |
| -------------------- | --------------------------------------------------------------------------------------------------- |
| **Parâmetro**        | **Detalhe**                                                                                         |
| URL                  | `https://api.gs1br.org/provider/v2/verified?gtin={{GTIN}}`                                          |
| GTIN                 | GTIN do produto consultado - Possível realizar a consulta de códigos GTIN-8/GTIN-12/GTIN-13/GTIN-14 |
| MÉTODO DA REQUISIÇÃO | `GET`                                                                                               |
| HEADERS              | Parâmetro obtido na Etapa 2 - GERAÇÃO DO APP: `Client_Id`                                           |
|                      | Parâmetro obtido na Etapa 3 GERAÇÃO DE ACCESS TOKEN: `Access_Token`                                 |

**CURL:**

```
curl --location --request GET 'https://api.gs1br.org/provider/v2/verified?gtin={GTIN}' \
--header 'client_id: seu_client_id' \
--header 'access_token: seu_access_token'\
--data-raw ''
```

**EXEMPLO REQUISIÇÃO PYTHON:**

```
import requests
import json
import pandas as pd

url = 'https://api.gs1br.org/provider/v2/verified'
headers = {
    'client_id': 'seu_client_id',
    'access_token': 'seu_access_token'
}

query = {
    'gtin': gtin_que_será_consultado
}

r = requests.get(url, headers=headers, params=query)
r.json()
```

**EXEMPLO REQUISIÇÃO JAVASCRIPT:**

```
function getGTIN(gtin) {
  var key = "seu_client_id";
  var key2 = "seu_access_token";
  var url_api = "https://api-hml.gs1br.org/provider/v2/verified?gtin=";
  var url = url_api.concat(gtin);
  console.log(httpGet(url, key, key2));
}

function httpGet(url, key, key2, gtin) {
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.open("GET", url, false);
  xmlHttp.setRequestHeader("client_id", key);
  xmlHttp.setRequestHeader("access_token", key2);
  xmlHttp.send(null);
  return xmlHttp.responseText;
}

getGTIN(gtin_que_sera_consultado);
```

**EXEMPLO REQUISIÇÃO C#:**

```
// Necessário instalar o pacote microsoft.aspnet.webapi.client
using System;
using System.Net.Http.Headers;
using System.Text;
using System.Net.Http;
using System.Web;
using System.IO;

namespace CSHttpClientSample
{
    static class Program
    {
        static void Main()
        {
            MakeRequest();
            Console.ReadLine();
        }

        static async void MakeRequest()
        {
            var client = new HttpClient();
            client.DefaultRequestHeaders.CacheControl = CacheControlHeaderValue.Parse("no-cache");
            client.DefaultRequestHeaders.Add("Client_Id", "seu_client_id");
            client.DefaultRequestHeaders.Add("Access_Token", "seu_access_token");

            var uri = "https://api-hml.gs1br.org/provider/v2/verified?gtin={GTIN}";

            HttpResponseMessage response;
            response = await client.GetAsync(uri); //, content

            Console.WriteLine(await response.Content.ReadAsStringAsync());
        }
    }
}
```

Dependendo da tecnologia que for utilizar pode ser necessário escrever o parametro Authorization usando base64, no seguinte formato: `"Authorization: Basic SEU_CLIENT_ID_:_SECRET_EM_BASE64"`, para isso você pode usar o site: "[https://www.base64encode.org](https://www.base64encode.org/ "null")" (Deixar a opção UTF-8 e LF(Unix) por default selecionadas).

**Códigos de Retorno:**

|   |   |
|---|---|
|**CÓDIGO**|**DESCRIÇÃO**|
|200|Sucesso|
|400|A requisição é inválida|
|403|Usuário proibido de acessar a URL|
|404|Produto não encontrado|
|500|Erro interno|

### 6. TABELAS DE REFERÊNCIA

#### 5.1. TABELA DE PADRÕES DE IDENTIFICAÇÃO:

|   |   |
|---|---|
|**PADRÃO**|**REFERÊNCIA**|
|GTIN|GTIN- Identificação de Produtos (gs1br.org)|
|GLN|GLN Identificação de Locais (qs1br.org)|
|SSCC|SSCC Identificação de Unidades Logisticas (qs1br.org)|
|GSIN|GSIN - Número global de identificação da carga (gs1br.org)|
|GINC|GINC - Número global de identificação de consignação (gs1br.org)|
|GRAI|GRAI Identificador global de ativo retornável (qs1br.org)|
|GIAI|GIAI Identificador global de ativo individual (qs1br.org)|
|GSRN|GSRN- Número global da relação de serviço (gs1br.org)|
|GDTI|GDTI Identificador global do tipo de documento (qs1br.org)|
|GCN|GCN- Número de cupom global (gs1br.org)|
|GMN|GMN- Número do modelo global (gs1br.org)|

#### 5.2. TABELA DE ATRIBUTOS DE VERIFICAÇÃO

|   |   |
|---|---|
|**NOME DO NEGÓCIO**|**DESCRIÇÃO ATRIBUTO**|
|Estrutura do GTIN|`gs1Licence.licenceType` - Estrutura do atributo GTIN - GCP: segue estrutura de GTIN-12 e/ou GTIN-13; GTIN-8: segue estrutura de GTIN-8|
|Nome da Empresa|`gs1Licence.licenseeName` - Nome da Empresa Cadastrada com a GS1|
|GLN|`gs1Licence.LicenseeGLN` - Número do GLN cadastrado para a empresa|
|GS1 responsável|`moName` - Unidade da GS1 que a empresa está associada|
|Data de Criação do GTIN|`dateCreated` - Data de criação do código GTIN|
|Data de Atualização do GTIN|`dateUpdated` - Data de atualização do código GTIN|
|Código de Retorno da API|`returnCode` - Código de retorno do status da requisição da API|
|Descrição do Código de Retorno da API|`returnCodeDescription` - Descrição do código de retorno de status da requisição da API|

#### 5.3. TABELA DE ATRIBUTOS INTERNACIONAIS:

|   |   |   |
|---|---|---|
|**NOME DO NEGÓCIO**|**ATRIBUTO**|**DESCRIÇÃO**|
|GTIN - Número Global do Item Comercial|`gtin`|Número de Identificação do produto GTIN - Global Trade Item Number|
|GPC - Classificação Global de Produtos|`gpcCategoryCode`|Deve conter um código de 8 dígitos. Domínio: [https://www.gs1.org/services/gpc-browser](https://www.gs1.org/services/gpc-browser "null")|
|Marca|`brandName`|Descrição da Marca do Produto|
|Descrição do produto|`productDescription`|Descrição do produto|
|Imagem do produto (URL)|`productImageUrl`|URL com o conteúdo da imagem|
|Conteúdo Líquido|`netContent`|Valor do conteúdo líquido|
|País de venda|`countryOfSaleCode`|País onde o produto é vendido|
|Status do produto|`gtinRecordStatus`|Status do produto: `INACTIVE`, `DISCONTINUED`, Retornará vazio para `ACTIVE`|

#### 5.4. TABELA DE ATRIBUTOS NACIONAIS:

|   |   |   |
|---|---|---|
|**NOME DO NEGÓCIO**|**ATRIBUTO**|**DESCRIÇÃO**|
|Tipo do GTIN|`gs1TradeItemIdentificationKeyCode`|Tipo GTIN do produto, pode ser GTIN-8, GTIN-12, GTIN-13 ou GTIN-14|
|GTIN - Número Global do Item Comercial|`gtin`|Número de Identificação do produto GTIN|
|Descrição|`tradeItemDescription`|Descrição do produto|
|Descrição adicional|`additionalTradeItemDescription`|Descrição do produto cadastrado com outro idioma|
|GTIN Contido GTIN|`childTradeItems`|Para produtos que possuem outros produtos (GTIN) em sua composição, recebe os GTIN dos itens|
|GTIN Contido Quantidade|`quantityOfNextLowerLevelTradeItem`|Quantidade de itens dos GTIN na composição do produto|
|GTIN Origem|`childTradeItems (gtin)`|GTIN-8, GTIN-12 ou GTIN-13 vinculado ao GTIN-14. _Campo disponível apenas para o código GTIN-14_|
|Quantidade de itens na caixa|`quantityOfNextLowerLevelTradeItem`|Quantidade de códigos GTIN-8, GTIN-12 ou GTIN-13 vinculado ao GTIN-14. _Campo disponível apenas para o código GTIN-14_|
|Imagens do produto, Websites e link disponíveis online - Descrição|`referencedFileInformations.contentDescription`|Descrição da imagem|
|Imagens do produto, Websites e link disponíveis online - URL|`referencedFileInformations.uniformResourceIdentifier`|URL com o conteúdo da imagem|
|FLAG - Imagem de destaque|`referencedFileInformations.featuredFile`|Informação se é a imagem de destaque do produto|
|Imagens do produto, Websites e link disponíveis online - Tipo|`referencedFileInformations.referencedFileTypeCode`|`PRODUCT_IMAGE` (Foto do produto), `OUT_OF_PACKAGE_IMAGE` (Imagem do produto fora da embalagem), `PLANOGRAM` (Planogram), `PRODUCT_LABEL_IMAGE` (Rótulo do produto), `ZOOM_VIEW` (Detalhe do produto), `INTERNAL_VIEW` (Imagem interna do produto), `LOGO` (Logo/Marca)|
|Marca|`brandName`|Tamanho maior que 0 e menor ou igual a 70 caracteres.|
|Idioma da Marca|`languageCode`|Idioma da Marca do produto. Para consultar todas as siglas: [https://www.gs1br.org/educacao-e-pratica/Documents/001APIReferenciaIdioma.xlsx](https://www.gs1br.org/educacao-e-pratica/Documents/001APIReferenciaIdioma.xlsx "null")|
|Peso Bruto|`tradeItemWeight.grossWeight.value`|Edição permite mudança de até 20% de variação do primeiro valor declarado. Deve ser maior ou igual ao Peso Líquido.|
|Unidade de Medida do Peso Bruto|`tradeItemWeight.grossWeight.measurementUnitCode`|Para consultar os dados os valores disponíveis em: Tabela 6|
|Peso Líquido|`tradeItemWeight.netWeight.value`|Valor do peso líquido do produto|
|Unidade de Medida do Peso Líquido|`tradeItemWeight.netWeight.measurementUnitCode`|Valores disponíveis em: Tabela 6|
|Conteúdo Líquido|`tradeItemMeasurements.netContent.value`|Valor do conteúdo líquido|
|Unidade de Medida do Conteúdo Líquido|`tradeItemMeasurements.measurementUnitCode`|Valores disponíveis em: Tabela 6|
|Altura do produto|`tradeItemMeasurements.netContent.value`|Valor da altura do produto|
|Unidade de Medida da Altura|`tradeItemMeasurements.measurementUnitCode`|Valores disponíveis em: Tabela 6|
|Largura do produto|`tradeItemMeasurements.netContent.value`|Valor da largura do produto|
|Unidade de Medida da Largura|`tradeItemMeasurements.measurementUnitCode`|Valores disponíveis em: Tabela 6|
|Profundidade do produto|`tradeItemMeasurements.netContent.value`|Valor da profundidade do produto|
|Unidade de Medida da Profundidade|`tradeItemMeasurements.measurementUnitCode`|Valores disponíveis em: Tabela 6|
|Tipo de Classificação do Produto|`tradeItemClassification.additionalTradeItemClassifications.additionalTradeItemClassificationSystemCode`|Trata-se da Nomenclatura Comum do Mercosul (NCM). Obrigatório para todos os produtos.|
|Valor da Classificação do Produto|`tradeItemClassification.additionalTradeItemClassifications.additionalTradeItemClassificationCodeValue`|Número do NCM. Código de 8 dígitos, somente números, formato 0000.00.00.|
|Tipo de Classificação do Produto|`tradeItemClassification.additionalTradeItemClassifications.additionalTradeItemClassificationSystemCode`|CEST - Código Especificador da Substituição Tributária. Pode conter mais de um CEST.|
|Valor da Classificação do Produto|`tradeItemClassification.additionalTradeItemClassifications.additionalTradeItemClassificationCodeValue`|Número do CEST. Código de 7 dígitos, somente números, formato 00.000.00.|
|GPC Classificação Global do Produto|`tradeItemClassification.gpcCategoryCode`|Deve conter um código de 8 dígitos. Domínio: [https://www.gs1.org/services/gpc-browser](https://www.gs1.org/services/gpc-browser "null")|
|Tipo de Produto|`tradeItemUnitDescriptorCode`|Admite os valores: `PALLET`, `PACK_OR_INNER_PACK`, `DISPLAY_SHIPPER`, `CASE`, `BASE_UNIT_OR_EACH`|
|Status de Sincronização CCG|`syncInformationCCG`|`True`: Produto sincronizado com o Cadastro Centralizado de GTIN; `False`: Produto não sincronizado com o Cadastro Centralizado de GTIN|

#### 5.5. TABELA DE CÓDIGOS DE ERRO

|   |   |
|---|---|
|**CÓDIGO DO ERRO**|**DESCRIÇÃO**|
|E001|Tamanho do GTIN inválido|
|E002|Dígito verificador inválido. Link para verificação de dígito verificador: [https://www.gs1.org/services/check-digit-calculator](https://www.gs1.org/services/check-digit-calculator "null")|
|E003|Contém caracteres inválidos / Tamanho do código fora do range permitido|
|E004|GTIN incorreto: Este código GTIN não existe na base GS1|
|E005|GTIN inválido: GTIN alocado para usos internos|
|E007|Código GTIN não identificado na base global|
|E008|Tamanho do GTIN inválido|
|E013|Formato da URL inválido|
|E014|Formato da URL não é HTTP/HTTPS|
|E019|Parâmetros Path e Body não convergem|
|E020|Não foi possível executar a Request ou o RPC|

### 7. TABELAS DE TIPOS DE DADOS

#### 6.1. UNIDADE DE MEDIDA – VOLUME, ÁREA E CONTAGEM

|   |   |   |
|---|---|---|
|**NOME PORTUGUÊS**|**COMMONCODE**|**SIGLA**|
|Millilitro|MLT|ml|
|Litro|LTR|l|
|Megalitro|MAL|Ml|
|Millímetro Cúbico|MMQ|mm3|
|Centímetro Cúbico|CMQ|cm3|
|Metro Cúbico|MTQ|m3|
|Conjunto|SET|conj|
|Par|PR|pr|
|Peça|H87|pç|
|Unidade|EA|un|
|Barril (EUA)|BLL|barrel (US)|
|Barril (Petróleo RU)|057|bbl (UK liq.)|
|Barril Seco (EUA)|BLD|bbl (US)|
|Batidas por Minuto|BPM|bpm|
|Becquerel|BQL|Bq|
|Bushel (EUA)|BUA|bu (US)|
|Bushel (RU)|BUI|bushel (UK)|
|Centilitro|CLT|cl|
|Centímetro Quadrado|CMK|cm2|
|Colher (EUA)|G24|Tablespoon (US)|
|Colher de Chá (EUA)|G25|Teaspoon (US)|
|Cúbico Decametre|DMA|dam³|
|Decalitro|A44|dal|
|Decilitro|DLT|dl|
|Decímetro Cúbico|DMQ|dm3|
|Decímetro Quadrado|DMK|dm2|
|Dúzia|DZN|DOZ|
|Estéreo|G26|st|
|Femtolitro|Q32|fl|
|Galão (EUA)|GLL|gal (US)|
|Galão (RU)|GLI|gal (UK)|
|Galão Seco (EUA)|GLD|dry gal (US)|
|Gigabecquerel|GBQ|GBq|
|Grau (Unidade de Angulo)|DD||
|Grosa|GRO|Gr (Contagem)|
|Hectolitro|HLT|hl|
|Hectômetro Cúbico|H19|hm3|
|Jarda Cúbica|YDQ|yd3|
|Jarda Quadrada|YDK|yd2|
|Metro Quadrado|MTK|m2|
|Microlitro|4G|μl|
|Milha Quadrada|MIK|mi2|
|Milimitro Quadrado|MMK|mm²|
|Monte (EUA)|G23|pk (US)|
|Monte (RU)|L43|pk (UK)|
|Nanolitro|Q34|nl|
|Onça Fluida (EUA)|OZA|fl oz (US)|
|Onça Fluida (RU)|OZI|fl oz (UK)|
|Pé Cúbico|FTQ|ft³|
|Pé Cúbico Padrão|5I|std|
|Pé Quadrado|FTK|ft²|
|Picolitro|Q33|pl|
|Pinta (EUA Seca)|L61|pt (US dry)|
|Pinta (EUA)|PT|pt (US)|
|Pinta (RU)|PTI|pt (UK)|
|Pinta Líquida (EUA)|PTL|liq pt (US)|
|Pinta Seca (EUA)|PTD|dry pt (US)|
|Polegada Cúbica|INQ|in³|
|Polegada Quadrada|INK|in²|
|Pontos por Polegada|E39|dpi|
|Porção|PTN|por|
|Quarto (EUA Seco)|L62|qt (US dry)|
|Quarto (EUA)|QT|qt (US)|
|Quarto (RU)|QTI|qt (UK)|
|Quarto Líquido (EUA)|QTL|liq qt (US)|
|Quarto Seco (EUA)|QTD|dry qt (US)|
|Quilobecquerel|2Q|kBq|
|Quilolitro|K6|kl|
|Quilômetro Cúbico|H20|km³|
|Unidades Formadoras de Colônia|CFU|CFU|
|Xícara [Unidade de Volume]|G21|cup (US)|

#### 6.2. UNIDADE DE MEDIDA - MASSA

|   |   |   |
|---|---|---|
|**NOME PORTUGUÊS**|**COMMONCODE**|**SIGLA**|
|Milligrama|MGM|mg|
|Grama|GRM|g|
|Quilograma|KGM|kg|
|Centigrama|CGM|cg|
|Decagrama|DJ|dag|
|Decigrama|DG|dg|
|Decitonelada|DTN|dt or dtn|
|Grama por Centímetro Cúbico|23|g/cm3|
|Grama por Litro|GL|g/I|
|Grão|GRN|gr|
|Hectograma|HGM|hg|
|Hundred Pound (Cwt) / Hundred Weight (EUA)|CWA|cwt (US)|
|Hundred Weight (RU)|CWI|cwt (UK)|
|Libra|LBR|Ib|
|Megagrama|2U|Mg|
|Micrograma|MC|μg|
|Micromole|FH|μmol|
|Milimole|C18|mmol|
|Mol|C34|mol|
|Onça (Avoirdupois)|ONZ|OZ|
|Onça Troy ou Onça de Boticário|APZ|tr oz|
|Peso Líquido Drenado em Quilos|KDW|kg/net eda|
|Quilograma de Hidróxido de Potássio (Potassa Cáustica)|KPH|kg KOH|
|Quilograma de Hidróxido de Sódio (Soda Cáustica)|KSH|kg NaOH|
|Quilograma de Metilamina|KMA|kg met.am.|
|Quilograma de Nitrogênio|KNI|kg N|
|Quilograma de Óxido de Potássio|KPO|kg K2O|
|Quilograma de Peróxido de Hidrogênio|KHY|kg H2O2|
|Quilograma de Substância 90% Seca|KSD|kg 90% sdt|
|Quilograma de Urânio|KUR|kg U|
|Quilotonelada|KTN|kt (Massa)|
|Stone (RU)|STI|st (Massa)|
|Tonelada (EUA) ou Tonelada Pequena (RU)|STN|ton (US)|
|Tonelada (RU) ou Tonelada Longa (EUA)|LTN|ton (UK)|
|Tonelada (Tonelada Métrica)|TNE|t|
|Tonelada de Peso Morto|A43|dwt|
|Unidades de Massa Atômica (AMU)|D43|amu|

#### 6.3. UNIDADE DE MEDIDA - DIMENSÕES

|   |   |   |
|---|---|---|
|**NOME PORTUGUÊS**|**COMMONCODE**|**SIGLA**|
|Millímetro|MMT|mm|
|Centímetro|CMT|cm|
|Metro|MTR|m|
|Angstrom|A11|A|
|Bitola Americana de Fios|AWG|AWG|
|Bitola Francesa|H79|Fg|
|Braça|AK|fth|
|Decâmetro|A45|dam|
|Decímetro|DMT|dm|
|Femtômetro|A71|fm|
|Hectômetro|HMT|hm|
|Jarda|YRD|yd|
|Megâmetro|MAM|Mm|
|Micrômetro (Micron)|4H|μm|
|Micropolegada|M7|uin|
|Milha (Milha Terrestre)|SMI|mile|
|Milipolegada|77|mil|
|Nanômetro|C45|nm|
|Pé|FOT|ft|
|Picômetro|C52|pm|
|Polegada|INH|in|
|Quilômetro|KTM|km|

#### 6.4. UNIDADE DE MEDIDA - TEMPERATURA

|   |   |   |
|---|---|---|
|**NOME PORTUGUÊS**|**COMMON CODE**|**SIGLA**|
|Grau Celsius|CEL|°C|
|Grau Fahrenheit|FAH|°F|
|Kelvin|KEL|K|

#### 6.5. UNIDADE DE MEDIDA - ENERGIA

|   |   |   |
|---|---|---|
|**NOME PORTUGUÊS**|**COMMONCODE**|**SIGLA**|
|Caloria (Média)|J75|cal|
|Quilocaloria (Média)|K51|kcal|
|Joule|JOU|J|
|Quilojoule|KJO|kJ|
|Milijoule|C15|mJ|
|Unidade Térmica Britânica (Média)|J39|Btu|

### 8. Perfis de Consulta:

A API Verified by GS1, conta com 4 perfis de consulta que apresentam restrições de informações de acordo com o contratado, sendo eles:

- Verificação
    
- Verificação + Atributos Nacionais
    
- Verificação + Atributos Internacionais
    
- Atributos Nacionais + Atributos Internacionais
    

#### 7.1. Verificação

O perfil Verificação, retorna os dados de licença do GTIN consultado, os dados da empresa, além de validar a estrutura do código em relação ao Padrão GS1 de Codificação, Status de Sincronização com o CCG e o Status da Situação do Código (onde, para GTINs nacionais será retornado o Status Válido ou Inválido e para GTINs internacionais deverá ser analisado o `returnCode` do array `verificacao.returnCode` e `verificacao.returnCodeDescription`).

Abaixo é possível visualizar um exemplo de request deste perfil:

```
[
  {
    "gtin": "00012358171329",
    "dadosInternacionais": {
      "gtin": "00012358171329",
      "licenseeName": "Empresa Teste",
      "gs1Licence": {
        "licenceType": "GCP",
        "licenseeName": "Empresa Teste",
        "licenseeGLN": "0000000000000",
        "licensingMO": {
          "moName": "GS1 US"
        },
        "dateCreated": "2018-03-29T19:48:26Z",
        "dateUpdated": "2019-10-18T22:49:34Z"
      }
    },
    "dateCreated": "2018-03-29T19:48:26Z",
    "dateUpdated": "2019-10-18T22:49:34Z",
    "gtinRecordStatus": null,
    "dadosNacionais": {},
    "message": "GTIN não encontrado.",
    "verificacao": {
      "lastChangeDate": "2014-10-18T00:00:00-04:00",
      "returnCode": "0",
      "returnCodeDescription": "Sucesso.",
      "process": "OK",
      "address": {
        "city": "TESTE",
        "countryCode": "US",
        "postalCode": "00000-0000",
        "streetAddressOne": "RUA TESTE EXEMPLO"
      },
      "gepirRequestedKey": {
        "requestedKeyCode": "GTIN",
        "requestedKeyValue": "00012358171329",
        "requestedLanguage": "en"
      }
    }
  }
]
```

#### 7.2. Verificação + Dados Nacionais

O perfil Verificação + Dados Nacionais, retorna os dados de licença do GTIN consultado, os dados da empresa, além de validar a estrutura do código em relação ao Padrão GS1 de Codificação, verificar o Status de Sincronização com o CCG, Status da Situação do Código (onde, para GTINs nacionais será retornado o Status Válido ou Inválido e para GTINS internacionais deverá ser analisado o `returnCode` do array `verificacao.returnCode` e `verificacao.returnCodeDescription`) e os atributos de Produtos Nacionais cadastrados no Cadastro Nacional de Produtos conforme TABELA DE ATRIBUTOS NACIONAIS.

Abaixo é possível visualizar um exemplo de request deste perfil:

```
{
  "gtin": "07898357416086",
  "dadosInternacionais": {
    "gtin": "07898357416086",
    "licenseeName": "GS1 BRASIL ASSOCIACAO BRASILEIRA DE AUTOMACAO",
    "gs1Licence": {
      "licenceType": "GCP",
      "licenseeName": "GS1 BRASIL ASSOCIACAO BRASILEIRA DE AUTOMACAO",
      "licensingMO": {
        "moName": "GS1 Brasil"
      },
      "dateCreated": "2018-05-31T20:28:37Z",
      "dateUpdated": "2018-12-18T18:57:49Z"
    }
  },
  "dateCreated": "2018-05-31T20:28:37Z",
  "dateUpdated": "2018-12-18T18:57:49Z",
  "gtinRecordStatus": null,
  "dadosNacionais": {
    "product": {
      "gs1TradeItemIdentificationKey": {
        "gs1TradeItemIdentificationKeyCode": "GTIN_13"
      },
      "gtin": "7898357416086",
      "fixedLengthGtin": "07898357416086",
      "tradeItemDescriptionInformationLang": [
        {
          "languageCode": "pt-BR",
          "tradeItemDescription": "GS1 Brasil Tênis de Corrida Style Azul com Branco Tamanho 37",
          "default": true,
          "additionalTradeItemDescription": null
        }
      ],
      "childTradeItems": [],
      "referencedFileInformations": [
        {
          "languageCode": "pt-BR",
          "featuredFile": true,
          "contentDescription": "Imagem do Produto",
          "fileName": null,
          "uniformResourceIdentifier": "https://cnp30blob.blob.core.windows.net/cnp3files/ae1f8d43d469596a35c5de02a0c2d59f347c88c17201990289aa9be416b4d05d.jpeg",
          "default": true,
          "referencedFileTypeCode": "OUT_OF_PACKAGE_IMAGE"
        }
      ],
      "brandNameInformationLang": [
        {
          "languageCode": "pt-BR",
          "brandName": "GS1 Brasil",
          "default": true
        }
      ],
      "tradeItemWeight": {
        "grossWeight": {
          "measurementUnitCode": "KGM",
          "value": 2.8
        },
        "netWeight": {
          "measurementUnitCode": "KGM",
          "value": 2.8
        }
      },
      "tradeItemMeasurements": {
        "netContent": {
          "measurementUnitCode": "EA",
          "value": 1
        },
        "height": {
          "measurementUnitCode": "CMT",
          "value": 40
        },
        "width": {
          "measurementUnitCode": "CMT",
          "value": 17
        },
        "depth": {
          "measurementUnitCode": "CMT",
          "value": 10
        }
      },
      "tradeItemClassification": {
        "gpcCategoryCode": "10001070",
        "additionalTradeItemClassifications": [
          {
            "additionalTradeItemClassificationSystemCode": "NCM",
            "additionalTradeItemClassificationCodeValue": "0000.00.00"
          },
          {
            "additionalTradeItemClassificationCodeValue": "28.059.00",
            "additionalTradeItemClassificationSystemCode": "CEST"
          }
        ],
        "gpcCategoryName": "Calçados Esportivos Uso Geral"
      },
      "syncInformationCCG": true
    }
  },
  "message": "GTIN encontrado com sucesso.",
  "verificacao": {
    "status": "Válido",
    "gepirRequestedKey": {
      "requestedKeyValue": "07898357416086"
    }
  }
}
```

#### 7.3. Verificação + Dados Internacionais

O perfil Verificação + Dados Internacionais, retorna os dados de licença do GTIN consultado, os dados da empresa, além de validar a estrutura do código em relação ao Padrão GS1 de Codificação, Status de Sincronização com o CCG, Status da Situação do Código (onde, para GTINs nacionais será retornado o Status Válido ou Inválido e para GTINs internacionais deverá ser analisado o `returnCode` do array `verificacao.returnCode` e `verificacao.returnCodeDescription`) e os atributos de produtos internacionais cadastrados no GS1 Registry Platform conforme TABELA DE ATRIBUTOS INTERNACIONAIS.

Abaixo é possível visualizar um exemplo de request deste perfil:

```
[
  {
    "gtin": "00000000000000",
    "dadosInternacionais": {
      "gtin": "00000000000000",
      "gpcCategoryCode": "00000000",
      "brandName": [
        {
          "language": "en",
          "value": "Brand Test"
        }
      ],
      "productDescription": [
        {
          "language": "en",
          "value": "Product Test"
        }
      ],
      "productImageUrl": [
        {
          "language": "en",
          "value": "https://test.jpg?download"
        }
      ],
      "netContent": [
        {
          "unitCode": "MLT",
          "value": "500.0"
        },
        {
          "unitCode": "OZA",
          "value": "16.9"
        }
      ],
      "countryOfSaleCode": [
        {
          "numeric": "840",
          "alpha2": "US",
          "alpha3": "USA"
        }
      ],
      "licenseeName": "Licensee Test",
      "gs1Licence": {
        "licenceType": "GCP",
        "licenseeName": "Licensee Test",
        "licenseeGLN": "0000000000000",
        "licensingMO": {
          "moName": "GS1 BRASIL"
        },
        "dateCreated": "2018-03-29T19:48:26Z",
        "dateUpdated": "2019-10-18T22:49:34Z"
      }
    },
    "dateCreated": "2018-03-29T19:48:26Z",
    "dateUpdated": "2019-10-18T22:49:34Z",
    "isComplete": true,
    "gtinRecordStatus": null,
    "dadosNacionais": {
      "message": "GTIN não encontrado."
    },
    "verificacao": {
      "lastChangeDate": "2014-10-18T00:00:00-04:00",
      "returnCode": "0",
      "returnCodeDescription": "Sucesso.",
      "process": "OK",
      "address": {
        "city": "PURCHASE",
        "countryCode": "US",
        "postalCode": "00000-0000",
        "streetAddressOne": "STREET TEST"
      },
      "gepirRequestedKey": {
        "requestedKeyCode": "GTIN",
        "requestedKeyValue": "00000000000000",
        "requestedLanguage": "en"
      }
    }
  }
]
```

#### 7.4. Atributos Nacionais + Atributos Internacionais

O perfil Verificação + Dados Internacionais, retorna os dados de licença do GTIN consultado, os dados da empresa, além de validar a estrutura do código em relação ao Padrão GS1 de Codificação, Status de Sincronização com o CCG, Status da Situação do Código (onde, para GTINs nacionais será retornado o Status Válido ou Inválido e para GTINs internacionais deverá ser analisado o `returnCode` do array `verificacao.returnCode` e `verificacao.returnCodeDescription`) e os atributos de produtos nacionais e internacionais cadastrados no GS1 Registry Platform conforme TABELA DE ATRIBUTOS NACIONAIS E INTERNACIONAIS.

Abaixo é possível visualizar um exemplo de request deste perfil:

```
[
  {
    "gtin": "07898357416086",
    "dadosInternacionais": {
      "gtin": "07898357416086",
      "gpcCategoryCode": "00000000",
      "brandName": [
        {
          "language": "en",
          "value": "Brand Test"
        }
      ],
      "productDescription": [
        {
          "language": "en",
          "value": "Product Test"
        }
      ],
      "productImageUrl": [
        {
          "language": "en",
          "value": "https://test.jpg?download"
        }
      ],
      "netContent": [
        {
          "unitCode": "MLT",
          "value": "500.0"
        },
        {
          "unitCode": "OZA",
          "value": "16.9"
        }
      ],
      "countryOfSaleCode": [
        {
          "numeric": "840",
          "alpha2": "US",
          "alpha3": "USA"
        }
      ],
      "licenseeName": "Licensee Test",
      "gs1Licence": {
        "licenceType": "GCP",
        "licenseeName": "Licensee Test",
        "licenseeGLN": "0000000000000",
        "licensingMO": {
          "moName": "GS1 BRASIL"
        },
        "dateCreated": "2018-03-29T19:48:26Z",
        "dateUpdated": "2019-10-18T22:49:34Z"
      }
    },
    "dateCreated": "2018-03-29T19:48:26Z",
    "dateUpdated": "2019-10-18T22:49:34Z",
    "isComplete": true,
    "gtinRecordStatus": "",
    "dadosNacionais": {
      "product": {
        "gs1TradeItemIdentificationKey": {
          "gs1TradeItemIdentificationKeyCode": "GTIN_13"
        },
        "gtin": "07898357416086",
        "fixedLengthGtin": "07898357416086",
        "tradeItemDescriptionInformationLang": [
          {
            "languageCode": "pt-BR",
            "tradeItemDescription": "GS1 Brasil Tênis de Corrida Style Azul com Branco Tamanho 37",
            "default": true,
            "additionalTradeItemDescription": null
          }
        ],
        "childTradeItems": [],
        "referencedFileInformations": [
          {
            "languageCode": "pt-BR",
            "featuredFile": true,
            "contentDescription": "Imagem do Produto",
            "fileName": null,
            "uniformResourceIdentifier": "https://cnp30blob.blob.core.windows.net/cnp3files/ae1f8d43d469596a35c5de02a0c2d59f347c88c17201990289aa9be416b4d05d.jpeg",
            "default": true,
            "referencedFileTypeCode": "OUT_OF_PACKAGE_IMAGE"
          }
        ],
        "brandNameInformationLang": [
          {
            "languageCode": "pt-BR",
            "brandName": "GS1 Brasil",
            "default": true
          }
        ],
        "tradeItemWeight": {
          "grossWeight": {
            "measurementUnitCode": "KGM",
            "value": 2.8
          },
          "netWeight": {
            "measurementUnitCode": "KGM",
            "value": 2.8
          }
        },
        "tradeItemMeasurements": {
          "netContent": {
            "measurementUnitCode": "EA",
            "value": 1
          },
          "height": {
            "measurementUnitCode": "CMT",
            "value": 40
          },
          "width": {
            "measurementUnitCode": "CMT",
            "value": 17
          },
          "depth": {
            "measurementUnitCode": "CMT",
            "value": 10
          }
        },
        "tradeItemClassification": {
          "gpcCategoryCode": "10001070",
          "additionalTradeItemClassifications": [
            {
              "additionalTradeItemClassificationSystemCode": "NCM",
              "additionalTradeItemClassificationCodeValue": "0000.00.00"
            },
            {
              "additionalTradeItemClassificationCodeValue": "28.059.00",
              "additionalTradeItemClassificationSystemCode": "CEST"
            }
          ],
          "gpcCategoryName": "Calçados Esportivos Uso Geral"
        },
        "syncInformationCCG": true
      }
    },
    "message": "GTIN encontrado com sucesso.",
    "verificacao": {
      "status": "Válido",
      "gepirRequestedKey": {
        "requestedKeyValue": "07898357416086"
      }
    }
  }
]
```
