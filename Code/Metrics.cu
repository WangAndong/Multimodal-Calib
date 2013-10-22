#include "Metrics.h"
#include "Kernels.h"
#include "reduction.h"
#include "mi.h"

float Metric::evalMetric(ScanList* scan, size_t index){
	mexErrMsgTxt("No metric has been specified");
	return 0;
}

MI::MI(size_t bins):
	bins_(bins){
}

float MI::evalMetric(ScanList* scan, size_t index){
	
	if((scan->getNumCh(index) != 1)){
		mexErrMsgTxt("MI metric can only accept a single intensity channel");
	}

	float miOut = miRun(scan->getGIP(index,0), scan->getIP(index,0), bins_, scan->getNumPoints(index), false, scan->getStream(index));
	CudaCheckError();
	cudaDeviceSynchronize();

	return -miOut;
}

NMI::NMI(size_t bins):
	bins_(bins){
}

float NMI::evalMetric(ScanList* scan, size_t index){
	
	if((scan->getNumCh(index) != 1)){
		mexErrMsgTxt("NMI metric can only accept a single intensity channel");
	}

	float miOut = miRun(scan->getGIP(index,0), scan->getIP(index,0), bins_, scan->getNumPoints(index), true, scan->getStream(index));
	CudaCheckError();
	cudaDeviceSynchronize();

	return -miOut;
}

SSD::SSD(){};

float SSD::evalMetric(ScanList* scan, size_t index){
	
	if((scan->getNumCh(index) != 1)){
		mexErrMsgTxt("SSD metric can only accept a single intensity channel");
	}
	
	SSDKernel<<<gridSize(scan->getNumPoints(index)), BLOCK_SIZE, 0, scan->getStream(index)>>>
		(scan->getGIP(index,0), scan->getIP(index,0), scan->getNumPoints(index));
	CudaCheckError();
	
	//perform reduction
	float temp = reduceEasy(scan->getGIP(index,0), scan->getNumPoints(index), scan->getStream(index), scan->getTMP(index));
	temp = sqrt(temp);

	return temp;
}

GOM::GOM(){};

float GOM::evalMetric(ScanList* scan, size_t index){
	
	if((scan->getNumCh(index) != 2)){
		mexErrMsgTxt("GOM metric can only accept a two intensity channels (mag and angle)");
	}
	
	GOMKernel<<<gridSize(scan->getNumPoints(index)), BLOCK_SIZE, 0, scan->getStream(index)>>>
		(scan->getGIP(index,0),scan->getGIP(index,1),scan->getIP(index,0),scan->getIP(index,1), scan->getNumPoints(index));
	CudaCheckError();

	float phase = reduceEasy(scan->getGIP(index,1), scan->getNumPoints(index), scan->getStream(index), scan->getTMP(index));
	float mag = reduceEasy(scan->getGIP(index,0), scan->getNumPoints(index), scan->getStream(index), scan->getTMP(index));
	
	float out = -phase / mag;

	return out;
}

GOMS::GOMS(){};

float GOMS::evalMetric(ScanList* scan, size_t index){
	
	if((scan->getNumCh(index) != 2)){
		mexErrMsgTxt("GOM metric can only accept a two intensity channels (mag and angle)");
	}
   
	GOMKernel<<<gridSize(scan->getNumPoints(index)), BLOCK_SIZE, 0, scan->getStream(index)>>>
		(scan->getGIP(index,0),scan->getGIP(index,1),scan->getIP(index,0),scan->getIP(index,1), scan->getNumPoints(index));
	CudaCheckError();

	float phase = reduceEasy(scan->getGIP(index,1), scan->getNumPoints(index), scan->getStream(index), scan->getTMP(index));
	float mag = reduceEasy(scan->getGIP(index,0), scan->getNumPoints(index), scan->getStream(index), scan->getTMP(index));
	
	float out = log(sqrt(6/(mag*PI))) - (6*((phase - (mag/2))*(phase - (mag/2)))/mag);
	((phase/mag) > 0.5) ? out = 1*out : out = -1*out;

	return out;
}

/*LIV::LIV(float* avImg, size_t width, size_t height){
	avImg_ = new PointsList(avImg, (width*height), true);
}

LIV::~LIV(){
	delete avImg_;
}

void LIV::evalMetric(std::vector<float*> A, std::vector< thrust::device_vector<float>> B, cudaStream_t stream){

	//check scans exist
	if(A == NULL || B == NULL){
		TRACE_ERROR("Two scans are required for the metric to operate");
		*value = 0;
		return;
	}

	size_t numElements;
	//check scans of same size
	if(A->getNumPoints() != B->getNumPoints()){
		numElements = (A->getNumPoints() > B->getNumPoints()) ? B->getNumPoints() : A->getNumPoints();
		TRACE_WARNING("Number of entries does not match, Scan A has %i, Scan B has %i, only using %i entries",A->getNumPoints(),B->getNumPoints(),numElements);
	}
	else{
		numElements = A->getNumPoints();
	}

	float* out;
	CudaSafeCall(cudaMalloc(&out, sizeof(float)*numElements));
	
	livValKernel<<<gridSize(numElements), BLOCK_SIZE, 0, *stream>>>
		((float*)A->getPoints()->GetGpuPointer(), (float*)B->getPoints()->GetGpuPointer(), (float*)avImg_->GetGpuPointer(), numElements, out);
	CudaCheckError();

	//perform reduction
	float outVal = reduceEasy(out, numElements);
	CudaSafeCall(cudaFree(out));
	
	*value = outVal;
}*/