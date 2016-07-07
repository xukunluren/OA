/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 DrawingView.m

 Abstract: implementation file for the main drawing view of the application.


 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 --------------------––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-––-----*/

#import "drawingView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>


#pragma mark -
#pragma mark drawingView (private) declarations
#pragma mark -

@interface drawingView (private)

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (double)calcBrushSize:(double)pressure;
@end


#pragma mark -
#pragma mark drawingView
#pragma mark -
@implementation drawingView
{
	GLfixed mBrushWidth;
	CGFloat mPressure;          // recent pressure vaue from Wacom framwork.
	CGFloat mCurrentPressure;   // current pressure to draw a line.
	CGFloat mPreviousPressure;  // previous pressure value to draw a line.
	NSInteger mBrushSize;
    BOOL erasing;
    
//    CGPoint currentPoint;
//    CGPoint lastContactPoint1;
//    CGPoint lastContactPoint2;
}


////////////////////////////////////////////////////////////////////////////////

/// Erases the screen
- (void) erase
{
	[EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
//	glClearColor(1.0, 1.0, 1.0, 0.0);
    glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
    self.isDraw = NO;
}


////////////////////////////////////////////////////////////////////////////////

/// sets up the subviews and allocates the framebuffer
-(void)layoutSubviews
{
	[super layoutSubviews];
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
    
    
    [self setupBrush:1.0f];
    // Set the view's scale factor
//    self.contentScaleFactor = 1.0;
//    glClearColor(1.0, 1.0, 1.0, 0.0);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    // Setup OpenGL states
    glMatrixMode(GL_PROJECTION);
    
    CGRect frame = self.bounds;
    CGFloat scale = self.contentScaleFactor;
    
    // Setup the view port in Pixels
    glLoadIdentity();
    glOrthof(0, frame.size.width * scale, 0, frame.size.height * scale, -1, 1);
    glViewport(0, 0, frame.size.width * scale, frame.size.height * scale);
    glMatrixMode(GL_MODELVIEW);
    
    glDisable(GL_DITHER);
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glEnable(GL_BLEND);
    // Set a blending function appropriate for premultiplied alpha pixel data
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnable(GL_POINT_SPRITE_OES);
    glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
    
    [self setBrushColorWithSegment:0];
    // Make sure to start with a cleared buffer
    needsErase = YES;
    
	// Clear the framebuffer the first time it is allocated
	if (needsErase) {
		[self erase];
		needsErase = NO;
	}
}


////////////////////////////////////////////////////////////////////////////////

/// does the actual work of setting up the frame buffer.
- (BOOL)createFramebuffer
{
    
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}

	[self erase];
	return YES;
}


////////////////////////////////////////////////////////////////////////////////

/// Clean up any buffers we have allocated.
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}


////////////////////////////////////////////////////////////////////////////////

/// calls super initwithframe and initializes some variables.
- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	mPressure = 0.0;
	mCurrentPressure = 0.0;
	mPreviousPressure = 0.0;
    
    
    // init three CGPonit
//    currentPoint = CGPointMake(0.0, 0.0);
//    lastContactPoint1 = CGPointMake(0.0, 0.0);
//    lastContactPoint2 = CGPointMake(0.0, 0.0);
	if (self) {
		// Initialization code
        [[WacomManager getManager] registerForNotifications:self];
        [self setMultipleTouchEnabled:YES];
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = NO;
        erasing = NO;
        // In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        self.contentScaleFactor = 1.0;
        self.isDraw = NO;
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context])
        {
            return nil;
        }
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////

/// gets the layer class.
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

#define MIN_BRUSH_SIZE (4.0)
#define THRESHOLD 1.0


////////////////////////////////////////////////////////////////////////////////

/// changes the color segment which changes the colors shown when drawing.
- (void)setBrushColorWithSegment:(NSInteger)segment
{
	CGFloat	components[4];
	
	// Define the brush color as black
    if (segment == 0) {
        components[0] = 0;
        components[1] = 0;
        components[2] = 0;
        components[3] = 1;
    }
	
	// Defer to the OpenGL view to set the brush color
	
	// Set the brush color using premultiplied alpha values
	glColor4f(components[0],
				 components[1],
				 components[2],
				 components[3]);
}


