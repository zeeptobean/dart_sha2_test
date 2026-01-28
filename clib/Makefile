all: main

main: sha2.o
	gcc -shared -o libmysha2.so sha2.o

sha2.o: sha2.c
	gcc -c -fPIC sha2.c -Wall -pedantic -O2 -march=native -o sha2.o

clean:
	rm -f *.so *.o