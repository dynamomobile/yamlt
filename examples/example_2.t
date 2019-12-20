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
