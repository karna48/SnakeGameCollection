// opengl-tutorial
// Tutorial 2 : The first triangle
// http://www.opengl-tutorial.org/beginners-tutorials/tutorial-2-the-first-triangle/

#include "loadshader.h"

#include <vector>
#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdio>

GLuint LoadShaders(const char * vertex_file_path, const char * fragment_file_path,  const char * geometry_file_path)
{
    std::cout << "Loading shaders\n  vertex: " << vertex_file_path << "\n  fragment: " << fragment_file_path << std::endl;

	// Create the shaders
	GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
	GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
	GLuint GeometryShaderID = geometry_file_path==nullptr ? 0 : glCreateShader(GL_GEOMETRY_SHADER);

	std::string VertexShaderCode;
	std::ifstream VertexShaderStream(vertex_file_path, std::ios::in);
	if(VertexShaderStream.is_open()){
		std::stringstream sstr;
		sstr << VertexShaderStream.rdbuf();
		VertexShaderCode = sstr.str();
		VertexShaderStream.close();
	} else{
        std::cerr << "ERROR: Impossible to open: " << vertex_file_path << std::endl;
		return 0;
	}

	std::string FragmentShaderCode;
	std::ifstream FragmentShaderStream(fragment_file_path, std::ios::in);
	if(FragmentShaderStream.is_open()){
		std::stringstream sstr;
		sstr << FragmentShaderStream.rdbuf();
		FragmentShaderCode = sstr.str();
		FragmentShaderStream.close();
	}else{
        std::cerr << "ERROR: Impossible to open: " << fragment_file_path << std::endl;
		return 0;
	}
	std::string GeometryShaderCode;
	if(geometry_file_path != nullptr) {
		std::ifstream GeometryShaderStream(geometry_file_path, std::ios::in);
		if(GeometryShaderStream.is_open()){
			std::stringstream sstr;
			sstr << GeometryShaderStream.rdbuf();
			GeometryShaderCode = sstr.str();
			GeometryShaderStream.close();
		}else{
			std::cerr << "ERROR: Impossible to open: " << fragment_file_path << std::endl;
			return 0;
		}
	}

	GLint Result = GL_FALSE;
	int InfoLogLength;

	// Compile Vertex Shader
    std::cout << "Compiling shader: " << vertex_file_path << std::endl;
	char const * VertexSourcePointer = VertexShaderCode.c_str();
	glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
	glCompileShader(VertexShaderID);

	// Check Vertex Shader
	glGetShaderiv(VertexShaderID, GL_COMPILE_STATUS, &Result);
	glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	if ( InfoLogLength > 0 ){
		std::vector<char> VertexShaderErrorMessage(InfoLogLength+1);
		glGetShaderInfoLog(VertexShaderID, InfoLogLength, NULL, &VertexShaderErrorMessage[0]);
        std::cerr << "ERROR: compile vertex: " << &VertexShaderErrorMessage[0] << std::endl;
        return 0;
	}

	// Compile Fragment Shader
    std::cout << "Compiling shader: " << fragment_file_path << std::endl;
	char const * FragmentSourcePointer = FragmentShaderCode.c_str();
	glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
	glCompileShader(FragmentShaderID);

	// Check Fragment Shader
	glGetShaderiv(FragmentShaderID, GL_COMPILE_STATUS, &Result);
	glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	if ( InfoLogLength > 0 ){
		std::vector<char> FragmentShaderErrorMessage(InfoLogLength+1);
		glGetShaderInfoLog(FragmentShaderID, InfoLogLength, NULL, &FragmentShaderErrorMessage[0]);
        std::cerr << "ERROR: compile fragment: " << &FragmentShaderErrorMessage[0] << std::endl;
        return 0;
	}
	
	if(geometry_file_path != nullptr) {
		// Compile Geometry Shader
		std::cout << "Compiling shader: " << geometry_file_path << std::endl;
		char const * GeometrySourcePointer = GeometryShaderCode.c_str();
		glShaderSource(GeometryShaderID, 1, &GeometrySourcePointer , NULL);
		glCompileShader(GeometryShaderID);

		// Check Geometry Shader
		glGetShaderiv(GeometryShaderID, GL_COMPILE_STATUS, &Result);
		glGetShaderiv(GeometryShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
		if ( InfoLogLength > 0 ){
			std::vector<char> GeometryShaderErrorMessage(InfoLogLength+1);
			glGetShaderInfoLog(GeometryShaderID, InfoLogLength, NULL, &GeometryShaderErrorMessage[0]);
			std::cerr << "ERROR: compile geometry: " << &GeometryShaderErrorMessage[0] << std::endl;
			return 0;
		}

	}

	// Link the program
	printf("Linking program\n");
	GLuint ProgramID = glCreateProgram();
	glAttachShader(ProgramID, VertexShaderID);
	glAttachShader(ProgramID, FragmentShaderID);
	if(geometry_file_path != nullptr) {
		glAttachShader(ProgramID, GeometryShaderID);
	}
	glLinkProgram(ProgramID);

	// Check the program
	glGetProgramiv(ProgramID, GL_LINK_STATUS, &Result);
	glGetProgramiv(ProgramID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	if ( InfoLogLength > 0 ){
		std::vector<char> ProgramErrorMessage(InfoLogLength+1);
		glGetProgramInfoLog(ProgramID, InfoLogLength, NULL, &ProgramErrorMessage[0]);
        std::cerr << "ERROR: linking: " << &ProgramErrorMessage[0] << std::endl;
        return 0;
	}
	
	glDetachShader(ProgramID, VertexShaderID);
	glDetachShader(ProgramID, FragmentShaderID);
	if(geometry_file_path != nullptr) {
		glDetachShader(ProgramID, GeometryShaderID);
	}
	
	glDeleteShader(VertexShaderID);
	glDeleteShader(FragmentShaderID);
	if(geometry_file_path != nullptr) {
		glDeleteShader(GeometryShaderID);
	}

	return ProgramID;
}
