all: test

TARGET=yamlt

$(TARGET): bin/main.dart
	dart2native $< -o $(TARGET)

test: $(TARGET)
	./$(TARGET) template.t data.yaml
	./$(TARGET) db_template.t db_data.yaml

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

clean:
	rm $(TARGET)
