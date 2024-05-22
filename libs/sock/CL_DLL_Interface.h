// ------------------------------------------------------------------------------------------------
//
// Copyright (C) 1998-2021 LaVision GmbH.  All Rights Reserved.
//
// ------------------------------------------------------------------------------------------------
//
/**
	@file CL_DLL_Interface.h
	@brief Interface for DLLs to use some DaVis functions
	@author BW,TL
**/

#ifndef __CL_DLL_INTERFACE_H__
#define __CL_DLL_INTERFACE_H__

/**
	Corresponding CL-subroutine:

	int CallDll( string p_sDllName, string p_sFunctionName, line& p_pParameter );

   Calls external user-defined function in DLL. The extension ".dll" must not be given to p_sDllName.

	Purpose: enable user to write his own DLL-functions for
   				- implementing fast image processing with 'C'-level speed
               - writing native drivers, execute native windows functions
               - do special action not supported by CL-functions

   The DLL must be in a certain format, see file CL_DLL_Example.cpp as an example of
   how to write your own DLL.

   When the DLL is loaded the first time, a function InitDll( void(*)() ) is
   automatically called (only once). This function has as a parameter a function
   pointer, with which it is possible to access many low-level data structures
   and functions inside DaVis. This is necessary for manipulating e.g. buffer
   data. For more details of how this is done, see file CL_DLL_Example.cpp.

   When CallDll() is called, and the DLL is loaded (and InitDll() called), then
   the DLL-function <function_name> is executed. In the DLL it must be of a format

   	extern "C" int EXPORT <function_name>( int* parameter );
   or
   	extern "C" int EXPORT <function_name>( float* parameter );

   The parameters in the integer or float array can be used to transfer data to
   the DLL-function or to return values from the DLL-function.

   Example: function AddTwoNumbers() in DEMODLL.DLL, use the following CL-code to
   call this function (see file DEMODLL.CL):

         float pars[3] = { 1.2, 2.4, 0 };
         CallDll( "demodll", "AddTwoNumbers", pars );
         InfoText( "Dll-function returns as a third parameter: " + pars[2] );

   If the DLL-function has an integer array for the parameters instead, you must
   set up an CL-integer array correspondingly.

   Note also: The DLL-function name most likely gets an underscore '_' put in front
   when compiled. The CL-subroutine CallDll() searches for _name() first. If this
   function is not found, then it searches for name().

	Note for different operating systems:
	A DLL with name "<name>.dll" is loaded on Windows systems and a library with
	extension ".lib" on Linux systems. If path to the DLL is a absolute path, then
	the caller has to concern about the operating system. When using a relative path,
	the correct subfolder of DaVis binaries is taken: win32, win64, linux32 or linux64.
**/

#ifndef _LINUX

#include <stdio.h>

#undef EXPORT

#ifdef __BORLANDC__
#	define EXPORT	_export
#endif

#ifdef _MSC_VER
#	define EXPORT	__declspec(dllexport)
#endif

#else // _LINUX

#	include <stdlib.h>
#	define EXPORT	__attribute((visibility("default")))
#	define HDC void*

#	ifndef TRUE
#		define TRUE  1
#		define FALSE 0
#	endif

#endif

#include <string>
using namespace std;

typedef unsigned short Word;

/*****************************************************************************/
// FUNCTIONS TO BE CALLED FROM OWN DLL CODE
/*****************************************************************************/

/// @brief Execute the CL macro.
/// @return 0 if ok, else internal error code.
extern int 	(*ExecuteCommand)		( const char* p_sCommand );

/// @brief Show buffer, useful for DaVis Classic only.
extern int 	(*Show)				 	( int p_hBuffer );

/// @brief Display a short text in a message box (standard mode is 0 to display a OK button).
/// @return Index of pressed button, see subroutine Message.
extern int 	(*Message)				( const char* theText, int theMode );

/// @brief Same as subroutines StatusText
/// @return 0 if ok, else internal error code.
typedef int	(*StatusTextType)		( const char* theText );
extern int	(*StatusText)			( const char* theText );

/// @brief Same as subroutines InfoText
/// @return 0 if ok, else internal error code.
extern int   (*InfoText)		   ( const char* theText );

/// @brief Same as subroutine IsValidSymbol: 
/// @return type of symbol: 0=not existing, 1=macro function, 2=subroutine, -1=variable
extern int	(*IsValidSymbol)		( const char* theSybolName );

