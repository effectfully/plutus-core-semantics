# Will eventually replace `test_all.sh`.
./run-pretty.sh app-1.plcore > out.xml
./plassert.py out.xml 'has_value(( Foo . r2 ), 17)'
./run-pretty.sh app-2.plcore > out.xml
./plassert.py out.xml 'has_value(( Foo . result ), 20)'

