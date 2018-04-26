#ifndef ColorPostProcess_h_
#define ColorPostProcess_h_
//-
// Copyright 2015 Autodesk, Inc.  All rights reserved.
//
// Use of this software is subject to the terms of the Autodesk license agreement
// provided at the time of installation or download, or which otherwise
// accompanies this software in either electronic or hard copy form.
//+
#include <maya/MString.h>
#include <maya/MViewport2Renderer.h>
#include <maya/MRenderTargetManager.h>

/////////////////////////////////////////////////////////////////////////////////////////
//
// Description: The purpose of this plug-in is to show how a render override
// can be used to perform post scene render color operations.
//
// The basic idea is to render the scene into a custom render target T1.
//
// T1 is then used as input in on the first color (quad) operation. The output
// is routed to a second render target T2. The next color operation will take
// T2 as input and route to T1. If we have series of color operations then
// they would "ping-pong" (alternative) the source and destination targets as needed.
//
// Following the color operations a HUD and presentation operation will use the
// destination target used by the last color operation.
// 
/////////////////////////////////////////////////////////////////////////////////////////

/* 
     Class to handle color post process override filters
*/
class ColorPostProcessOverride : public MHWRender::MRenderOverride
{
public:
    // operation names
    //static const MString kSwirlPassName;
    //static const MString kFishEyePassName;
    static const MString kEdgeDetectPassName;
	static const MString kAttributePassName;

	ColorPostProcessOverride( const MString & name , const MString & filepath);
	virtual ~ColorPostProcessOverride();
	virtual MHWRender::DrawAPI supportedDrawAPIs() const;

	// Basic setup and cleanup
	virtual MStatus setup( const MString & destination );
	virtual MStatus cleanup();

	// UI name
	virtual MString uiName() const
	{
		return mUIName;
	}
	
protected:

	// UI name 
	MString mUIName;

	MString mFilepath;

	friend class viewRenderOverridePostColorCmd;

	MHWRender::MRenderTarget* mTargets;
	MHWRender::MRenderTargetDescription* mTargetDescriptions;
};

//
// 2d Post scene render quad operation
//
class PostQuadRender : public MHWRender::MQuadRender
{
public:

	PostQuadRender(const MString &name, const MString &id, const MString &technique, MHWRender::MRenderTarget* input2 = NULL);
	~PostQuadRender();

	virtual const MHWRender::MShaderInstance * shader();
    virtual MHWRender::MClearOperation & clearOperation();

    virtual int writableTargets(unsigned int& count);
    virtual bool getInputTargetDescription(const MString& name, MHWRender::MRenderTargetDescription& description);

protected:

	MHWRender::MShaderInstance *mShaderInstance;
	MString mEffectId;
	MString mEffectIdTechnique;
	MHWRender::MRenderTarget* prePass;
};

// Scene render to output to targets
class sceneRenderMRT : public MHWRender::MSceneRender
{
public:
	sceneRenderMRT(const MString &name);
	virtual ~sceneRenderMRT();

	virtual MHWRender::MRenderTarget* const* targetOverrideList(unsigned int &listSize);
	virtual MHWRender::MClearOperation & clearOperation();
	virtual const MHWRender::MShaderInstance* shaderOverride();
	virtual MHWRender::MSceneRender::MSceneFilterOption renderFilterOverride();

	void setRenderTargets(MHWRender::MRenderTarget *targets);
	void setShader(MHWRender::MShaderInstance *shader)
	{
		mShaderInstance = shader;
	}
	void useViewportRect(bool val)
	{
		mUseViewportRect = val;
	}
	const MFloatPoint * viewportRectangleOverride();

protected:
	MHWRender::MRenderTarget *mTargets;
	MHWRender::MShaderInstance *mShaderInstance;
	MFloatPoint mViewRectangle;
	bool mUseViewportRect;
};

#endif
