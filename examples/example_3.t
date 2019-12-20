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