/// @brief Get or set the value of CL variable with name theVarName.
/// Warning: GetString is not thread-safe, please use Dll_GetStringBuffer when calling this function from several threads.
/// @param theIndex Index for arrays (0,...,N-1) or 0 for simple variables.
/// @return Value of the variable
extern int 	 (*GetInt)				( const char* theVarName, int theIndex );
extern float (*GetFloat)			( const char* theVarName, int theIndex );
extern const char* (*GetString)	( const char* theVarName, int theIndex );
extern char* (*Dll_GetStringBuffer)( const char* p_sVarName, int p_nIndex, char* p_sBuffer, int p_nBufferLength );
extern void  (*SetInt)				( const char* theVarName, int theIndex, int value );
extern void  (*SetFloat)			( const char* theVarName, int theIndex, float value );
extern void  (*SetString)			( const char* theVarName, int theIndex, char* str );

/// @brief Get the type of a buffer
/// @param p_hBuffer Buffer handle
/// @return 0=word, 1= float, 2= double, 3= int32
extern int 	(*IsFloat)		  		( int p_hBuffer );

/// @brief Determine if a buffer is empty.
/// @param p_hBuffer Buffer handle
/// @return 1 if empty (e.g. size if zero), 0 if not empty.
extern int 	(*IsEmpty)		  		( int p_hBuffer );

/// @brief Request the size of a 2D buffer. Use GetVolumeSize (see below) for general buffers.
/// @param p_hBuffer Buffer handle
/// @param theNx Filled with width
/// @param theNy Filled with height
/// @param theType Filled with buffer type, e.g. 0 for word or 1 for float
/// @return 0 if ok, -1 if invalid buffer number, else internal error code.
extern int 	(*GetBufferSize)		( int p_hBuffer, int* theNx, int* theNy, int* theType );

/// @brief Create a 2D buffer. Use CreateVolume (see below) for general buffers.
/// @param p_hBuffer Buffer handle
/// @param theNx Width
/// @param theNy Height
/// @param theType 0 for word and 1 for float buffers.
extern int 	(*SetBufferSize)		( int p_hBuffer, int theNx, int theNy, int theType );

/// @brief Get a pointer to a data row of the given buffer.
/// NULL is returned on invalid row numbers or invalid buffers.
/// For Word buffers the pointer must be changed to Word* like 
///		Word* myPtrW = (Word*)GetBufferRowPtr(...);
/// For float buffer to float* like 
///		float* myPtrF = (float*)GetBufferRowPtr(...);
/// Same for buffer data types double, int, byte and RGB (with RGBQUAD*).
/// Then each pointer can be addressed with the column index:
///		for (int x=0; x<nx; x++)
///			myPtrW[x] = x;
/// @param p_hBuffer Buffer handle
/// @param theRow Row index
/// @return Pointer to row data, NULL on invalid row
extern void* (*GetBufferRowPtr)	( int p_hBuffer, int theRow );

/// @brief Get a pointer to a data row of the given buffer. Same as GetBufferRowPtr but for 4D buffers.
/// @param p_hBuffer Buffer handle
/// @param theY Row index
/// @param theZ Plane index
/// @param theF Frame index
/// @return Pointer to row data, NULL on invalid position
extern void* (*GetVolBufRowPtr)	( int p_hBuffer, int theY, int theZ, int theF );

/// @brief Get address of data of word buffer.
/// Packed word buffers will not be unpacked, access this buffer with (Byte*)-cast of the address.
/// @param p_hBuffer Buffer handle
/// @return Pointer to row data, NULL on invalid position
extern Word* (*GetWordDataAccess)		( int p_hBuffer );
extern Word* (*GetWordDataAccessRow)	( int p_hBuffer, int theY, int theZ, int theF );

/// @brief Get or set the vector grid size of given buffer number.
/// @param p_hBuffer Buffer handle
extern int 	(*GetVectorGrid)		( int p_hBuffer );
extern void (*SetVectorGrid)		( int p_hBuffer, int theGridSize );

