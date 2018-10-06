#include 'hbclass.ch'

#define CRLF Chr( 13 ) + Chr( 10 )
#define Quoted( cId ) "[" + cId + "]"

Class FWQueryBuilder
    Hidden:
    Data aFrom       As Array
    Data aOrderBy    As Array
    Data aSelect     As Array
    Data cLastSelect As String

    Data nCurrAlias
    Data nNextAlias

    Export:
    Method New() Constructor
    Method As( cAs )
    Method From( cTable )
    Method OrderBy( aOrderBy )
    Method Select( xSelect )

    Method GetSql()

    Hidden:
    Method NextAlias()
EndClass

Method New() Class FWQueryBuilder
    ::nNextAlias := 0
    ::aSelect    := {}
    ::aOrderBy   := {}
Return Self

Method NextAlias() Class FWQueryBuilder
    Local cAlias := 'TB' + AllTrim( Str( ::nNextAlias ) )
    ::nNextAlias++
Return cAlias

Method As( cAs ) Class FWQueryBuilder
    Local nIndex

    If ::cLastSelect <> Nil
        nIndex := AScan( ::aSelect, ::cLastSelect )
        ::aSelect[ nIndex ] := { ::cLastSelect, cAs }
    EndIf
Return Self

Method From( cFrom ) Class FWQueryBuilder
    Local nCurrAlias := ::NextAlias()

    ::aFrom      := { cFrom, nCurrAlias }
    ::nCurrAlias := nCurrAlias
Return Self

Method Select( xSelect ) Class FWQueryBuilder
    If ValType( xSelect ) == 'C'
        xSelect := { xSelect }
    EndIf

    If !Empty( xSelect )
        ::cLastSelect := ATail( xSelect )
    EndIf

    AEval( xSelect, { |cField| AAdd( ::aSelect, cField ) } )
Return Self

Method OrderBy( aOrderBy ) Class FWQueryBuilder
    ::aOrderBy := aOrderBy
Return Self

Method GetSql()
    Local cSql
    Local cAlias
    Local cFrom

    aFields  := {}
    aOrderBy := {}
    cPrefix  := ::aFrom[ 2 ]
    cFrom    := Quoted( ::aFrom[ 1 ] ) + " " + cPrefix

    cSql := "SELECT   " + GenFields( ::aSelect, cPrefix, 9, .T. ) + CRLF
    cSql += "FROM     " + cFrom + CRLF
    cSql += "WHERE    " + cPrefix + "." + Quoted( "D_E_L_E_T_" ) + " <> '*'" + CRLF

    If !Empty( ::aOrderBy )
        cSql += "ORDER BY " + GenFields( ::aOrderBy, cPrefix )
    EndIf

Return cSql

Static Function GenFields( aFields, cPrefix, nSpaces, lNewline )
    Local nLength
    Local nIndex
    Local cSeparator
    Local cResult
    Local xField

    HB_DEFAULT( @nSpaces, 1 )
    HB_DEFAULT( @lNewline, .F. )

    cSeparator := ","
    If lNewline
        cSeparator += CRLF
    EndIf
    cSeparator += Space( nSpaces )

    If !Empty( cPrefix )
        cPrefix += "."
    EndIf

    nLength := Len( aFields )
    cResult := ""
    For nIndex := 1 To nLength
        xField = aFields[ nIndex ]
        cResult += cPrefix
        If ValType( xField ) == 'A'
            cResult += Quoted( xField[ 1 ] ) + " AS " + Quoted( xField[ 2 ] )
        Else
            cResult += Quoted( xField )
        EndIf

        If nIndex < nLength
            cResult += cSeparator
        EndIf
    Next
Return cResult

Procedure Main()
    Local oQuery

    oQuery := FWQueryBuilder():New()
    oQuery:Select( { "T9_CODBEM", "T9_CONTACU" } )
    oQuery:Select( "T9_HORINI" ):As( "START_HOUR" )
    oQuery:From( "ST9" )
    oQuery:OrderBy( { "T9_CODBEM", "T9_CONTACU" } )

    ? oQuery:GetSql()
