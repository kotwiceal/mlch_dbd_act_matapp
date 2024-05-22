// ------------------------------------------------------------------------------------------------
//
// Copyright (C) 1998-2021 LaVision GmbH.  All Rights Reserved.
//
// ------------------------------------------------------------------------------------------------
//
/**
	@file CL_DLL_Interface.cpp
	@brief Interface for DLLs to use some DaVis functions
	@author BW,TL
**/

#include "CL_DLL_Interface.h"

/// <!-------------------------------------------------------------------------------------------->
/// <!-- MyInitDLLExtensions -->
/// <!-------------------------------------------------------------------------------------------->
/// @brief User defined initialization called when loading the DLL.
/// <!-------------------------------------------------------------------------------------------->
void MyInitDLLExtensions() {

}

typedef void (*FunType)();

// This function is given as parameter to InitDll, which uses the function to retrieve the function pointers from DaVis.
FunType (*GetFunctionPointer)(int) = NULL;

// This enum list must be compatible to older versions of DaVis!
// When creating new functions, the id's of the enums are not allowed to be changed!
// Insert new enums at the marked position (near end of list).
enum {
	F_EXECUTECOMMAND = 0, 		// execute arbitrary CL-command (or macro,...)
   									// can be used for calling any useful CL-subroutine
   F_ISFLOAT,						// same as CL: IsFloat()
   F_ISEMPTY,                 // same as CL: IsEmpty()
   F_GETBUFFERSIZE,				// same as CL: GetBufferSize()
   F_SETBUFFERSIZE,				// same as CL: SetBufferSize()
   F_SETIMAGEFORMAT_RETIRED,	// retired
   F_GETBUFFERROWPTR,			// get pointer to row of buffer, return NULL if row does not exit
   									// pointer type: 	Word-buffer: unsigned short* (16-bit data)
                              //						Float-buffer: float* (32-bit data)
   F_SHOW,							// same as CL: Show()
   F_MESSAGE,						// same as CL: Message()
   F_GETINT,						// retrieve value of global integer variable[index] (0 for simple int)
   F_GETFLOAT,						// retrieve value of global float variable[index] (0 for simple float)
   F_GETSTRING,					// retrieve value of global string variable[index] (0 for simple string)
   F_SETPIO_,    					// removed
   F_GETPIO_,    					// removed
   F_SETINT,						// set value of global integer variable[index] (0 for simple int)
   F_SETFLOAT,						// set value of global float variable[index] (0 for simple float)
   F_SETSTRING,					// set value of global string variable[index] (0 for simple string)
   F_GETVECTORGRID,				// vector buffer: get vector grid spacing
   F_SETVECTORGRID,				// vector buffer: set vector grid spacing
   F_GETVECTOR,					// vector buffer: get 2D-vector, same as CL: GetVector()
   F_SETVECTOR,					// vector buffer: set 2D-vector, same as CL: SetVector()
   F_GET3DVECTOR,					// vector buffer: get 3D-vector, same as CL: Get3DVector()
   F_SET3DVECTOR,					// vector buffer: set 3D-vector, same as CL: Set3DVector()
   F_PIVCALCULATEVECTORFIELD,	// same as CL: PivCalculatevectorField(), returns error code or 0(ok)

   F_STATUSTEXT,
   F_INFOTEXT,

	F_CREATEVOLUME,
	F_RESIZEVOLUME,
	F_GETVOLUMESIZE,
	F_ISVOLUME,
	F_GETVOLUMEINFO,

	F_CREATEVOXEL_RETIRED,
	F_GETVOXEL_RETIRED,
	F_GETFIRSTVOLIT_RETIRED,
	F_GETNEXTVOLIT_RETIRED,
	F_SETVOLIT_VECTOR_RETIRED,
	F_GETVOLIT_VECTOR_RETIRED,
	F_SETVOLIT_FLOAT_RETIRED,
	F_GETVOLIT_FLOAT_RETIRED,

	F_GETATTRSTR,
	F_SETATTRSTR,
	F_GETATTRARRAY,
	F_SETATTRARRAY,
	F_DELETEALLATTR,

   F_GETCOLORPIXEL,
	F_GETVOLBUFROWPTR,

	F_PROCESSEVENTS,
	F_ISVALIDSYMBOL,

	F_GET4DVECTOR,
	F_SET4DVECTOR,

	F_GETSCALE,
	F_SETSCALE,

	F_GETPALETTECOLORS,

	F_MASK_GETPLANE,
	F_MASK_FREEPLANE, 
	F_MASK_SETPLANE,

	F_GETWORDDATAACCESS,
	F_GETWORDDATAACCESS_ROW,

	F_GETCOMPONENTINDEXOFFIRSTADDSCALAR,
	F_GETFLOATPLANE,
	F_SETFLOATPLANE,
	F_FREEFLOATPLANE,

	F_BUFFER_SETPAR,
	F_BUFFER_GETPAR,

	F_GETINTERPOLATEDVECTOR,
	F_SETTYPEDSCALAR,
	F_GETTYPEDSCALAR,

// direct call of macros and subroutines, new in 8.0.5
	F_DLLEX_CALLMACRO_INIT,
	F_DLLEX_CALLMACRO_INITOBJECT,
	F_DLLEX_CALLMACRO_PAR_INT,
	F_DLLEX_CALLMACRO_PAR_FLOAT,
	F_DLLEX_CALLMACRO_PAR_DOUBLE,
	F_DLLEX_CALLMACRO_PAR_STRING,
	F_DLLEX_CALLMACRO_EXECUTE,
	F_DLLEX_CALLMACRO_REFERENCE_INT,
	F_DLLEX_CALLMACRO_REFERENCE_FLOAT,
	F_DLLEX_CALLMACRO_REFERENCE_DOUBLE,
	F_DLLEX_CALLMACRO_REFERENCE_STRING,
	F_DLLEX_CALLMACRO_RETURN_INT,
	F_DLLEX_CALLMACRO_RETURN_FLOAT,
	F_DLLEX_CALLMACRO_RETURN_DOUBLE,
	F_DLLEX_CALLMACRO_RETURN_STRING,
	F_DLLEX_CALLMACRO_EXIT,
	F_DLLEX_CALLMACRO_GETLASTERROR,

