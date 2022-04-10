NAME	=	minLisp

$(NAME):	$(NAME).tab.c lex.yy.c
	gcc $(NAME).tab.c lex.yy.c -o $(NAME) -ll

$(NAME).tab.c:	$(NAME).y
	bison -vd $(NAME).y

lex.yy.c:	$(NAME).l
	flex $(NAME).l