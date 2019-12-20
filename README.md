# yamlt - yaml templates

`yamlt` can be used to generate code and configuration files.

By supplying data though a yaml file a template file can be used to generate a target file.

Usage: `yaml template.t data.yaml > target`

Features available in the template file.

### Example 1

Use of `%%nn:vv%%` to select nodes that has property `nn` with the value `vv`. 

Also uses `${^name}` to get name of node and `${nn}` to get value of property `nn`.

example_1.yaml

```
node_1:
  type: A
  description: This is node 1

node_2:
  type: A
  description: This is node 2

node_3:
  type: B
  description: This is node 3
```

example_1.t

```
Start
%%type:A%%
${^name}: "${description}"
%%end%%
End.
```

Output

```
Start
node_1: "This is node 1"
node_2: "This is node 2"
End.
```

### Example 2

Use of `%%foreach:nn%%` to repeat template part for each node under `nn`.

Also uses `${^value}` to get the value of the node being used if it has a value and not subnodes.

example_2.yaml

```
node_a:
  type: object
  column:
    x: float
    y: float
    width: float
    height: float

node_b:
  type: object
  column:
    id: int
    name: string
    happy: bool
```

example_2.t

```
Start

%%type:object%%
## Defining: ${^name} ##

${^name} {
%%foreach:column%%
  ${^value} ${^name};
%%end%%
}

%%end%%
End.
```

Output

```
Start

## Defining: node_a ##

node_a {
  float x;
  float y;
  float width;
  float height;
}

## Defining: node_b ##

node_b {
  int id;
  string name;
  bool happy;
}

End.
```

### Example 3

Uses of dot seperated path to access values. Also use of prefix dot to access globals and a technic to lookup value from list in yaml.

example_3.yaml

```
color:
	yellow: "0x00ffff"
	blue:   "0x0000ff"
	green:  "0x00ff00"
	red:    "0xff0000"
	gray:   "0x808080"
	white:  "0xffffff"

cars:
    vw:
        beetle: yellow
    volvo:
        "240": blue
    saab:
        "95": green
    tesla:
        s: red
        "3": gray
        x: white

stickers:
	type: object
	material: plastic
	shapes:
		cirle:
			color: red
		square:
			color: green
		triangle:
			color: blue
```

example_3.t

```
Start

// Use '${cars.tesla.3}'
pen.set(${color.${cars.tesla.3}});

%%type:object%%
// ${^name}/${material}
%%foreach:shapes%%
// ${^name} ${color} ${.color.${color}}
%%end%%
%%end%%

End.
```

Output

```
Start

// Use 'gray'
pen.set(0x808080);

// stickers/plastic
// cirle red 0xff0000
// square green 0x00ff00
// triangle blue 0x0000ff

End.
```


Other features:

* `%%define:nn%%` Define macro
* `%%macro:nn%%` Use macro
* `${^id}` insert unique id (int) for node
* `${^date}` insert current datetime "Dec 20, 2019 10:46:03 AM"
* `${^yamlFile}` insert name of yaml file
* `${^templateFile}` insert name of template file
* `${^path}` insert variable path to current node
* `indent:mm` use `mm` as line indentation for template part in `%%nn:vv;indent:mm%%` and `%%foreach:nn;indent:mm%%`
* `delimiter:mm` use `mm` as delimiter when repeating the nodes in `%%nn:vv;delimiter:mm%%` and `%%foreach:nn;delimiter:mm%%`
* `oneline` expand template part on oneline in `%%nn:vv;oneline%%` and `%%foreach:nn;oneline%%`