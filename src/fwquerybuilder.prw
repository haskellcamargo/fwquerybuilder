#ifdef __HARBOUR__
#include 'hbclass.ch'
#else
#include 'protheus.ch'
#endif

#define CRLF Chr( 13 ) + Chr( 10 )

#define OP_SELECT 1
#define OP_ORDER  2
#define OP_FROM   3
#define OP_GROUP  4

#define SELECT_PREFIX   1
#define SELECT_VALUE    2
#define SELECT_AS       3
#define SELECT_FUNCTION 4

#define FROM_VALUE 1
#define FROM_AS    2

#define GROUP_VALUE 1

#define WHERE_LEFT     1
#define WHERE_OPERATOR 2
#define WHERE_RIGHT    3

#define ORDER_VALUE 1
#define ORDER_MODE  2

#define SELECT_FUNCTION_COUNT "COUNT"
#define SELECT_FUNCTION_SUM   "SUM"

#define ORDER_MODE_ASC  "ASC"
#define ORDER_MODE_DESC "DESC"

#ifdef __HARBOUR__
Class QueryBuilder
#else
Class QueryBuilder From LongNameClass
#endif
    Data aFrom       As Array
    Data aGroupBy    As Array
    Data aOrderBy    As Array
    Data aSelect     As Array
    Data aWhere      As Array
    Data nTop        As Numeric
    Data nLastOp     As Numeric
    Data cLastOp     As String
    Data aLastOp     As Array

    Data nCurrAlias
    Data nNextAlias

    Method New() Constructor
    Method _As( cAs )
    Method Asc()
    Method Count( xExpr )
    Method Desc()
    Method From( cTable )
    Method GroupBy( xGroupBy )
    Method OrderBy( xOrderBy )
    Method Select( xSelect )
    Method Sum( xExpr )
    Method Top( nTop )

    Method GetSql()

    Method NextAlias()
EndClass

Method New() Class QueryBuilder
    ::nNextAlias := 0
    ::aGroupBy   := {}
    ::aOrderBy   := {}
    ::aSelect    := {}
    ::aWhere     := { { "D_E_L_E_T_", "<>", "'*'" } }
Return Self

Method NextAlias() Class QueryBuilder
    Local cAlias := "TB" + AllTrim( Str( ::nNextAlias ) )
    ::nNextAlias++
Return cAlias

/**
 * :Select( "T9_CODBEM" ):_As( "NAME" )
 * :From( "ST9" ):_As( "T9" )
 */
Method _As( cAs ) Class QueryBuilder
    Do Case
        Case ::nLastOp == OP_SELECT
            ::aLastOp[ SELECT_AS ] := cAs
        Case ::nLastOp == OP_FROM
            ::aLastOp[ FROM_AS ] := cAs
    EndCase
Return Self

/**
 * :OrderBy( "C" ):Asc()
 * :OrderBy( { "A", "B" } ):Asc()
 */
Method Asc() Class QueryBuilder
    If ::nLastOp == OP_ORDER
        ::aLastOp[ ORDER_MODE ] := ORDER_MODE_ASC
    Else
        UserException( "ASC: can only be applied to an ORDER BY clause" )
    EndIf
Return Self

/**
 * :Select( "A" ):Count( "B" )
 * :Count( "C")
 * :Count()
 */
Method Count( xExpr ) Class QueryBuilder
    Local aValue

    Default xExpr := '1'

    aValue := { Nil, xExpr, Nil, SELECT_FUNCTION_COUNT }
    AAdd( ::aSelect, aValue )
    ::nLastOp := OP_SELECT
    ::aLastOp := aValue
Return Self

/**
 * :OrderBy( "C" ):Desc()
 * :OrderBy( { "A", "B" } ):Desc()
 */
Method Desc() Class QueryBuilder
    If ::nLastOp == OP_ORDER
        ::aLastOp[ ORDER_MODE ] := ORDER_MODE_DESC
    Else
        UserException( "DESC: can only be applied to an ORDER BY clause" )
    EndIf
Return Self

/**
 * :From( "ST9" )
 */
Method From( cFrom ) Class QueryBuilder
    Local nIndex
    Local aFrom

    If ValType( cFrom ) <> "C"
        UserException( "FROM: expected string" )
    EndIf

    aFrom := { cFrom, Nil }
    ::aFrom      := aFrom
    ::nLastOp    := OP_FROM
    ::aLastOp    := aFrom
