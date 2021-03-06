#include <mex.h>

#include "Tforms.h"
#include "ScanList.h"
#include "ImageList.h"
#include "GenList.h"
#include "Kernels.h"

void Tforms::addTforms(thrust::device_vector<float> tformDIn, size_t tformSizeX, size_t tformSizeY){
	if(tformDIn.size() != (tformSizeX*tformSizeY)){
		mexErrMsgTxt("Error input tform matricies must be same size as given dimensions in size");
		return;
	}
	tform tformIn;
	tformD.push_back(tformIn);
	tformD.back().tform = tformDIn;
	tformD.back().tformSizeX = tformSizeX;
	tformD.back().tformSizeY = tformSizeY;
}

void Tforms::addTforms(thrust::host_vector<float> tformDIn, size_t tformSizeX, size_t tformSizeY){
	if(tformDIn.size() != (tformSizeX*tformSizeY)){
		mexErrMsgTxt("Error input tform matricies must be same size as given dimensions in size");
		return;
	}
	tform tformIn;
	tformD.push_back(tformIn);
	tformD.back().tform = tformDIn;
	tformD.back().tformSizeX = tformSizeX;
	tformD.back().tformSizeY = tformSizeY;
}

void Tforms::removeAllTforms(void){
	tformD.clear();
}

float* Tforms::getTformP(size_t idx){
	if(tformD.size() <= idx){
		std::ostringstream err;
		err << "Cannot get pointer to element " << idx << " as only " << tformD.size() << " elements exist";
		mexErrMsgTxt(err.str().c_str());
		return NULL;
	}
	return thrust::raw_pointer_cast(&(tformD[idx].tform[0]));
}

size_t Tforms::getTformSize(size_t idx){
	if(tformD.size() <= idx){
		std::ostringstream err; err << "Cannot get element " << idx << " as only " << tformD.size() << " elements exist";
		mexErrMsgTxt(err.str().c_str());
		return 0;
	}
	return (tformD[idx].tformSizeX * tformD[idx].tformSizeY);
}

void Tforms::transform(ScanList* scans, Cameras* cam, GenList* gen, size_t tformIdx, size_t camIdx, size_t scanIdx, size_t genIdx){};

void CameraTforms::addTforms(thrust::device_vector<float> tformDIn){
	if(tformDIn.size() != 16){
		std::ostringstream err; err << "Error input tform matricies must be same size as given dimensions in size";
		mexErrMsgTxt(err.str().c_str());
		return;
	}
	tform tformIn;
	tformD.push_back(tformIn);
	tformD.back().tform = tformDIn;
	tformD.back().tformSizeX = 4;
	tformD.back().tformSizeY = 4;
}

void CameraTforms::addTforms(thrust::host_vector<float> tformDIn){
	if(tformDIn.size() != 16){
		std::ostringstream err; err << "Error input tform matricies must be same size as given dimensions in size";
		mexErrMsgTxt(err.str().c_str());
		return;
	}
	tform tformIn;
	tformD.push_back(tformIn);
	tformD.back().tform = tformDIn;
	tformD.back().tformSizeX = 4;
	tformD.back().tformSizeY = 4;
}

void CameraTforms::transform(ScanList* scans, Cameras* cam, GenList* gen, size_t tformIdx, size_t camIdx, size_t scanIdx, size_t genIdx){

	CameraTransformKernel<<<gridSize(scans->getNumPoints(scanIdx)), BLOCK_SIZE, 0, gen->getStream(genIdx)>>>(
		getTformP(tformIdx),
		cam->getCamP(camIdx),
		cam->getPanoramic(camIdx),
		scans->getLP(scanIdx,0),
		scans->getLP(scanIdx,1),
		scans->getLP(scanIdx,2),
		scans->getNumPoints(scanIdx),
		gen->getGLP(genIdx,0,scans->getNumPoints(scanIdx)),
		gen->getGLP(genIdx,1,scans->getNumPoints(scanIdx)));

	CudaCheckError();
}

void AffineTforms::addTforms(thrust::host_vector<float> tformDIn){
	tform tformIn;
	tformD.push_back(tformIn);
	tformD.back().tform = tformDIn;
	tformD.back().tformSizeX = 3;
	tformD.back().tformSizeY = 3;
}

void AffineTforms::addTforms(thrust::device_vector<float> tformDIn){
	tform tformIn;
	tformD.push_back(tformIn);
	tformD.back().tform = tformDIn;
	tformD.back().tformSizeX = 3;
	tformD.back().tformSizeY = 3;
}

void AffineTforms::transform(ScanList* scans, Cameras* cam, GenList* gen, size_t tformIdx, size_t camIdx, size_t scanIdx, size_t genIdx){
	AffineTransformKernel<<<gridSize(scans->getNumPoints(scanIdx)), BLOCK_SIZE, 0, gen->getStream(genIdx)>>>(
		getTformP(tformIdx),
		scans->getLP(scanIdx,0),
		scans->getLP(scanIdx,1),
		scans->getNumPoints(scanIdx),
		gen->getGLP(genIdx,0,scans->getNumPoints(scanIdx)),
		gen->getGLP(genIdx,1,scans->getNumPoints(scanIdx)));

	CudaCheckError();
}
