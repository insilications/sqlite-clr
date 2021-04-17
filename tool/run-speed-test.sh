#!/bin/bash
#
# This is a template for a script used for day-to-day size and 
# performance monitoring of SQLite.  Typical usage:
#
#     sh run-speed-test.sh trunk  #  Baseline measurement of trunk
#     sh run-speed-test.sh x1     # Measure some experimental change
#     fossil test-diff --tk cout-trunk.txt cout-x1.txt   # View chanages
#
# There are multiple output files, all with a base name given by
# the first argument:
#
#     summary-$BASE.txt           # Copy of standard output
#     cout-$BASE.txt              # cachegrind output
#     explain-$BASE.txt           # EXPLAIN listings (only with --explain)
#
PGO_GEN="-fprofile-generate=/var/tmp/pgo -fprofile-dir=/var/tmp/pgo -fprofile-abs-path -fprofile-update=atomic -fprofile-arcs -ftest-coverage --coverage -fprofile-correction -fprofile-partial-training"
CPPFLAGS="$PGO_GEN -DHAVE_EDITLINE=1 -DHAVE_READLINE=1 -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_MMAP_SIZE=268435456 -DSQLITE_DEFAULT_PAGE_SIZE=4096 -DSQLITE_DEFAULT_SYNCHRONOUS=1 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_DEFAULT_WORKER_THREADS=6 -DSQLITE_DISABLE_DIRSYNC -DSQLITE_ENABLE_BYTECODE_VTAB -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_DBPAGE_VTAB -DSQLITE_ENABLE_DBSTAT_VTAB -DSQLITE_ENABLE_DESERIALIZE -DSQLITE_ENABLE_EXPLAIN_COMMENTS -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_MEMSYS5 -DSQLITE_ENABLE_OFFSET_SQL_FUNC -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_STMTVTAB -DSQLITE_ENABLE_UNKNOWN_SQL_FUNCTION -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_HAVE_ZLIB -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_DEFAULT_PAGE_SIZE=32768 -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_MAX_WORKER_THREADS=16 -DSQLITE_TEMP_STORE=2 -DSQLITE_THREADSAFE=2 -DSQLITE_USE_ALLOCA -DUSE_AMALGAMATION=1 -DUSE_PREAD"
MYFLAGS="-g -O3 --param=lto-max-streaming-parallelism=16 -march=native -mtune=native -fgraphite-identity -Wall -Wl,--as-needed -Wl,--build-id=sha1 -Wl,--enable-new-dtags -Wl,--hash-style=gnu -Wl,-O2 -Wl,-z,now -Wl,-z,relro -falign-functions=32 -flimit-function-alignment -fasynchronous-unwind-tables -fdevirtualize-at-ltrans -floop-nest-optimize -floop-block -fno-math-errno -fno-semantic-interposition -fno-stack-protector -fno-trapping-math -ftree-loop-distribute-patterns -ftree-loop-vectorize -ftree-vectorize -funroll-loops -fuse-ld=bfd -fuse-linker-plugin -malign-data=cacheline -fipa-pta -flto=16 -fno-plt -mtls-dialect=gnu2 -Wl,-sort-common -Wno-error -Wp,-D_REENTRANT -pipe -ffat-lto-objects -fPIC -fno-math-errno -fomit-frame-pointer -pthread -static-libgcc -Wl,--whole-archive,--as-needed,/usr/lib64/libz.a,-lpthread,-ldl,-lm,-lmvec,--no-whole-archive $CPPFLAGS"
if test "$1" = ""
then
  echo "Usage: $0 OUTPUTFILE [OPTIONS]"
  exit
fi
NAME=$1
shift
CC_OPTS=""
SPEEDTEST_OPTS="--shrink-memory --reprepare --heap 10000000 64"
SIZE=5
doExplain=0
while test "$1" != ""; do
  case $1 in
    --reprepare)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS $1"
        ;;
    --autovacuum)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS $1"
        ;;
    --utf16be)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS $1"
        ;;
    --stats)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS $1"
        ;;
    --without-rowid)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS $1"
        ;;
    --nomemstat)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS $1"
        ;;
    --wal)
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS --journal wal"
        ;;
    --size)
        shift; SIZE=$1
        ;;
    --explain)
        doExplain=1
        ;;
    --heap)
        CC_OPTS="$CC_OPTS -DSQLITE_ENABLE_MEMSYS5"
        shift;
        SPEEDTEST_OPTS="$SPEEDTEST_OPTS --heap $1 64"
        ;;
    *)
        CC_OPTS="$CC_OPTS $1"
        ;;
  esac
  shift
done
SPEEDTEST_OPTS="$SPEEDTEST_OPTS --size $SIZE"
echo "NAME           = $NAME" | tee summary-$NAME.txt
echo "SPEEDTEST_OPTS = $SPEEDTEST_OPTS" | tee -a summary-$NAME.txt
echo "CC_OPTS        = $CC_OPTS" | tee -a summary-$NAME.txt
#rm -f cachegrind.out.* speedtest1 speedtest1.db || :
# gcc $MYFLAGS -Wall -I. $CC_OPTS -c sqlite3.c
# size sqlite3.o | tee -a summary-$NAME.txt
# if test $doExplain -eq 1; then
#  gcc $MYFLAGS -Wall -I. $CC_OPTS \
#     -DSQLITE_ENABLE_EXPLAIN_COMMENTS \
#    ./shell.c ./sqlite3.c -o sqlite3 -ldl -lpthread
# fi
SRC=test/speedtest1.c
#rm speedtest* || :
#rm *trunk* || :
if [ -e speedtest1 ]
then
    echo "speedtest1 exists"
else
    gcc -Wall -I. $SRC .libs/sqlite3.o -o speedtest1 $MYFLAGS
fi

# ls -l speedtest1 | tee -a summary-$NAME.txt
#valgrind --tool=cachegrind ./speedtest1 speedtest1.db $SPEEDTEST_OPTS 2>&1 | tee -a summary-$NAME.txt
./speedtest1 speedtest1.db $SPEEDTEST_OPTS
# size sqlite3.o | tee -a summary-$NAME.txt
# wc sqlite3.c
#tool/cg_anno.tcl cachegrind.out.* >cout-$NAME.txt

# if test $doExplain -eq 1; then
#   ./speedtest1 --explain $SPEEDTEST_OPTS | ./sqlite3 >explain-$NAME.txt
# fi
#rm speedtest* || :
#rm *trunk* || :
