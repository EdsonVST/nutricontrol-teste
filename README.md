# NutriControl TESTE

Crie um sistema web responsivo de controle alimentar pessoal chamado NutriControl.

O objetivo do sistema é permitir que o usuário registre sua alimentação diária, acompanhe seus nutrientes consumidos e tenha uma visão histórica da sua dieta.

Tecnologias desejadas

Frontend moderno e responsivo

Backend com API própria

Banco de dados relacional

Autenticação de usuário

Integração com API da TACO (Tabela Brasileira de Composição de Alimentos) para buscar informações nutricionais dos alimentos

Permitir cadastro manual quando o alimento não existir na base

Funcionalidades principais

1. Usuário / Perfil

Criar uma área de usuário contendo:

Nome

Peso

Altura

Idade

Objetivo (emagrecimento, manutenção, ganho de massa)

Meta diária de calorias

Meta de proteínas, carboidratos e gorduras

Página de perfil mostrando:

Consumo médio diário

Evolução semanal

Evolução mensal

Histórico alimentar

2. Registro de alimentação

Criar uma tela principal chamada "Minha Alimentação".

Por padrão o dia deve possuir 4 refeições:

Café da manhã

Almoço

Lanche

Jantar

Cada refeição deve permitir:

Escolher data

Escolher horário opcional

Pesquisar alimento

Informar quantidade consumida em gramas/ml/unidade

Adicionar alimento

Exemplo:

Almoço:

Arroz branco cozido

150g

O sistema deve calcular automaticamente:

Calorias consumidas

Proteínas

Carboidratos

Gorduras

Fibras

Outros nutrientes disponíveis

O cálculo deve ser proporcional à quantidade ingerida.

Exemplo:

100g arroz = X nutrientes

Usuário informa:

200g arroz

Sistema calcula:

2x os valores nutricionais.

3. Cadastro de alimentos

Criar uma área chamada "Tabela Nutricional".

Deve possuir:

Lista de alimentos cadastrados contendo:

Nome do alimento

Categoria

Calorias

Proteínas

Carboidratos

Gorduras

Fibras

Sódio

Vitaminas e minerais disponíveis

Funções:

Pesquisar alimento

Editar alimento

Excluir alimento

Criar novo alimento manualmente

Ao iniciar o sistema:

Importar alimentos da API da TACO automaticamente.

Salvar esses alimentos no banco local para melhorar velocidade.

Criar campos:

id
nome
categoria
energia_kcal
proteina
carboidrato
gordura
fibra
minerais
vitaminas
fonte

4. Dashboard nutricional

Criar uma página "Dashboard".

Mostrar:

Visão diária

Total de calorias consumidas

Proteína consumida

Carboidratos

Gorduras

Comparação:

Consumido x Meta diária

Filtros:

Permitir visualizar:

Hoje

Últimos 7 dias

Últimos 30 dias

Último ano

Permitir filtrar por:

Refeição

Alimento

Categoria

Nutriente

Criar gráficos:

Evolução de calorias

Proteína por dia

Distribuição de macros

Alimentos mais consumidos

5. Exportação de dados

Criar opção:

"Exportar alimentação"

Formatos:

Excel (.xlsx)

CSV

PDF

O arquivo deve conter:

Data
Refeição
Alimento
Quantidade consumida
Calorias
Proteínas
Carboidratos
Gorduras
Fibras
Outros nutrientes

Exemplo:

01/06/2026 | Almoço | Frango grelhado | 200g | 330 kcal | 62g proteína

6. Banco de dados

Criar tabelas:

users

foods

meals

meal_foods

nutrition_goals

Relacionamento:

Usuário possui várias refeições

Refeição possui vários alimentos

Alimento possui informações nutricionais

7. Experiência do usuário

Criar uma interface simples semelhante a aplicativos de dieta.

Ter:

Menu lateral:

Dashboard

Minha Alimentação

Alimentos

Histórico

Perfil

Usar cards mostrando:

Calorias restantes
Proteína restante
Meta diária

Design limpo, moderno e responsivo para celular.

8. Regras importantes

Nunca apagar dados automaticamente

Permitir edição manual dos alimentos vindos da TACO

Guardar histórico das refeições

Todos os cálculos devem considerar a quantidade realmente consumida

Criar validações nos formulários

Criar busca rápida de alimentos

Preparar o sistema para futuramente adicionar inteligência artificial para sugestões de dieta

Entregar o projeto funcionando com:

Frontend

Backend

Banco configurado

Autenticação

Integração API TACO

Exportação funcionando

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/9e9cca57-3f45-40c1-ad0c-be4949274921).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