	F_GETBUFFERINTERFACE		= 100,
	F_RELEASEBUFFERINTERFACE,
	F_SETBUFFERINTERFACE,

// new in 8.0.8
	F_GETSTRINGBUFFER = 110,
	F_GETATTRSTRBUF,

// new in 8.0.9, in 10.2.0 retired
	F_BUFFER_GETTYPEDSCALARID_RETIRED,

// new in 8.2.0
	F_CONVERTBAYERTORGBCOMPONENTS_RETIRED,

// ADD NEW ENUMS HERE !!!

// special functions for internal usage:
	F_DLLEX_SETSTRINGPARM	= -96,
	F_CALCULATE_VECTOR_FROM_CORRPLANE_RETIRED	= -97,
	F_PIVCALCULATEVECTORFIELD_SELFCALIB = -98,

// access to C_Subroutine interface for subroutines
	F_SUBR_REGISTER			= -100,
	F_SUBR_GETSTRINGPAR		= -101,
	F_SUBR_GETINTPAR			= -102,
	F_SUBR_GETFLOATPAR		= -103,
	F_SUBR_GETDOUBLEPAR		= -104,
	F_SUBR_RETURNSTRING		= -105,
	F_SUBR_RETURNINT			= -106,
	F_SUBR_RETURNFLOAT		= -107,
	F_SUBR_RETURNDOUBLE		= -108,
	F_SUBR_GETSTRINGPARBUFFER	= -109,
	F_SUBR_SETINTPAR			= -112,
	F_SUBR_SETFLOATPAR		= -113,
	F_SUBR_SETDOUBLEPAR		= -114,
	F_SUBR_SETSTRINGPAR		= -115,

// Access to ClassTable, new in 8.0.3
	F_CLASSTABLE_CREATEHANDLE = -110,
	F_CLASSTABLE_DELETEHANDLE = -111,
};



typedef int 	(*ExecuteCommandType)	( const char* theCommand );
int 	(*ExecuteCommand)		( const char* theCommand ) = NULL;

typedef int 	(*IsFloatType)				( int p_hBuffer );
int 	(*IsFloat)		  		( int p_hBuffer ) = NULL;

typedef int 	(*IsEmptyType)				( int p_hBuffer );
int 	(*IsEmpty)		  		( int p_hBuffer ) = NULL;

typedef int 	(*GetBufferSizeType)		( int p_hBuffer, int* theNx, int* theNy, int* theType );
int 	(*GetBufferSize)		( int p_hBuffer, int* theNx, int* theNy, int* theType ) = NULL;

typedef int 	(*SetBufferSizeType)		( int p_hBuffer, int theNx, int theNy, int theType );
int 	(*SetBufferSize)		( int p_hBuffer, int theNx, int theNy, int theType ) = NULL;

typedef void* 	(*GetBufferRowPtrType)	( int p_hBuffer, int theRow );
void* (*GetBufferRowPtr)	( int p_hBuffer, int theRow ) = NULL;

typedef int 	(*ShowType)					( int p_hBuffer );
int 	(*Show)				 	( int p_hBuffer ) = NULL;

typedef int 	(*MessageType)				( const char* theText, int theMode );
int 	(*Message)				( const char* theText, int theMode ) = NULL;

typedef int 	(*GetIntType)				( const char* theVarName, int theIndex );
int 	(*GetInt)				( const char* theVarName, int theIndex ) = NULL;

typedef float 	(*GetFloatType)			( const char* theVarName, int theIndex );
float (*GetFloat)				( const char* theVarName, int theIndex ) = NULL;

typedef const char* 	(*GetStringType)	( const char* theVarName, int theIndex );
const char* (*GetString)	( const char* theVarName, int theIndex ) = NULL;

typedef char* 	(*Dll_GetStringBufferType)	( const char* theVarName, int theIndex, char* p_sBuffer, int p_nBufferLength );
char* (*Dll_GetStringBuffer)	( const char* theVarName, int theIndex, char* p_sBuffer, int p_nBufferLength ) = NULL;

typedef void 	(*SetIntType)				( const char* theVarName, int theIndex, int value );
void 	(*SetInt)				( const char* theVarName, int theIndex, int value ) = NULL;

typedef void 	(*SetFloatType)			( const char* theVarName, int theIndex, float value );
void 	(*SetFloat)				( const char* theVarName, int theIndex, float value ) = NULL;

typedef void 	(*SetStringType)			( const char* theVarName, int theIndex, char* str );
void 	(*SetString)			( const char* theVarName, int theIndex, char* str ) = NULL;

typedef int 	(*GetVectorGridType)		( int p_hBuffer );
int 	(*GetVectorGrid)		( int p_hBuffer ) = NULL;

typedef void 	(*SetVectorGridType)		( int p_hBuffer, int theGridSize );
void 	(*SetVectorGrid)		( int p_hBuffer, int theGridSize ) = NULL;

typedef int 	(*GetVectorType)			( int p_hBuffer, int x, int y, float& vx, float& vy, int header );
int 	(*GetVector)			( int p_hBuffer, int x, int y, float& vx, float& vy, int header ) = NULL;

typedef void 	(*SetVectorType)			( int p_hBuffer, int x, int y, float vx, float vy, int header );
void 	(*SetVector)			( int p_hBuffer, int x, int y, float vx, float vy, int header ) = NULL;

typedef int 	(*Get3DVectorType)		( int p_hBuffer, int x, int y, float& vx, float& vy, float& vz, int header );
int 	(*Get3DVector)			( int p_hBuffer, int x, int y, float& vx, float& vy, float& vz, int header ) = NULL;

typedef void 	(*Set3DVectorType)		( int p_hBuffer, int x, int y, float vx, float vy, float vz, int header );
void 	(*Set3DVector)			( int p_hBuffer, int x, int y, float vx, float vy, float vz, int header ) = NULL;

typedef int 	(*Get4DVectorType)		( int p_hBuffer, int x, int y, int z, int f, float& vx, float& vy, float& vz, int header );
int 	(*Get4DVector)			( int p_hBuffer, int x, int y, int z, int f, float& vx, float& vy, float& vz, int header ) = NULL;

typedef void 	(*Set4DVectorType)		( int p_hBuffer, int x, int y, int z, int f, float vx, float vy, float vz, int header );
void 	(*Set4DVector)			( int p_hBuffer, int x, int y, int z, int f, float vx, float vy, float vz, int header ) = NULL;

typedef int 	(*PivCalculateVectorFieldType) (int inbuf, int outbuf, int rectangle);
int 	(*PivCalculateVectorField) (int inbuf, int outbuf, int rectangle ) = NULL;

int   (*StatusText)			( const char* theText ) = NULL;

typedef int    (*InfoTextType)  		   ( const char* theText );
int   (*InfoText)			   ( const char* theText ) = NULL;

typedef int    (*CreateVolumeType)     ( int p_hBuffer, int nx, int ny, int nz, int nf, int isSparse, int isFloat, int nScalars, int theSubtype );
int   (*CreateVolume)      ( int p_hBuffer, int nx, int ny, int nz, int nf, int isSparse, int isFloat, int nScalars, int theSubtype ) = NULL;

