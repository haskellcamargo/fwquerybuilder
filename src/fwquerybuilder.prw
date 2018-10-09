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

#define SELECT_VALUE    2
#define SELECT_AS       3
#define SELECT_FUNCTION 4

#define FROM_VALUE 1
#define FROM_AS    2

#define ORDER_VALUE 1
#define ORDER_MODE  2

#define JOIN_MODE   1
#define JOIN_TABLE  2
#define JOIN_VALUES 3

#define ORDER_MODE_ASC  "ASC"
#define ORDER_MODE_DESC "DESC"

#define JOIN_MODE_INNER "INNER"
#define JOIN_MODE_LEFT  "LEFT"

#define IN_JOIN_MODE  1
#define IN_WHERE_MODE 2

//------------------------------------------------------------------------------
// EXPRESSION TYPES
//------------------------------------------------------------------------------
#define SQL_BINARY_EXPR  1 // { _, xLeft, cOp, xRight }
#define SQL_BETWEEN_EXPR 2 // { _, xValue, xFrom, xTo }
#define SQL_UNARY_EXPR   3 // { _, cOp, xExpr }

//------------------------------------------------------------------------------
// PROPERTY ACCESSORS
//------------------------------------------------------------------------------
#define SQL_EXPR_TYPE 1

#define SQL_BINARY_EXPR_LEFT  2
#define SQL_BINARY_EXPR_OP    3
#define SQL_BINARY_EXPR_RIGHT 4

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
    Data aStack      As Array

    Method New() Constructor

    // Select
    Method _As( cAs )
    Method From( cTable ) Constructor
    Method Select( xSelect )
    Method Top( nTop )

    // Unions
    Method Union( oRight )
    Method UnionAll( oRight )

    // Joins
    Method InnerJoin( cJoin )
    Method Join( cJoin, nMode )
    Method LeftJoin( cJoin )
    Method On( xLeft )

    // Where clause
    Method Where( xLeft )

    // Ordering
    Method Asc()
    Method Desc()
    Method OrderBy( xOrderBy )

    // Grouping
    Method GroupBy( xGroupBy )

    // Binary expressions
    Method And( xLeft )
    Method Equals( xRight )
    Method GreaterThan( xRight )
    Method _In( xRight )
    Method Like( xRight )

    // Aggregation functions
    Method Avg( xExpr )
    Method Count( xExpr )
    Method Max( xExpr )
    Method Min( xExpr )
    Method Sum( xExpr )

    // Exposed API
    Method GetSql()

    // Internal methods
    Method CallExpr( cCallee, xParam )
    Method PopNode()
    Method PushNode( xNode )
    Method Shift()
EndClass

Method New() Class QueryBuilder
    ::nMode      := 0
    ::aGroupBy   := {}
    ::aOrderBy   := {}
    ::aSelect    := {}
    ::aWhere     := {}
    ::aJoins     := {}
    ::aStack     := {}
    ::lUnionAll  := .F.
    ::lDidMount  := .T.
Return Self

Method CallExpr( cCallee, xParam ) Class QueryBuilder
    Local aValue

    aValue := { Nil, xParam, Nil, cCallee }
    AAdd( ::aSelect, aValue )
    ::nLastOp := OP_SELECT
    ::aLastOp := aValue
Return Self

Method PopNode() Class QueryBuilder
    Local nLength
    Local xNode

    nLength := Len( ::aStack )
    If nLength == 0
        UserException( "No expression on stack" )
    EndIf

    xNode := ::aStack[ nLength ]
    ADel( ::aStack, nLength )
    ASize( ::aStack, nLength - 1 )
Return xNode

Method PushNode( xNode ) Class QueryBuilder
    AAdd( ::aStack, xNode )
Return xNode

Method Shift() Class QueryBuilder
    Local nSize
    Local cOperator
    Local xLeft
    Local xRight
    Local aSource

    Do Case
        Case ::nMode == IN_JOIN_MODE
            aSource := ::aJoin[ JOIN_VALUES ]
        Case ::nMode == IN_WHERE_MODE
            aSource := ::aWhere
        Otherwise
            UserException( "Not inside predicate" )
    EndCase

    nSize := Len( ::aStack )
    If nSize >= 3
        cOperator := ::PopNode()
        xRight    := ::PopNode()
        xLeft     := ::PopNode()
        AAdd( aSource, { SQL_BINARY_EXPR, xLeft, cOperator, xRight } )
    EndIf
Return

//------------------------------------------------------------------------------
// SELECT
//------------------------------------------------------------------------------

