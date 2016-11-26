//
//  GLRenderer.m
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//

#import "GLRenderer.h"
#import "Model.h"

static inline const char * GetGLErrorString(GLenum error)
{
    const char *str;
    switch( error )
    {
        case GL_NO_ERROR:
            str = "GL_NO_ERROR";
            break;
        case GL_INVALID_ENUM:
            str = "GL_INVALID_ENUM";
            break;
        case GL_INVALID_VALUE:
            str = "GL_INVALID_VALUE";
            break;
        case GL_INVALID_OPERATION:
            str = "GL_INVALID_OPERATION";
            break;
#if defined __gl_h_ || defined __gl3_h_
        case GL_OUT_OF_MEMORY:
            str = "GL_OUT_OF_MEMORY";
            break;
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            str = "GL_INVALID_FRAMEBUFFER_OPERATION";
            break;
#endif
#if defined __gl_h_
        case GL_STACK_OVERFLOW:
            str = "GL_STACK_OVERFLOW";
            break;
        case GL_STACK_UNDERFLOW:
            str = "GL_STACK_UNDERFLOW";
            break;
        case GL_TABLE_TOO_LARGE:
            str = "GL_TABLE_TOO_LARGE";
            break;
#endif
        default:
            str = "(ERROR: Unknown Error Enum)";
            break;
    }
    return str;
}

#define GetGLError()									\
{														\
GLenum err = glGetError();							\
while (err != GL_NO_ERROR) {						\
NSLog(@"GLError %s set in File:%s Line:%d\n",   \
GetGLErrorString(err), __FILE__, __LINE__);	    \
err = glGetError();								\
}													\
}


// Indicies to which we will set vertex array attibutes
// See buildVAO and buildProgram
enum {
    POS_ATTRIB_IDX,
    NORMAL_ATTRIB_IDX,
    TEXCOORD_ATTRIB_IDX,
    COLOR_ATTRIB_IDX
};

@interface GLRenderer ()
{
    GLuint _defaultFBOName;
    GLuint _modelVAOName;
    GLuint _program;
    GLint _modelViewUniformIdx;
    GLint _projectionUniformIdx;
    //Light
    GLint _ambientUniformIdx;
    GLint _lightDirectionIdx;
    GLint _lightColorIdx;
    GLint _eyeDirectionIdx;
    GLint _shininessIdx;
    GLint _strengthIdx;
    GLint _useMaterialIdx;
    
    GLint _materialAmbientIdx;
    GLint _materialDiffuseIdx;
    GLint _materialSpecularIdx;
    GLint _materialShininessIdx;
    
    GLint _constantColorIdx;
    GLint _normalMatrixIdx;
    
    GLuint _viewWidth;
    GLuint _viewHeight;

}
@end

@implementation GLRenderer

- (instancetype) initWithModel:(Model *)model
{
    if(self = [super init])
    {
        _zoom = 1;
        _showMaterial = YES;
        _renderType = RENDER_AS_TRANGLES;
        _rotationx = _rotationy = _rotationz = 0;
        
        _defaultFBOName = 0;
        _viewWidth = 100;
        _viewHeight = 100;
        //If we're using VBOs we can destroy all this memory since buffers are
        // loaded into GL and we've saved anything else we need
        self.model = model;
        
        // Build Vertex Buffer Objects (VBOs) and Vertex Array Object (VAOs) with our model data
        _modelVAOName = [self buildVAO];
        
        ////////////////////////////////////
        // Load texture for our character //
        ////////////////////////////////////
        
        
        ////////////////////////////////////////////////////
        // Load and Setup shaders for character rendering //
        ////////////////////////////////////////////////////
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"character" ofType:@"vsh"];
        GLuint vertexShader = [self loadShader:filePath ofType:GL_VERTEX_SHADER];
        
        filePath = [[NSBundle mainBundle] pathForResource:@"character" ofType:@"fsh"];
        GLuint fragShader = [self loadShader:filePath ofType:GL_FRAGMENT_SHADER];
        
        GLuint program = [self createProgramWithShader:vertexShader fshader:fragShader];
        // Delete the fragment shader since it is now attached
        // to the program, which will retain a reference to it
        glDeleteShader(vertexShader);
        glDeleteShader(fragShader);
        if(program)
        {
            glUseProgram(program);
        }
        _program = program;
        ///////////////////////////////////////
        // Setup common program input points //
        ///////////////////////////////////////
        
        
        //GLint samplerLoc = glGetUniformLocation(prgName, "diffuseTexture");
        
        // Indicate that the diffuse texture will be bound to texture unit 0
        //GLint unit = 0;
        //glUniform1i(samplerLoc, unit);
        
        ////////////////////////////////////////////////
        // Set up OpenGL state that will never change //
        ////////////////////////////////////////////////
        // Depth test will always be enabled
        glEnable(GL_DEPTH_TEST);
        // We will always cull back faces for better performance
        glEnable(GL_CULL_FACE);
        glEnable(GL_BLEND);
        // Always use this clear color
        glClearColor(_backgroundR, _backgroundG, _backgroundB, 1.0f);
        // Draw our scene once without presenting the rendered image.
        //   This is done in order to pre-warm OpenGL
        // We don't need to present the buffer since we don't actually want the
        //   user to see this, we're only drawing as a pre-warm stage
        [self render];
    }
    
    return self;
}