////////////////////////////////////////////////////////////////////////////////

/// the brush size is function of pressure, this calculates the size based on pressure and levels of pressure
-(double) calcBrushSize:(double)pressure
{
	long maximumPressure = [[[WacomManager getManager] getSelectedDevice] getMaximumPressure];

	double brushSize = MIN_BRUSH_SIZE;
	if ( pressure > 0.0)
	{
		double scale;
		if(pressure < THRESHOLD)
			scale = maximumPressure;
		else
			scale = (double)(((maximumPressure-THRESHOLD)+1.0)) / (pressure-THRESHOLD);
		brushSize = mBrushSize / (scale*3);
		if (brushSize < MIN_BRUSH_SIZE)
		{
			brushSize = MIN_BRUSH_SIZE;
		}
	}
	return brushSize;
}

- (CGPoint)drawBezierWithOrigin:(CGPoint) origin andControl:(CGPoint) control andDestination:(CGPoint) destination andSegment:(int) segments
{
    CGPoint vertices[segments/2];
    CGPoint midPoint;
    glDisable(GL_TEXTURE_2D);
    float x = 0.0, y = 0.0;
    
    float t = 0.0;
    for(int i = 0; i < (segments/2); i++)
    {
        x = pow(1 - t, 2) * origin.x + 2.0 * (1 - t) * t * control.x + t * t * destination.x;
        y = pow(1 - t, 2) * origin.y + 2.0 * (1 - t) * t * control.y + t * t * destination.y;
        vertices[i] = CGPointMake(x, y);
        t += 1.0 / (segments);
        
    }
    midPoint = CGPointMake(x, self.frame.size.height - y);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_POINTS, 0, segments/2);
    return midPoint;
}

- (void) renderLineFromOrigin:(CGPoint)start control:(CGPoint)control destination:(CGPoint)end
{
    static GLfloat*		vertexBuffer = NULL;
    static NSUInteger	vertexMax = 64;
    NSUInteger			vertexCount = 0, count;
    GLint i = 0;
    static float kBrushPixelStep = 3;// 3
    
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    // Convert locations from Points to Pixels
    CGFloat scale = self.contentScaleFactor;
    start.x *= scale;
    start.y *= scale;
    control.x *= scale;
    control.y *= scale;
    end.x *= scale;
    end.y *= scale;
    
    // Allocate vertex array buffer
    if(vertexBuffer == NULL)
        vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
    
    // Add points to the buffer so there are drawing points every X pixels
    count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) *kBrushPixelStep), 1);

    glDisable(GL_TEXTURE_2D);
//    CGPoint vertices[count/2];
    float x = 0.0, y = 0.0;
    float t = 0.0;
    for(int i = 0; i < count; i++)
    {
        if(vertexCount == vertexMax) {
            vertexMax = 2 * vertexMax;
            vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
        }
        x = pow(1 - t, 2) * start.x + 2.0 * (1 - t) * t * control.x + t * t * end.x;
        y = pow(1 - t, 2) * start.y + 2.0 * (1 - t) * t * control.y + t * t * end.y;
//        vertices[i] = CGPointMake(x, y);
        vertexBuffer[2 * vertexCount + 0] = x;
        vertexBuffer[2 * vertexCount + 1] = y;
        t += 1.0 / (count);
        vertexCount += 1;
        
    }
    
    // Calc blush size
    double fromSize, toSize;
    if ([[[WacomManager getManager] connectedServices] count] == 0)
    {
        // Fixed Brush Size
        fromSize = toSize = [self calcBrushSize: 0];
    }
    else
    {
        fromSize = [self calcBrushSize: mPreviousPressure];
        toSize = [self calcBrushSize: mCurrentPressure];
    }
    if (erasing) {
        //You need set the mixed-mode
        glBlendFunc(GL_ONE, GL_ZERO);
        //the erase brush color  is transparent.
        glColor4f(0, 0, 0, 0.0);
    }
    glColor4f(arc4random_uniform(255)/255.0, arc4random_uniform(255)/255.0, arc4random_uniform(255)/255.0, 1.0);
    // Render the vertex array
    glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