Return Self

/**
 * :GroupBy( "A" )
 * :GroupBy( { "B", "C" } )
 */
Method GroupBy( xGroupBy ) Class QueryBuilder
    Local nIndex
    Local nLength
    Local cType
    Local aValue

    cType := ValType( xGroupBy )
    // Normalize string to array
    If cType == "C"
        xGroupBy := { xGroupBy }
    ElseIf cType <> "A"
        UserException( "GROUP BY: expected string or array" )
    EndIf

    nLength := Len( xGroupBy )
    For nIndex := 1 To nLength
        If ValType( xGroupBy[ nIndex ] ) <> "C"
            UserException( "GROUP BY: expected string" )
        EndIf
        aValue := { xGroupBy[ nIndex ] }
        AAdd( ::aGroupBy, aValue )
        If nIndex == nLength
            ::nLastOp := OP_GROUP
            ::aLastOp := aValue
        EndIf
    Next
Return Self

/**
 * :OrderBy( { "A", "B" } )
 * :OrderBy( "C" )
 */
Method OrderBy( xOrderBy ) Class QueryBuilder
    Local nIndex
    Local nLength
    Local cType
    Local aValue

    cType := ValType( xOrderBy )
    // Normalize string to array
    If cType == "C"
        xOrderBy := { xOrderBy }
    ElseIf cType <> "A"
        UserException( "ORDER BY: expected string or array" )
    EndIf

    nLength := Len( xOrderBy )
    For nIndex := 1 To nLength
        If ValType( xOrderBy[ nIndex ] ) <> "C"
            UserException( "ORDER BY: expected string" )
        EndIf
        aValue := { xOrderBy[ nIndex ], Nil }
        AAdd( ::aOrderBy, aValue )
        If nIndex == nLength
            ::nLastOp := OP_ORDER
            ::aLastOp := aValue
        EndIf
    Next
Return Self

/**
 * :Select( "NAME" )
 * :Select( { "NAME", "AGE", "0" } )
 */
Method Select( xSelect ) Class QueryBuilder
    Local nIndex
    Local nLength
    Local cType
    Local aValue

    cType := ValType( xSelect )
    // Normalize string to array
    If cType == "C"
        xSelect := { xSelect }
    ElseIf cType <> "A"
        UserException( "SELECT: expected string or array" )
    EndIf

    // Append each field with specialized anonymous alias and tell from
    nLength := Len( xSelect )
    For nIndex := 1 To nLength
        If ValType( xSelect[ nIndex ] ) <> "C"
            UserException( "SELECT: expected string" )
        EndIf
        aValue := { Nil, xSelect[ nIndex ], Nil, Nil }
        AAdd( ::aSelect, aValue )
        If nIndex == nLength
            ::nLastOp := OP_SELECT
            ::aLastOp := aValue
        EndIf
    Next
Return Self

/**
 * :Select( "A" ):Sum( "B" )
 * :Sum( "C" )
 */
Method Sum( xExpr ) Class QueryBuilder
    Local aValue

    aValue := { Nil, xExpr, Nil, SELECT_FUNCTION_SUM }
    AAdd( ::aSelect, aValue )
    ::nLastOp := OP_SELECT
    ::aLastOp := aValue
Return Self

/**
 * :Select( "A" ):Top( 10 )
 * :Top( 20 )
 */
Method Top( nTop ) Class QueryBuilder
    If ValType( nTop ) <> "N"
        UserException( "TOP: expected number" )
    EndIf

    ::nTop := nTop
Return Self

Method GetSql() Class QueryBuilder
    Local cSql

    cSql := GenSelect( ::aSelect, ::nTop )
    cSql += GenFrom( ::aFrom )
    cSql += GenGroupBy( ::aGroupBy )
    cSql += GenWhere( ::aWhere )
    cSql += GenOrderBy( ::aOrderBy )
Return cSql

