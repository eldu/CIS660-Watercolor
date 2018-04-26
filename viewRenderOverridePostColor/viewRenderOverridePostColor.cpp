//-
// Copyright 2015 Autodesk, Inc.  All rights reserved.
//
// Use of this software is subject to the terms of the Autodesk license agreement
// provided at the time of installation or download, or which otherwise
// accompanies this software in either electronic or hard copy form.
//+
#include "viewRenderOverridePostColor.h"
#include <maya/MShaderManager.h>

//const MString ColorPostProcessOverride::kSwirlPassName = "ColorPostProcessOverride_Swirl";
//const MString ColorPostProcessOverride::kFishEyePassName = "ColorPostProcessOverride_FishEye";
const MString ColorPostProcessOverride::kEdgeDetectPassName = "ColorPostProcessOverride_EdgeDetect";
const MString ColorPostProcessOverride::kAttributePassName = "ColorPostProcessOverride_Attribute";

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

//
// Constructor for override will set up operation lists.
// This override has fairly simple logic to render a scene, perform
// 2d post color operations, and then present the final results
//
ColorPostProcessOverride::ColorPostProcessOverride( const MString & name , const MString &filepath)
: MRenderOverride( name )
, mUIName("Color Post"), mFilepath(filepath)
{
    MHWRender::MRenderer *theRenderer = MHWRender::MRenderer::theRenderer();
    if (!theRenderer)
        return;

    // Create a new set of operations as required
    MHWRender::MRenderer::theRenderer()->getStandardViewportOperations(mOperations);

    PostQuadRender* edgeDetectOp = new PostQuadRender( kEdgeDetectPassName, "FilterEdgeDetect", "", mTargets );
	sceneRenderMRT* attributeOp = new sceneRenderMRT(kAttributePassName);
	//PostQuadRender* attributeOp = new PostQuadRender(kAttributePassName, "AttributePass", "");

	/*
	unsigned int sampleCount = 1; // no multi-sampling, 16-bit floating point target
	MHWRender::MRasterFormat colorFormat = MHWRender::kR16G16B16A16_FLOAT; 

	mTargetDescriptions =
		new MHWRender::MRenderTargetDescription("Attributes", 256, 256, sampleCount, colorFormat, 0, false);

	const MHWRender::MRenderTargetManager* targetManager = theRenderer->getRenderTargetManager();
	mTargets = targetManager->acquireRenderTarget(*(mTargetDescriptions)); 


	//attributeOp->useViewportRect(true); 
	attributeOp->setRenderTargets(mTargets);

	MHWRender::MRenderer* renderer = MHWRender::MRenderer::theRenderer();
	const MHWRender::MShaderManager* shaderMgr = renderer->getShaderManager();
	MHWRender::MShaderInstance* shaderInstance1 = shaderMgr->getEffectsFileShader("AttributePass", "");
	attributeOp->setShader(shaderInstance1);
	*/

    //mOperations.insertAfter(MHWRender::MRenderOperation::kStandardSceneName, attributeOp);
	//mOperations.insertAfter(kAttributePassName, edgeDetectOp);

	mOperations.insertAfter(MHWRender::MRenderOperation::kStandardSceneName, edgeDetectOp);
}


// On destruction all operations are deleted.
//
ColorPostProcessOverride::~ColorPostProcessOverride()
{
}
	
// Drawing uses all internal code so will support all draw APIs
//
MHWRender::DrawAPI ColorPostProcessOverride::supportedDrawAPIs() const
{
	return MHWRender::kAllDevices;
}


// This method is just here as an example.  Simply calls the base class method.
//
MStatus ColorPostProcessOverride::setup( const MString & destination )
{
    return MRenderOverride::setup(destination);
}

// This method is just here as an example.  Simply calls the base class method.
//
MStatus ColorPostProcessOverride::cleanup()
{
	return MRenderOverride::cleanup();
}

//------------------------------------------------------------------------
// Custom quad operation (post color operation)
//
// Instances of this class are used to provide different
// shaders to be applied to a full screen quad.
//
PostQuadRender::PostQuadRender(const MString &name, const MString &id, const MString &technique, MHWRender::MRenderTarget* input2)
	: MQuadRender( name )
	, mShaderInstance(NULL)
    , mEffectId(id)
    , mEffectIdTechnique(technique)
	, prePass(input2)
{
    // Declare the required input targets
    mInputTargetNames.clear();
    // these are the targets we draw into for the post pass
    // newly created offscreen targets.
    mInputTargetNames.append(kAuxiliaryTargetName);
    mInputTargetNames.append(kAuxiliaryDepthTargetName);
    // These are the targets the scene is rendered into.  
    // These are passed into the post pass shader for read.
    mInputTargetNames.append(kColorTargetName);
    mInputTargetNames.append(kDepthTargetName);

    // Declare the produced output targets
    // note these are in the reverse order of the inputs.
    // This is because we want to read from the previously written target
    // and write to a new auxiliary target.  The new target becomes the color target.
    mOutputTargetNames.clear();
    mOutputTargetNames.append(kColorTargetName);
    mOutputTargetNames.append(kDepthTargetName);
    mOutputTargetNames.append(kAuxiliaryTargetName);
    mOutputTargetNames.append(kAuxiliaryDepthTargetName);

}

