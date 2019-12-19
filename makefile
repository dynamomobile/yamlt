all: test

TARGET=yamlt

$(TARGET): bin/main.dart
	dart2native $< -o $(TARGET)

test: $(TARGET)
	./$(TARGET) template.t data.yaml

clean:
	rm $(TARGET)
