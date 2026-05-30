# Monitor Indicadores BCB

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=111)
![BCB SGS](https://img.shields.io/badge/BCB-SGS-006C67)

Aplicativo Flutter para consultar indicadores economicos brasileiros na API SGS
do Banco Central, visualizar series historicas, calcular estatisticas e salvar
analises no Firebase Firestore.

## Visao geral

O projeto centraliza um fluxo simples de acompanhamento de indicadores:

- lista indicadores cadastrados no Firestore;
- busca o valor mais recente de cada serie na API SGS do Banco Central;
- permite consultar um periodo por data inicial e final;
- exibe os registros retornados pela API;
- gera graficos e estatisticas do periodo;
- salva analises com conclusao, valores e metricas calculadas.

## Funcionalidades

| Area | O que faz |
| --- | --- |
| Indicadores | Lista os indicadores cadastrados e mostra o valor mais recente via API BCB. |
| Consulta | Valida datas, consulta a serie SGS e lista os valores encontrados. |
| Analise | Exibe grafico de linha, media, minimo, maximo, variacao percentual e desvio padrao. |
| Analises salvas | Persiste analises no Firestore, lista historico e permite exclusao. |

## Stack

- Flutter com Material 3
- Firebase Core
- Cloud Firestore
- HTTP para consumo da API SGS do BCB
- `fl_chart` para graficos
- `intl` para datas
- `flutter_multi_formatter` para mascara de data

## Como rodar

### 1. Instale as dependencias

```bash
flutter pub get
```

### 2. Configure o Firebase

O app depende de um projeto Firebase com Firestore habilitado. Gere os arquivos
locais com:

```bash
flutterfire configure
```

Esse comando cria arquivos como:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `.firebaserc`
- `firebase.json`

Esses arquivos ficam fora do versionamento por conterem configuracoes locais do
projeto Firebase.

### 3. Rode o app

```bash
flutter run
```

Para escolher uma plataforma especifica:

```bash
flutter run -d chrome
flutter run -d android
flutter run -d windows
```

## Dados no Firestore

O app usa duas colecoes principais.

### `indicadores`

Cada documento representa uma serie SGS consultavel:

```json
{
  "nome": "Dolar comercial",
  "codigo": 1,
  "unidade": "R$",
  "descricao": "Taxa de cambio comercial para compra."
}
```

Campos esperados:

| Campo | Tipo | Descricao |
| --- | --- | --- |
| `nome` | `string` | Nome exibido no app. |
| `codigo` | `number` | Codigo da serie no SGS do Banco Central. |
| `unidade` | `string` | Unidade do indicador, como `%`, `R$` ou `pontos`. |
| `descricao` | `string` | Texto opcional com contexto sobre o indicador. |

Exemplos uteis de indicadores:

| Indicador | Codigo SGS |
| --- | --- |
| Dolar comercial | `1` |
| Taxa Selic | `11` |
| IPCA | `433` |

### `analises`

Criada automaticamente quando uma analise e salva pelo app. Cada documento
guarda:

- nome da analise;
- indicador e codigo SGS;
- periodo consultado;
- estatisticas calculadas;
- lista de valores retornados pela API;
- conclusao textual;
- data de criacao.

## API utilizada

As consultas sao feitas diretamente na API SGS do Banco Central:

```text
https://api.bcb.gov.br/dados/serie/bcdata.sgs.{codigo}/dados
```

Parametros usados:

- `formato=json`
- `dataInicial=DD/MM/AAAA`
- `dataFinal=DD/MM/AAAA`

## Testes

Execute a suite de testes com:

```bash
flutter test
```

Hoje o projeto possui teste para o calculo de estatisticas basicas dos
indicadores.

## Estrutura principal

```text
lib/
  main.dart
  models/
    analise_draft.dart
    analise_salva.dart
    indicador.dart
    indicador_estatisticas.dart
    indicador_valor.dart
  screens/
    analise_screen.dart
    analises_salvas_screen.dart
    consulta_screen.dart
    indicadores_screen.dart
  services/
    bcb_service.dart
test/
  model_test.dart
```

## Seguranca

Nao versione credenciais sensiveis, chaves privadas, arquivos de service account
ou configuracoes administrativas do Firebase. O acesso real aos dados deve ser
protegido pelas regras do Firestore no console do Firebase.

## Status

Projeto em desenvolvimento, com o fluxo principal de consulta, analise e
persistencia ja implementado.
