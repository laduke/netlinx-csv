PROGRAM_NAME='main'
DEFINE_DEVICE
vdvCSVModule = 33333:1:0
vdvModule = 33333:1:0

dvRelay = 5001:4:0

DEFINE_CONSTANT
#INCLUDE'inc-csv'

DEFINE_VARIABLE
_Tokenizer _tokenizer1

DEFINE_VARIABLE
CHAR str_csv_mock[1024]

DEFINE_FUNCTION INTEGER fnLoadCSVMock(CHAR str[])
{
    str = "'one,1,1,1',13,10,'2,two,2,2',13,',3,3,"three",',10,'4,4,4,"fo,ur",'"
}

DEFINE_FUNCTION INTEGER fnConsumerConsumeField(_Tokenizer Vars)
{
    fnDEBUG2(__FILE__, DEBUG, nDebugCSV, "'    fnConsumerConsumeField ', ITOA(Vars.nNumFields), ' -- ', Vars.cFieldValue")
} 

DEFINE_FUNCTION INTEGER fnConsumerEndOfRecord(_Tokenizer Vars) 
{
    STACK_VAR INTEGER nLoop
    STACK_VAR CHAR cMsg[MAX_CHARS * MAX_COLS]
    
    fnDEBUG2(__FILE__, DEBUG, nDebugCSV, "'  fnConsumerEndOfRecord ', ITOA(Vars.nNumRows)")
    
    FOR(nLoop = 1; nLoop <= Vars.nNumFieldsLastRecord; nLoop++)
    {
	cMsg = "cMsg,'"', Vars.c_Record[nLoop],'" '"
    }
    IF(LENGTH_STRING(cMsg) > 1)
    {
	fnDEBUG2(__FILE__, INFO, nDebugCSV, "'    [',cMsg,']'")
    }

} 

DEFINE_FUNCTION INTEGER fnConsumerEndOfFile(_Tokenizer Vars) 
{
    fnDEBUG2(__FILE__, DEBUG, nDebugCSV, "'fnConsumerEndOfFile '")
} 

DEFINE_START
fnLoadCSVMock(str_csv_mock)

DEFINE_EVENT
CHANNEL_EVENT[vdvModule,0]
{
    ON:
    {
	STACK_VAR INTEGER nLengthLine
	STACK_VAR CHAR sReturn[256]
	
	SWITCH(CHANNEL.CHANNEL)
	{
	    CASE 1: {fnLoadCSVMock(str_csv_mock)}
	    CASE 2:
	    {

	    }
	    CASE 3:
	    {
		STACK_VAR CHAR cResult
		
		fnLoadCSVMock(str_csv_mock)
		
		fnDEBUG(vdvModule, DEBUG, nDebugCSV, "'fnTokenizer init'")
		
		_tokenizer1.s = str_csv_mock
		fnTokenizer(_tokenizer1, TKN_INIT)
		
		cResult = fnTokenizer(_tokenizer1, TKN_PEEK)
		
		WHILE(cResult && (cResult <> EOF))
		{
		    //fnDEBUG(vdvModule, TRACE, nDebugCSV, "'cResult ', cResult")
		    
		    fnParseCSVRecord(_tokenizer1)
		    		    
		    SWITCH(_tokenizer1.nFlag)
		    {
			CASE CNSMR_CONSUME_FIELD:
			{
			   fnConsumerConsumeField(_tokenizer1)
			}
			CASE CNSMR_END_OF_RECORD:
			{
			   fnConsumerEndOfRecord(_tokenizer1)
			}
			CASE CNSMR_EOF:
			{
			    fnConsumerEndOfFile(_tokenizer1)
			}
		    }
		    
		    cResult = fnTokenizer(_tokenizer1, TKN_PEEK)
		}
		fnConsumer(_tokenizer1, CNSMR_EOF);
	    }
	}
    }
}



//DEFINE_MODULE 'mdl-csv' mdlcsv01(vdvCSVModule)