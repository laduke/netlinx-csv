PROGRAM_NAME='inc-csv'


DEFINE_CONSTANT
INTEGER MAX_COLS = 26
INTEGER MAX_CHARS = 1024
CHAR EOF = 255

INTEGER TKN_INIT = 1
INTEGER TKN_PEEK = 2
INTEGER TKN_READ = 3
INTEGER TKN_UNREAD = 4

INTEGER CNSMR_INIT = 1
INTEGER CNSMR_CONSUME_FIELD = 2 
INTEGER CNSMR_END_OF_RECORD = 3
INTEGER CNSMR_EOF = 4

DEFINE_TYPE
STRUCTURE _Tokenizer
{
    CHAR s[MAX_CHARS]
    INTEGER nIndex
    INTEGER bHaveUnreadChar
    CHAR cUnreadChar
    CHAR c
    CHAR ch
    
    //consumer
    INTEGER nNumFields
    INTEGER nNumRows
    CHAR cFieldValue[MAX_CHARS]
    CHAR c_Record[MAX_COLS][MAX_CHARS]
    
    INTEGER nFlag
    INTEGER nNumFieldsLastRecord
}


DEFINE_FUNCTION CHAR fnTokenizer(_Tokenizer Vars, INTEGER nAction)
{
    
    SWITCH(nAction)
    {
	CASE TKN_INIT: 
	{ 
	    Vars.nIndex = 0
	    Vars.bHaveUnreadChar = FALSE
	}
	CASE TKN_PEEK:
	{
	    Vars.nFlag = 0
	    
	    IF(Vars.bHaveUnreadChar)
	    {
		Vars.ch = Vars.cUnreadChar;
		RETURN Vars.ch
	    }
	    IF (Vars.nIndex+1 <= LENGTH_STRING(Vars.s))
	    {
		Vars.ch = mapCrToLf(Vars.s[Vars.nIndex+1]);
		RETURN Vars.ch
	    }
	    
	    RETURN EOF
	}
	CASE TKN_READ:
	{
	    IF(Vars.bHaveUnreadChar)
	    {
		    Vars.bHaveUnreadChar = FALSE
		Vars.ch = Vars.cUnreadChar
		
		return Vars.ch
	    }
	    IF(Vars.nIndex <= LENGTH_STRING(Vars.s))
	    {//skipCrInCrLf
		if ( (Vars.s[Vars.nIndex+1] == 13) && 
		    (Vars.nIndex+1 <= LENGTH_STRING(Vars.s) ) && 
		    (Vars.s[Vars.nIndex+1] == 10) ) 
		{ 
		    Vars.nIndex++ 
		}
		Vars.nIndex++
		Vars.ch =  mapCrToLf(Vars.s[Vars.nIndex]);
		
		RETURN Vars.ch
	    }
	    
	    return EOF
	}
	CASE TKN_UNREAD:
	{
	    if (Vars.bHaveUnreadChar) {
	     RETURN 0 //error
	    }
	    Vars.bHaveUnreadChar = true;
	    Vars.cUnreadChar = Vars.c;
	    Vars.c = 0
	}
    }
    
}

DEFINE_FUNCTION INTEGER fnParseCSVRecord(_Tokenizer Vars)
{
    STACK_VAR CHAR ch
    
    parseCsvStringList(Vars);
    
    ch = fnTokenizer(Vars, TKN_READ)
    if (ch == EOF) {
	Vars.c = ch
	fnTokenizer(Vars, TKN_UNREAD)
	ch = 10;
    }
    if (ch != 10) {
	RETURN 0 //error
    }
    fnConsumer(Vars, CNSMR_END_OF_RECORD)
}

DEFINE_FUNCTION INTEGER parseCsvStringList(_Tokenizer Vars)
{
    char ch;
    
    WHILE(TRUE) 
    {
	parseRawString(Vars);
	ch = fnTokenizer(Vars, TKN_READ)
	IF(ch <> ','){BREAK}
    }
    
    Vars.c = ch
    fnTokenizer(Vars, TKN_UNREAD)
}

DEFINE_FUNCTION INTEGER isFieldTerminator(char c) {
  return ((c == ',') || (c == 10) || (c == EOF));
}

DEFINE_FUNCTION INTEGER isSpace(char c) {
  return ( (c == "$20") || (c == "$09") ); //space or tab
}

DEFINE_FUNCTION INTEGER parseOptionalSpaces(_Tokenizer Vars) {
    char ch;
    WHILE(TRUE) 
    {  
	ch = fnTokenizer(Vars, TKN_READ)
	IF( !isSpace(ch) ) {break}
    }
    Vars.c = ch
    fnTokenizer(Vars, TKN_UNREAD)
}

DEFINE_FUNCTION INTEGER parseRawString(_Tokenizer Vars) {
    parseOptionalSpaces(Vars);
    parseRawField(Vars);
    if (!isFieldTerminator(fnTokenizer(Vars, TKN_PEEK)))
    {
	parseOptionalSpaces(Vars);
    }
}

