a
b
c 
d

Hello, World!

OK this can work

help(${Cat.${arg}})

/*----------*/
%%type:object;indent:....;delimiter:/*--${plus}--*/%%
AAA ${^name} ${^path}
BBB ${plus}
CCC
%%foreach:columns%%
aaa
--> hej ${^name}.${^value}(${^path})
--> hej ${^name}.${type}(${^path})
bbb
%%end%%
%%end%%
/*----------*/
%%type:object;indent:....%%
[${^name}:^id]
%%end%%
/*----------*/

123: ${ajaj}

END.