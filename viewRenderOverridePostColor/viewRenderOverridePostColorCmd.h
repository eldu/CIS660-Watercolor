#include <maya/MPxCommand.h>

/*
	Command arguments and command name
*/

#define kEdgeDetectFlag		"-ed"
#define kEdgeDetectFlagLong	"-edgeDetect"

#define commandName			"postColor"

/*
	Command class declaration
*/
class viewRenderOverridePostColorCmd : public MPxCommand
{
public:
	viewRenderOverridePostColorCmd();
	virtual			~viewRenderOverridePostColorCmd(); 

	MStatus			doIt( const MArgList& args );
	static MSyntax	newSyntax();
	static void*	creator();
private:
	bool			fishEye;
	bool			swirl;
	bool			edgeDetect;
};