- (GLuint) buildVAO
{
    // Create a vertex array object (VAO) to cache model parameters
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // Create a vertex buffer object (VBO) to store positions
    GLuint posBufferName;
    glGenBuffers(1, &posBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    // Allocate and load position data into the VBO
    glBufferData(GL_ARRAY_BUFFER, sizeof(SceneVertex) * _model.numOfTriangles * 3, _model.pVertices, GL_STATIC_DRAW);
    
    // Enable the position attribute for this VAO
    glEnableVertexAttribArray(POS_ATTRIB_IDX);
    glVertexAttribPointer(POS_ATTRIB_IDX, 3, GL_FLOAT, GL_FALSE, (GLsizei)sizeof(SceneVertex), 0);

    glEnableVertexAttribArray(NORMAL_ATTRIB_IDX);
    glVertexAttribPointer(NORMAL_ATTRIB_IDX, 3, GL_FLOAT, GL_FALSE, (GLsizei)sizeof(SceneVertex), (GLvoid *)offsetof(SceneVertex, normal));
 
    
    //glEnableVertexAttribArray(COLOR_ATTRIB_IDX);
    //glVertexAttribPointer(COLOR_ATTRIB_IDX, 4, GL_FLOAT, GL_FALSE, (GLsizei)sizeof(SceneVertex), (GLvoid *)offsetof(SceneVertex, color));

    // Texels
    if(_model.hasVertexCoord) {
        //NSLog(@"Enable texture coord");
        //glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        //glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, (GLsizei)sizeof(SceneVertex), (GLvoid *)offsetof(SceneVertex, textcoord));
    }
    
    return vaoName;
}

-(GLuint) createProgramWithShader:(GLuint) vertexShader fshader:(GLuint) fragShader
{
    GLuint program = glCreateProgram();

    glAttachShader(program, vertexShader);
    glAttachShader(program, fragShader);


    //////////////////////
    // Link the program //
    //////////////////////
    glLinkProgram(program);
    
    GLint logLength, status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (!status)
    {
        NSLog(@"Failed to link program");
        
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar*)malloc(logLength);
            glGetProgramInfoLog(program, logLength, &logLength, log);
            NSLog(@"Program link log:\n%s\n", log);
            free(log);
        }
        return 0;
    }
    
    
    // Indicate the attribute indicies on which vertex arrays will be
    //  set with glVertexAttribPointer
    //  See buildVAO to see where vertex arrays are actually set
    glBindAttribLocation(program, POS_ATTRIB_IDX, "inPosition");
    //glBindAttribLocation(program, COLOR_ATTRIB_IDX, "inColor");
    glBindAttribLocation(program, NORMAL_ATTRIB_IDX, "inNormal");
    //glBindAttribLocation(program, TEXCOORD_ATTRIB_IDX, "inTexcoord");

    _modelViewUniformIdx = glGetUniformLocation(program, "modelViewMatrix");
    _projectionUniformIdx = glGetUniformLocation(program, "projectionMatrix");
    _constantColorIdx = glGetUniformLocation(program, "constantColor");
    _ambientUniformIdx = glGetUniformLocation(program, "ambientColor");
    _lightDirectionIdx = glGetUniformLocation(program, "lightDirection");
    _lightColorIdx = glGetUniformLocation(program, "lightColor");
    _eyeDirectionIdx = glGetUniformLocation(program, "eyeDirection");
    _shininessIdx = glGetUniformLocation(program, "shininess");
    _strengthIdx = glGetUniformLocation(program, "strength");
    _useMaterialIdx = glGetUniformLocation(program, "useMaterial");
    
    _materialAmbientIdx = glGetUniformLocation(program, "material.ambient");
    _materialDiffuseIdx = glGetUniformLocation(program, "material.diffuse");
    _materialSpecularIdx = glGetUniformLocation(program, "material.specular");
    _materialShininessIdx = glGetUniformLocation(program, "material.shininess");
    
    _normalMatrixIdx = glGetUniformLocation(program, "normalMatrix");
    
    return program;
}
-(GLuint) loadShader:(NSString *) filePath ofType:(GLenum) type {
    GLuint shader;
    GLint compiled;
    
    NSLog(@"GL_SHADING_LANGUAGE_VERSION %s", glGetString(GL_SHADING_LANGUAGE_VERSION));
    shader = glCreateShader(type);
    if(!shader) {
        GetGLError();
        return 0;
    }
    
    NSError *error = nil;
    NSString *sourceString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (sourceString == nil) {
        return 0;
    }
    
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if(!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 0) {
            char* infoLog = malloc(sizeof(char) * infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            NSLog(@"compile error:%s", infoLog);
            free(infoLog);
        }
        
        glDeleteShader(shader);
    }
    return shader;
}

- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
    glViewport(0, 0, width, height);
    
    _viewWidth = width;
    _viewHeight = height;
}

typedef struct materialProp {
    //    vec3 emission;
    GLKVector3 ambient;
    GLKVector3 diffuse;
    GLKVector3 specular;
    float shininess;
} materialProp;

- (void) render {
    glClearColor(_backgroundR, _backgroundG, _backgroundB, 1.0f);
    if(!_model) {
        return;
    }
    // Bind our default FBO to render to the screen
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFBOName);
    
    glViewport(0, 0, _viewWidth, _viewHeight);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Use the program for rendering our character
    glUseProgram(_program);

    // Bind our vertex array object
    glBindVertexArray(_modelVAOName);
    // Cull back faces now that we no longer render
    // with an inverted matrix
    glCullFace(GL_BACK);
    
    //float scale = 1.8 / _model.diameter;
    float near = 0.1;
    float far = 1000.0;

    GLfloat fieldView = GLKMathDegreesToRadians(90.0f);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fieldView, (float)_viewWidth / (float)_viewHeight, near, far);
    GLKMatrix4 modelviewMatrix = GLKMatrix4Identity;//GLKMatrix4MakeLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0);
    
#if DEBUG

#endif
    modelviewMatrix = GLKMatrix4Translate(modelviewMatrix, 0.0f, 0.0f, -MAX(ABS(_model.maxZ), ABS(_model.minZ)) - near -5);
    
   modelviewMatrix = GLKMatrix4RotateX(modelviewMatrix, GLKMathDegreesToRadians(30));
    modelviewMatrix = GLKMatrix4RotateY(modelviewMatrix, GLKMathDegreesToRadians(45));
    //modelviewMatrix = GLKMatrix4RotateZ(modelviewMatrix, GLKMathDegreesToRadians(_rotationz));
    
    modelviewMatrix = GLKMatrix4Scale(modelviewMatrix, _zoom, _zoom, _zoom);
    
    //modelviewMatrix = GLKMatrix4Scale(modelviewMatrix, scale, scale, scale);
    modelviewMatrix = GLKMatrix4Translate(modelviewMatrix, -_model.center.x, -_model.center.y, -_model.center.z);
    //modelviewMatrix = GLKMatrix4Multiply(modelviewMatrix, GLKMatrix4MakeLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0));
    // Have our shader use the modelview projection matrix
    // that we calculated above
    glUniformMatrix4fv(_projectionUniformIdx, 1, GL_FALSE, projectionMatrix.m);
    glUniformMatrix4fv(_modelViewUniformIdx, 1, GL_FALSE, modelviewMatrix.m);
    bool isInvertible;
    GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelviewMatrix), &isInvertible);
    glUniformMatrix3fv(_normalMatrixIdx, 1, GL_FALSE, normalMatrix.m);

    glUniform4f(_constantColorIdx, 0.7, 0.7, 0.7, 1);
    
    glUniform3f(_ambientUniformIdx, _ambientR, _ambientG, _ambientB);
    
    float lightDirection[3]={0.0, 0.0, 1.0};
    glUniform3fv(_lightDirectionIdx, 1, lightDirection);
    glUniform3f(_lightColorIdx, _lightR, _lightG, _lightB);
    
    float eyeDirection[3]={0.0, 0.0, 1.0};
    glUniform3fv(_eyeDirectionIdx, 1, eyeDirection);
    
    glUniform1f(_shininessIdx, 60);
    glUniform1f(_strengthIdx, 60);
    
    glUniform1i(_useMaterialIdx, _showMaterial);
    
    if(_renderType == RENDER_AS_DOTS) {
        glPointSize(4);
    } else {
        glPointSize(1);
    }
    GLsizei numOfVertexDrawed = 0;
    for (ModelGroup *mg in _model.modelGroup) {
        for (MaterialGroup *materialGroup in mg.materialGroup) {
            if(materialGroup.numOfVertices > 0) {
                NSString *materialName = materialGroup.name;
                Material *material = [_model.materialDict objectForKey:materialName];
                if(!material) {
                    material = [Material defaultMaterial];
                }

                glUniform3fv(_materialAmbientIdx, 1, material.ambient.v);
                glUniform3fv(_materialDiffuseIdx, 1, material.diffuse.v);
                glUniform3fv(_materialSpecularIdx, 1, material.spectral.v);
                glUniform1f(_materialShininessIdx, material.shininess);
                
                if(_renderType == RENDER_AS_DOTS) {
                    glDrawArrays(GL_POINTS, numOfVertexDrawed, (GLsizei)materialGroup.numOfVertices);
                } else {
                    glDrawArrays(GL_TRIANGLES, numOfVertexDrawed, (GLsizei)materialGroup.numOfVertices);
                }
                
                numOfVertexDrawed += materialGroup.numOfVertices;
            }
        }
    }
}