/// @brief Get or set the vector components of the defined vector position (not pixel position!).
/*	If the vector field format is extended (as used for PIV evaluations)
	the parameter header selects the position of the vector:
	   header < 0: set only the header entry to abs(header). the vector is untouched.
		header = 0: vector is disabled.
		header > 0: set the header entry and the vector.
		header = 5: vector is preprocessed, the components are stored in vector entry 4
		header = 6: vector is smoothed, the components are stored in vector entry 4
		header = 99: set correlation peak ratio to value of vx, or return peak ratio in vx
*/
/// @return Header value.
extern int 	(*GetVector)			( int p_hBuffer, int x, int y, float& vx, float& vy, int header );
extern void (*SetVector)			( int p_hBuffer, int x, int y, float vx, float vy, int header );
extern int 	(*Get3DVector)			( int p_hBuffer, int x, int y, float& vx, float& vy, float& vz, int header );
extern void (*Set3DVector)			( int p_hBuffer, int x, int y, float vx, float vy, float vz, int header );
extern int 	(*Get4DVector)			( int p_hBuffer, int x, int y, int z, int f, float& vx, float& vy, float& vz, int header );	// new in DaVis 7.0
extern void (*Set4DVector)			( int p_hBuffer, int x, int y, int z, int f, float vx, float vy, float vz, int header );		// new in DaVis 7.0

/// @brief Same as subroutine
/// @return 0 if ok, else internal error code.
extern int 	(*PivCalculateVectorField) ( int inbuf, int outbuf, int rectangle );

/// @brief Working with 4D buffers, same as subroutines.
/// @param p_hBuffer Buffer handle
/// @return 0 if ok, else internal error code.
extern int   (*CreateVolume)     ( int p_hBuffer, int nx, int ny, int nz, int nf, int isSparse, int isFloat, int nScalars, int theSubtype );
extern int   (*ResizeVolume)     ( int p_hBuffer, int nx, int ny, int nz, int nf, int isSaveContents, int isFloat );
extern int   (*GetVolumeSize)    ( int p_hBuffer, int& nx, int& ny, int& nz, int& nf );

/// @brief Check if number of planes is larger than 1.
/// @param p_hBuffer Buffer handle
/// @return 1 if nz > 1, else 0.
extern int	 (*IsVolume)			( int p_hBuffer );

/// @brief Same as subroutine.
/// @param p_hBuffer Buffer handle
/// @param isSparse Retired, always 0.
/// @param aSubType 0 for the usual image data types (word, float, double), -2 for byte, -11 for RGB, >0 for vector types.
///        Call IsFloat() to get information about word, float or double.
/// @param nComponents Retired, always 0.
/// @param nVectors Number of vector choices: 1 or 4.
/// @param nScalars Retired, always 0.
extern void	 (*GetVolumeInfo)		( int p_hBuffer, int& isSparse, int& aSubType, int& nComponents, int& nVectors, int& nScalars );

/// @brief Mask access.
/// Mask_GetPlane returns an array of size nx*ny or NULL if no mask plane is available.
/// The requested plane must be free'd by Mask_FreePlane after usage!
/// You can create your own bool[nx*ny] array and copy it into the buffer with Mask_SetPlane.
/// Mask_SetPlane returns 0 on success and creates the mask if not existing before.
extern bool*	(*Mask_GetPlane)	( int p_hBuffer, int theZ, int theF );
extern void		(*Mask_FreePlane)	( int p_hBuffer, const bool* thePlane );
extern int		(*Mask_SetPlane)	( int p_hBuffer, int theZ, int theF, const bool* thePlane );

/// @brief Retired!
/// @param p_hBuffer Buffer handle
/// @return Value 0
extern int    (*GetComponentIndexOfFirstAdditionalScalar)( int p_hBuffer );

/// @brief Float plane access
/// @param p_hBuffer Buffer handle
extern float* (*GetFloatPlane)	( int p_hBuffer, int theZ, int theF, int theC );
extern void   (*SetFloatPlane)	( int p_hBuffer, int theZ, int theF, int theC, const float* plane );
extern void   (*FreeFloatPlane)	( int p_hBuffer, float* plane );

/// @brief Set or get buffer parameter. See macro file Buffer.cl for examples and constants for theMode.
/// @param p_hBuffer Buffer handle
extern int    (*Buffer_SetPar)	( int p_hBuffer, int theMode, int theIntParsN, int* theIntPars, int theFloarParsN, float* theFloatPars, int theStringParsN, char** theStringPars );
extern int    (*Buffer_GetPar)	( int p_hBuffer, int theMode, int theIntParsN, int* theIntPars, int theFloarParsN, float* theFloatPars, int theStringParsN, char** theStringPars );