Method _As( cAs ) Class QueryBuilder
    Do Case
        Case ::nLastOp == OP_SELECT
            ::aLastOp[ SELECT_AS ] := cAs
        Case ::nLastOp == OP_FROM
            ::aLastOp[ FROM_AS ] := cAs
    EndCase
Return Self

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

Method Select( xSelect ) Class QueryBuilder
    Local nIndex
    Local nLength
    Local cType
    Local aValue

    Default xSelect := {}

    If Empty( xSelect )
        Return Self
    EndIf

    cType := ValType( xSelect )
    // Normalize string to array
    If cType == "C" .Or. (cType == "O" .And. GetClassName( xSelect ) == "QUERYBUILDER")
        xSelect := { xSelect }
    ElseIf cType <> "A"
        UserException( "SELECT: expected string or array" )
    EndIf

    // Append each field with specialized anonymous alias and tell from
    nLength := Len( xSelect )
    For nIndex := 1 To nLength
        If !(ValType( xSelect[ nIndex ] ) $ "CO")
            UserException( "SELECT: expected string or object" )
        EndIf
        aValue := { Nil, xSelect[ nIndex ], Nil, Nil }
        AAdd( ::aSelect, aValue )
        If nIndex == nLength
            ::nLastOp := OP_SELECT
            ::aLastOp := aValue
        EndIf
    Next
Return Self

Method Top( nTop ) Class QueryBuilder
    If ValType( nTop ) <> "N"
        UserException( "TOP: expected number" )
    EndIf

    ::nTop := nTop
Return Self

//------------------------------------------------------------------------------
// UNIONS
//------------------------------------------------------------------------------

Method Union( oRight ) Class QueryBuilder
    If ValType( oRight ) <> "O"
        UserException( "UNION: expected object" )
    EndIf

    ::oUnion := oRight
Return Self

Method UnionAll( oRight ) Class QueryBuilder
    If ValType( oRight ) <> "O"
        UserException( "UNION ALL: expected object" )
    EndIf

    ::lUnionAll := .T.
    ::oUnion    := oRight
Return Self

//------------------------------------------------------------------------------
// JOINS
//------------------------------------------------------------------------------

Method InnerJoin( cJoin ) Class QueryBuilder
    ::Join( cJoin, JOIN_MODE_INNER )
Return Self

Method Join( cJoin, nMode ) Class QueryBuilder
    If ValType( cJoin ) <> "C"
        UserException( "JOIN: expected string" )
    EndIf

    ::nMode := IN_JOIN_MODE
    ::aJoin := { nMode, cJoin, {} }
    AAdd( ::aJoins, ::aJoin )
Return Self

Method LeftJoin( cJoin ) Class QueryBuilder
    ::Join( cJoin, JOIN_MODE_LEFT )
Return Self

Method On( xLeft ) Class QueryBuilder
    Local aValue
    Local cType

    cType := ValType( xLeft )
    Do Case
        Case cType == "U"
            Return Self
        Case cType == "C"
            ::nMode := IN_JOIN_MODE
            ::PushNode( xLeft )
        Otherwise
            UserException( "WHERE: expected string" )
    EndCase
Return Self

//------------------------------------------------------------------------------
// WHERE
//------------------------------------------------------------------------------

Method Where( xLeft ) Class QueryBuilder
    Local aValue
    Local cType

    cType := ValType( xLeft )
    Do Case
        Case cType == "U"
            Return Self
        Case cType == "C"
            ::nMode := IN_WHERE_MODE
            ::PushNode( xLeft )
        Otherwise
            UserException( "WHERE: expected string" )
    EndCase
Return Self

//------------------------------------------------------------------------------
// ORDERING
//------------------------------------------------------------------------------

Method Asc() Class QueryBuilder
    If ::nLastOp == OP_ORDER
        ::aLastOp[ ORDER_MODE ] := ORDER_MODE_ASC
    Else
        UserException( "ASC: can only be applied to an ORDER BY clause" )
    EndIf
Return Self

Method Desc() Class QueryBuilder
    If ::nLastOp == OP_ORDER
        ::aLastOp[ ORDER_MODE ] := ORDER_MODE_DESC
    Else
        UserException( "DESC: can only be applied to an ORDER BY clause" )
    EndIf
Return Self

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

//------------------------------------------------------------------------------
// GROUPING
//------------------------------------------------------------------------------

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
        aValue := xGroupBy[ nIndex ]
        AAdd( ::aGroupBy, aValue )
        If nIndex == nLength
            ::nLastOp := OP_GROUP
            ::aLastOp := aValue
        EndIf
    Next
Return Self

