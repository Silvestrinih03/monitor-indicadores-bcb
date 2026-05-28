# Monitor Indicadores BCB

App Flutter para consultar indicadores economicos do Banco Central, analisar dados retornados pela API SGS e salvar analises no Firestore.

## Configuracao do Firebase

Antes de executar, configure o Firebase no app:

```bash
flutterfire configure
```

Os arquivos gerados com dados do projeto Firebase ficam apenas locais e estao no
`.gitignore`, incluindo `lib/firebase_options.dart`,
`android/app/google-services.json`, `GoogleService-Info.plist`, `.firebaserc` e
`firebase.json`. Recrie esses arquivos em cada maquina com o comando acima.

Nunca versione credenciais de servidor, como JSON de service account/Admin SDK.
O acesso real aos dados deve ser protegido pelas regras do Firestore no console
do Firebase.

O app usa duas colecoes:

### `indicadores`

Documentos com pelo menos:

```json
{
  "nome": "Dolar comercial",
  "codigo": 1,
  "unidade": "R$",
  "descricao": "Taxa de cambio comercial para compra."
}
```

Caso a colecao esteja vazia, a tela inicial oferece um botao para criar tres exemplos: Dolar comercial, Taxa Selic e IPCA.

### `analises`

Criada automaticamente quando uma analise e salva. Cada documento guarda nome, observacao, indicador, periodo e estatisticas calculadas.

## Telas implementadas

- Lista de Indicadores: `StreamBuilder` no Firestore e `FutureBuilder` para valor mais recente via HTTP.
- Consulta: formulario validado com data inicial/final, `FutureBuilder` com carregando, erro e dados, e `ListView.builder`.
- Analise: grafico de linha com `fl_chart` e seis estatisticas calculadas.
- Analises Salvas: formulario validado, `add` e `delete` no Firestore, lista em tempo real e confirmacao com `AlertDialog`.