//    glVertexPointer(2, GL_FLOAT, 0, vertices);
//    MyLog(@"vertices:%@",vertices);
    double size;
    for(i = 0; i < count; ++i) {
        // interporlate brush size by linear function.
        size = ((toSize-fromSize)/count)* i + fromSize;
        if (erasing) {
            size = size * 10;
        }
        glPointSize(size);
        glDrawArrays(GL_POINTS, i, 1);
    }
    
    // Display the buffer
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    if (erasing) {
        // at last restore the  mixed-mode
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }
}


////////////////////////////////////////////////////////////////////////////////

/// Draws a line on screen based on a start and an end position.
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0, count;
	GLint i = 0;
    static float kBrushPixelStep = 3;// 3
   
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	// Convert locations from Points to Pixels
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	// Allocate vertex array buffer
	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) *kBrushPixelStep), 1);

	for(i = 0; i < count; ++i) {
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
	
	// Calc blush size
	double fromSize, toSize;
	if ([[[WacomManager getManager] connectedServices] count] == 0)
	{
		// Fixed Brush Size
		fromSize = toSize = [self calcBrushSize: 0];
	}
	else
	{
		fromSize = [self calcBrushSize: mPreviousPressure];
		toSize = [self calcBrushSize: mCurrentPressure];
	}
    if (erasing) {
        //You need set the mixed-mode
        glBlendFunc(GL_ONE, GL_ZERO);
        //the erase brush color  is transparent.
        glColor4f(0, 0, 0, 0.0);
    }
	
	// Render the vertex array
	glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
	double size;
	for(i = 0; i < count; ++i) {
		// interporlate brush size by linear function.
		size = ((toSize-fromSize)/count)* i + fromSize;
        if (erasing) {
            size = size * 10;
        }
		glPointSize(size);
		glDrawArrays(GL_POINTS, i, 1);
	}
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    if (erasing) {
        // at last restore the  mixed-mode
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }
}

////////////////////////////////////////////////////////////////////////////////

/// does the initial configuration to get a brush configured and ready for use.
- (void)setupBrush:(CGFloat) size
{
	CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t			width, height;
	CGFloat 			lSize = 0.0;
//    lSize = size;
	if(lSize == 0)
		lSize = 1.0f;
	// Create a texture from an image
	// First create a UIImage object from the data in a image file, and then extract the Core Graphics image
	brushImage = [UIImage imageNamed:@"Particle32.png"].CGImage;
	
	// Get the width and height of the image
	mBrushSize = width = CGImageGetWidth(brushImage);
	height = CGImageGetHeight(brushImage);
	
	// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
	// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
	
	// Make sure the image exists
	if(brushImage) {
		// Allocate  memory needed for the bitmap context
		brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
		// Use  the bitmatp creation function provided by the Core Graphics framework.
		brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
		// After you create the context, you can draw the  image to the context.
		CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width*lSize, (CGFloat)height*lSize), brushImage);
		// You don't need the context at this point, so you need to release it to avoid memory leaks.
		CGContextRelease(brushContext);
		// Use OpenGL ES to generate a name for the texture.
		glGenTextures(1, &brushTexture);
		// Bind the texture name.
		glBindTexture(GL_TEXTURE_2D, brushTexture);
		// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		// Specify a 2D texture image, providing the a pointer to the image data in memory
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
		// Release  the image data; it's no longer needed
		free(brushData);
	}
	glPointSize(width / 2.0f);
	
	
}

////////////////////////////////////////////////////////////////////////////////