DEFINE_FUNCTION INTEGER parseRawField(_Tokenizer Vars) {
    STACK_VAR CHAR fieldValue[MAX_CHARS]
    STACK_VAR CHAR ch
    
    ch = fnTokenizer(Vars,TKN_PEEK);
    if (!isFieldTerminator(ch)) {
	if (ch == "$22") // double quote "
	{
	    fieldValue = parseQuotedField(Vars);
	}
	else 
	{
	   fieldValue = parseSimpleField(Vars);
	}
	Vars.cFieldValue = fieldValue
	fnConsumer(Vars, CNSMR_CONSUME_FIELD)
    }
    
}

DEFINE_FUNCTION CHAR[MAX_CHARS] parseQuotedField(_Tokenizer Vars) {
    STACK_VAR CHAR field[MAX_CHARS]
    STACK_VAR CHAR ch
    
    fnTokenizer(Vars, TKN_READ); // read and discard initial quote

    field = parseEscapedField(Vars);

  ch = fnTokenizer(Vars, TKN_READ);
  if (ch != '"') {
    Vars.c = ch
    fnTokenizer(Vars, TKN_UNREAD);
    RETURN 0
        //"Quoted field has no terminating double quote");
  }
  return field;
}

DEFINE_FUNCTION CHAR[MAX_CHARS] parseEscapedField(_Tokenizer Vars) {
    STACK_VAR CHAR sb[MAX_CHARS]
    STACK_VAR CHAR ch
  
    parseSubField(Vars, sb);
    ch = fnTokenizer(Vars, TKN_READ);
    
    while (processDoubleQuote(Vars, ch)) {
	sb = "sb,'"'"
	parseSubField(Vars, sb);
	ch = fnTokenizer(Vars, TKN_READ);
    }
    Vars.c = ch
    fnTokenizer(Vars, TKN_UNREAD);
    
    return sb;
}

DEFINE_FUNCTION INTEGER parseSubField(_Tokenizer Vars, CHAR sb[]) {
  STACK_VAR CHAR ch
  
  ch = fnTokenizer(Vars, TKN_READ);
  
  while ((ch != '"') && (ch != EOF)) {
    sb = "sb,ch"

    ch = fnTokenizer(Vars, TKN_READ);
  }
  Vars.c = ch
  fnTokenizer(Vars, TKN_UNREAD);
}

DEFINE_FUNCTION INTEGER isBadSimpleFieldChar(char c) {
  return ( /*isSpace(c) ||*/ isFieldTerminator(c) || (c == "$22") );
}

DEFINE_FUNCTION CHAR[MAX_CHARS] parseSimpleField(_Tokenizer Vars) {

  STACK_VAR CHAR ch
  STACK_VAR CHAR sb[max_chars]
  
  ch = fnTokenizer(Vars, TKN_READ);
  
  if (isBadSimpleFieldChar(ch)) {
    Vars.c = ch
    fnTokenizer(Vars, TKN_UNREAD);
    return ''
  }

  sb = "sb, ch"
  
    ch = fnTokenizer(Vars, TKN_READ);
    while (!isBadSimpleFieldChar(ch)) {
	sb = "sb, ch"
	ch = fnTokenizer(Vars, TKN_READ);
    }
  
    Vars.c = ch
    fnTokenizer(Vars, TKN_UNREAD);

    return sb
}

DEFINE_FUNCTION INTEGER processDoubleQuote(_Tokenizer Vars, char ch) {
  
  if ((ch == "$22") && (fnTokenizer(Vars,TKN_PEEK) == "$22")) {
    fnTokenizer(Vars, TKN_READ); // discard second quote of double
    return true;
  }
  return false;
}
DEFINE_FUNCTION CHAR mapCrToLf(char c)
{
    if (c == 13)
	return 10;
    
    return c;
}

//DEFINE_FUNCTION CHAR skipCrInCrLf(char c)
//{
//    if ((s[nIndex] == 13) &&
//    (nIndex + 1 < LENGTH_STRING(s)) &&
//    (s[nIndex + 1] == 10))
//    nIndex++;
//}

DEFINE_FUNCTION INTEGER fnConsumer(_Tokenizer Vars, INTEGER nMethod)
{
    Vars.nFlag = nMethod
    SWITCH(nMethod)
    {
	CASE CNSMR_INIT: 
	{ 
	    Vars.nNumRows = 0
	    Vars.nNumFields = 0
	}
	CASE CNSMR_CONSUME_FIELD:
	{
	    Vars.nNumFields++
	    Vars.c_Record[Vars.nNumFields] = Vars.cFieldValue
	    //Vars.cFieldValue = ''
	}
	CASE CNSMR_END_OF_RECORD:
	{
	    Vars.nNumRows++
	    Vars.nNumFieldsLastRecord = Vars.nNumFields
	    Vars.nNumFields=0
	}
	CASE CNSMR_EOF:
	{
	    fnConsumer(Vars, CNSMR_INIT)
	}
    }
}
