VALAC=valac
PKGS = --pkg gtk4 --pkg gee-0.8

all: snake

snake: snake.vala
	$(VALAC) $(PKGS) snake.vala 


rebuild: clean all

clean:
	rm snake