/// @brief Interpolate a vector at the given position
/// @param p_hBuffer Buffer handle
/// @return Best choice
extern int		(*Dll_GetInterpolatedVector)	( int p_hBuffer, float xpos, float ypos, int p_nPlane, int p_nFrame, float& p_rfVx, float& p_rfVy, float& p_rfVz, int p_eMode );

/// @brief Replace plane of typed scalar (TS) in a TS with same size as buffer. New in 8.0.4. Create TS for all frames if not existing.
/// @param p_hBuffer Buffer handle
/// @param p_sName Name of TS
/// @param p_nPlane Plane index
/// @param p_nFrame Frame index
/// @param p_fArray Data to be copied into the TS plane.
/// @return 0 on success else internal error code.
extern int		(*Dll_Buffer_SetTypedScalar)	( int p_hBuffer, const char* p_sName, int p_nPlane, int p_nFrame, const float* p_fArray );

/// @brief Fill the given array with typed scalar data from a TS with same size as buffer. New in 8.0.4.
/// @param p_hBuffer Buffer handle
/// @param p_sName Name of TS
/// @param p_nPlane Plane index
/// @param p_nFrame Frame index
/// @param p_fArray Data to be filled with TS data. Array must be large enough to hold the complete plane!
/// @return 0 on success else internal error code.
extern int		(*Dll_Buffer_GetTypedScalar)	( int p_hBuffer, const char* p_sName, int p_nPlane, int p_nFrame, float* p_fArray );

/// @brief Set or get buffer attributes.
enum BufAttr_Type {	BAT_EMPTY = 0, BAT_STRING, BAT_FLOATARRAY, BAT_INTARRAY, BAT_WORDARRAY, BAT_DOUBLEARRAY };

/// @brief Access buffer attributes
/// Warning: GetAttrStr is not thread-safe, please use Dll_GetAttrStrBuffer when calling this function from several threads.
/// @param p_hBuffer Buffer handle
/// @param p_sName Name of attribute
/// @param theValue New string value of the attribute.
/// @return 0 on success else internal error code.
extern const char* (*GetAttrStr)  ( int p_hBuffer, const char* p_sName );
extern char* (*Dll_GetAttrStrBuffer)( int p_hBuffer, const char* p_sName, char* p_sBuffer, int p_nBufferLength );
extern int   (*SetAttrStr)        ( int p_hBuffer, const char* p_sName, const char* theValue );
extern int   (*GetAttrArray)      ( int p_hBuffer, const char* p_sName, int theSize, BufAttr_Type theType, void* theArray );
extern int   (*SetAttrArray)      ( int p_hBuffer, const char* p_sName, int theSize, BufAttr_Type theType, void* theArray );

/// @brief Delete all attributes.
/// @param p_hBuffer Buffer handle
extern void  (*DeleteAttributes)  ( int p_hBuffer );

/// @brief Same as subroutine GetColorPixel.
extern void  (*GetColorPixel)		( int p_hBuffer, int mode, int x, int y, float& par1, float& par2, float& par3 );

/// @brief Let DaVis process Windows events, e.g. repainting GUI or mouse move or macro stopping.
/// This should be called from the main thread and from the thread of the DLL function call.
/// Don't call this e.g. from OpenMP threads. This costs time and would never return TRUE.
/// @return TRUE (1) if the DLL has to return/quit, because the user has stopped the macro run.
typedef int	(*ProcessEventsType)	();
extern int	(*ProcessEvents)		();

/// @brief Get or set the scale information of a buffer for X (theScaleXYZIF=0), Y (1), Z (2), I (3) or F (4).
// The get function can be called with NULL for both char pointers, but the char-array must be large
// enough to store the requested value.
extern void	(*GetScale)				( int buffer, int theFrame, int theScaleXYZIF, float&factor, float&offset, char* unit, char* description );
extern void	(*SetScale)				( int buffer, int theFrame, int theScaleXYZIF, float factor, float offset, const char* unit, const char* description );

/// @brief New in DaVis 8.1: access BufferLib
namespace BufferApi
{
	class I_Buffer;
};

//#pragma deprecated(C_InterfaceOfSCBuffer)
/// @brief Scoped access to the I_Buffer interface of a SC-Buffer.
/// RETIRED: Please use Core/BufferCLHandlesMapping.dll and classes C_ClHandleBuffer, C_ClHandleBufferWriteAccess or C_ClHandleBufferReadOnly instead!
class C_InterfaceOfSCBuffer
{
public:
	C_InterfaceOfSCBuffer( int p_hBuffer );
	~C_InterfaceOfSCBuffer();

