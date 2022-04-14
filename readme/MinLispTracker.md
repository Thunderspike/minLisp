```minLisp
ML		    :=	arrays program      [x]                         
arrays		:=	arrays array        [x]
            |   ε                   [x]
array		:=	( array id num )    [x]
program		:=	program function    [x]
		    |	function            [x]                   
function	:=	( define id param_list expr ) [x] -- check for arr
param_list	:=	( )                 [x]
			|	( id_list )         [x]
id_list		:=	id_list id          [x] _int
		    |	id	                [x] _int
expr		:=	num                 [x] 
            |	id                  [x] -- check for array/func (done)
            |	id [ expr ]         [x] -- check for func/local (done)
            |	true                [x]
            |	false               [x]
            |	( if expr expr expr )   [x]
            |	( while expr expr ) [x]
            |	( id actual_list )  [-] -- check for arr/local (done)
            |	( write expr )      [x]
            |	( writeln expr )    [x]
            |	( read )            [x]
            |	( let ( assign_list ) expr ) [x]
            |	( set id expr )     [x] -- check for array/func (done)
            |	( set id [ expr ] expr ) [x] -- check for func/local (done)
            |	( + expr expr )     [x]
            |	( - expr expr)      [x]
            |	( * expr expr )     [x]
            |	( / expr expr)      [x]
            |	( < expr expr )     |	( > expr expr )  [x]
            |	( <= expr expr)     |	( >= expr expr)  [x]
            |	( = expr expr )     [x]
            |	( <> expr expr)     [x]
            |	( - expr )          [x]
            |	( and  expr expr)  	|	( &  expr expr)  [x]
            |	( or  expr expr )	|	( |  expr expr ) [x]
            |	( not expr ) 		|	( ! expr )       [x]
            |   ( seq expr_list )       [x]
actual_list	:=	actual_list expr        [x]
		    |	ε                       [x]
assign_list	:=	assign_list ( id expr ) [x]
		    |	( id expr )             [x]
expr_list   :=  expr_list expr          [x]
		    |	expr                    [x]
```