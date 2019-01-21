# QueryBuilder

> Classe AdvPL para criar consultas SQL composicionais de forma declarativa

O objetivo deste projeto é prover uma biblioteca para a linguagem AdvPL que seja
capaz de construir consultas SQL compatíveis com diversos bancos de dados de
maneira declarativa e não suscetível a erros.

## Exemplo

```xbase
Local oQuery := QueryBuilder():New()
oQuery:From( "STJ990" )
ConOut( oQuery:GetSql() )
```

Teremos como saída no terminal a seguinte consulta:

```
SELECT *
  FROM STJ990
```

Podem-se utilizar métodos de maneira fluente para compor a query.

## Instalação

Para torná-la disponível, basta fazer fazer download do arquivo
[querybuilder.prw](./src/querybuilder.prw) e compilá-lo em seu RPO.

## Características Suportadas

- `SELECT` simples
- _Aliases_ em campos
- `ORDER BY`
- _Alias_ customizado para tabela
- `GROUP BY`
- Expressões (`:Equals`, `GreaterThan`, entre outros)
- `INNER JOIN` e `LEFT JOIN`
- `WHERE`
- Funções de agregação (`SUM`, `AVG`, entre outras)
- Subqueries

Se desejar ver alguns exemplos, pode consultar os testes em
[querybuilder.test.prw](./test/querybuilder.test.prw).
