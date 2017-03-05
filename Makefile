ifeq ($(DEBUG),true)
    OPT_CFLAGS  := -O0 -g3 -ftrapv -fstack-protector-all -D_FORTIFY_SOURCE=2
ifneq ($(shell echo $$OSTYPE),cygwin)
    OPT_CFLAGS  := $(OPT_CFLAGS) -fsanitize=address -fno-omit-frame-pointer
endif
    OPT_LDLIBS  := -lssp
else
ifeq ($(OPT),true)
    OPT_CFLAGS  := -flto -Ofast -march=native -DNDEBUG
    OPT_LDFLAGS := -flto -s
else
ifeq ($(LTO),true)
    OPT_CFLAGS  := -flto -DNDEBUG
    OPT_LDFLAGS := -flto
else
    OPT_CFLAGS  := -O3 -DNDEBUG
    OPT_LDFLAGS := -s
endif
endif
endif

WARNING_CFLAGS := \
    -Wall \
    -Wextra \
    -Wcast-align \
    -Wcast-qual \
    -Wconversion \
    -Wfloat-equal \
    -Wformat=2 \
    -Wpointer-arith \
    -Wstrict-aliasing=2 \
    -Wswitch-enum \
    -Wwrite-strings \
    -pedantic

MAX_SOURCE_SIZE   ?= 65536
MAX_BYTECODE_SIZE ?= 1048576
MAX_LABEL_LENGTH  ?= 65536
MAX_N_LABEL       ?= 1024
UNDEF_LIST_SIZE   ?= 256
STACK_SIZE        ?= 65536
HEAP_SIZE         ?= 65536
CALL_STACK_SIZE   ?= 65536
WS_INT            ?= int
WS_ADDR_INT       ?= 'unsigned int'
INDENT_STR        ?= '"  "'
MACROS ?= -DMAX_SOURCE_SIZE=$(MAX_SOURCE_SIZE) \
          -DMAX_BYTECODE_SIZE=$(MAX_BYTECODE_SIZE) \
          -DMAX_LABEL_LENGTH=$(MAX_LABEL_LENGTH) \
          -DMAX_N_LABEL=$(MAX_N_LABEL) \
          -DUNDEF_LIST_SIZE=$(UNDEF_LIST_SIZE) \
          -DSTACK_SIZE=$(STACK_SIZE) \
          -DHEAP_SIZE=$(HEAP_SIZE) \
          -DCALL_STACK_SIZE=$(CALL_STACK_SIZE) \
          -DWS_INT=$(WS_INT) \
          -DWS_ADDR_INT=$(WS_ADDR_INT) \
          -DINDENT_STR=$(INDENT_STR)

CC         := gcc $(if $(STDC), $(addprefix -std=, $(STDC)),)
MAKE       := make
MKDIR      := mkdir -p
CP         := cp
RM         := rm -f
CTAGS      := ctags
CFLAGS     := -pipe $(WARNING_CFLAGS) $(OPT_CFLAGS) $(INCS) $(MACROS)
LDFLAGS    := -pipe $(OPT_LDFLAGS)
CTAGSFLAGS := -R --languages=c
LDLIBS     := $(OPT_LDLIBS)
TARGET     := whitespace
OBJS       := $(addsuffix .o, $(basename $(TARGET)))
SRCS       := $(OBJS:.o=.c)
DEPENDS    := depends.mk

ifeq ($(OS),Windows_NT)
    TARGET := $(addsuffix .exe, $(TARGET))
else
    TARGET := $(addsuffix .out, $(TARGET))
endif
INSTALLED_TARGET := $(if $(PREFIX), $(PREFIX),/usr/local)/bin/$(TARGET)

%.exe:
	$(CC) $(LDFLAGS) $(filter %.c %.o, $^) $(LDLIBS) -o $@
%.out:
	$(CC) $(LDFLAGS) $(filter %.c %.o, $^) $(LDLIBS) -o $@


.PHONY: all test depends syntax ctags install uninstall clean cleanobj
all: $(TARGET)
$(TARGET): $(OBJS)

$(foreach SRC,$(SRCS),$(eval $(subst \,,$(shell $(CC) -MM $(SRC)))))

test: $(TARGET)
	$(MAKE) -C t/

depends:
	$(CC) -MM $(SRCS) > $(DEPENDS)

syntax:
	$(CC) $(SRCS) $(STD_CFLAGS) -fsyntax-only $(WARNING_CFLAGS) $(INCS) $(MACROS)

ctags:
	$(CTAGS) $(CTAGSFLAGS)

install: $(INSTALLED_TARGET)
$(INSTALLED_TARGET): $(TARGET)
	@[ ! -d $(@D) ] && $(MKDIR) $(@D) || :
	$(CP) $< $@

uninstall:
	$(RM) $(INSTALLED_TARGET)

clean:
	$(RM) $(TARGET) $(OBJS)

cleanobj:
	$(RM) $(OBJS)
