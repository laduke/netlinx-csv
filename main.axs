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
		    fnDEBUG(vdvModule, TRACE, nDebugCSV, "'cResult ', cResult")
		    
		    fnParseCSVRecord(_tokenizer1)
		    
		    cResult = fnTokenizer(_tokenizer1, TKN_PEEK)
		}
		fnConsumer(_tokenizer1, CNSMR_EOF);
	    }
	}
    }
}



//DEFINE_MODULE 'mdl-csv' mdlcsv01(vdvCSVModule)