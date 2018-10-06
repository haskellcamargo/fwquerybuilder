#include 'hbclass.ch'

#define CRLF Chr( 13 ) + Chr( 10 )
#define Quoted( cId ) "[" + cId + "]"

Class FWQueryBuilder
    Hidden:
    Data aOrderBy As Array
    Data aSelect  As Array
    Data cFrom    As String

    Data nNextAlias

    Export:
    Method New() Constructor
    Method From( cTable )
    Method OrderBy( aOrderBy )
    Method Select( aSelect )

    Method GetSql()

    Hidden:
    Method NextAlias()
EndClass

Method New() Class FWQueryBuilder
    ::nNextAlias := 0
    ::aOrderBy   := {}
Return Self

Method NextAlias() Class FWQueryBuilder
    Local cAlias := 'TB' + AllTrim( Str( ::nNextAlias ) )
    ::nNextAlias++
Return cAlias

Method Select( aSelect ) Class FWQueryBuilder
    HB_DEFAULT( @aSelect, {} )
    ::aSelect := aSelect
Return Self

Method From( cFrom ) Class FWQueryBuilder
    ::cFrom := cFrom
Return Self

Method OrderBy( aOrderBy ) Class FWQueryBuilder
    ::aOrderBy := aOrderBy
Return Self

Method GetSql()
    Local cSql
    Local cAlias
    Local cFrom
    Local aFields
    Local aOrderBy

    aFields  := {}
    aOrderBy := {}
    cAlias   := Quoted( ::NextAlias() )
    cFrom    := Quoted( ::cFrom )
    AEval( ::aSelect, { |cField| AAdd( aFields, cAlias + "." + Quoted( cField ) ) } )
    AEval( ::aOrderBy, { |cOrder| AAdd( aOrderBy, cAlias + "." + Quoted( cOrder ) ) } )

    cSql := "SELECT   " + StrJoin( aFields, "," + CRLF + Space( 9 ) ) + CRLF
    cSql += "FROM     " + cFrom + " " + cAlias + CRLF
    cSql += "WHERE    " + cAlias + "." + Quoted( "D_E_L_E_T_" ) + " <> '*'" + CRLF

    If !Empty( aOrderBy )
        cSql += "ORDER BY " + StrJoin( aOrderBy, ", " )
    EndIf

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
    oQuery:OrderBy( { "T9_CODBEM", "T9_CONTACU" } )

    ? oQuery:GetSql()