typedef int    (*ResizeVolumeType)     ( int p_hBuffer, int nx, int ny, int nz, int nf, int isSaveContents, int isFloat );
int   (*ResizeVolume)      ( int p_hBuffer, int nx, int ny, int nz, int nf, int isSaveContents, int isFloat ) = NULL;

typedef int    (*GetVolumeSizeType)    ( int p_hBuffer, int& nx, int& ny, int& nz, int& nf );
int   (*GetVolumeSize)     ( int p_hBuffer, int& nx, int& ny, int& nz, int& nf ) = NULL;

typedef int		(*IsVolumeType)			( int p_hBuffer );
int	(*IsVolume)				( int p_hBuffer ) = NULL;

typedef void	(*GetVolumeInfoType)		( int p_hBuffer, int&isSparse, int&aSubType, int&nComponents, int&nVectors, int&nScalars );
void	(*GetVolumeInfo)		( int p_hBuffer, int&isSparse, int&aSubType, int&nComponents, int&nVectors, int&nScalars ) = NULL;

typedef const char* (*GetAttrStrType) ( int p_hBuffer, const char* theName );
const char* (*GetAttrStr)  ( int p_hBuffer, const char* theName ) = NULL;

typedef char* (*Dll_GetAttrStrBufferType) ( int p_hBuffer, const char* theName, char* p_sBuffer, int p_nBufferLength );
char* (*Dll_GetAttrStrBuffer)	( int p_hBuffer, const char* theName, char* p_sBuffer, int p_nBufferLength ) = NULL;

typedef int    (*SetAttrStrType)      ( int p_hBuffer, const char* theName, const char* theValue );
int   (*SetAttrStr)        ( int p_hBuffer, const char* theName, const char* theValue ) = NULL;

typedef int    (*GetAttrArrayType)    ( int p_hBuffer, const char* theName, int theSize, BufAttr_Type theType, void* theArray );
int   (*GetAttrArray)      ( int p_hBuffer, const char* theName, int theSize, BufAttr_Type theType, void* theArray ) = NULL;

typedef int    (*SetAttrArrayType)    ( int p_hBuffer, const char* theName, int theSize, BufAttr_Type theType, void* theArray );
int   (*SetAttrArray)      ( int p_hBuffer, const char* theName, int theSize, BufAttr_Type theType, void* theArray ) = NULL;

typedef void   (*DeleteAttributesType)( int p_hBuffer );
void  (*DeleteAttributes)  ( int p_hBuffer ) = NULL;

typedef void   (*GetColorPixelType)    ( int p_hBuffer, int mode, int x, int y, float& par1, float& par2, float& par3);
void  (*GetColorPixel)     ( int p_hBuffer, int mode, int x, int y, float& par1, float& par2, float& par3) = NULL;

typedef void*	(*GetVolBufRowPtrType)	( int p_hBuffer, int theY, int theZ, int theF );
void* (*GetVolBufRowPtr)	( int p_hBuffer, int theY, int theZ, int theF ) = NULL;

typedef Word*  (*GetWordDataAccessType)( int p_hBuffer );
Word* (*GetWordDataAccess) ( int p_hBuffer ) = NULL;

typedef Word*  (*GetWordDataAccessRowType)( int p_hBuffer, int theY, int theZ, int theF );
Word* (*GetWordDataAccessRow) ( int p_hBuffer, int theY, int theZ, int theF ) = NULL;

int	(*ProcessEvents)		() = NULL;

typedef int		(*IsValidSymbolType)		( const char* theSybolName );
int	(*IsValidSymbol)		( const char* theSybolName ) = NULL;

typedef void	(*GetScaleType)			( int p_hBuffer, int theFrame, int theScaleXYZIF, float&factor, float&offset, char* unit, char* description );
void	(*GetScale)				( int p_hBuffer, int theFrame, int theScaleXYZIF, float&factor, float&offset, char* unit, char* description ) = NULL;

typedef void	(*SetScaleType)			( int p_hBuffer, int theFrame, int theScaleXYZIF, float factor, float offset, const char* unit, const char* description );
void	(*SetScale)				( int p_hBuffer, int theFrame, int theScaleXYZIF, float factor, float offset, const char* unit, const char* description ) = NULL;

typedef bool	(*GetPaletteColorsType)	( int thePalette, unsigned int* theRGB_256 );
bool	(*GetPaletteColors)	( int thePalette, unsigned int* theRGB_256 ) = NULL;

typedef bool*	(*Mask_GetPlaneType)		( int p_hBuffer, int theZ, int theF );
bool*	(*Mask_GetPlane)		( int p_hBuffer, int theZ, int theF )	= NULL;

typedef void	(*Mask_FreePlaneType)	( int p_hBuffer, const bool* thePlane );
void	(*Mask_FreePlane)		( int p_hBuffer, const bool* thePlane )		= NULL;

typedef int		(*Mask_SetPlaneType)		( int p_hBuffer, int theZ, int theF, const bool* thePlane );
int	(*Mask_SetPlane)		( int p_hBuffer, int theZ, int theF, const bool* thePlane ) = NULL;

typedef int    (*GetComponentIndexOfFirstAdditionalScalarType)( int p_hBuffer );
int    (*GetComponentIndexOfFirstAdditionalScalar)	( int p_hBuffer )	= NULL;

typedef float* (*GetFloatPlaneType)		( int p_hBuffer, int theZ, int theF, int theC );
float* (*GetFloatPlane)		( int p_hBuffer, int theZ, int theF, int theC )	= NULL;

typedef void   (*SetFloatPlaneType)		( int p_hBuffer, int theZ, int theF, int theC, const float* plane );
void   (*SetFloatPlane)		( int p_hBuffer, int theZ, int theF, int theC, const float* plane ) = NULL;

typedef void   (*FreeFloatPlaneType)	( int p_hBuffer, float* plane );
void   (*FreeFloatPlane)	( int p_hBuffer, float* plane ) = NULL;

typedef int    (*Buffer_SetParType)		( int p_hBuffer, int theMode, int theIntParsN, int* theIntPars, int theFloarParsN, float* theFloatPars, int theStringParsN, char** theStringPars );
int    (*Buffer_SetPar)		( int p_hBuffer, int theMode, int theIntParsN, int* theIntPars, int theFloarParsN, float* theFloatPars, int theStringParsN, char** theStringPars ) = NULL;

typedef int    (*Buffer_GetParType)		( int p_hBuffer, int theMode, int theIntParsN, int* theIntPars, int theFloarParsN, float* theFloatPars, int theStringParsN, char** theStringPars );
int    (*Buffer_GetPar)		( int p_hBuffer, int theMode, int theIntParsN, int* theIntPars, int theFloarParsN, float* theFloatPars, int theStringParsN, char** theStringPars ) = NULL;

