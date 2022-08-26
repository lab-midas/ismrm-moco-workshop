# Makefile
# This makefile builds the .mex* files needed for NUFFT interpolation.

# User may need to edit the path below to find matlab's mex compiler:
matlab_top = /usr/local/matlab/
mexloc = $(matlab_top)/bin/mex
#mexloc = mex

# different OS versions have different suffixes for the compiled mex files:
suf_i686 = mexglx
suf_ppc = mexmac
suf_x86_64 = mexa64
suf_i386 = mexmaci
suf_mi64 = mexmaci64
suf_ = suf_i686; # default is linux
suf = $(suf_$(Arch))

# where to install the compiled mex files:
dir = ../../mex/v7/

# architecture specific compile flags:
aflag_x86_64 = -fPIC
aflag_mi64 = -arch x86_64
aflag = $(aflag_$(Arch))

# this -D_GNU_SOURCE flag came from looking at "mex -v" output...
CFLAGS = -D_GNU_SOURCE \
	-ansi -Wall -Wshadow -Wpointer-arith -W -Werror $(aflag)
mex = $(mexloc) CFLAGS='$(CFLAGS)'

def = def,table.h

goal:	\
	$(dir)interp1_table_mex.$(suf) \
	$(dir)interp2_table_mex.$(suf) \
	$(dir)interp3_table_mex.$(suf) \
	$(dir)interp1_table_adj_mex.$(suf) \
	$(dir)interp2_table_adj_mex.$(suf) \
	$(dir)interp3_table_adj_mex.$(suf)
	@echo working on $(suf)


i1c = interp1_table1_for.c interp1_table_mex.c
$(dir)interp1_table_mex.$(suf):	$(i1c) $(def) def,table1.h
	$(mex) -output $@ $(i1c)
	chmod 755 $@

i2c = interp2_table1_for.c interp2_table_mex.c
$(dir)interp2_table_mex.$(suf):	$(i2c) $(def) def,table2.h
	$(mex) -output $@ $(i2c)
	chmod 755 $@

i3c = interp3_table1_for.c interp3_table_mex.c
$(dir)interp3_table_mex.$(suf):	$(i3c) $(def) def,table3.h
	$(mex) -output $@ $(i3c)
	chmod 755 $@


a1c = interp1_table1_adj.c interp1_table_adj_mex.c
$(dir)interp1_table_adj_mex.$(suf):	$(a1c) $(def) def,table1.h
	$(mex) -output $@ $(a1c)
	chmod 755 $@

a2c = interp2_table1_adj.c interp2_table_adj_mex.c
$(dir)interp2_table_adj_mex.$(suf):	$(a2c) $(def) def,table2.h
	$(mex) -output $@ $(a2c)
	chmod 755 $@

a3c = interp3_table1_adj.c interp3_table_adj_mex.c
$(dir)interp3_table_adj_mex.$(suf):	$(a3c) $(def) def,table3.h
	$(mex) -output $@ $(a3c)
	chmod 755 $@


# how to compile for freemat import?
todo:
	cc -dynamic -fPIC -c interp1_table1.c
	libtool -o interp1_table1.a interp1_table1.o
	#libtool -dynamic -noall_load -o interp1_table1.so interp1_table1.o

reset:
	/bin/rm -i $(dir)interp*table*mex.$(suf)
