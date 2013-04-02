#ifndef MATLAB_CALLS_H
#define MATLAB_CALLS_H

//must use "extern c" when creating dll so matlab can read it, but matlab can't see "extern c" as it is a c++ term.
#ifdef __cplusplus
	#define DllExport  extern "C" __declspec( dllexport )
#endif

#ifndef __cplusplus
	#define DllExport
#endif

DllExport unsigned int getNumMove(void);
DllExport unsigned int getNumBase(void);
DllExport unsigned int getNumPairs(void);

DllExport void clearScans(void);
DllExport void initalizeScans(unsigned int numBaseIn, unsigned int numMoveIn, unsigned int numPairsIn);

DllExport void setBaseImage(unsigned int scanNum, unsigned int height, unsigned int width, unsigned int numCh, float* base);
DllExport void setMoveImage(unsigned int scanNum, unsigned int height, unsigned int width, unsigned int numCh, float* move);
DllExport void setMoveScan(unsigned int scanNum, unsigned int numDim, unsigned int numCh, unsigned int numPoints, float* move);

DllExport const float* getMoveLocs(unsigned int scanNum);
DllExport const float* getMovePoints(unsigned int scanNum);

DllExport int getMoveNumCh(unsigned int scanNum);
DllExport int getMoveNumDim(unsigned int scanNum);
DllExport int getMoveNumPoints(unsigned int scanNum);

DllExport int getBaseDim(unsigned int scanNum, unsigned int dim);
DllExport int getBaseNumCh(unsigned int scanNum);
DllExport const float* getBaseImage(unsigned int scanNum);

DllExport void setupCamera(int panoramic);
DllExport void setupTformAffine(void);
DllExport void setupCameraTform(void);

DllExport void setCameraMatrix(float* camMat);
DllExport void setTformMatrix(float* tMat);

DllExport void transform(unsigned int imgNum);

DllExport const float* getGenLocs(void);

#endif //MATLAB_CALLS_H