/// initializes the class. sets up the openGL viewport for drawing.
- (id)initWithCoder:(NSCoder*)coder
{
	if ((self = [super initWithCoder:coder]))
	{
		[[WacomManager getManager] registerForNotifications:self];

		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

		eaglLayer.opaque = YES;
		// In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context])
		{
			return nil;
		}
	}


	return self;
}



#pragma mark -
#pragma mark touchpoint tracking
#pragma mark -


////////////////////////////////////////////////////////////////////////////////

/// notification method for the receipt of new touches.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isDraw = YES;
	mCurrentPressure = mPreviousPressure = mPressure;
	[[TouchManager GetTouchManager] addTouches:touches knownTouches:[event touchesForView:self] view:self];
	@try
	{
		CGPoint current;

		NSArray *theTrackedTouches = [[TouchManager GetTouchManager] getTrackedTouches];
		for(TrackedTouch *touch in theTrackedTouches)
		{
			if([touches containsObject:touch.associatedTouch])
			{
				current = touch.currentLocation;
				mCurrentPressure = mPressure;
                
                //TODO
//                currentPoint = lastContactPoint2 = lastContactPoint1 = current;
			}
		}
	}
	@catch (NSException *exception)
	{
		NSLog(@"Uh-oh");
	}

}


////////////////////////////////////////////////////////////////////////////////

/// notifcation method for the receipt of updates to existing touches
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	@try
	{
		CGPoint current, previous;

		[[TouchManager GetTouchManager] moveTouches:touches  knownTouches:[event touchesForView:self] view:self];
		NSArray *theTrackedTouches = [[TouchManager GetTouchManager] getTrackedTouches];
		for(TrackedTouch *touch in theTrackedTouches)
		{
			if([touches containsObject:touch.associatedTouch])
			{
				current = touch.currentLocation;
				current.y = self.bounds.size.height - touch.currentLocation.y;
				previous = touch.previousLocation;
				previous.y = self.bounds.size.height - touch.previousLocation.y;
                
				// update to latest pressure value
				if (mPressure != mCurrentPressure)
				{
					mCurrentPressure = mPressure;
				}
                
                //TODO
//                currentPoint = current;
//                lastContactPoint2 = lastContactPoint1;
//                lastContactPoint1 = previous;
//                if (!CGPointEqualToPoint(lastContactPoint2, lastContactPoint1) && !CGPointEqualToPoint(lastContactPoint1, CGPointMake(0.0, 0.0))) {
//                    [self renderLineFromOrigin:lastContactPoint2 control:lastContactPoint1 destination:currentPoint];
//                }
                [self renderLineFromPoint:previous toPoint:current];
				mPreviousPressure = mCurrentPressure;
				mCurrentPressure = mPressure;
			}
		}
	}
	@catch (NSException *exception)
	{
		NSLog(@"Uh-oh");
	}
}


////////////////////////////////////////////////////////////////////////////////

/// notification method when touches are removed from the screen
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	@try
	{
		CGPoint current, previous;
		[[TouchManager GetTouchManager] moveTouches:touches  knownTouches:[event touchesForView:self] view:self];

		NSArray *theTrackedTouches = [[TouchManager GetTouchManager] getTrackedTouches];

		for(TrackedTouch *tTouch in theTrackedTouches)
		{
			if([touches containsObject:tTouch.associatedTouch])
			{
				current = tTouch.currentLocation;
				current.y = self.bounds.size.height - current.y;
				previous = tTouch.previousLocation;
				previous.y = self.bounds.size.height - previous.y;
				// update to latest pressure value
				if (mPressure != mCurrentPressure)
				{
					mCurrentPressure = mPressure;
				}
                
                //TODO
//                currentPoint = current;
//                lastContactPoint2 = lastContactPoint1;
//                lastContactPoint1 = previous;
//                [self renderLineFromOrigin:lastContactPoint2 control:lastContactPoint1 destination:currentPoint];
                [self renderLineFromPoint:previous toPoint:current];
				mPreviousPressure = mCurrentPressure;
				mCurrentPressure = mPressure;

			}
		}

		[[TouchManager GetTouchManager] removeTouches:touches knownTouches:[event touchesForView:self] view:self];
        
        // init three CGPonit
//        currentPoint = lastContactPoint1 = lastContactPoint2 = CGPointMake(0.0, 0.0);
	}
	@catch (NSException *exception) {
		NSLog(@"uh oh. %@ %@",[exception name] ,[exception reason]);
	}
}


