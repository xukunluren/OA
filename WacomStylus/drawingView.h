/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 DrawingView.h

 Abstract: header file for the main drawing view of the application.


 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 --------------------––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-––-----*/

#import <UIKit/UIKit.h>
#import "GLKit/GLKView.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <WacomDevice/WacomDeviceFramework.h>

@interface drawingView : UIView <WacomStylusEventCallback>
{
@private
	// The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	// OpenGL names for the renderbuffer and framebuffers used to render to this view
	GLuint viewRenderbuffer, viewFramebuffer;
	
	// OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
	GLuint depthRenderbuffer;
	
	GLuint	brushTexture;
	Boolean needsErase;
}
@property BOOL isDraw;

/// sets up the brush size based on pressure data.
-(void)setupBrush:(CGFloat) size;

/// a callback method for the Wacom SDK that provides pressure data among other things.
-(void)stylusEvent:(WacomStylusEvent *)stylusEvent;

/// clears the screen.
-(void)erase;

/// draws a line between two points.
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;

- (UIImage *) glToUIImage;
- (UIImage *)cropTransparencyFromImage:(UIImage *)img;

@end