	/// @brief Get the buffer interface.
	BufferApi::I_Buffer* Get()				{	return m_pBufferInterface; }

	/// @brief Access object of buffer interface.
	BufferApi::I_Buffer* operator->()	{	return m_pBufferInterface; }

private:
	int m_hBuffer;
	BufferApi::I_Buffer* m_pBufferInterface;
};

/// @brief Get buffer interface for a given buffer document. Usage has to be released at end of processing.
/// RETIRED: Please use Core/BufferCLHandlesMapping.dll and class C_ClHandleBuffer instead!
/// @param p_hBuffer Buffer document handle.
/// @return Interface pointer to BufferLib or NULL on invalid (empty) buffer.
extern BufferApi::I_Buffer* (*DllEx_Buffer_GetInterface)( int p_hBuffer );

/// @brief Release usage of buffer interface for a given buffer document.
/// RETIRED: Please use Core/BufferCLHandlesMapping.dll and class C_ClHandleBuffer instead!
/// @param p_hBuffer Buffer document handle.
extern void (*DllEx_Buffer_ReleaseInterface)( int p_hBuffer );

/// @brief Define the given buffer interface as new content of the buffer. Buffer takes control via interface and does not copy the data.
/// @param p_hBuffer Buffer document handle.
/// @param p_pBufferInterface New buffer interface for the buffer.
extern void (*DllEx_Buffer_SetInterface)( int p_hBuffer, BufferApi::I_Buffer* p_pBufferInterface );

/// @brief Same as subroutine GetRGB4CLUT.
/// @param thePalette Palette index 0,...,n or -1 for image default, -2 for vector default and -3 for vector background default.
/// @param theRGB_256 Array of 256 integer values to be filled with CLUT color data (RGB).
/// @return TRUE for valid palette, else FALSE.
extern bool (*GetPaletteColors)	( int thePalette, unsigned int* theRGB_256 );

/// @brief Return the given string (setParString) as string results for the CallDllEx subroutine.
/// The string parameters are given as parsString pointer, setParI defines the array item to be set.
extern void (*DllEx_SetStringParm) ( char** parsString, int setParI, const char* setParString );

/// @brief Internal subroutines.
typedef void* SubroutineParameters;
typedef int (*T_SubroutineExec) ( SubroutineParameters* p_pSubroutineParameters );

/// @brief Typedef needed for cpp-files generated with ruby.
namespace CL
{
	typedef ::SubroutineParameters SubroutineParameters;
};

/// @brief Register function as subroutine to DaVis.
/// Use p_pFunction=NULL to unregister the function e.g. when unloading the DLL.
/// See example function C_ExampleSubroutineDLL_Execute for general usage.
/// @return 0 on success else error code.
extern int	(*DllEx_Subroutine_Register)( const char* p_sName, T_SubroutineExec p_pFunction );

