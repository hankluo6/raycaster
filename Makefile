BIN = main

CXXFLAGS = -std=c++11 -O2 -Wall -g

# SDL
CXXFLAGS += `sdl2-config --cflags`
LDFLAGS += `sdl2-config --libs`

# Control the build verbosity
ifeq ("$(VERBOSE)","1")
    Q :=
    VECHO = @true
else
    Q := @
    VECHO = @printf
endif

GIT_HOOKS := .git/hooks/applied
.PHONY: all clean

all: $(GIT_HOOKS) $(BIN)

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

raycaster_tables.h: Makefile
	@echo "Generating $@"
	
	@echo "#include <iterator> " >> $@
	@echo "#include <array> " >> $@
	@echo "#include <type_traits> " >> $@
	@echo "#include <cmath> " >> $@
	@echo "#include \"raycaster.h\" " >> $@

	@echo "#if __cplusplus < 201402L " >> $@
	@echo "namespace std" >> $@
	@echo "{" >> $@
	@echo "  // A type that represents a parameter pack of zero or more integers." >> $@
	@echo "  template<typename T, T... I>" >> $@
	@echo "    struct integer_sequence" >> $@
	@echo "    {" >> $@
	@echo "      static_assert( std::is_integral<T>::value, \"Integral type\" );" >> $@
	@echo "      using type = T;" >> $@
	@echo "      static constexpr T size = sizeof...(I);" >> $@
	@echo "      // Generate an integer_sequence with an additional element." >> $@
	@echo "      template<T N>" >> $@
	@echo "	using append = integer_sequence<T, I..., N>;" >> $@

	@echo "      using next = append<size>;" >> $@
	@echo "    };" >> $@

	@echo "  template<typename T, T... I>" >> $@
	@echo "    constexpr T integer_sequence<T, I...>::size;" >> $@

	@echo "  template<std::size_t... I>" >> $@
	@echo "    using index_sequence = integer_sequence<std::size_t, I...>;" >> $@

	@echo "  namespace detail" >> $@
	@echo "  {" >> $@
	@echo "    // Metafunction that generates an integer_sequence of T containing [0, N)" >> $@
	@echo "    template<typename T, T Nt, std::size_t N>" >> $@
	@echo "      struct iota" >> $@
	@echo "      {" >> $@
	@echo "	static_assert( Nt >= 0, \"N cannot be negative\" );" >> $@

	@echo "	using type = typename iota<T, Nt-1, N-1>::type::next;" >> $@
	@echo "      };" >> $@

	@echo "    // Terminal case of the recursive metafunction." >> $@
	@echo "    template<typename T, T Nt>" >> $@
	@echo "      struct iota<T, Nt, 0ul>" >> $@
	@echo "      {" >> $@
	@echo "	using type = integer_sequence<T>;" >> $@
	@echo "      };" >> $@
	@echo "  }" >> $@


	@echo "  // make_integer_sequence<T, N> is an alias for integer_sequence<T, 0,...N-1>" >> $@
	@echo "  template<typename T, T N>" >> $@
	@echo "    using make_integer_sequence = typename detail::iota<T, N, N>::type;" >> $@

	@echo "  template<int N>" >> $@
	@echo "    using make_index_sequence = make_integer_sequence<std::size_t, N>;" >> $@


	@echo "  // index_sequence_for<A, B, C> is an alias for index_sequence<0, 1, 2>" >> $@
	@echo "  template<typename... Args>" >> $@
	@echo "    using index_sequence_for = make_index_sequence<sizeof...(Args)>;" >> $@

	@echo "}  // namespace std" >> $@

	@echo "#endif" >> $@

	@echo "template<class Function, std::size_t... Indices>" >> $@
	@echo "constexpr auto make_array_helper(Function f, std::index_sequence<Indices...>) " >> $@
	@echo "-> std::array<typename std::result_of<Function(std::size_t)>::type, sizeof...(Indices)> " >> $@
	@echo "{" >> $@
	@echo "    return {{ f(Indices)... }};" >> $@
	@echo "}" >> $@

	@echo "template<int N, class Function>" >> $@
	@echo "constexpr auto make_array(Function f)" >> $@
	@echo "-> std::array<typename std::result_of<Function(std::size_t)>::type, N> " >> $@
	@echo "{" >> $@
	@echo "    return make_array_helper(f, std::make_index_sequence<N>{});    " >> $@
	@echo "}" >> $@

	@echo "constexpr uint16_t tanHelper(uint16_t i) {" >> $@
	@echo "    return static_cast<uint16_t>((256.0f * tan(i * M_PI_2 / 256.0f))); " >> $@
	@echo "}" >> $@

	@echo "constexpr uint16_t cotanHelper(uint16_t i) {" >> $@
	@echo "    return i ? static_cast<uint16_t>((256.0f / tan(i * M_PI_2 / 256.0f))) : 0; " >> $@
	@echo "}" >> $@

	@echo "constexpr uint8_t sinHelper(uint16_t i) {" >> $@
	@echo "    return static_cast<uint8_t>(256.0f * sin(i / 1024.0f * 2 * M_PI)); " >> $@
	@echo "}" >> $@

	@echo "constexpr uint8_t cosHelper(uint16_t i) {" >> $@
	@echo "    return i ? static_cast<uint8_t>(256.0f * cos(i / 1024.0f * 2 * M_PI)) : 0; " >> $@
	@echo "}" >> $@
	@echo "constexpr uint8_t nearHeightHelper(uint16_t i) {" >> $@
	@echo "    return static_cast<uint8_t>(" >> $@
	@echo "	    (INV_FACTOR_INT / (((i << 2) + MIN_DIST) >> 2)) >> 2);" >> $@
	@echo "}" >> $@
	@echo "constexpr uint8_t farHeightHelper(uint16_t i) {" >> $@
	@echo "    return static_cast<uint8_t>(" >> $@
	@echo "	    (INV_FACTOR_INT / (((i << 5) + MIN_DIST) >> 5)) >> 5);" >> $@
	@echo "}" >> $@
	@echo "constexpr uint16_t nearStepHelper(uint16_t i) {  " >> $@
	@echo "    return (256 / (((INV_FACTOR_INT / (((i * 4.0f) + MIN_DIST) / 4.0f)) / 4.0f) * 2.0f)) * 256;" >> $@
	@echo "}" >> $@
	@echo "constexpr uint16_t farStepHelper(uint16_t i) {" >> $@
	@echo "    return (256 / (((INV_FACTOR_INT / (((i * 32.0f) + MIN_DIST) / 32.0f)) / 32.0f) * 2.0f)) * 256;" >> $@
	@echo "}" >> $@
	@echo "constexpr uint16_t overflowOffsetHelper(uint16_t i) {" >> $@
	@echo "    return i == 0 ? 0 : static_cast<int16_t>(((((INV_FACTOR_INT / (float) (i / 2.0f))) - SCREEN_HEIGHT) / 2) * (256 / ((INV_FACTOR_INT / (float) (i / 2.0f)))) * 256);" >> $@
	@echo "}" >> $@
	@echo "constexpr uint16_t overflowStepHelper(uint16_t i) {" >> $@
	@echo "    return i == 0 ? 0 : (256 / ((INV_FACTOR_INT / (float) (i / 2.0f)))) * 256;" >> $@
	@echo "}" >> $@
	@echo "constexpr uint16_t deltaAngleHelper(uint16_t i) {" >> $@
	@echo "    return static_cast<int16_t>((atanf(((int16_t) i - SCREEN_WIDTH / 2.0f) / (SCREEN_WIDTH / 2.0f) * M_PI / 4)) / M_PI_2 * 256.0f) < 0 ? static_cast<int16_t>((atanf(((int16_t) i - SCREEN_WIDTH / 2.0f) / (SCREEN_WIDTH / 2.0f) * M_PI / 4)) / M_PI_2 * 256.0f) + 1024 : static_cast<int16_t>((atanf(((int16_t) i - SCREEN_WIDTH / 2.0f) / (SCREEN_WIDTH / 2.0f) * M_PI / 4)) / M_PI_2 * 256.0f);" >> $@
	@echo "}" >> $@
	@echo "constexpr auto N = 256;" >> $@
	@echo "constexpr auto g_tan = make_array<N>(tanHelper);" >> $@
	@echo "constexpr auto g_cotan = make_array<N>(cotanHelper);" >> $@
	@echo "constexpr auto g_sin = make_array<N>(sinHelper);" >> $@
	@echo "constexpr auto g_cos = make_array<N>(cosHelper);" >> $@
	@echo "constexpr auto g_nearHeight = make_array<N>(nearHeightHelper);" >> $@
	@echo "constexpr auto g_farHeight = make_array<N>(farHeightHelper);" >> $@
	@echo "constexpr auto g_nearStep = make_array<N>(nearStepHelper);" >> $@
	@echo "constexpr auto g_farStep = make_array<N>(farStepHelper);" >> $@
	@echo "constexpr auto g_overflowOffset = make_array<N>(overflowOffsetHelper);" >> $@
	@echo "constexpr auto g_overflowStep = make_array<N>(overflowStepHelper);" >> $@
	@echo "constexpr auto g_deltaAngle = make_array<SCREEN_WIDTH>(deltaAngleHelper);" >> $@


raycaster_fixed.o: raycaster_tables.h 
	$(VECHO) "  CXX\t$@\n"
	$(Q)$(CXX) -c $(CXXFLAGS) raycaster_fixed.cpp

OBJS := \
	game.o \
	raycaster_fixed.o \
	raycaster_float.o \
	renderer.o \
	main.o
deps := $(OBJS:%.o=.%.o.d)

%.o: %.cpp
	$(VECHO) "  CXX\t$@\n"
	$(Q)$(CXX) -o $@ $(CXXFLAGS) -c -MMD -MF .$@.d $<

$(BIN): $(OBJS)
	$(Q)$(CXX)  -o $@ $^ $(LDFLAGS)

clean:
	$(RM) $(BIN) $(OBJS) $(deps) raycaster_tables.h

-include $(deps)
