CC = gcc
CFLAGS = -O3 -march=native -flto -ffast-math -Wall -Wextra
LDFLAGS = -O3 -flto

TARGET = fib_bench

all: $(TARGET)

$(TARGET): main.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

.PHONY: clean run

clean:
	rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET) 