Static Function GenSelect( aSelect, nTop )
    Local cSelect
    Local nLength
    Local nIndex
    Local aField
    Local cSeparator

    cSelect := IIf( nTop == Nil, "SELECT   ", "SELECT TOP " + AllTrim( Str( nTop ) ) + " " )
    // Create separator with given spacing
    cSeparator := "," + CRLF + Space( Len( cSelect ) )
    nLength    := Len( aSelect )
    // Empty select picks all fields
    If nLength == 0
        cSelect += "*" + CRLF
    Else
        For nIndex := 1 To nLength
            aField := aSelect[ nIndex ]
            // Prefix is given
            If !Empty( aField[ SELECT_PREFIX ] )
                cSelect += aField[ SELECT_PREFIX ] + "."
            EndIf
            // Check wrapping function and append field name
            If !Empty( aField[ SELECT_FUNCTION ] )
                cSelect += aField[ SELECT_FUNCTION ] + "("
                cSelect += aField[ SELECT_VALUE ]
                cSelect += ")"
            Else
                cSelect += aField[ SELECT_VALUE ]
            EndIf
            // Alias is given
            If !Empty( aField[ SELECT_AS ] )
                cSelect += " AS " + aField[ SELECT_AS ]
            EndIf
            // Append separator between fields
            If nIndex < nLength
                cSelect += cSeparator
            EndIf
        Next
        cSelect += CRLF
    EndIf
Return cSelect

Static Function GenFrom( aFrom )
    Local cFrom

    cFrom := "FROM     "
    cFrom += aFrom[ FROM_VALUE ]
    If !Empty( aFrom[ FROM_AS ] )
        cFrom += " " + aFrom[ FROM_AS ]
    EndIf
    cFrom += CRLF
Return cFrom

Static Function GenGroupBy( aGroupBy )
    Local cGroupBy
    Local nIndex
    Local nLength

    nLength := Len( aGroupBy )
    // Empty order generates no code
    If nLength == 0
        cGroupBy := ""
    Else
        cGroupBy := "GROUP BY "
        For nIndex := 1 To nLength
            // Append order field name
            cGroupBy += aGroupBy[ nIndex, ORDER_VALUE ]
            If nIndex < nLength
                cGroupBy += ", "
            EndIf
        Next
        cGroupBy += CRLF
    EndIf
Return cGroupBy

Static Function GenOrderBy( aOrderBy, nSpaces, lNewline )
    Local cOrderBy
    Local nIndex
    Local nLength

    nLength := Len( aOrderBy )
    // Empty order generates no code
    If nLength == 0
        cOrderBy := ""
    Else
        cOrderBy := "ORDER BY "
        For nIndex := 1 To nLength
            // Append order field name
            cOrderBy += aOrderBy[ nIndex, ORDER_VALUE ]
            // Append order mode for field, if possible
            If !Empty( aOrderBy[ nIndex, ORDER_MODE ] )
                cOrderBy += " " + aOrderBy[ nIndex, ORDER_MODE ]
            EndIf
            If nIndex < nLength
                cOrderBy += ", "
            EndIf
        Next
        cOrderBy += CRLF
    EndIf
Return cOrderBy

Static Function GenWhere( aWhere )
    Local cWhere
    Local nIndex
    Local nLength
    Local cSeparator

    nLength := Len( aWhere )
    If nLength == 0
        cWhere := ""
    Else
        cWhere := "WHERE    "
        cSeparator := "," + Space( Len( cWhere ) ) + CRLF
        For nIndex := 1 To nLength
            cWhere += aWhere[ nIndex, WHERE_LEFT ]
            cWhere += " " + aWhere[ nIndex, WHERE_OPERATOR ] + " "
            cWhere += aWhere[ nIndex, WHERE_RIGHT ]

            If nIndex < nLength
                cOrderBy += ", "
            EndIf
        Next
        cWhere += CRLF
    EndIf
Return cWhere

#ifdef __HARBOUR__
Procedure Main()
#else
User Function Build()
#endif
    Local oQuery

    oQuery := QueryBuilder():New()
    oQuery:Select( { "T9_FILIAL", "T9_CODBEM", "T9_CONTACU" } )
    oQuery:Sum( "T9_CONTACU" )
    oQuery:Count()
    oQuery:Select( "T9_HORINI" ):_As( "START_HOUR" )
    oQuery:Select( "T9_NOME" ):_As( "NAME" )
    oQuery:From( "ST9" ):_As( "T9" )
    oQuery:GroupBy( "T9_CONTACU" )
    oQuery:GroupBy( { "AND_OTHER", "ANOTHER" } )
    oQuery:OrderBy( { "T9_CODBEM" } )
    oQuery:OrderBy( "T9_NOME" ):Desc()

    ConOut( oQuery:GetSql() )
