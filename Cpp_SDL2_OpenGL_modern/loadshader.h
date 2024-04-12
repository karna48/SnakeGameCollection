// opengl-tutorial
// Tutorial 2 : The first triangle
// http://www.opengl-tutorial.org/beginners-tutorials/tutorial-2-the-first-triangle/

#ifndef LoadShader_H__
#define LoadShader_H__


#if defined(__WIN32__) || defined(__WIN64__)
#   include <glad/glad.h>
#else
#   ifndef GL_GLEXT_PROTOTYPES
#   define GL_GLEXT_PROTOTYPES
#   endif
#endif // defined

#include <SDL.h>
#include <SDL_opengl.h>


GLuint LoadShaders(const char * vertex_file_path,const char * fragment_file_path);

#endif