-(void)destroyVAO:(GLuint) vaoName
{
    GLuint index;
    GLuint bufName;
    
    // Bind the VAO so we can get data from it
    glBindVertexArray(vaoName);
    
    // For every possible attribute set in the VAO
    for(index = 0; index < 16; index++)
    {
        // Get the VBO set for that attibute
        glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
        
        // If there was a VBO set...
        if(bufName)
        {
            //...delete the VBO
            glDeleteBuffers(1, &bufName);
        }
    }
    
    // Get any element array VBO set in the VAO
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
    
    // If there was a element array VBO set in the VAO
    if(bufName)
    {
        //...delete the VBO
        glDeleteBuffers(1, &bufName);
    }
    
    // Finally, delete the VAO
    glDeleteVertexArrays(1, &vaoName);
    
    //GetGLError();
}


- (void) dealloc
{
    // Cleanup all OpenGL objects and
    //glDeleteTextures(1, &_characterTexName);
    [self destroyVAO:_modelVAOName];
    
    glDeleteProgram(_program);
    //mdlDestroyModel(_characterModel);
}

-(NSImage *) image {
    NSImage *image = nil;
    NSBitmapImageRep *representation = nil;
    if([_model ready]) {
        glReadBuffer(GL_BACK);
        NSMutableData *pixelsData = [[NSMutableData alloc] initWithLength:_viewWidth * _viewHeight * 4];
        glReadPixels(0, 0, _viewWidth, _viewHeight, GL_RGBA, GL_UNSIGNED_BYTE, [pixelsData mutableBytes]);
        unsigned char* planes[1];
        planes[0] = [pixelsData mutableBytes];
        representation= [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
                                                pixelsWide:_viewWidth
                                                pixelsHigh:_viewHeight
                                             bitsPerSample:8
                                           samplesPerPixel:4
                                                  hasAlpha:YES
                                                  isPlanar:NO
                                            colorSpaceName:NSDeviceRGBColorSpace
                                               bytesPerRow:_viewWidth * 4
                                              bitsPerPixel:32];
        if(representation) {
            image = [[NSImage alloc] initWithSize:CGSizeMake(_viewWidth, _viewHeight)];
            [image lockFocusFlipped:YES];
            [representation drawInRect:NSMakeRect(0, 0, _viewWidth, _viewHeight)];
            [image unlockFocus];
        }
    }
    return image;
}

-(void) renderAs:(RenderType) renderType {
    _renderType = renderType;
}
@end
