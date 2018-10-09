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

#define ORDER_VALUE 1
#define ORDER_MODE  2

#define BINARY_EXPR_LEFT  1
#define BINARY_EXPR_OP    2
#define BINARY_EXPR_RIGHT 3

#define JOIN_MODE   1
#define JOIN_TABLE  2
#define JOIN_VALUES 3

#define SELECT_FUNCTION_COUNT "COUNT"
#define SELECT_FUNCTION_SUM   "SUM"

#define ORDER_MODE_ASC  "ASC"
#define ORDER_MODE_DESC "DESC"

#define JOIN_MODE_INNER "INNER"
#define JOIN_MODE_LEFT  "LEFT"

#define IN_JOIN_MODE  1
#define IN_WHERE_MODE 2

#ifdef __HARBOUR__
Class QueryBuilder
#else
Class QueryBuilder From LongNameClass
#endif
    Data nMode       As Numeric
    Data aFrom       As Array
    Data aGroupBy    As Array
    Data aOrderBy    As Array
    Data aSelect     As Array
    Data aWhere      As Array
    Data oUnion      As Object
    Data lUnionAll   As Logical
    Data aJoin       As Array
    Data aJoins      As Array
    Data nTop        As Numeric
    Data nLastOp     As Numeric
    Data cLastOp     As String
    Data aLastOp     As Array
    Data lDidMount   As Logical

    Data nCurrAlias
    Data nNextAlias

    Method New() Constructor

    // Select
    Method _As( cAs )
    Method Count( xExpr )
    Method From( cTable ) Constructor
    Method Select( xSelect )
    Method Sum( xExpr )
    Method Top( nTop )

    // Unions
    Method Union( oRight )
    Method UnionAll( oRight )

    // Joins
    Method InnerJoin( cJoin )
    Method Join( cJoin, nMode )
    Method LeftJoin( cJoin )
    Method On( xLeft )

    // Where clause and predicates
    Method And( xLeft )
    Method Where( xLeft )

    // Ordering and grouping
    Method Asc()
    Method Desc()
    Method GroupBy( xGroupBy )
    Method OrderBy( xOrderBy )

    // Binary operators
    Method Equals( xRight )
    Method GreaterThan( xRight )

    // Exposed API
    Method GetSql()

    // Internal methods
    Method BinaryExpr( cOperator, xRight )
    Method NextAlias()
EndClass

Method New() Class QueryBuilder
    ::nMode      := 0
    ::nNextAlias := 0
    ::aGroupBy   := {}
    ::aOrderBy   := {}
    ::aSelect    := {}
    ::aWhere     := { { "D_E_L_E_T_", "<>", "'*'" } }
    ::aJoins     := {}
    ::lUnionAll  := .F.
    ::lDidMount  := .T.
Return Self

Method BinaryExpr( cOperator, xRight ) Class QueryBuilder
    Local aPeek
    Local aSource

    Do Case
        Case ::nMode == IN_JOIN_MODE
            aSource := ::aJoin[ JOIN_VALUES ]
        Case ::nMode == IN_WHERE_MODE
            aSource := ::aWhere
        Otherwise
            UserException( "(" + cOperator + "): not inside predicate")
    EndCase

    aPeek := ATail( aSource )
    aPeek[ BINARY_EXPR_OP ]    := cOperator
    aPeek[ BINARY_EXPR_RIGHT ] := xRight
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

    Default xExpr := "1"

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
 * :Join( "A" ):On( "B" ):Equals( "C" )
 */
Method Equals( xRight ) Class QueryBuilder
Return ::BinaryExpr( "=", xRight )

/**
 * :From( "ST9" )
 */
Method From( cFrom ) Class QueryBuilder
    Local nIndex
    Local aFrom

    If ValType( cFrom ) <> "C"
        UserException( "FROM: expected string" )
    EndIf

    If Empty( ::lDidMount )
        ::New()
    EndIf

    aFrom := { cFrom, Nil }
    ::aFrom      := aFrom
    ::nLastOp    := OP_FROM
    ::aLastOp    := aFrom
Return Self

/**
 * :Where( "A" ):GreaterThan( "B" )
 */
Method GreaterThan( xRight ) Class QueryBuilder
Return ::BinaryExpr( ">", xRight )

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
 * :InnerJoin( "A" )
 */
Method InnerJoin( cJoin ) Class QueryBuilder
    ::Join( cJoin, JOIN_MODE_INNER )
Return Self

/**
 * :Join( "A" )
 */
Method Join( cJoin, nMode ) Class QueryBuilder
    If ValType( cJoin ) <> "C"
        UserException( "JOIN: expected string" )
    EndIf

    ::nMode := IN_JOIN_MODE
    ::aJoin := { nMode, cJoin, {} }
    AAdd( ::aJoins, ::aJoin )