////////////////////////////////////////////////////////////////////////////////

/// notification when touches are cancelled
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[TouchManager GetTouchManager] removeTouches:touches knownTouches:[event touchesForView:self] view:self];
}


////////////////////////////////////////////////////////////////////////////////

/// notification when pressure or other event is received from the Wacom SDK
-(void)stylusEvent:(WacomStylusEvent *)stylusEvent
{

	switch ([stylusEvent getType])
	{
		case eStylusEventType_PressureChange:
			
			mPressure = [stylusEvent getPressure];
			break;
		case eStylusEventType_ButtonReleased:
		{
			NSString *title     = @"Button released";
			NSString *message = nil;
			switch ([stylusEvent getButton])
			{
				case 2:
				{
					message = @"Button 2 released";
				}
					break;
				case 1:
				{
					message = @"Button 1 released.";
                    erasing = NO;
                    [self setBrushColorWithSegment:0];
				}
					break;
				default:
					break;
			}
            MyLog(@"%@:%@",title,message);
		}
			break;
			
		case eStylusEventType_ButtonPressed:
		{
			NSString *title     = @"Button Clicked";
			NSString *message = nil;
			switch ([stylusEvent getButton])
			{
				case 2:
				{
					message = @"Button 2 clicked";
				}
					break;
				case 1:
				{
					message = @"Button 1 Clicked.";
                    erasing = YES;
				}
					break;
				default:
					break;
			}
            MyLog(@"%@:%@",title,message);
		}
			break;
		case eStylusEventType_MACAddressAvaiable:
			break;
		case eStylusEventType_BatteryLevelChanged:

		default:
			break;
	}
}

#pragma mark - Convert GL image to UIImage
-(UIImage *) glToUIImage
{
    int imageWidth  = (int) roundf(self.frame.size.width);
    int imageHeight = (int) roundf(self.frame.size.height);
    
    NSInteger myDataLength = imageWidth * imageHeight * 4;
    
    
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, imageWidth, imageHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y < imageHeight; y++)
    {
        for(int x = 0; x < imageWidth * 4; x++)
        {
            buffer2[((imageHeight - 1) - y) * imageWidth * 4 + x] = buffer[y * 4 * imageWidth + x];
        }
    }
    
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * imageWidth;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault|kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}

- (UIImage *)cropTransparencyFromImage:(UIImage *)img
{
    
    CGImageRef inImage = img.CGImage;
    CFDataRef m_DataRef;
    m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetBytePtr(m_DataRef);
    
    int width = img.size.width;
    int height = img.size.height;
    
    CGPoint top,left,right,bottom;
    
    BOOL breakOut = NO;
    for (int x = 0;breakOut==NO && x < width; x++) {
        for (int y = 0; y < height; y++) {
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                left = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
        }
    }
    
    breakOut = NO;
    for (int y = 0;breakOut==NO && y < height; y++) {
        
        for (int x = 0; x < width; x++) {
            
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                top = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (int y = height-1;breakOut==NO && y >= 0; y--) {
        
        for (int x = width-1; x >= 0; x--) {
            
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                bottom = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (int x = width-1;breakOut==NO && x >= 0; x--) {
        
        for (int y = height-1; y >= 0; y--) {
            
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                right = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    
    CGRect cropRect = CGRectMake(left.x, top.y, right.x - left.x, bottom.y - top.y);
    
    UIGraphicsBeginImageContextWithOptions( cropRect.size,NO,0.);
    [img drawAtPoint:CGPointMake(-cropRect.origin.x, -cropRect.origin.y)
           blendMode:kCGBlendModeCopy
               alpha:1.];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CFRelease(m_DataRef);
    return croppedImage;
}

@end