typedef int		(*Dll_GetInterpolatedVectorType)	( int p_hBuffer, float xpos, float ypos, int p_nPlane, int p_nFrame, float& p_rfVx, float& p_rfVy, float& p_rfVz, int p_eMode );
int	(*Dll_GetInterpolatedVector)	( int p_hBuffer, float xpos, float ypos, int p_nPlane, int p_nFrame, float& p_rfVx, float& p_rfVy, float& p_rfVz, int p_eMode ) = NULL;

typedef int		(*Dll_Buffer_SetTypedScalarType)	( int p_hBuffer, const char* p_sName, int p_nPlane, int p_nFrame, const float* p_fArray );
int	(*Dll_Buffer_SetTypedScalar)	( int p_hBuffer, const char* p_sName, int p_nPlane, int p_nFrame, const float* p_fArray ) = NULL;

typedef int		(*Dll_Buffer_GetTypedScalarType)	( int p_hBuffer, const char* p_sName, int p_nPlane, int p_nFrame, float* p_fArray );
int	(*Dll_Buffer_GetTypedScalar)	( int p_hBuffer, const char* p_sName, int p_nPlane, int p_nFrame, float* p_fArray ) = NULL;

typedef void	(*DllEx_SetStringParmType) ( char** parsString, int setParI, const char* setParString );
void	(*DllEx_SetStringParm) ( char** parsString, int setParI, const char* setParString ) = NULL;

typedef int	(*DllEx_Subroutine_RegisterType)( const char* p_sName, T_SubroutineExec p_pFunction );
int	(*DllEx_Subroutine_Register)( const char* p_sName, T_SubroutineExec p_pFunction ) = NULL;

typedef const char* (*DllEx_Subroutine_GetStringParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
const char* (*DllEx_Subroutine_GetStringPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex ) = NULL;

typedef int	(*DllEx_Subroutine_GetStringParBufferType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, char* p_sBuffer, int p_nBufferLength );
int	(*DllEx_Subroutine_GetStringParBuffer)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, char* p_sBuffer, int p_nBufferLength ) = NULL;

typedef int		(*DllEx_Subroutine_GetIntParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
int	(*DllEx_Subroutine_GetIntPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex ) = NULL;

typedef float	(*DllEx_Subroutine_GetFloatParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
float (*DllEx_Subroutine_GetFloatPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex ) = NULL;

typedef double	(*DllEx_Subroutine_GetDoubleParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
double (*DllEx_Subroutine_GetDoublePar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex ) = NULL;

typedef void (*DllEx_Subroutine_SetIntParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, int p_nValue );
void (*DllEx_Subroutine_SetIntPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, int p_nValue ) = NULL;

typedef void (*DllEx_Subroutine_SetFloatParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, float p_fValue );
void (*DllEx_Subroutine_SetFloatPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, float p_fValue ) = NULL;

typedef void (*DllEx_Subroutine_SetDoubleParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, double p_dValue );
void (*DllEx_Subroutine_SetDoublePar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, double p_dValue ) = NULL;

typedef void (*DllEx_Subroutine_SetStringParType)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, const char* p_sValue );
void (*DllEx_Subroutine_SetStringPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, const char* p_sValue ) = NULL;

typedef void	(*DllEx_Subroutine_ReturnStringType)( SubroutineParameters* p_pSubroutineParameters, const char* p_sResult );
void	(*DllEx_Subroutine_ReturnString)( SubroutineParameters* p_pSubroutineParameters, const char* p_sResult ) = NULL;

typedef void	(*DllEx_Subroutine_ReturnIntType)( SubroutineParameters* p_pSubroutineParameters, int p_iResult );
void	(*DllEx_Subroutine_ReturnInt)( SubroutineParameters* p_pSubroutineParameters, int p_iResult ) = NULL;

typedef void	(*DllEx_Subroutine_ReturnFloatType)( SubroutineParameters* p_pSubroutineParameters, float p_fResult );
void	(*DllEx_Subroutine_ReturnFloat)( SubroutineParameters* p_pSubroutineParameters, float p_fResult ) = NULL;

typedef void	(*DllEx_Subroutine_ReturnDoubleType)( SubroutineParameters* p_pSubroutineParameters, double p_fResult );
void	(*DllEx_Subroutine_ReturnDouble)( SubroutineParameters* p_pSubroutineParameters, double p_fResult ) = NULL;

// Functions and type definitions for accessing ClassTable.
typedef int (*Dll_ClassTableCreateHandleType)(const char*);
typedef void (*Dll_ClassTableDeleteHandleType)(const int);

int   (*Dll_ClassTableCreateHandle)(const char* p_sClass) = NULL;
void  (*Dll_ClassTableDeleteHandle)(const int p_hClass) = NULL;

typedef C_DirectMacroCall_Intern* (*DllEx_CallMacro_InitType)( const char* p_sName );
typedef C_DirectMacroCall_Intern* (*DllEx_CallMacro_InitObjectType)( int p_hObject, const char* p_sMethod );
typedef void	(*DllEx_CallMacro_Par_IntType)( C_DirectMacroCall_Intern* p_pMacro, int p_nValue );
typedef void	(*DllEx_CallMacro_Par_FloatType)( C_DirectMacroCall_Intern* p_pMacro, float p_fValue );
typedef void	(*DllEx_CallMacro_Par_DoubleType)( C_DirectMacroCall_Intern* p_pMacro, double p_fValue );
typedef void	(*DllEx_CallMacro_Par_StringType)( C_DirectMacroCall_Intern* p_pMacro, const char* p_sValue );
typedef int		(*DllEx_CallMacro_ExecuteType)( C_DirectMacroCall_Intern* p_pMacro );
typedef int		(*DllEx_CallMacro_GetLastErrorType)( C_DirectMacroCall_Intern* p_pMacro, char *p_rsErrorMsg, int p_nErrorMsgLength, bool p_bResetError );
typedef int		(*DllEx_CallMacro_GetIntReferenceType)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex );
typedef float	(*DllEx_CallMacro_GetFloatReferenceType)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex );
typedef double	(*DllEx_CallMacro_GetDoubleReferenceType)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex );
typedef int		(*DllEx_CallMacro_GetStringReferenceType)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex, char *p_rsString, int p_nStringLength  );
typedef int		(*DllEx_CallMacro_ReturnIntType)( C_DirectMacroCall_Intern* p_pMacro );
typedef float	(*DllEx_CallMacro_ReturnFloatType)( C_DirectMacroCall_Intern* p_pMacro );
typedef double	(*DllEx_CallMacro_ReturnDoubleType)( C_DirectMacroCall_Intern* p_pMacro );
typedef int		(*DllEx_CallMacro_ReturnStringType)( C_DirectMacroCall_Intern* p_pMacro, char *p_rsString, int p_nStringLength  );
typedef void	(*DllEx_CallMacro_ExitType)( C_DirectMacroCall_Intern* p_pMacro );

