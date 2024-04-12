 New-Item -Path "deps" -ItemType Directory -ErrorAction Ignore

Invoke-WebRequest https://github.com/libsdl-org/SDL/releases/download/release-2.30.2/SDL2-devel-2.30.2-mingw.zip  -OutFile deps\SDL2-devel-2.30.2-mingw.zip
Invoke-WebRequest https://master.dl.sourceforge.net/project/glm.mirror/1.0.1/glm-1.0.1-light.zip?viasf=1 -OutFile deps\glm-1.0.1-light.zip
Invoke-WebRequest https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.8.0/SDL2_mixer-devel-2.8.0-mingw.zip -OutFile deps\SDL2_mixer-devel-2.8.0-mingw.zip
Invoke-WebRequest https://github.com/libsdl-org/SDL_image/releases/download/release-2.8.2/SDL2_image-devel-2.8.2-mingw.zip -OutFile deps\SDL2_image-devel-2.8.2-mingw.zip

Expand-Archive deps\SDL2-devel-2.30.2-mingw.zip -DestinationPath deps -Force
Expand-Archive deps\glm-1.0.1-light.zip -DestinationPath deps -Force
Expand-Archive deps\SDL2_mixer-devel-2.8.0-mingw.zip -DestinationPath deps -Force
Expand-Archive deps\SDL2_image-devel-2.8.2-mingw.zip -DestinationPath deps -Force

