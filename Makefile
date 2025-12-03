$(info Introduction to MPI)

CC := mpicc
CFLAGS ?= -O2 -Wall
LDFLAGS ?= $(CFLAGS)

MPI ?=

MPICC := gcc
MPICFLAGS = $(CFLAGS)
ifdef MPI
MPICFLAGS += -D_MPI
MPICC = $(CC)
endif

TARGETS_BARE=1.1.MPI_hello_world 2.1.MPI_bcast
TARGETS_BARE_CONDITIONAL_MPI=1.2.MPI_hello_world_PP
TARGETS_UTILS=2.2.MPI_bcast_arrays 2.3.MPI_bcast_matrices_error 2.4.MPI_bcast_matrices_vs1 2.5.MPI_bcast_matrices_vs2 3.1.MPI_send_recv_arrays 4.1.MPI_scatter_gather_arrays 5.1.MPI_reduce_allreduce

BUILD_DIR?=build ## Define the outpur directory

BIN_DIR=$(strip $(BUILD_DIR))/bin
OBJ_DIR=$(strip $(BUILD_DIR))/obj

SRC_DIR=simple_examples
LIB_SRC=util

LIB_OBJS=$(patsubst $(SRC_DIR)/$(LIB_SRC)/%.c, $(OBJ_DIR)/%.o, $(wildcard $(SRC_DIR)/$(LIB_SRC)/*.c))
LIB_HEADERS=$(wildcard $(SRC_DIR)/$(LIB_SRC)/*.h)

.PHONY: help
help: # Shows interactive help.
	@cat README.md
	@echo
	@echo "make variables:"
	@echo
	@sed -e 's/^\([^\ \t]\+\)[\ \t]*?=[^#]\+#\+\(.*\)$$/\1 \2/p;d' Makefile \
        | column --table --table-columns-limit=2 \
        | sort
	@echo
	@echo "make targets:"
	@echo
	@echo Targets without utilities: $(TARGETS_BARE) 
	@echo Targets that can be compiled without MPI: $(TARGETS_BARE_CONDITIONAL_MPI) 
	@echo Targets with utilities: $(TARGETS_UTILS)
	@echo
	@echo "make special targets:"
	@echo
	@sed -e 's/^\([^:\ \t]\+\):.*#\+\(.*\)$$/\1 \2/p;d' Makefile \
        | column --table --table-columns-limit=2 \
        | sort

$(BUILD_DIR):
	mkdir --parents "$(strip $(BUILD_DIR))"

$(BIN_DIR): | $(BUILD_DIR)
	mkdir "$(BIN_DIR)"

$(OBJ_DIR): | $(BUILD_DIR)
	mkdir "$(OBJ_DIR)"

.PHONY: all
all: $(TARGETS_BARE) $(TARGETS_BARE_CONDITIONAL_MPI) $(TARGETS_UTILS)

$(TARGETS_BARE): %: $(BIN_DIR)/%

$(patsubst %, $(BIN_DIR)/%, $(TARGETS_BARE)): $(BIN_DIR)/%: $(OBJ_DIR)/%.o | $(BIN_DIR)
	$(CC) $(LDFLAGS) $^ -o $@

$(patsubst %, $(OBJ_DIR)/%.o, $(TARGETS_BARE)): $(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(TARGETS_UTILS): %: $(BIN_DIR)/%

$(patsubst %, $(BIN_DIR)/%, $(TARGETS_UTILS)): $(BIN_DIR)/%: $(OBJ_DIR)/%.o $(LIB_OBJS) | $(BIN_DIR)
	$(CC) $(LDFLAGS) $^ -o $@

$(patsubst %, $(OBJ_DIR)/%.o, $(TARGETS_UTILS)): $(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(LIB_HEADERS) | $(OBJ_DIR)
	$(CC) -c $(CFLAGS) -I$(SRC_DIR)/$(LIB_SRC) $< -o $@

$(TARGETS_BARE_CONDITIONAL_MPI): %: $(BIN_DIR)/%

$(patsubst %, $(BIN_DIR)/%, $(TARGETS_BARE_CONDITIONAL_MPI)): $(BIN_DIR)/%: $(OBJ_DIR)/%.o | $(BIN_DIR)
	$(MPICC) $(LDFLAGS) $^ -o $@

$(patsubst %, $(OBJ_DIR)/%.o, $(TARGETS_BARE_CONDITIONAL_MPI)): $(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(MPICC) -c $(MPICFLAGS) $< -o $@

$(LIB_OBJS): $(OBJ_DIR)/%.o: $(SRC_DIR)/$(LIB_SRC)/%.c $(LIB_HEADERS) | $(OBJ_LIB_DIR)
	$(CC) -c $(CFLAGS) -I$(SRC_DIR)/$(LIB_SRC) $< -o $@

.PHONY: clean
clean:
	@echo "Removing files:"
	@if [ -d $(BUILD_DIR) ]; then \
	    find $(BUILD_DIR) -type f -print0 | xargs -0I % bash -c '{ echo "%"; rm "%"; }'; \
	    rm -r $(BUILD_DIR); \
	fi