C_DirectMacroCall_Intern* (*DllEx_CallMacro_Init)( const char* p_sName ) = NULL;
C_DirectMacroCall_Intern* (*DllEx_CallMacro_InitObject)( int p_hObject, const char* p_sMethod ) = NULL;
void (*DllEx_CallMacro_Par_Int)( C_DirectMacroCall_Intern* p_pMacro, int p_nValue ) = NULL;
void (*DllEx_CallMacro_Par_Float)( C_DirectMacroCall_Intern* p_pMacro, float p_fValue ) = NULL;
void (*DllEx_CallMacro_Par_Double)( C_DirectMacroCall_Intern* p_pMacro, double p_fValue ) = NULL;
void (*DllEx_CallMacro_Par_String)( C_DirectMacroCall_Intern* p_pMacro, const char* p_sValue ) = NULL;
int (*DllEx_CallMacro_Execute)( C_DirectMacroCall_Intern* p_pMacro ) = NULL;
int (*DllEx_CallMacro_GetLastError)( C_DirectMacroCall_Intern* p_pMacro, char *p_rsErrorMsg, int p_nErrorMsgLength, bool p_bResetError ) = NULL;
int (*DllEx_CallMacro_GetIntReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex ) = NULL;
float (*DllEx_CallMacro_GetFloatReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex ) = NULL;
double (*DllEx_CallMacro_GetDoubleReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex ) = NULL;
int (*DllEx_CallMacro_GetStringReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex, char *p_rsString, int p_nStringLength ) = NULL;
int (*DllEx_CallMacro_ReturnInt)( C_DirectMacroCall_Intern* p_pMacro ) = NULL;
float (*DllEx_CallMacro_ReturnFloat)( C_DirectMacroCall_Intern* p_pMacro ) = NULL;
double (*DllEx_CallMacro_ReturnDouble)( C_DirectMacroCall_Intern* p_pMacro ) = NULL;
int (*DllEx_CallMacro_ReturnString)( C_DirectMacroCall_Intern* p_pMacro, char *p_rsString, int p_nStringLength ) = NULL;
void (*DllEx_CallMacro_Exit)( C_DirectMacroCall_Intern* p_pMacro ) = NULL;

typedef BufferApi::I_Buffer* (*DllEx_Buffer_GetInterfaceType)( int p_hBuffer );
BufferApi::I_Buffer* (*DllEx_Buffer_GetInterface)( int p_hBuffer ) = NULL;

typedef void (*DllEx_Buffer_ReleaseInterfaceType)( int p_hBuffer );
void (*DllEx_Buffer_ReleaseInterface)( int p_hBuffer ) = NULL;

typedef void (*DllEx_Buffer_SetInterfaceType)( int p_hBuffer, BufferApi::I_Buffer* p_pBufferInterface );
void (*DllEx_Buffer_SetInterface)( int p_hBuffer, BufferApi::I_Buffer* p_pBufferInterface ) = NULL;


void FuncError()
{
	if (ExecuteCommand)
	{
		ExecuteCommand("Message(\"Internal function not available in DLL, please check your source code!\",0)");
	}
}


FunType* GetFunctionPointerTest( int p_nFunctionIndex )
{
	FunType* pGetFunctionPointerTest = (FunType*)GetFunctionPointer(p_nFunctionIndex);
	return (pGetFunctionPointerTest ? pGetFunctionPointerTest : (FunType*)FuncError);
}


