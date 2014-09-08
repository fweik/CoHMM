2D_Kriging
=========

HMM computation of 2D elastodynamics based on G.-S. Jiang, E. Tadmor, Nonoscillatory central schemes for multidimensional hyperbolic conservation laws, SIAM Journal on Scientific Computing 19 (6) (1998) 1892–1917 theory. The [Redis database](http://redis.io) is used via the [hredis](https://github.com/redis/hiredis) interface. The database supports the prediction of CoMD results with the ordinary Kriging method. 

Original authors of the source code include Dominic Roehm and Robert Pavel. CoHMM is now maintained by ExMatEx: [Exascale Co-Design Center for Materials in Extreme Environments](exmatex.org).

Dependencies
------------

1. [redis](http://redis.io)

2. [hredis](https://github.com/redis/hiredis)

3. [mkl] or (another implementation of the cblas and lapacke interfaces)

4. [mkl](define mkl="mkl install path" in Makefile)

5. [comd](define COMD="comd install path" in Makefile) 

6. [comd](define BOOST="boost install path" in Makefile) 

Charm++:

7. [charm](http://charm.cs.illinois.edu/software)

   or git repo  http://charm.cs.illinois.edu/gerrit/charm

8. [charm](define CHARMDIR="Charm install path" in Makefile) 

CnC:

7. [cnc](https://software.intel.com/en-us/articles/intel-concurrent-collections-for-cc)

8. [cnc](Load the latest Intel Compiler, Intel MPI, and MKL) 

9. [cnc](define CNCDIR="CnC install path" in Makefile) 

10. [cnc](Make sure that the CoMD library is compiled with the intel mpi) 


Installation
------------

1. SET=charm or SET=cnc or SET=omp make

Execution
---------

1. start redis server in background (`redis-server &`)

1.1. distributed -> start redis using ./start_redis.sh hostfile

1.2. hostfile includes the name of the available hosts (e.g. cn40;cn41;...)

Charm++:

2. run 2D_Kriging with './charmrun +p#processes  ++mpiexec ./2D_Kriging input.json +stacksize 512000'

2.1. optional +isomalloc_sync

2.2. example command line:

     distributed: ./charmrun +p96  ++mpiexec ./2D_Kriging input.json +stacksize 512000
     local: ./charmrun +p8  ++local ./2D_Kriging input.json +stacksize 512000

3. for use of only one local redis master use:

    
     distributed: ./charmrun +p96  ++mpiexec ./2D_Kriging input.json `hostname` +stacksize 512000

CnC:

2. MPI: run 2D_Kriging distributed with 'env DIST_CNC=MPI mpirun -n $(NPROCS*48) ./2D_Kriging input.json' 

   on Darwin (no infiniband) 'env DIST_CNC=MPI mpirun -n 96 -env I_MPI_FABRICS shm:tcp ~/2014/CoHMM/2D_Kriging input.json'

3. SOCKETS: write client nodes in hostfile (eg.g cn30;cn31)

4. run 'env DIST_CNC=SOCKETS HOST_FILE=hostfile CNC_SOCKET_HOST=./start.sh ./2D_Kriging input.json'

5. SHARED MEM: in Makefile remove -D_DIST_ option in CNC_FLAG and rebuild 

6. run './2D_Kriging input.json'

OpenMP:

2. set $OMP_NUM_THREADS e.g. to the number of processors

3. run './2D_Kriging input.json'

Test Problems:

TP1

1. in 2DKriging.cpp enable define XWAVE (disable CIRCULAR)

2. features: define DB, KRIGING, KR_DB

3. in flux.cpp enable define COMD and DB !!! (disable C_RAND)

4. inout.json macro_solver:

        {"id": "dim x",                     "value": 100},
        {"id": "dim y",                     "value": 10},
        {"id": "integration steps",         "value": 50},
        {"id": "redis headnode",            "value": "localhost"},
        {"id": "database threshold",        "value": 0.00001},
        {"id": "kriging err. threshold",    "value": 0.001},
        {"id": "Gaussian noise",            "value": 0.0},
        {"id": "dx",                        "value": 1.0},
        {"id": "dy",                        "value": 1.0},
        {"id": "dt_x",                      "value": 0.1},
        {"id": "dt_y",                      "value": 0.1}

TP2

1. in 2DKriging.cpp enable define CIRCULAR (disable XWAVE)

2. features: define DB, KRIGING, KR_DB

3. in flux.cpp enable define COMD and DB !!! (disable C_RAND)

4. inout.json macro_solver:

        {"id": "dim x",                     "value": 50},
        {"id": "dim y",                     "value": 50},
        {"id": "integration steps",         "value": 50},
        {"id": "redis headnode",            "value": "localhost"},
        {"id": "database threshold",        "value": 0.00001},
        {"id": "kriging err. threshold",    "value": 0.001},
        {"id": "Gaussian noise",            "value": 0.0},
        {"id": "dx",                        "value": 1.0},
        {"id": "dy",                        "value": 1.0},
        {"id": "dt_x",                      "value": 0.1},
        {"id": "dt_y",                      "value": 0.1}


#TODO deprecated
Generating a Trace of Database Accesses
---------

1. start redis server in background (`redis-server &`)

2. ()start tools/redisTrace.sh in the background (From the source directory, './tools/redisTrace.sh &')

3. run 2DKriging normally

4. when 2DKriging is complete, terminate the redisTrace process and examine the resulting redisTrace.log file