/// @brief Get the value of the n-th parameter (p_nPar=0,1,..) to the subroutine during execution.
/// Parameter p_nIndex gives access to array and must be set to 0 for non-array variables.
/// Note: The call to older DllEx_Subroutine_GetStringPar is not thread safe while newer DllEx_Subroutine_GetStdStringPar is thread safe!
extern const char* (*DllEx_Subroutine_GetStringPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
extern std::string DllEx_Subroutine_GetStdStringPar( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
extern int   (*DllEx_Subroutine_GetIntPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
extern float (*DllEx_Subroutine_GetFloatPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );
extern double (*DllEx_Subroutine_GetDoublePar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex );

/// @brief Set the value of reference parameters of the subroutine.
extern void	(*DllEx_Subroutine_SetStringPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, const char* p_sValue );
extern void	(*DllEx_Subroutine_SetIntPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, int p_nValue );
extern void	(*DllEx_Subroutine_SetFloatPar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, float p_fValue );
extern void	(*DllEx_Subroutine_SetDoublePar)( SubroutineParameters* p_pSubroutineParameters, int p_nPar, int p_nIndex, double p_dValue );

/// @brief Set the return value of the subroutine.
extern void	(*DllEx_Subroutine_ReturnString)( SubroutineParameters* p_pSubroutineParameters, const char* p_sResult );
extern void	(*DllEx_Subroutine_ReturnInt)( SubroutineParameters* p_pSubroutineParameters, int p_iResult );
extern void	(*DllEx_Subroutine_ReturnFloat)( SubroutineParameters* p_pSubroutineParameters, float p_fResult );
extern void	(*DllEx_Subroutine_ReturnDouble)( SubroutineParameters* p_pSubroutineParameters, double p_fResult );

/// @brief Direct call to macros and subroutines, new in 8.0.5
typedef void C_DirectMacroCall_Intern;

/// @brief Prepare the direct call to a macro or subroutine instead of executing a string via Dll_ExecuteCommand.
/// @param p_sName Name of macro or subroutine
/// @return Pointer of macro data structure, NULL if macro or subroutine does no exist.
extern C_DirectMacroCall_Intern* (*DllEx_CallMacro_Init)( const char* p_sName );

/// @brief Append a integer parameter for direct macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_nValue Integer parameter
extern void (*DllEx_CallMacro_Par_Int)( C_DirectMacroCall_Intern* p_pMacro, int p_nValue );

/// @brief Append a float parameter for direct macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_fValue Float parameter
extern void (*DllEx_CallMacro_Par_Float)( C_DirectMacroCall_Intern* p_pMacro, float p_fValue );

/// @brief Append a double parameter for direct macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_fValue Double parameter
extern void (*DllEx_CallMacro_Par_Double)( C_DirectMacroCall_Intern* p_pMacro, double p_fValue );

/// @brief Append a string parameter for direct macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_sValue String parameter
extern void (*DllEx_CallMacro_Par_String)( C_DirectMacroCall_Intern* p_pMacro, const char* p_sValue );

/// @brief Execute the macro or subroutine.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @return SCError or 0 on success
extern int (*DllEx_CallMacro_Execute)( C_DirectMacroCall_Intern* p_pMacro );

/// @brief Get value of reference variable
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_nIndex Parameter index (0, 1, ...)
/// @return Integer result
extern int (*DllEx_CallMacro_GetIntReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex );

/// @brief Get value of reference variable
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_nIndex Parameter index (0, 1, ...)
/// @return Float result
extern float (*DllEx_CallMacro_GetFloatReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex );

/// @brief Get value of reference variable
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_nIndex Parameter index (0, 1, ...)
/// @return Double result
extern double (*DllEx_CallMacro_GetDoubleReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex );

/// @brief Get value of reference variable
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_nIndex Parameter index (0, 1, ...)
/// @param p_rsString String memory to be filled, NULL allowed to check the string size.
/// @param p_nStringLength Size of string memory
/// @return Real length of string
extern int (*DllEx_CallMacro_GetStringReference)( C_DirectMacroCall_Intern* p_pMacro, int p_nIndex, char *p_rsString, int p_nStringLength );

/// @brief Get the return value from macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @return Integer result
extern int (*DllEx_CallMacro_ReturnInt)( C_DirectMacroCall_Intern* p_pMacro );

/// @brief Get the return value from macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @return Float result
extern float (*DllEx_CallMacro_ReturnFloat)( C_DirectMacroCall_Intern* p_pMacro );

/// @brief Get the return value from macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @return Double result
extern double (*DllEx_CallMacro_ReturnDouble)( C_DirectMacroCall_Intern* p_pMacro );

/// @brief Get the return value from macro call.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
/// @param p_rsString String memory to be filled
/// @param p_nStringLength Size of string memory, NULL allowed to check the string size.
/// @return Real length of string
extern int (*DllEx_CallMacro_ReturnString)( C_DirectMacroCall_Intern* p_pMacro, char *p_rsString, int p_nStringLength );

/// @brief Finish the call and destroy all internal structures.
/// @param p_pMacro Return value of DllEx_CallMacro_Init().
extern void (*DllEx_CallMacro_Exit)( C_DirectMacroCall_Intern* p_pMacro );




#include <vector>

/// @brief Wrapper class for the DllEx_CallMacro methods.
class C_DirectMacroCall
{
public:
	/// @brief Error codes
	static const int CL_MACRO_ERROR_INVALID_MACRO = -1;

	/// @brief Constructor.
	/// If the macro of subroutine does not exist, the instance is not properly initialised. For more
	/// information see the IsValid() method.
	/// @param p_sName The name of the CL macro or subroutine. If empty then call SetName() before filling all parameters and execute.
	C_DirectMacroCall( std::string p_sName = std::string("") );

	/// @brief Constructor. Initialize direct call to method of CL object.
	/// If the macro of subroutine does not exist, the instance is not properly initialised. For more
	/// information see the IsValid() method.
	/// @param p_hObject Handle of CL object.
	/// @param p_sMethod Name of the object's method.
	C_DirectMacroCall( int p_hObject, std::string p_sMethod );

	/// @brief Virtual destructor.
	virtual ~C_DirectMacroCall();

	/// @brief Adds an int parameter to the macro.
	/// @param p_nMacroParameter The int parameter.
	void Append( int p_nMacroParameter );

	/// @brief Adds an int reference parameter to the macro.
	/// @param p_rnMacroParameter The int reference parameter.
	void AppendReference( int& p_rnMacroParameter );

	/// @brief Adds a float parameter to the macro.
	/// @param p_fMacroParameter The float parameter.
	void Append( float p_fMacroParameter );

	/// @brief Adds a float reference parameter to the macro.
	/// @param p_rfMacroParameter The float reference parameter.
	void AppendReference( float& p_rfMacroParameter );

	/// @brief Adds a double parameter to the macro.
	/// @param p_fMacroParameter The dounle parameter.
	void Append( double p_fMacroParameter );

	/// @brief Adds a double reference parameter to the macro.
	/// @param p_rfMacroParameter The double reference parameter.
	void AppendReference( double& p_rfMacroParameter );

	/// @brief Adds a string parameter to the macro.
	/// @param p_sMacroParameter The string parameter.
	void Append( std::string p_sMacroParameter );

	/// @brief Adds a string reference parameter to the macro.
	/// @param p_rsMacroParameter The string reference parameter.
	void AppendReference( std::string& p_rsMacroParameter );

	/// @brief Executes the macro or subroutine with the current parameters and fill all reference parameters with the results.
	/// If the execution fails, call GetLastErrorCode to obtain the error code of the execution.
	/// @param p_bResetError If TRUE then in case of error the internal error state is resetted and macro execution goes on
	///                      in a non-error state. Otherwise the macro, which calls the DLL function, breaks with this error.
	/// @return True if the execution was successful, else false.
	bool Execute( bool p_bResetError = false );

	/// @brief Gets the code of the last error that occured.
	/// @return The code of the last error or 0 if there was no error yet.
	int GetLastErrorCode()				{ return m_nLastErrorCode; }

	/// @brief Get error message after calling Execute().
	/// Format is: "<ErrorCode>: <Text>".
	/// @return Error message, empty string if Execute() stopped without error.
	std::string GetLastErrorMessage()	{ return m_sLastErrorMsg; }

	/// @brief Gets the name of the macro or subroutine.
	/// @return The name of the macro or subroutine.
	std::string GetName()				{ return m_sName; }

	/// @brief Gets the macro's int return value.
	/// @return The int return value.
	int ResultInt();
	
	/// @brief Gets the macro's float return value.
	/// @return The float return value.
	float ResultFloat();
	
	/// @brief Gets the macro's double return value.
	/// @return The double return value.
	double ResultDouble();
	
	/// @brief Gets the macro's string return value.
	/// @return The string return value.
	std::string ResultString();

	/// @brief States if the instance is properly initialised or not.
	/// @return True if the instance is properly initialised, else false.
	bool IsValid()						{ return m_bIsValid; }

	/// @brief Sets a new macro name.
	/// This method destroys the old internal macro object including all parameters and reference parameters.
	/// @param p_sName The name of the new macro or subroutine.
	void SetName( const std::string& p_sName );

private:
	/// @brief Increase parameter lists.
	void AppendParameter();

	C_DirectMacroCall_Intern* m_pMacro;
	bool m_bIsValid;
	int m_nLastErrorCode;
	std::string m_sLastErrorMsg;
	int m_nParameterCount;
	std::string m_sName;
	int m_hObject;
	
	std::vector< int* > m_IntRefPars;
	std::vector< float* > m_FloatRefPars;
	std::vector< double* > m_DoubleRefPars;
	std::vector< std::string* > m_StringRefPars;

	/// @brief Clears the internal map and destroys the internal macro object.
	void Clear();

	/// @brief Creates a new internal macro object.
	void Init();
};


#endif /* __CL_DLL_INTERFACE_H__*/
