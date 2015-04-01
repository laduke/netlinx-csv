PROGRAM_NAME='CDG-Lib'
DEFINE_FUNCTION CHAR[15] fnDEVTOA (DEV dvDev)					//Convert DEV to ASCII for sending between modules without declarations
{
    RETURN("ITOA(dvDev.NUMBER),':',ITOA(dvDev.PORT),':',ITOA(dvDev.SYSTEM)");
}

//log levels
DEFINE_CONSTANT
#DEFINE CDG_LIB  1

INTEGER TRACE = 5
INTEGER DEBUG = 4
INTEGER INFO = 3
INTEGER WARN = 2
INTEGER ERROR = 1

INTEGER LVL_DEBUG = 1

DEFINE_FUNCTION INTEGER fnDEBUG (DEV dv, INTEGER debug_level,INTEGER  msg_level, CHAR msg[] ){

    IF( msg_level >= debug_level){
	SEND_STRING 0, "fnDEVTOA(dv), ' -- [', ITOA(msg_level), '] ', msg"
    }

}
DEFINE_FUNCTION INTEGER fnDEBUG2(CHAR sFile[], INTEGER debug_level,INTEGER  msg_level, CHAR msg[] ){

    IF( msg_level >= debug_level){
	SEND_STRING 0, "sFile, ' -- [', ITOA(msg_level), '] ', msg"
    }

}
DEFINE_FUNCTION CHAR[64] fnButtonTextString(INTEGER nBtn, CHAR cString[]){
    RETURN "'^TXT-',ITOA(nBtn),',0,',cString"
}
DEFINE_FUNCTION INTEGER fnArrayOR(INTEGER n_Array[])
{
    //Are any of the items in the array True?
    STACK_VAR INTEGER nCounter
    STACK_VAR INTEGER nNumTrue
    
    FOR(nCounter = MAX_LENGTH_ARRAY(n_Array); nCounter>0; nCounter--)
    {
	IF( n_Array[nCounter])
	{
	    nNumTrue++
	}
    }
    
    RETURN nNumTrue
}
DEFINE_CONSTANT
