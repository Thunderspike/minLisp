NAME	=	minLisp

$(NAME):	$(NAME).tab.c lex.yy.c stateManagement.c
	gcc -o $(NAME) $(NAME).tab.c lex.yy.c stateManagement.c $(NAME).h -ll

$(NAME).tab.c: $(NAME).y
	bison -vd $(NAME).y 

lex.yy.c:	$(NAME).l
	flex $(NAME).l 