Return Self

/**
 * :LeftJoin( "A" )
 */
Method LeftJoin( cJoin ) Class QueryBuilder
    ::Join( cJoin, JOIN_MODE_LEFT )
Return Self

/**
 * :Join( "A" ):On( "B" )
 */
Method On( xLeft ) Class QueryBuilder
    Local aValue

    aValue := { xLeft, Nil, Nil }
    AAdd( ::aJoin[ JOIN_VALUES ], aValue )
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

/**
 * :From( "A" ):Union( QueryBuilder():From( "B" ) )
 */
Method Union( oRight ) Class QueryBuilder
    If ValType( oRight ) <> "O"
        UserException( "UNION: expected object" )
    EndIf

    ::oUnion := oRight
Return Self

/**
 * :From( "A" ):UnionAll( QueryBuilder():From( "B" ) )
 */
Method UnionAll( oRight ) Class QueryBuilder
    If ValType( oRight ) <> "O"
        UserException( "UNION ALL: expected object" )
    EndIf

    ::lUnionAll := .T.
    ::oUnion    := oRight
Return Self

/**
 * :Where( "A" )
 */
Method Where( xLeft ) Class QueryBuilder
    Local aValue

    ::nMode := IN_WHERE_MODE
    aValue := { xLeft, Nil, Nil }
    AAdd( ::aWhere, aValue )
Return Self

/**
 * :Where( "A" ):Equals( "B" ):And( "C" ):Equals( "D" )
 */
Method And( xLeft ) Class QueryBuilder
    Do Case
        Case ::nMode == IN_JOIN_MODE
            ::On( xLeft )
        Case ::nMode == IN_WHERE_MODE
            ::Where( xLeft )
        Otherwise
            UserException( "AND: not inside predicate")
    EndCase
Return Self

Method GetSql() Class QueryBuilder
    Local cSql

    cSql := GenSelect( ::aSelect, ::nTop )
    cSql += GenFrom( ::aFrom )
    cSql += GenJoins( ::aJoins )
    cSql += GenGroupBy( ::aGroupBy )
    cSql += GenWhere( ::aWhere )
    cSql += GenOrderBy( ::aOrderBy )
    cSql += GenUnion( ::oUnion, ::lUnionAll )
Return cSql

Static Function GenSelect( aSelect, nTop )
    Local cSelect
    Local nLength
    Local nIndex
    Local aField
    Local cSeparator

    cSelect := IIf( nTop == Nil, "SELECT ", "SELECT TOP " + AllTrim( Str( nTop ) ) + " " )
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

    cFrom := "FROM "
    cFrom += aFrom[ FROM_VALUE ]
    If !Empty( aFrom[ FROM_AS ] )
        cFrom += " " + aFrom[ FROM_AS ]
    EndIf
    cFrom += CRLF
Return cFrom

Static Function GenJoins( aJoins )
    Local cJoins
    Local nIndex
    Local nLength
    Local aJoin

    cJoins := ""
    If Empty( aJoins )
        Return cJoins
    EndIf

    nLength := Len( aJoins )
    For nIndex := 1 To nLength
        aJoin    := aJoins[ nIndex ]
        cJoins += IIf( Empty( aJoin[ JOIN_MODE ] ), "JOIN ", aJoin[ JOIN_MODE ] + " JOIN " )
        cJoins += aJoin[ JOIN_TABLE ] + CRLF
        cJoins += "  ON "
        cJoins += GenPredicates( aJoin[ JOIN_VALUES ] ) + CRLF
    Next
Return cJoins

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

Static Function GenUnion( oUnion, lUnionAll )
    Local cUnion := ""

    Default lUnionAll := .F.
    If oUnion <> Nil
        cUnion := IIf( lUnionAll, "UNION ALL", "UNION" ) + CRLF
        cUnion += oUnion:GetSql()
    EndIf
Return cUnion

Static Function GenWhere( aWhere )
    Local cWhere
    Local nLength

    If Empty( aWhere )
        cWhere := ""
    Else
        cWhere := "WHERE "
        cWhere += GenPredicates( aWhere ) + CRLF
    EndIf

Return cWhere

Static Function GenPredicates( aExpr )
    Local cPred
    Local nIndex
    Local nLength
    Local cSeparator

    cPred   := ""
    nLength := Len( aExpr )
    cSeparator := CRLF + "  AND "
    For nIndex := 1 To nLength
        cPred += aExpr[ nIndex, BINARY_EXPR_LEFT ]
        cPred += " " + aExpr[ nIndex, BINARY_EXPR_OP ] + " "
        cPred += aExpr[ nIndex, BINARY_EXPR_RIGHT ]

        If nIndex < nLength
            cPred += cSeparator
        EndIf
    Next
Return cPred
