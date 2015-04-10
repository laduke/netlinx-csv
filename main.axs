PROGRAM_NAME='main'
DEFINE_DEVICE
vdvCSVModule = 33333:1:0
vdvModule = 33333:1:0

dvRelay = 5001:4:0

DEFINE_CONSTANT
#INCLUDE'inc-csv'


DEFINE_CONSTANT
INTEGER TRACE = 5
INTEGER DEBUG = 4
INTEGER INFO = 3
INTEGER WARN = 2
INTEGER ERROR = 1

DEFINE_VARIABLE
_Tokenizer _tokenizer1

DEFINE_VARIABLE
VOLATILE INTEGER nDebugCSV = 6
VOLATILE CHAR sPath[64] = 'csv/big.csv'
VOLATILE CHAR sBuffer[MAX_CHARS*2]
VOLATILE INTEGER nBufferChunkSize = MAX_CHARS*MAX_COLS


DEFINE_FUNCTION CHAR[15] fnDEVTOA (DEV dvDev)					//Convert DEV to ASCII for sending between modules without declarations
{
    RETURN("ITOA(dvDev.NUMBER),':',ITOA(dvDev.PORT),':',ITOA(dvDev.SYSTEM)");
}

DEFINE_FUNCTION INTEGER fnDEBUG (DEV dv, INTEGER debug_level,INTEGER  msg_level, CHAR msg[] )
{
    IF( msg_level >= debug_level)
    {
	STACK_VAR CHAR sPadding[5]
	STACK_VAR INTEGER nLoop
	
	FOR(nLoop=1;nLoop<=debug_level;nLoop++)
	{
	    sPadding = "sPadding,' '"
	}
	
	SEND_STRING 0, "fnDEVTOA(dv), ' -- [', ITOA(msg_level), '] ',sPadding, msg"
    }
}
DEFINE_FUNCTION INTEGER fnLoadCSVMock(CHAR str[])
{
    str = "'"o n e",1,1,1',13,10,'2,t wo,2,2',13,',3,3,"thr ee",',10,'4,4,4,"fo,ur",'"
}

DEFINE_FUNCTION INTEGER fnLoadCSVFile(CHAR sPath[], CHAR _sBuffer[])
{
    STACK_VAR SLONG slHandle
    STACK_VAR SLONG slBytesRead
    
    slHandle = FILE_OPEN(sPath, 1)

    IF(slHandle)
    {
	slBytesRead = FILE_READ(slHandle, _sBuffer, MAX_LENGTH_ARRAY(_sBuffer))
    }
    
    SET_LENGTH_ARRAY(sBuffer, TYPE_CAST(slBytesRead))
}

DEFINE_FUNCTION INTEGER fnConsumerConsumeField(_Tokenizer Vars)
{
    fnDebug(vdvCSVModule, DEBUG, nDebugCSV, "'fnConsumerConsumeField ', ITOA(Vars.nNumFields), ' -- ', Vars.cFieldValue")
} 

DEFINE_FUNCTION INTEGER fnConsumerEndOfRecord(_Tokenizer Vars) 
{
    STACK_VAR INTEGER nLoop
    STACK_VAR CHAR cMsg[MAX_CHARS*MAX_COLS]
    
    fnDebug(vdvCSVModule, DEBUG, nDebugCSV, "'fnConsumerEndOfRecord ', ITOA(Vars.nNumRows)")
    
    FOR(nLoop = 1; nLoop <= Vars.nNumFieldsLastRecord; nLoop++)
    {
	cMsg = "cMsg,'"', Vars.c_Record[nLoop],'" '"
    }
    IF(LENGTH_STRING(cMsg) > 1)
    {
	fnDebug(vdvCSVModule, INFO, nDebugCSV, "'[',ITOA(Vars.nNumRows),'][',cMsg,']'")
    }

} 

DEFINE_FUNCTION INTEGER fnConsumerEndOfFile(_Tokenizer Vars) 
{
    fnDebug(vdvCSVModule, DEBUG, nDebugCSV, "'fnConsumerEndOfFile '")
} 

DEFINE_FUNCTION INTEGER fnReadCSVFile(_Tokenizer Vars1, CHAR sPath[], CHAR _sBuffer[])
{
    STACK_VAR CHAR cResult
    STACK_VAR SLONG slHandle
    STACK_VAR SLONG slBytesRead
    
    slHandle = FILE_OPEN(sPath, 1) //Read Only

    IF(slHandle)
    {
	slBytesRead = FILE_READ(slHandle, Vars1.s, nBufferChunkSize)
    }
    
    IF(slBytesRead >= 0 )
    {
	//great
    } ELSE 
    {
	fnDEBUG(vdvModule, ERROR, nDebugCSV, "'something wrong'")
	RETURN 0
    }
    
    FILE_CLOSE(slHandle)
    
    fnTokenizer(Vars1, TKN_INIT)

    cResult = fnTokenizer(Vars1, TKN_PEEK)
    WHILE(/*cResult &&*/ (cResult <> EOF))
    {
	fnParseCSVRecord(Vars1)
	fnConsumerEndOfRecord(Vars1)		
	cResult = fnTokenizer(Vars1, TKN_PEEK)
    }
    fnConsumer(Vars1, CNSMR_EOF);
}

DEFINE_START
fnLoadCSVMock(sBuffer)

DEFINE_EVENT
CHANNEL_EVENT[vdvModule,0]
{
    ON:
    {
	STACK_VAR INTEGER nLengthLine
	
	SWITCH(CHANNEL.CHANNEL)
	{
	    CASE 1: {fnLoadCSVMock(sBuffer)}
	    CASE 2:
	    {	
		fnLoadCSVFile(sPath, sBuffer)
	    }
	    CASE 3:
	    {
		STACK_VAR CHAR cResult
		
		fnDEBUG(vdvModule, INFO, nDebugCSV, "'Read CSV File'")
		
		fnReadCSVFile(_tokenizer1, sPath, sBuffer)
	    }
	}
    }
}



//DEFINE_MODULE 'mdl-csv' mdlcsv01(vdvCSVModule)