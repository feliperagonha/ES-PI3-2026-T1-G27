# MesclaInvest

Projeto Integrador 3 - Engenharia de Software - PUC-Campinas - 2026.

O MesclaInvest e um aplicativo mobile academico que simula uma plataforma de investimentos em startups do ecossistema Mescla. O usuario pode criar conta, consultar startups, comprar e vender tokens simulados, acompanhar carteira, visualizar valorizacao dos ativos e interagir com socios por perguntas.

> Este projeto e exclusivamente academico. Nao ha captacao real, pagamento real, blockchain real ou oferta de valores mobiliarios.

## Integrantes

| Nome | RA |
| --- | --- |
| Felipe Ragonha | 24023900 |
| Juliano Perusso | 24023434 |
| Arthur Sebastian | 24795528 |
| Guilherme Marras | 24027681 |
| Rafael Fabrini | 24026022 |

## Stack

- Flutter e Dart para o aplicativo mobile.
- Firebase Authentication para autenticacao.
- Firebase Firestore como banco de dados.
- Firebase Functions com Node.js e TypeScript para regras de negocio.
- Firebase Storage quando houver arquivos/documentos.

Regiao padrao das callable Functions: `southamerica-east1`.

## Como Rodar

Requisitos:

- Flutter instalado.
- Node.js compativel com o runtime das Functions.
- Firebase CLI configurado quando for usar emuladores ou deploy.
- Projeto Firebase configurado nos arquivos `firebase.json` e `lib/firebase_options.dart`.

Instale dependencias do app:

```powershell
flutter pub get
```

Instale dependencias das Functions:

```powershell
npm --prefix functions install
```

Rode o app:

```powershell
flutter run
```

Compile as Functions:

```powershell
npm --prefix functions run build
```

Opcionalmente, rode emuladores:

```powershell
npm --prefix functions run serve
```

## Verificacoes Antes De Entregar

```powershell
flutter analyze
flutter test
npm --prefix functions run build
```

## Funcionalidades

- Cadastro com nome, email, CPF, telefone e senha.
- Login sem acesso anonimo.
- Recuperacao de senha.
- 2FA opcional.
- Catalogo de startups com filtros.
- Detalhe de startup com informacoes institucionais, socios, mentores, capital e tokens.
- Carteira com saldo ficticio.
- Compra primaria de tokens.
- Balcao de ofertas entre usuarios.
- Dashboard de valorizacao baseado em transacoes simuladas.
- Perguntas privadas para socios/empreendedores.

## Documentacao Do Projeto

- [Contexto do projeto](docs/PROJECT_CONTEXT.md)
- [Matriz de requisitos](docs/REQUIREMENTS_MATRIX.md)
- [Backlog](docs/BACKLOG.md)
- [Runbook de demonstracao](docs/DEMO_RUNBOOK.md)

## Artefatos Externos

| Artefato | Descricao | Link |
| --- | --- | --- |
| Planilha de Startups | Base de dados simulada com startups do ecossistema Mescla | [Ver planilha](https://docs.google.com/spreadsheets/d/1HGo9I57RYEkW_qFGg929zzWY_s66bnq_WRgcp-1RQho/edit?usp=sharing) |
| Mapa Mental | Mapa mental do projeto MesclaInvest | [Ver mapa mental](https://www.figma.com/design/06zXn2ejJpj2iUm1XXQWra/FIGMA---MESCLAINVEST?node-id=846-404) |
| Prototipo | Prototipo das telas no Figma | [Ver prototipo](https://www.figma.com/design/06zXn2ejJpj2iUm1XXQWra/FIGMA---MESCLAINVEST?node-id=601-9&p=f&t=LRQ0OejGIRgPLq68-0) |

## Regras Academicas Importantes

- O repositorio final deve seguir o padrao `ES-PI3-2026-TURMA-G27`; confirme a turma antes da entrega.
- A entrega final deve ter a tag `1.0.0-final`.
- O README deve estar presente na raiz.
- As tarefas devem estar registradas no GitHub Projects com estimativa e esforco real.
- Cada arquivo deve declarar um unico autor principal com nome completo e RA. Arquivos com multiplos autores devem ser revisados pela equipe.
