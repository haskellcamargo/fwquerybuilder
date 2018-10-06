#include 'hbclass.ch'

#define CRLF Chr( 13 ) + Chr( 10 )

Class FWQueryBuilder
    Hidden:
    Data aSelect As Array
    Data cTable As String

    Data nNextAlias

    Export:
    Method New() Constructor
    Method From( cTable )
    Method Select( aSelect )

    Method GetSql()

    Hidden:
    Method NextAlias()
EndClass

Method New() Class FWQueryBuilder
    ::nNextAlias := 0
Return Self

Method NextAlias() Class FWQueryBuilder
    Local cAlias := 'TB' + AllTrim( Str( ::nNextAlias ) )
    ::nNextAlias++
Return cAlias

Method Select( aSelect )
    HB_DEFAULT( @aSelect, {} )
    ::aSelect := aSelect
Return Self

Method From( cTable )
    ::cTable := cTable
Return Self

Method GetSql()
    Local cSql
    Local cAlias
    Local aFields

    aFields := {}
    cAlias  := ::NextAlias()
    AEval( ::aSelect, { |cField| AAdd( aFields, cAlias + "." + cField ) } )

    cSql := "SELECT " + StrJoin( aFields, "," + CRLF + Space( 7 ) ) + CRLF
    cSql += "FROM   " + ::cTable + " " + cAlias + CRLF
    cSql += "WHERE  " + cAlias + ".D_E_L_E_T_ <> '*'" + CRLF
Return cSql

Static Function StrJoin( aWords, cSeparator )
    Local nLength := Len( aWords )
    Local nIndex
    Local cResult := ''

    For nIndex := 1 To nLength
        cResult += aWords[ nIndex ]
        If nIndex < nLength
            cResult += cSeparator
        EndIf
    Next
Return cResult

Procedure Main()
    Local oQuery

    oQuery := FWQueryBuilder():New()
    oQuery:Select( { "T9_CODBEM", "T9_CONTACU" } )
    oQuery:From( "ST9" )

    ? oQuery:GetSql()
