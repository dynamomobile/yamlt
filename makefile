.SILENT:

all: test examples

EXAMPLES=example_1 example_2 example_3

TARGET=yamlt

$(TARGET): bin/main.dart
	echo "### Compile $@ ###"
	dart2native $< -o $(TARGET)

test: $(TARGET)
	echo "### Run $@ ###"
	./$(TARGET) template.t data.yaml > output.out
	echo "Output: output.out"
	./$(TARGET) db_template.t db_data.yaml > db_output.out
	echo "Output: db_output.out"

examples: $(EXAMPLES)

example_%: $(TARGET)
	echo "### Running $@ ###"
	./$(TARGET) examples/$@.t examples/$@.yaml > $@.out
	echo "Output: $@.out"

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

clean:
	rm -v $(TARGET) *.out
