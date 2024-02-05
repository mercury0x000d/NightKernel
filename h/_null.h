/*************************************************************************
 *                                                                                                                                               *
 *                                                                                                                                               *
 *              NIGHTDOS - 32-bit kernel                                                                                 *
 *              ------------------------------------                                                 *
 *              _NULL.H header file                                                                                              *
 *                                                                                                                                               *
 *************************************************************************/


#ifdef NULL
#undef NULL
#endif

#ifdef __cplusplus
extern "C"
{
#endif

/* Standard NULL declaration */
#define NULL    0
#ifdef __cplusplus
}
#else
/* standard NULL declaration */
#define NULL    (void *)0
#endif
