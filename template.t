a
b
c 
d

Hello, World!

%%define:11%%
Hello ${^name} ${^value}!
%%end%%

%%define:22%%
Hello ${^name} ${^value}!
%%end%%

OK this can work

help(${Cat.${arg}})

/*----------*/
%%type:object;indent:....;delimiter:/*--${plus} ${.plus}--*/%%
AAA ${^name} ${^path}
BBB ${plus}
CCC
%%foreach:columns%%
aaa
--> hej ${^name}.${^value}(${^path})
--> hej ${^name}.${type}(${^path})
bbb
ccc ${.help}
%%end%%

%%end%%
/*----------*/
%%type:object;indent:....%%
[${^name}:${^id}]
%%end%%
/*----------*/

123: ${.help}

%%foreach:my_list%%
%%macro:${^value}%%
%%end%%

XX: ${vw.columns.age} ${vw.columns.${.property}}

new = [ %%type:object;oneline;delimiter:, %%
"${^name}"
%%end%%
 ];

END.