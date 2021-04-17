#!/bin/bash
#
# A script for running speed tests using kvtest.
#
# The test database must be set up first.  Recommended
# command-line:
#
#    ./kvtest init kvtest.db --count 100K --size 12K --variance 5K
PGO_GEN="-fprofile-generate=/var/tmp/pgo -fprofile-dir=/var/tmp/pgo -fprofile-abs-path -fprofile-update=atomic -fprofile-arcs -ftest-coverage --coverage -fprofile-correction -fprofile-partial-training"
CPPFLAGS="$PGO_GEN -DHAVE_EDITLINE=1 -DHAVE_READLINE=1 -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_MMAP_SIZE=268435456 -DSQLITE_DEFAULT_PAGE_SIZE=4096 -DSQLITE_DEFAULT_SYNCHRONOUS=1 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_DEFAULT_WORKER_THREADS=6 -DSQLITE_DISABLE_DIRSYNC -DSQLITE_ENABLE_BYTECODE_VTAB -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_DBPAGE_VTAB -DSQLITE_ENABLE_DBSTAT_VTAB -DSQLITE_ENABLE_DESERIALIZE -DSQLITE_ENABLE_EXPLAIN_COMMENTS -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_MEMSYS5 -DSQLITE_ENABLE_OFFSET_SQL_FUNC -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_STMTVTAB -DSQLITE_ENABLE_UNKNOWN_SQL_FUNCTION -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_HAVE_ZLIB -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_DEFAULT_PAGE_SIZE=32768 -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_MAX_WORKER_THREADS=16 -DSQLITE_TEMP_STORE=2 -DSQLITE_THREADSAFE=2 -DSQLITE_USE_ALLOCA -DUSE_AMALGAMATION=1 -DUSE_PREAD"
MYFLAGS="-g -O3 --param=lto-max-streaming-parallelism=16 -march=native -mtune=native -fgraphite-identity -Wall -Wl,--as-needed -Wl,--build-id=sha1 -Wl,--enable-new-dtags -Wl,--hash-style=gnu -Wl,-O2 -Wl,-z,now -Wl,-z,relro -falign-functions=32 -flimit-function-alignment -fasynchronous-unwind-tables -fdevirtualize-at-ltrans -floop-nest-optimize -floop-block -fno-math-errno -fno-semantic-interposition -fno-stack-protector -fno-trapping-math -ftree-loop-distribute-patterns -ftree-loop-vectorize -ftree-vectorize -funroll-loops -fuse-ld=bfd -fuse-linker-plugin -malign-data=cacheline -fipa-pta -flto=16 -fno-plt -mtls-dialect=gnu2 -Wl,-sort-common -Wno-error -Wp,-D_REENTRANT -pipe -ffat-lto-objects -fPIC -fno-math-errno -fomit-frame-pointer -pthread -static-libgcc -Wl,--whole-archive,--as-needed,/usr/lib64/libz.a,-lpthread,-ldl,-lm,-lmvec,--no-whole-archive $CPPFLAGS"
if test "$1" = ""
then
  echo "Usage: $0 OUTPUTFILE [OPTIONS]"
  exit
fi
# if [ -e kvtest ]
# then
#     echo "kvtest exists"
# else
#     echo "building kvtest"
#     gcc -Wall -I. test/kvtest.c .libs/sqlite3.o -o kvtest $MYFLAGS
#      gcc -Wall -I. test/kvtest.c sqlite3.c -o kvtest $MYFLAGS
# fi

if [ -e speedtest2 ]
then
    echo "speedtest2 exists"
else
    echo "building speedtest2"
#     gcc -Wall -I. test/speedtest1.c .libs/sqlite3.o -o speedtest1 $MYFLAGS
     gcc -Wall -I. test/speedtest1.c sqlite3.o -o speedtest2 $MYFLAGS
fi

# if [ -e kvtest.db ]
# then
#     echo "kvtest.db exists"
# else
#     echo "creating kvtest.db"
#     ./kvtest init kvtest.db --count 50K --size 10K --variance 5K
# fi

# ./kvtest run kvtest.db --count 50K --stats
# ./kvtest run kvtest.db --count 50K --stats --blob-api
# ./kvtest run kvtest.db --count 50K --stats --update
# ./kvtest run kvtest.db --count 50K --stats --random
./speedtest2 speedtest1.db --shrink-memory --reprepare --heap 21474838 64 --size 5
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --repeat 30
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --singlethread
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --testset main
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --testset cte
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --testset rtree
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --testset orm
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --testset fp
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --journal wal
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --main --journal wal
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --journal wal
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --journal wal
./speedtest2 speedtest1.db --shrink-memory --reprepare --stats --heap 21474838 64 --size 5 --multithread --threads 16 --journal wal