// extern "C" void EXPORT InitDll( FunType (*p_pGetFunctionPointerTest)(int) ) // WMVS
extern "C" __declspec(dllexport) void InitDll( FunType (*p_pGetFunctionPointerTest)(int) ) // MinGW
{
	GetFunctionPointer = p_pGetFunctionPointerTest;
   // get important entry points into DaVis
   ExecuteCommand 	= (ExecuteCommandType) GetFunctionPointerTest( F_EXECUTECOMMAND );
   Message 				= (MessageType) GetFunctionPointerTest( F_MESSAGE );
   IsFloat		 		= (IsFloatType) GetFunctionPointerTest( F_ISFLOAT );
   IsEmpty		 		= (IsFloatType) GetFunctionPointerTest( F_ISEMPTY );
   SetBufferSize 		= (SetBufferSizeType) GetFunctionPointerTest( F_SETBUFFERSIZE );
   GetBufferSize 		= (GetBufferSizeType) GetFunctionPointerTest( F_GETBUFFERSIZE );
   GetBufferRowPtr 	= (GetBufferRowPtrType) GetFunctionPointerTest( F_GETBUFFERROWPTR );
   Show					= (ShowType) GetFunctionPointerTest( F_SHOW );
   Message 				= (MessageType) GetFunctionPointerTest( F_MESSAGE );
   GetInt 				= (GetIntType) GetFunctionPointerTest( F_GETINT );
   GetFloat 			= (GetFloatType) GetFunctionPointerTest( F_GETFLOAT );
   GetString 			= (GetStringType) GetFunctionPointerTest( F_GETSTRING );
	Dll_GetStringBuffer	= (Dll_GetStringBufferType) GetFunctionPointerTest( F_GETSTRINGBUFFER );
	SetInt				= (SetIntType) GetFunctionPointerTest( F_SETINT );
	SetFloat				= (SetFloatType) GetFunctionPointerTest( F_SETFLOAT );
	SetString			= (SetStringType) GetFunctionPointerTest( F_SETSTRING );
	GetVectorGrid		= (GetVectorGridType) GetFunctionPointerTest( F_GETVECTORGRID );
	SetVectorGrid		= (SetVectorGridType) GetFunctionPointerTest( F_SETVECTORGRID );
	GetVector			= (GetVectorType) GetFunctionPointerTest( F_GETVECTOR );
	SetVector			= (SetVectorType) GetFunctionPointerTest( F_SETVECTOR );
	Get3DVector			= (Get3DVectorType) GetFunctionPointerTest( F_GET3DVECTOR );
	Set3DVector			= (Set3DVectorType) GetFunctionPointerTest( F_SET3DVECTOR );
	Get4DVector			= (Get4DVectorType) GetFunctionPointerTest( F_GET4DVECTOR );
	Set4DVector			= (Set4DVectorType) GetFunctionPointerTest( F_SET4DVECTOR );
	PivCalculateVectorField	= (PivCalculateVectorFieldType) GetFunctionPointerTest( F_PIVCALCULATEVECTORFIELD );

   StatusText			= (StatusTextType) GetFunctionPointerTest( F_STATUSTEXT );
   InfoText				= (InfoTextType) GetFunctionPointerTest( F_INFOTEXT );

	CreateVolume		= (CreateVolumeType) GetFunctionPointerTest(F_CREATEVOLUME);
	ResizeVolume		= (ResizeVolumeType) GetFunctionPointerTest(F_RESIZEVOLUME);
	GetVolumeSize		= (GetVolumeSizeType) GetFunctionPointerTest(F_GETVOLUMESIZE);
	IsVolume				= (IsVolumeType) GetFunctionPointerTest(F_ISVOLUME);
	GetVolumeInfo		= (GetVolumeInfoType) GetFunctionPointerTest(F_GETVOLUMEINFO);

	GetAttrStr	      = (GetAttrStrType) GetFunctionPointerTest(F_GETATTRSTR);
	Dll_GetAttrStrBuffer  = (Dll_GetAttrStrBufferType) GetFunctionPointerTest(F_GETATTRSTRBUF);
	SetAttrStr	      = (SetAttrStrType) GetFunctionPointerTest(F_SETATTRSTR);
	GetAttrArray	   = (GetAttrArrayType) GetFunctionPointerTest(F_GETATTRARRAY);
	SetAttrArray      = (SetAttrArrayType) GetFunctionPointerTest(F_SETATTRARRAY);
   DeleteAttributes  = (DeleteAttributesType) GetFunctionPointerTest(F_DELETEALLATTR);

   GetColorPixel     = (GetColorPixelType)	GetFunctionPointerTest(F_GETCOLORPIXEL);
	GetVolBufRowPtr	= (GetVolBufRowPtrType) GetFunctionPointerTest(F_GETVOLBUFROWPTR);
	GetWordDataAccess	= (GetWordDataAccessType) GetFunctionPointerTest(F_GETWORDDATAACCESS);
	GetWordDataAccessRow	= (GetWordDataAccessRowType) GetFunctionPointerTest(F_GETWORDDATAACCESS_ROW);

	ProcessEvents		= (ProcessEventsType)	GetFunctionPointerTest(F_PROCESSEVENTS);
	IsValidSymbol		= (IsValidSymbolType)	GetFunctionPointerTest(F_ISVALIDSYMBOL);

	GetScale				= (GetScaleType)	GetFunctionPointerTest(F_GETSCALE);
	SetScale				= (SetScaleType)	GetFunctionPointerTest(F_SETSCALE);

	GetPaletteColors	= (GetPaletteColorsType)	GetFunctionPointerTest(F_GETPALETTECOLORS);

	Mask_GetPlane		= (Mask_GetPlaneType)	GetFunctionPointerTest(F_MASK_GETPLANE);
	Mask_FreePlane		= (Mask_FreePlaneType)	GetFunctionPointerTest(F_MASK_FREEPLANE);
	Mask_SetPlane		= (Mask_SetPlaneType)	GetFunctionPointerTest(F_MASK_SETPLANE);

	GetComponentIndexOfFirstAdditionalScalar = (GetComponentIndexOfFirstAdditionalScalarType) GetFunctionPointerTest(F_GETCOMPONENTINDEXOFFIRSTADDSCALAR);
	GetFloatPlane		= (GetFloatPlaneType)	GetFunctionPointerTest(F_GETFLOATPLANE);
	SetFloatPlane		= (SetFloatPlaneType)	GetFunctionPointerTest(F_SETFLOATPLANE);
	FreeFloatPlane		= (FreeFloatPlaneType)	GetFunctionPointerTest(F_FREEFLOATPLANE);

	Buffer_SetPar		= (Buffer_SetParType)	GetFunctionPointerTest(F_BUFFER_SETPAR);
	Buffer_GetPar		= (Buffer_GetParType)	GetFunctionPointerTest(F_BUFFER_GETPAR);

	Dll_GetInterpolatedVector	= (Dll_GetInterpolatedVectorType)	GetFunctionPointerTest(F_GETINTERPOLATEDVECTOR);
	Dll_Buffer_SetTypedScalar	= (Dll_Buffer_SetTypedScalarType)	GetFunctionPointerTest(F_SETTYPEDSCALAR);
	Dll_Buffer_GetTypedScalar	= (Dll_Buffer_GetTypedScalarType)	GetFunctionPointerTest(F_GETTYPEDSCALAR);

	DllEx_CallMacro_Init			= (DllEx_CallMacro_InitType)			GetFunctionPointerTest(F_DLLEX_CALLMACRO_INIT);
	DllEx_CallMacro_InitObject	= (DllEx_CallMacro_InitObjectType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_INITOBJECT);
	DllEx_CallMacro_Par_Int		= (DllEx_CallMacro_Par_IntType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_PAR_INT);
	DllEx_CallMacro_Par_Float	= (DllEx_CallMacro_Par_FloatType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_PAR_FLOAT);
	DllEx_CallMacro_Par_Double	= (DllEx_CallMacro_Par_DoubleType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_PAR_DOUBLE);
	DllEx_CallMacro_Par_String	= (DllEx_CallMacro_Par_StringType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_PAR_STRING);
	DllEx_CallMacro_Execute		= (DllEx_CallMacro_ExecuteType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_EXECUTE);
	DllEx_CallMacro_GetLastError	= (DllEx_CallMacro_GetLastErrorType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_GETLASTERROR);
	DllEx_CallMacro_GetIntReference		= (DllEx_CallMacro_GetIntReferenceType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_REFERENCE_INT);
	DllEx_CallMacro_GetFloatReference	= (DllEx_CallMacro_GetFloatReferenceType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_REFERENCE_FLOAT);
	DllEx_CallMacro_GetDoubleReference	= (DllEx_CallMacro_GetDoubleReferenceType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_REFERENCE_DOUBLE);
	DllEx_CallMacro_GetStringReference	= (DllEx_CallMacro_GetStringReferenceType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_REFERENCE_STRING);
	DllEx_CallMacro_ReturnInt		= (DllEx_CallMacro_ReturnIntType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_RETURN_INT);
	DllEx_CallMacro_ReturnFloat	= (DllEx_CallMacro_ReturnFloatType)		GetFunctionPointerTest(F_DLLEX_CALLMACRO_RETURN_FLOAT);
	DllEx_CallMacro_ReturnDouble	= (DllEx_CallMacro_ReturnDoubleType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_RETURN_DOUBLE);
	DllEx_CallMacro_ReturnString	= (DllEx_CallMacro_ReturnStringType)	GetFunctionPointerTest(F_DLLEX_CALLMACRO_RETURN_STRING);
	DllEx_CallMacro_Exit				= (DllEx_CallMacro_ExitType)				GetFunctionPointerTest(F_DLLEX_CALLMACRO_EXIT);

	DllEx_Buffer_GetInterface		= (DllEx_Buffer_GetInterfaceType)		GetFunctionPointerTest(F_GETBUFFERINTERFACE);
	DllEx_Buffer_ReleaseInterface	= (DllEx_Buffer_ReleaseInterfaceType)	GetFunctionPointerTest(F_RELEASEBUFFERINTERFACE);
	DllEx_Buffer_SetInterface		= (DllEx_Buffer_SetInterfaceType)		GetFunctionPointerTest(F_SETBUFFERINTERFACE);

	DllEx_SetStringParm = (DllEx_SetStringParmType) GetFunctionPointerTest(F_DLLEX_SETSTRINGPARM);

	DllEx_Subroutine_Register		= (DllEx_Subroutine_RegisterType)		GetFunctionPointerTest(F_SUBR_REGISTER);
	DllEx_Subroutine_GetStringPar	= (DllEx_Subroutine_GetStringParType)	GetFunctionPointerTest(F_SUBR_GETSTRINGPAR);
	DllEx_Subroutine_GetIntPar		= (DllEx_Subroutine_GetIntParType)		GetFunctionPointerTest(F_SUBR_GETINTPAR);
	DllEx_Subroutine_GetFloatPar	= (DllEx_Subroutine_GetFloatParType)	GetFunctionPointerTest(F_SUBR_GETFLOATPAR);
	DllEx_Subroutine_GetDoublePar	= (DllEx_Subroutine_GetDoubleParType)	GetFunctionPointerTest(F_SUBR_GETDOUBLEPAR);
	DllEx_Subroutine_ReturnString	= (DllEx_Subroutine_ReturnStringType)	GetFunctionPointerTest(F_SUBR_RETURNSTRING);
	DllEx_Subroutine_ReturnInt		= (DllEx_Subroutine_ReturnIntType)		GetFunctionPointerTest(F_SUBR_RETURNINT);
	DllEx_Subroutine_ReturnFloat	= (DllEx_Subroutine_ReturnFloatType)	GetFunctionPointerTest(F_SUBR_RETURNFLOAT);
	DllEx_Subroutine_ReturnDouble	= (DllEx_Subroutine_ReturnDoubleType)	GetFunctionPointerTest(F_SUBR_RETURNDOUBLE);
	DllEx_Subroutine_GetStringParBuffer	= (DllEx_Subroutine_GetStringParBufferType)	GetFunctionPointerTest(F_SUBR_GETSTRINGPARBUFFER);
	DllEx_Subroutine_SetIntPar		= (DllEx_Subroutine_SetIntParType)		GetFunctionPointerTest(F_SUBR_SETINTPAR);
	DllEx_Subroutine_SetFloatPar	= (DllEx_Subroutine_SetFloatParType)		GetFunctionPointerTest(F_SUBR_SETFLOATPAR);
	DllEx_Subroutine_SetDoublePar	= (DllEx_Subroutine_SetDoubleParType)		GetFunctionPointerTest(F_SUBR_SETDOUBLEPAR);
	DllEx_Subroutine_SetStringPar	= (DllEx_Subroutine_SetStringParType)		GetFunctionPointerTest(F_SUBR_SETSTRINGPAR);

	Dll_ClassTableCreateHandle = (Dll_ClassTableCreateHandleType) GetFunctionPointerTest(F_CLASSTABLE_CREATEHANDLE);
	Dll_ClassTableDeleteHandle = (Dll_ClassTableDeleteHandleType) GetFunctionPointerTest(F_CLASSTABLE_DELETEHANDLE);

	//
	// call user defined initialization in "CL_DLL_Example.cpp"
	//
	MyInitDLLExtensions();
}