PostQuadRender::~PostQuadRender()
{
	if (mShaderInstance)
	{
		MHWRender::MRenderer* renderer = MHWRender::MRenderer::theRenderer();
		if (renderer)
		{
			const MHWRender::MShaderManager* shaderMgr = renderer->getShaderManager();
			if (shaderMgr)
			{
				shaderMgr->releaseShader(mShaderInstance);
			}
		}
		mShaderInstance = NULL;
	}
}

/*
	Return the appropriate shader instance based on the what
	we want the quad operation to perform
*/
const MHWRender::MShaderInstance *
PostQuadRender::shader()
{
	// Create a new shader instance for this quad render instance
	//
	if (mShaderInstance == NULL)
	{
		MHWRender::MRenderer* renderer = MHWRender::MRenderer::theRenderer();
		if (renderer)
		{
			const MHWRender::MShaderManager* shaderMgr = renderer->getShaderManager();
			if (shaderMgr)
			{
				mShaderInstance = shaderMgr->getEffectsFileShader( mEffectId.asChar(), mEffectIdTechnique.asChar() );
			}
		}
	}

	if (mShaderInstance)
	{
		// Set the input texture parameter 'gInputTex' to use
		// a given color target
		MHWRender::MRenderTargetAssignment assignment;
		// Note that we have 2 targets with one being used as the output and
		// here the other as the input.
		assignment.target = getInputTarget(kColorTargetName);
		
		MStatus status = mShaderInstance->setParameter("gInputTex", assignment);
		if (status != MStatus::kSuccess)
		{
			printf("Could not set input render target / texture parameter on post 2d shader\n");
			return NULL;
		}
		const MString edgeDetect("FilterEdgeDetect");
		if (mEffectId == edgeDetect)
		{
			status = mShaderInstance->setParameter("gThickness", 0.5f );
			if (status != MStatus::kSuccess)
			{
				printf("Could not set thickness parameter on edge detect shader\n");
			}
			status = mShaderInstance->setParameter("gThreshold", 0.1f );
			if (status != MStatus::kSuccess)
			{
				printf("Could not set threshold parameter on edge detect shader\n");
			}

			if (prePass) {

				MHWRender::MRenderTargetAssignment assignment2;
				assignment2.target = prePass;
				mShaderInstance->setParameter("gSourceTex", assignment2);
			}
		}
	}

	return mShaderInstance;
}

bool PostQuadRender::getInputTargetDescription(const MString& name, MHWRender::MRenderTargetDescription& description) 
{ 
    // We do not provide a target description for the auxiliary target because 
    // we expect that target to be set as an output.
    // We copy the descriptions from the auxiliary targets so the msaa properties and size match.
    if (name == kColorTargetName)
    {
        MHWRender::MRenderTarget* outTarget = getInputTarget(kAuxiliaryTargetName);
        if (outTarget)
            outTarget->targetDescription(description);
        description.setName("_post_target_1");
        return true;
    }
    else if (name == kDepthTargetName)   
    {
        MHWRender::MRenderTarget* outTarget = getInputTarget(kAuxiliaryDepthTargetName);
        if (outTarget)
            outTarget->targetDescription(description);
        description.setName("_post_target_depth");
        return true;
    }

    return false;
}

int PostQuadRender::writableTargets(unsigned int& count)
{
    count = 2;
    return 0;
}

MHWRender::MClearOperation &
PostQuadRender::clearOperation()
{
	mClearOperation.setClearGradient( false );
	mClearOperation.setMask( (unsigned int) MHWRender::MClearOperation::kClearNone );
	return mClearOperation;
}


// Scene render
sceneRenderMRT ::sceneRenderMRT (const MString& name)
: MSceneRender(name)
{
	float val[4] = { 0.0f, 0.0f, 1.0f, 1.0f };
	mClearOperation.setClearColor(val);
	mTargets = NULL;
	mShaderInstance = NULL;
	mViewRectangle[0] = 0.1f;
	mViewRectangle[1] = 0.1f;
	mViewRectangle[2] = 0.8f;
	mViewRectangle[3] = 0.8f;
	mUseViewportRect = false;
}

sceneRenderMRT ::~sceneRenderMRT ()
{
	mTargets = NULL;
	mShaderInstance = NULL;
}

/* virtual */
MHWRender::MRenderTarget* const*
sceneRenderMRT::targetOverrideList(unsigned int &listSize)
{
	if (mTargets)
	{
		listSize = 1;
		return &mTargets;
	}
	return NULL;
}

/* virtual */
MHWRender::MClearOperation &
sceneRenderMRT::clearOperation()
{
	mClearOperation.setMask( (unsigned int)
		( MHWRender::MClearOperation::kClearDepth | MHWRender::MClearOperation::kClearStencil ) );
	return mClearOperation;
}


/* virtual */
const MHWRender::MShaderInstance* sceneRenderMRT::shaderOverride()
{
	return mShaderInstance;
}

/* virtual */
// We only care about the opaque objects
MHWRender::MSceneRender::MSceneFilterOption sceneRenderMRT::renderFilterOverride()
{
	return MHWRender::MSceneRender::kRenderOpaqueShadedItems;
}

void
sceneRenderMRT::setRenderTargets(MHWRender::MRenderTarget *targets)
{
	mTargets = targets;
}

const MFloatPoint * 
sceneRenderMRT::viewportRectangleOverride()
{
	if (mUseViewportRect)
		return &mViewRectangle;
	return NULL;
}

