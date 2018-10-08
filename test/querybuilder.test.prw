#include 'protheus.ch'
#include 'testsuite.ch'

#define CRLF Chr( 13 ) + Chr( 10 )

TestSuite QueryBuilder Description "Query Builder"
    Feature _01_ Description "SELECT *"
    Feature _02_ Description "SELECT single field"
    Feature _03_ Description "SELECT multiple fields"
    Feature _04_ Description "SELECT field AS"
    Feature _05_ Description "SELECT COUNT"
    Feature _06_ Description "SELECT SUM"
    Feature _07_ Description "ORDER BY"
    Feature _08_ Description "ORDER BY ASC"
    Feature _09_ Description "ORDER BY DESC"
    Feature _10_ Description "SELECT TOP"
EndTestSuite

Feature _01_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   *" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _02_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   TJ_ORDEM" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

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

    cExpect := "SELECT   TJ_ORDEM," + CRLF
    cExpect += "         TJ_CODBEM," + CRLF
    cExpect += "         TJ_TERMINO" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" )
    oQuery:Select( { "TJ_CODBEM", "TJ_TERMINO" })
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _04_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   TJ_ORDEM," + CRLF
    cExpect += "         TJ_CODBEM AS EQUIPMENT" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Select( "TJ_ORDEM" )
    oQuery:Select( "TJ_CODBEM" ):_As( "EQUIPMENT" )
    oQuery:From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _05_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   COUNT(1) AS TOTAL" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Count():_As( "TOTAL" ):From( "STJ990" )
    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _06_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   SUM(TJ_POSCONT)" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Sum( "TJ_POSCONT" ):From( "STJ990" )
    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _07_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   *" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "ORDER BY TJ_POSCONT" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" ):OrderBy( "TJ_POSCONT" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _08_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   *" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF
    cExpect += "ORDER BY TJ_POSCONT ASC" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:From( "STJ990" ):OrderBy( "TJ_POSCONT" ):Asc()

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

Feature _09_ TestSuite QueryBuilder
    Local oQuery
    Local cExpect

    cExpect := "SELECT   *" + CRLF
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF
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
    cExpect += "FROM     STJ990" + CRLF
    cExpect += "WHERE    D_E_L_E_T_ <> '*'" + CRLF

    oQuery := QueryBuilder():New()
    oQuery:Top( 10 ):Select({ "TJ_ORDEM", "TJ_CODBEM" }):From( "STJ990" )

    ::Expect( oQuery:GetSql() ):ToBe( cExpect )
Return

CompileTestSuite QueryBuilder