std::string DllEx_Subroutine_GetStdStringPar( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex )
{
	// get size of string, reserve enough characters and get the string itself
	int nSize = DllEx_Subroutine_GetStringParBuffer( p_pSubroutineParameters, p_nPar, p_nIndex, NULL, 0 );
	char *sBuffer = new char[nSize];
	DllEx_Subroutine_GetStringParBuffer( p_pSubroutineParameters, p_nPar, p_nIndex, sBuffer, nSize );
	std::string sResult = sBuffer;
	delete[] sBuffer;
	return sResult;
}


/*****************************************************************************/

C_InterfaceOfSCBuffer::C_InterfaceOfSCBuffer( int p_hBuffer )
{
	m_hBuffer = p_hBuffer;
	m_pBufferInterface = DllEx_Buffer_GetInterface( m_hBuffer );
}

C_InterfaceOfSCBuffer::~C_InterfaceOfSCBuffer()
{
	DllEx_Buffer_ReleaseInterface( m_hBuffer );
}


// *************************************************************************************************
// *************************************************************************************************
// ***                                                                                           ***
// ***                       Implementation of the C_DirectMacroCall class                       ***
// ***                                                                                           ***
// *************************************************************************************************
// *************************************************************************************************

// -------------------------------------------------------------------------------------------------
// ---                                     C_DirectMacroCall                                     ---
// -------------------------------------------------------------------------------------------------
C_DirectMacroCall::C_DirectMacroCall( std::string p_sName )
{
	m_sName = p_sName;
	Init();
}


C_DirectMacroCall::C_DirectMacroCall( int p_hObject, std::string p_sMethod )
{
	m_hObject = p_hObject;
	m_sName = p_sMethod;
	m_pMacro = DllEx_CallMacro_InitObject( p_hObject, p_sMethod.c_str() );
	m_bIsValid = (m_pMacro != NULL);
	m_nParameterCount = 0;
	m_nLastErrorCode = 0;
	m_sLastErrorMsg = "";
}


// -------------------------------------------------------------------------------------------------
// ---                                    ~C_DirectMacroCall                                     ---
// -------------------------------------------------------------------------------------------------
C_DirectMacroCall::~C_DirectMacroCall()
{
	Clear();
}

// -------------------------------------------------------------------------------------------------
// ---                                            Init                                           ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::Init()
{
	m_hObject = 0;
	m_pMacro = DllEx_CallMacro_Init( m_sName.c_str() );
	m_bIsValid = (m_pMacro != NULL);
	m_nParameterCount = 0;
	m_nLastErrorCode = 0;
	m_sLastErrorMsg = "";
}

// -------------------------------------------------------------------------------------------------
// ---                                     AppendParameter                                       ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::AppendParameter()
{
	m_nParameterCount++;
	m_IntRefPars.push_back( NULL );
	m_FloatRefPars.push_back( NULL );
	m_DoubleRefPars.push_back( NULL );
	m_StringRefPars.push_back( NULL );
}

