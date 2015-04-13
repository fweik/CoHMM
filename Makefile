ARCH := intel64
M_UNAME := $(shell uname -m)
ifeq ($(M_UNAME), i686)
ARCH := ia32
endif
#VPATH = ..
SRCDIR=src
##############CHARM##########
ifeq ($(SET), charm)
#CHARM_ROOT=$(HOME)/charm
ifeq (,$(CHARM_ROOT))
$(info Please establish Charmm++ environment variables before using this Makefile.)
$(info E.g. by running setting CHARM_ROOT or run 'module load charm++')
$(error CHARM_ROOT is not set)
endif
CXXFLAGS+=-DCHARM
CHARMBIN=$(CHARM_ROOT)/bin
CHARMINC=$(CHARM_ROOT)/include
CXX=$(CHARMBIN)/charmc
OBJDIR=charm_obj
BINDIR=charm_bin
#############CNC############
else ifeq ($(SET), cnc) 
CXXFLAGS+=-DCNC
CXX=icpc
#CXX=g++
#CXX=/home/droehm/vampirTrace/bin/vtcxx
OBJDIR=cnc_obj
BINDIR=cnc_bin
#############OMP############
else ifeq ($(SET), omp)
CXXFLAGS+=-DOMP
CXX=g++
OBJDIR=omp_obj
BINDIR=omp_bin
#############SERIAL############
else ifeq ($(SET), serial)
CXXFLAGS+=-DSERIAL
CXX=g++
OBJDIR=serial_obj
BINDIR=serial_bin
#############CIRCLE############
else ifeq ($(SET), circle)
CXXFLAGS+=-DCIRCLE
CXX=mpicxx
#CXX=/home/droehm/vampirTrace/bin/vtcxx -vt:cxx mpicxx
LIBCIRCLELIBS=$(shell pkg-config --libs libcircle)
LIBCIRCLE_CFLAGS=$(shell pkg-config --cflags libcircle)
ifeq ($(LIBCIRCLELIBS), )
$(error Set LIBCIRCLELIBS or run 'module load libcircle' first)
endif
OBJDIR=circle_obj
BINDIR=circle_bin
else
ifneq "$(MAKECMDGOALS)" "clean"
$(error please SET=cnc, SET=charm, SET=circle, SET=serial or SET=omp)
endif
endif

ifeq ($(SET), cnc)
ifeq (,$(CNCROOT))
$(info Please establish CnC environment variables before using this Makefile.)
$(info E.g. by running cncvars.sh or cncvars.csh)
$(error CNCROOT is not set)
endif
endif

#HIREDIS_INCLUDES=$(HOME)/hiredis
ifeq ($(HIREDIS_INCLUDES), )
ifeq ($(wildcard /usr/include/hiredis/hiredis.h), )
$(error Set HIREDIS_INCLUDES or run 'module load hiredis' first)
else
$(info Found hiredis in /usr/include, setting HIREDIS_INCLUDES=/usr/include)
HIREDIS_INCLUDES=/usr/include
endif
endif
HIREDISLIB=$(HIREDIS_INCLUDES)/../lib
HIREDISINC=$(HIREDIS_INCLUDES)/hiredis
HIREDIS_CFLAG=-I$(HIREDISINC)
HIREDIS_LDFLAG=-L$(HIREDISLIB) -lhiredis

ifeq ($(MKLROOT), )
$(info MKLROOT not set, using llapack and lblas, run 'module load mkl' or set MKLROOT first to use mkl)
LINALGROOT=/usr
else
LINALGROOT=
MKLINC=$(MKLROOT)/include
MKLLIB=$(MKLROOT)/lib/$(ARCH)
endif

#LINALG
LINALGLIB=
LINALG=$(LINALGROOT)
LINALGINC=$(LINALG)/include/
#INCLUDE BLAS
BLASROOT=
BLAS=$(BLASROOT)
BLASINC=$(BLAS)/include/
BLASLIB=$(BLAS)/lib64
BLAS_CFLAG=-I$(BLASINC)

ifeq ($(LINALGROOT), )
#MKL flags
  #MKL_LDFLAG= -L$(MKLLIB) -lmkl_intel_ilp64 -lmkl_core -lmkl_sequential
  MKL_CFLAG=-I$(MKLINC) -DHAVE_MKL
  MKL_LDFLAG= -L$(MKLLIB) -lmkl_rt
else
  #LINALG_CFLAGS=-I$(LINALGINC) -llapack
  LINALG_LDFLAG=$(shell pkg-config --silence-errors --libs lapack blas || true)
  ifeq ($(LINALG_LDFLAG), )
  $(info No pkg-config for blas/lapack using LINALG_LDFLAG='-lblas -llapack' instead.)
  LINALG_LDFLAG= -lblas -llapack
  endif
endif

#OPTFLAGS=-g
OPTFLAGS=-O3
#other features
#DEFS=-DTRACE
ifeq ($(SET), cnc) 
  CNC_LDFLAG=-L$(CNCROOT)/lib/$(ARCH) -lcnc -ltbb -ltbbmalloc
  CNC_CFLAG= -D_DIST_ -I$(CNCROOT)/include -std=c++0x
  #CNC_CFLAG=-I$(CNCROOT)/include -std=c++0x
else ifeq ($(SET), omp) 
  OMP_CFLAGS=-fopenmp
  OMP_LDFLAGS=-fopenmp
endif