//------------------------------------------------------------------------------
// BINARY EXPRESSIONS
//------------------------------------------------------------------------------

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

Method Equals( xRight ) Class QueryBuilder
    ::PushNode( xRight )
    ::PushNode( "=" )
    ::Shift()
Return Self

Method GreaterThan( xRight ) Class QueryBuilder
    ::PushNode( xRight )
    ::PushNode( ">" )
    ::Shift()
Return Self

Method _In( xRight ) Class QueryBuilder
    ::PushNode( xRight )
    ::PushNode( "IN" )
    ::Shift()
Return Self

Method Like( cRight ) Class QueryBuilder
    If ValType( cRight ) <> "C"
        UserException( "LIKE: expected pattern" )
    EndIf

    ::PushNode( ValToSql( cRight ) )
    ::PushNode( "LIKE" )
    ::Shift()
Return Self

//------------------------------------------------------------------------------
// UNARY FUNCTIONS
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// AGGREGATION FUNCTIONS
//------------------------------------------------------------------------------

Method Avg( xExpr ) Class QueryBuilder
Return ::CallExpr( "AVG", xExpr )

Method Count( xExpr ) Class QueryBuilder
    Default xExpr := "1"
Return ::CallExpr( "COUNT", xExpr )

Method Max( xExpr ) Class QueryBuilder
Return ::CallExpr( "MAX", xExpr )

Method Min( xExpr ) Class QueryBuilder
Return ::CallExpr( "MIN", xExpr )

Method Sum( xExpr ) Class QueryBuilder
Return ::CallExpr( "SUM", xExpr )

//------------------------------------------------------------------------------
// EXPOSED API AND CODEGEN
//------------------------------------------------------------------------------

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

    Default M->NDEPTH := 0

    cSelect := Space( M->NDEPTH * 4 )
    cSelect += IIf( nTop == Nil, "SELECT ", "SELECT TOP " + AllTrim( Str( nTop ) ) + " " )
    // Create separator with given spacing
    cSeparator := "," + CRLF + Space( Len( cSelect ) )
    nLength    := Len( aSelect )
    // Empty select picks all fields
    If nLength == 0
        cSelect += "*" + CRLF
    Else
        For nIndex := 1 To nLength
            aField := aSelect[ nIndex ]
            // Check wrapping function and append field name
            If !Empty( aField[ SELECT_FUNCTION ] )
                cSelect += aField[ SELECT_FUNCTION ] + "("
                cSelect += GenExpr( aField[ SELECT_VALUE ] )
                cSelect += ")"
            Else
                cSelect += GenExpr( aField[ SELECT_VALUE ] )
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

    Default M->NDEPTH := 0

    cFrom := Space( M->NDEPTH * 4 ) + "FROM "
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
        aJoin  := aJoins[ nIndex ]
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
            cGroupBy += aGroupBy[ nIndex ]
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

    Default M->NDEPTH := 0

    If Empty( aWhere )
        cWhere := ""
    Else
        cWhere := Space( M->NDEPTH * 4 ) + "WHERE "
        cWhere += GenPredicates( aWhere ) + CRLF
    EndIf
Return cWhere

Static Function GenPredicates( aExpr )
    Local cPred
    Local nIndex
    Local nLength
    Local cSeparator

    Default M->NDEPTH := 0

    cPred   := ""
    nLength := Len( aExpr )
    cSeparator := CRLF + Space( M->NDEPTH * 4 ) + "  AND "
    For nIndex := 1 To nLength
        cPred += GenExpr( aExpr[ nIndex ] )
        If nIndex < nLength
            cPred += cSeparator
        EndIf
    Next
Return cPred

Static Function GenExpr( xExpr )
    Local cType
    Local cExpr

    Default M->NDEPTH := 0

    cExpr := ""
    cType := ValType( xExpr )
    Do Case
        Case cType == "O" .And. GetClassName( xExpr ) == "QUERYBUILDER"
            M->NDEPTH++
            cExpr += "(" + CRLF + xExpr:GetSql() + Space( M->NDEPTH  * 2 ) + ")"
            M->NDEPTH--
        Case cType == "A"
            Do Case
                Case xExpr[ SQL_EXPR_TYPE ] == SQL_BINARY_EXPR
                    cExpr += GenExpr( xExpr[ SQL_BINARY_EXPR_LEFT ] )
                    cExpr += " " + xExpr[ SQL_BINARY_EXPR_OP ] + " "
                    cExpr += GenExpr( xExpr[ SQL_BINARY_EXPR_RIGHT ] )
            EndCase
        Case cType == "C"
            cExpr += xExpr
    EndCase
Return cExpr