// -------------------------------------------------------------------------------------------------
// ---                                       Append float                                        ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::Append( float p_fMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	DllEx_CallMacro_Par_Float( m_pMacro, p_fMacroParameter );
	AppendParameter();
}

// -------------------------------------------------------------------------------------------------
// ---                                   AppendReference float                                   ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::AppendReference( float& p_rfMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	Append( p_rfMacroParameter );
	m_FloatRefPars[m_nParameterCount-1] = &p_rfMacroParameter;
}

// -------------------------------------------------------------------------------------------------
// ---                                       Append int                                          ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::Append( int p_nMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	DllEx_CallMacro_Par_Int( m_pMacro, p_nMacroParameter );
	AppendParameter();
}

// -------------------------------------------------------------------------------------------------
// ---                                    AppendReference int                                    ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::AppendReference( int& p_rnMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	Append( p_rnMacroParameter );
	m_IntRefPars[m_nParameterCount-1] = &p_rnMacroParameter;
}

// -------------------------------------------------------------------------------------------------
// ---                                     Append double                                         ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::Append( double p_fMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	DllEx_CallMacro_Par_Double( m_pMacro, p_fMacroParameter );
	AppendParameter();
}

// -------------------------------------------------------------------------------------------------
// ---                                   AppendReference double                                  ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::AppendReference( double& p_rfMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	Append( p_rfMacroParameter );
	m_DoubleRefPars[m_nParameterCount-1] = &p_rfMacroParameter;
}

// -------------------------------------------------------------------------------------------------
// ---                                   AppendReference string                                  ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::AppendReference( std::string& p_rsMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	Append( p_rsMacroParameter );
	m_StringRefPars[m_nParameterCount-1] = &p_rsMacroParameter;
}

// -------------------------------------------------------------------------------------------------
// ---                                      Append string                                        ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::Append( std::string p_sMacroParameter )
{
	if (m_pMacro == NULL)
	{
		return;
	}
	DllEx_CallMacro_Par_String( m_pMacro, p_sMacroParameter.c_str() );
	AppendParameter();
}

// -------------------------------------------------------------------------------------------------
// ---                                           Clear                                           ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::Clear()
{
	m_IntRefPars.clear();
	m_FloatRefPars.clear();
	m_DoubleRefPars.clear();
	m_StringRefPars.clear();
	if (m_pMacro != NULL)
	{
		DllEx_CallMacro_Exit(m_pMacro);
	}
}

// -------------------------------------------------------------------------------------------------
// ---                                          Execute                                          ---
// -------------------------------------------------------------------------------------------------
bool C_DirectMacroCall::Execute( bool p_bResetError )
{
	if (m_pMacro == NULL)
	{
		m_nLastErrorCode = CL_MACRO_ERROR_INVALID_MACRO;
		return false;
	}
	m_nLastErrorCode = DllEx_CallMacro_Execute(m_pMacro);
	if (m_nLastErrorCode==0)
	{	// no error
		m_sLastErrorMsg = "";
	}
	else
	{	// get error message
		char sError[1024];
		DllEx_CallMacro_GetLastError( m_pMacro, sError, sizeof(sError), p_bResetError );
		m_sLastErrorMsg = sError;
	}

	// fill reference parameters
	for (unsigned int nIndex=0; nIndex < (unsigned int) m_IntRefPars.size(); nIndex++)
	{
		int* pValue = m_IntRefPars[nIndex];
		if (pValue)
			*pValue = DllEx_CallMacro_GetIntReference( m_pMacro, nIndex );
	}
	for (unsigned int nIndex=0; nIndex < (unsigned int) m_FloatRefPars.size(); nIndex++)
	{
		float* pValue = m_FloatRefPars[nIndex];
		if (pValue)
			*pValue = DllEx_CallMacro_GetFloatReference( m_pMacro, nIndex );
	}
	for (unsigned int nIndex=0; nIndex < (unsigned int) m_DoubleRefPars.size(); nIndex++)
	{
		double* pValue = m_DoubleRefPars[nIndex];
		if (pValue)
			*pValue = DllEx_CallMacro_GetDoubleReference( m_pMacro, nIndex );
	}
	for (unsigned int nIndex=0; nIndex < (unsigned int) m_StringRefPars.size(); nIndex++)
	{
		std::string* pValue = m_StringRefPars[nIndex];
		if (pValue)
		{
			int nStringSize = DllEx_CallMacro_GetStringReference( m_pMacro, nIndex, NULL, 0 ) + 1;
			char *szTemp = new char[nStringSize];
			DllEx_CallMacro_GetStringReference( m_pMacro, nIndex, szTemp, nStringSize );
			*pValue = szTemp;
			delete[] szTemp;
		}
	}

	return (m_nLastErrorCode == 0);
}

// -------------------------------------------------------------------------------------------------
// ---                                    GetFloatReturnValue                                    ---
// -------------------------------------------------------------------------------------------------
float C_DirectMacroCall::ResultFloat()
{
	if (m_pMacro == NULL)
	{
		return 0.0;
	}
	return DllEx_CallMacro_ReturnFloat(m_pMacro);
}

// -------------------------------------------------------------------------------------------------
// ---                                    GetFloatReturnValue                                    ---
// -------------------------------------------------------------------------------------------------
double C_DirectMacroCall::ResultDouble()
{
	if (m_pMacro == NULL)
	{
		return 0.0;
	}
	return DllEx_CallMacro_ReturnDouble(m_pMacro);
}

// -------------------------------------------------------------------------------------------------
// ---                                     GetIntReturnValue                                     ---
// -------------------------------------------------------------------------------------------------
int C_DirectMacroCall::ResultInt()
{
	if (m_pMacro == NULL)
	{
		return 0;
	}
	return DllEx_CallMacro_ReturnInt(m_pMacro);
}

// -------------------------------------------------------------------------------------------------
// ---                                    GetStringReturnValue                                   ---
// -------------------------------------------------------------------------------------------------
std::string C_DirectMacroCall::ResultString()
{
	if (m_pMacro == NULL)
	{
		return "";
	}
	int nStringSize = DllEx_CallMacro_ReturnString( m_pMacro, NULL, 0 ) + 1;
	char *szTemp = new char[nStringSize];
	DllEx_CallMacro_ReturnString( m_pMacro, szTemp, nStringSize );
	std::string sResult = szTemp;
	delete[] szTemp;
	return sResult;
}

// -------------------------------------------------------------------------------------------------
// ---                                           SetName                                         ---
// -------------------------------------------------------------------------------------------------
void C_DirectMacroCall::SetName( const std::string& p_sName )
{
	Clear();
	m_sName = p_sName;
	Init();
}