ifeq ($(BOOST_INCLUDES), )
ifeq ($(wildcard /usr/include/boost/property_tree/json_parser.hpp), )
$(error Set BOOST_INCLUDES or run 'module load boost' first)
else
$(info Found Boost in /usr/include, setting BOOST_INCLUDES=/usr/include)
BOOST_INCLUDES=/usr/include
endif
endif
BOOST_CFLAG=-I$(BOOST_INCLUDES)
#We use boost header only so far
BOOSTLIB=$(BOOST_INCLUDES)/../lib
BOOST_LDFLAG=-L$(BOOSTLIB)

COMD=$(CURDIR)/COMD_lib
COMDINC=$(COMD)/src-lib
SUBDIRS=$(COMDINC)
ifeq ($(wildcard $(COMDINC)/CoMD_lib.h), )
$(error COMDINC=$(COMDINC) seems to point to the wrong directory)
endif
COMDLIB=$(COMD)
COMD_CFLAG=-I$(COMDINC)
COMD_LDFLAG=-L$(COMDLIB) -Wl,-rpath,$(COMDLIB) -lCoMD_2D
#COMD_LDFLAG=-L$(COMDLIB) -lcomd

OBJS:=$(addprefix $(OBJDIR)/, 2DKriging.o kriging.o flux.o redisBuckets.o output.o input.o)
ifeq ($(LINALGROOT), )
CXXFLAGS+=$(HIREDIS_CFLAG) $(MKL_CFLAG) $(COMD_CFLAG) $(BOOST_CFLAG) $(OPTFLAGS) $(DEFS)
LDFLAGS=$(HIREDIS_LDFLAG) $(MKL_LDFLAG) $(COMD_LDFLAG) -lm -lrt
else
CXXFLAGS+=$(HIREDIS_CFLAG) $(LINALG_CFLAG) $(COMD_CFLAG) $(BOOST_CFLAG) $(OPTFLAGS) $(DEFS)
LDFLAGS=$(HIREDIS_LDFLAG) $(LINALG_LDFLAG) $(COMD_LDFLAG) -lm -lrt 
endif

ifeq ($(SET), charm)
$(info compiling Charm files)
OBJS+=$(OBJDIR)/main_charm.o
else ifeq ($(SET), cnc) 
$(info compiling CnC files)
OBJS+=$(OBJDIR)/main_generic.o
LDFLAGS+=$(CNC_LDFLAG) 
CXXFLAGS+=$(CNC_CFLAG)
else ifeq ($(SET), omp) 
$(info compiling OpenMP files)
OBJS+=$(OBJDIR)/main_generic.o
CXXFLAGS+=$(OMP_CFLAGS)
LDFLAGS+=$(OMP_LDFLAGS)
else ifeq ($(SET), serial) 
$(info compiling Serial files)
OBJS+=$(OBJDIR)/main_generic.o
else ifeq ($(SET), circle)
OBJS+=$(OBJDIR)/main_generic.o
CXXFLAGS+=$(LIBCIRCLE_CFLAGS)
LDFLAGS+=$(LIBCIRCLELIBS) $(BOOST_LDFLAG) -lboost_serialization
endif
CXXFLAGS+=$(LINALG_CFLAGS)

#target
NAME=$(BINDIR)/2D_Kriging
default: all
all: $(SUBDIRS) $(OBJDIR) $(NAME)

ifeq ($(SET), charm)
$(OBJDIR)/%.d: $(SRCDIR)/%.cpp
	@#1. sed:  put one file per line * * -> *\\\n*
	@#2. sed gcc -MG does not know that missing files will be in $(SRCDIR)
	@# no path -> SRCDIR
	@echo g++ -MM -MG -MT $(OBJDIR)/$*.o $(CXXFLAGS) -I$(SRCDIR) -I$(CHARMINC) $< \> $@
	@g++ -MM -MG -MT $(OBJDIR)/$*.o $(CXXFLAGS) -I$(SRCDIR) -I$(CHARMINC) $< | \
	sed 's/\([^[:space:]]\) \([^\\[:space:]]\)/\1 \\\n \2/g' | \
	sed '/^[^/]*.\(def\|decl\)\./s@[^[:space:]]@$(SRCDIR)/&@' > $@

#Charmm++ ci files
$(SRCDIR)/%.decl.h $(SRCDIR)/%.def.h: $(SRCDIR)/%.ci
	@#charmc writes to pwd only
	cd $(<D) && $(CXX) $(<F)
else
#deps rule for c files
$(OBJDIR)/%.d: $(SRCDIR)/%.cpp
	$(CXX) $(CXXFLAGS) -MM -MF $@ -MT $(OBJDIR)/$*.o $<
endif

DEPS=$(OBJS:.o=.d)
ifneq "$(MAKECMDGOALS)" "clean"
-include $(DEPS)
endif

#make subdirs for objects and executable
$(NAME): | $(BINDIR)

$(BINDIR):
	@mkdir -p $(BINDIR)

$(OBJS): | $(OBJDIR)
$(DEPS): | $(OBJDIR)

$(OBJDIR):
	@mkdir -p $(OBJDIR)

##--- Executable ---##

$(NAME): $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS)
ifeq ($(SET), charm)
	@mv charmrun $(BINDIR)/
endif

#GNU make implicit rule
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) $(MFLAGS) -C $@ OPTFLAGS='$(OPTFLAGS)'

subdirclean:
	@for i in $(SUBDIRS); do \
	  echo $(MAKE) $(MFLAGS) -C $$i clean; \
	  $(MAKE) $(MFLAGS) -C $$i clean || exit 1; \
	done

clean: subdirclean
	rm -f $(SRCDIR)/*.decl.h $(SRCDIR)/*.def.h
	rm -f *.vtk *.dat core.* 
	[ -z $(OBJDIR) ] || rm -f $(OBJS) $(DEPS)  $(OBJDIR)/main_*.[od]
	[ -z $(BINDIR) ] || rm -f $(NAME)

