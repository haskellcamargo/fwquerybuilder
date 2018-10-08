#ifdef __HARBOUR__
#include 'hbclass.ch'
#else
#include 'protheus.ch'
#endif

#define CRLF Chr( 13 ) + Chr( 10 )
#define Quoted( cId ) "[" + cId + "]"

#define OP_SELECT 1
#define OP_ORDER  2
#define OP_FROM   3

Class QueryBuilder
    Data aFrom       As Array
    Data aOrderBy    As Array
    Data aSelect     As Array
    Data nLastOp     As Numeric
    Data cLastOp     As String

    Data nCurrAlias
    Data nNextAlias

    Method New() Constructor
    Method _As( cAs )
    Method Asc()
    Method Desc()
    Method From( cTable )
    Method OrderBy( xOrderBy )
    Method Select( xSelect )

    Method GetSql()

    Method NextAlias()
EndClass

Method New() Class QueryBuilder
    ::nNextAlias := 0
    ::aSelect    := {}
    ::aOrderBy   := {}
Return Self

Method NextAlias() Class QueryBuilder
    Local cAlias := 'TB' + AllTrim( Str( ::nNextAlias ) )
    ::nNextAlias++
Return cAlias

Method _As( cAs ) Class QueryBuilder
    Local nIndex

    Do Case
        Case ::nLastOp == OP_SELECT
            nIndex := AScan( ::aSelect, ::cLastOp )
            ::aSelect[ nIndex ] := { ::cLastOp, cAs }
        Case ::nLastOp == OP_FROM
            ::aFrom := { ::cLastOp, cAs }
    EndCase
Return Self

Method Asc() Class QueryBuilder
    Local nIndex

    If ::nLastOp == OP_ORDER
        nIndex := AScan( ::aOrderBy, ::cLastOp )
        ::aOrderBy[ nIndex ] := { ::cLastOp, "ASC" }
    EndIf
Return Self

Method Desc() Class QueryBuilder
    Local nIndex

    If ::nLastOp == OP_ORDER
        nIndex := AScan( ::aOrderBy, ::cLastOp )
        ::aOrderBy[ nIndex ] := { ::cLastOp, "DESC" }
    EndIf
Return Self

Method From( cFrom ) Class QueryBuilder
    Local nCurrAlias := ::NextAlias()

    ::aFrom      := { cFrom, nCurrAlias }
    ::nCurrAlias := nCurrAlias
    ::nLastOp    := OP_FROM
    ::cLastOp    := cFrom
Return Self

Method Select( xSelect ) Class QueryBuilder
    If ValType( xSelect ) == "C"
        xSelect := { xSelect }
    EndIf

    If !Empty( xSelect )
        ::nLastOp := OP_SELECT
        ::cLastOp := ATail( xSelect )
    EndIf

    AEval( xSelect, { |cField| AAdd( ::aSelect, cField ) } )
Return Self

Method OrderBy( xOrderBy ) Class QueryBuilder
    If ValType( xOrderBy ) == "C"
        xOrderBy := { xOrderBy }
    EndIf

    If !Empty( xOrderBy )
        ::nLastOp := OP_ORDER
        ::cLastOp := ATail( xOrderBy )
    EndIf

    AEval( xOrderBy, { |cOrder| AAdd( ::aOrderBy, cOrder ) } )
Return Self

Method GetSql() Class QueryBuilder
    Local cSql
    Local cAlias
    Local cFrom

    aFields  := {}
    aOrderBy := {}
    cPrefix  := ::aFrom[ 2 ]
    cFrom    := Quoted( ::aFrom[ 1 ] ) + " " + cPrefix

    cSql := "SELECT   " + GenFields( ::aSelect, cPrefix, 9, .T., .T. ) + CRLF
    cSql += "FROM     " + cFrom + CRLF
    cSql += "WHERE    " + cPrefix + "." + Quoted( "D_E_L_E_T_" ) + " <> '*'" + CRLF

    If !Empty( ::aOrderBy )
        cSql += "ORDER BY " + GenFields( ::aOrderBy, cPrefix )
    EndIf

Return cSql

Static Function GenFields( aFields, cPrefix, nSpaces, lNewline, lAs )
    Local nLength
    Local nIndex
    Local cSeparator
    Local cResult
    Local xField

    Default nSpaces  := 1
    Default lNewline := .F.
    Default lAs      := .F.

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
        If ValType( xField ) == "A"
            cResult += Quoted( xField[ 1 ] )
            If lAs
                cResult += " AS " + Quoted( xField[ 2 ] )
            Else
                cResult += " " + xField[ 2 ]
            EndIf
        Else
            cResult += Quoted( xField )
        EndIf

        If nIndex < nLength
            cResult += cSeparator
        EndIf
    Next
Return cResult

#ifdef __HARBOUR__
Procedure Main()
#else
User Function Build()
#endif
    Local oQuery

    oQuery := QueryBuilder():New()
    oQuery:Select( { "T9_FILIAL", "T9_CODBEM", "T9_CONTACU" } )
    oQuery:Select( "T9_HORINI" ):_As( "START_HOUR" )
    oQuery:Select( "T9_NOME" ):_As( "NAME" )
    oQuery:From( "ST9" ):_As( "T9" )
    oQuery:OrderBy( { "T9_CODBEM" } )
    oQuery:OrderBy( "T9_NOME" ):Desc()

    ConOut( oQuery:GetSql() )
