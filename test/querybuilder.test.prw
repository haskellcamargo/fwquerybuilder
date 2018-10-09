#include 'protheus.ch'
#include 'testsuite.ch'

#define CRLF Chr( 13 ) + Chr( 10 )

TestSuite QueryBuilder Description "Query Builder"
    Feature _01_ Description "SELECT *"
    Feature _02_ Description "SELECT single field"
    Feature _03_ Description "SELECT multiple fields"
    Feature _04_ Description "SELECT field AS"
    Feature _05_ Description "COUNT"
    Feature _06_ Description "SUM"
    Feature _07_ Description "ORDER BY"
    Feature _08_ Description "ORDER BY ASC"
    Feature _09_ Description "ORDER BY DESC"
    Feature _10_ Description "SELECT TOP"
    Feature _11_ Description "UNION"
    Feature _12_ Description "UNION ALL"
    Feature _13_ Description "JOIN"
    Feature _14_ Description "INNER JOIN"
    Feature _15_ Description "LEFT JOIN"
    Feature _16_ Description "JOIN multiple tables"
    Feature _17_ Description "WHERE"
    Feature _18_ Description "AND"
    Feature _19_ Description "AVG"
    Feature _20_ Description "MAX and MIN"
EndTestSuite

Feature _01_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT *" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _02_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" )
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )

    FreeObj( oQuery )
    oQuery := QueryBuilder():New()
    oQuery:Select( { "TJ_ORDEM" } )
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _03_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM," + CRLF
    cExpect += "       TJ_CODBEM," + CRLF
    cExpect += "       TJ_TERMINO" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" )
    oQuery:Select( { "TJ_CODBEM", "TJ_TERMINO" })
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _04_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM," + CRLF
    cExpect += "       TJ_CODBEM AS EQUIPMENT" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" )
    oQuery:Select( "TJ_CODBEM" ):_As( "EQUIPMENT" )
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _05_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT COUNT(1) AS TOTAL" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Count():_As( "TOTAL" ):From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _06_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT SUM(TJ_POSCONT)" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Sum( "TJ_POSCONT" ):From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _07_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT *" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "ORDER BY TJ_POSCONT" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" ):OrderBy( "TJ_POSCONT" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _08_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT *" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "ORDER BY TJ_POSCONT ASC" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" ):OrderBy( "TJ_POSCONT" ):Asc()

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _09_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT *" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "ORDER BY TJ_POSCONT ASC, TJ_CODBEM DESC" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" ):OrderBy( "TJ_POSCONT" ):Asc()
    oQuery:OrderBy( { "TJ_CODBEM" } ):Desc()

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _10_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TOP 10 TJ_ORDEM," + CRLF
    cExpect += "              TJ_CODBEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Top( 10 ):Select({ "TJ_ORDEM", "TJ_CODBEM" }):From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _11_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_CODBEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "UNION" + CRLF
    cExpect += "SELECT *" + CRLF
    cExpect += "FROM ST9990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_CODBEM" ):From( "STJ990" )
    oQuery:Union( QueryBuilder():From( "ST9990" ) )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _12_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_CODBEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "UNION ALL" + CRLF
    cExpect += "SELECT *" + CRLF
    cExpect += "FROM ST9990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_CODBEM" ):From( "STJ990" )
    oQuery:UnionAll( QueryBuilder():From( "ST9990" ) )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _13_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "JOIN ST9990" + CRLF
    cExpect += "  ON TJ_ORDEM = T9_CODBEM" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" ):From( "STJ990" )
    oQuery:Join( "ST9990" )
    oQuery:On( "TJ_ORDEM" ):Equals( "T9_CODBEM" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _14_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "INNER JOIN ST9990" + CRLF
    cExpect += "  ON TJ_ORDEM = T9_CODBEM" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" ):From( "STJ990" )
    oQuery:InnerJoin( "ST9990" )
    oQuery:On( "TJ_ORDEM" ):Equals( "T9_CODBEM" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _15_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "LEFT JOIN ST9990" + CRLF
    cExpect += "  ON TJ_ORDEM = T9_CODBEM" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" ):From( "STJ990" )
    oQuery:LeftJoin( "ST9990" )
    oQuery:On( "TJ_ORDEM" ):Equals( "T9_CODBEM" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _16_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT TJ_ORDEM" + CRLF
    cExpect += "FROM STJ990" + CRLF
    cExpect += "LEFT JOIN ST9990" + CRLF
    cExpect += "  ON TJ_ORDEM = T9_CODBEM" + CRLF
    cExpect += "INNER JOIN STC990" + CRLF
    cExpect += "  ON TJ_ORDEM = TC_CODBEM" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" ):From( "STJ990" )
    oQuery:LeftJoin( "ST9990" )
    oQuery:On( "TJ_ORDEM" ):Equals( "T9_CODBEM" )
    oQuery:InnerJoin( "STC990" )
    oQuery:On( "TJ_ORDEM" ):Equals( "TC_CODBEM" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _17_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT *" + CRLF
    cExpect += "FROM ST9990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "  AND T9_CONTACU > OTHER_FIELD" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "ST9990" ):Where( "T9_CONTACU" ):GreaterThan( "OTHER_FIELD" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _18_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT *" + CRLF
    cExpect += "FROM ST9990" + CRLF
    cExpect += "INNER JOIN FEELINGS" + CRLF
    cExpect += "  ON DEPRESSION > INFINITY"  + CRLF
    cExpect += "  AND SADNESS = BLAH" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "  AND T9_CONTACU > OTHER_FIELD" + CRLF
    cExpect += "  AND A = B" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "ST9990" )
    oQuery:InnerJoin( "FEELINGS" ):On( "DEPRESSION" ):GreaterThan( "INFINITY" )
    oQuery:And( "SADNESS" ):Equals( "BLAH" )
    oQuery:Where( "T9_CONTACU" ):GreaterThan( "OTHER_FIELD" )
    oQuery:And( "A" ):Equals( "B" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _19_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT AVG(T9_CONTACU)" + CRLF
    cExpect += "FROM ST9990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Avg( "T9_CONTACU" ):From( "ST9990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _20_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT MIN(T9_CONTACU)," + CRLF
    cExpect += "       MAX(T9_CONTACU)" + CRLF
    cExpect += "FROM ST9990" + CRLF
    cExpect += "WHERE D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select():Min( "T9_CONTACU" ):Max( "T9_CONTACU" ):From( "ST9990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

CompileTestSuite QueryBuilder

