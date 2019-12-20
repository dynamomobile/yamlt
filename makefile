.SILENT:

all: test

TARGET=yamlt

$(TARGET): bin/main.dart
	dart2native $< -o $(TARGET)

test: $(TARGET)
	./$(TARGET) template.t data.yaml
	./$(TARGET) db_template.t db_data.yaml

examples: example_1 example_2 example_3

example_1: $(TARGET)
	echo "### Running $@ ###"
	$(TARGET) examples/$@.t examples/$@.yaml

example_2: $(TARGET)
	echo "### Running $@ ###"
	$(TARGET) examples/$@.t examples/$@.yaml

example_3: $(TARGET)
	echo "### Running $@ ###"
	$(TARGET) examples/$@.t examples/$@.yaml

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

clean:
	rm $(TARGET)
