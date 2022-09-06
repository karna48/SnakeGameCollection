CXX=g++

CXXFLAGS=-std=c++17 -Wall -Wextra `pkg-config --cflags sdl2 SDL2_image SDL2_mixer SDL2_ttf`
LIBS=`pkg-config --libs sdl2 SDL2_image SDL2_mixer SDL2_ttf` -lGL

.PHONY: all
all: snake

snake.o: snake.cpp audiosystem.h
	$(CXX) snake.cpp -o snake.o -c $(CXXFLAGS)

snake: snake.o
	$(CXX) snake.o -o snake $(LIBS)

rebuild: clean all

clean:
	rm *.o snake