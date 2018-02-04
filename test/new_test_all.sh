# Will eventually replace `test_all.sh`.
./plassert.py app-1.plcore 'has_value(( Foo . r2 ), 17)'
./plassert.py app-2.plcore 'has_value(( Foo . result ), 20)'
./plassert.py app-3.plcore 'has_value(( Foo . r2 ), 5)'
./plassert.py let-1.plcore 'has_value(( Foo . result ), 4)'
