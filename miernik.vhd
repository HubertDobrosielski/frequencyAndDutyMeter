LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY miernik IS
  PORT (
    ck : IN STD_LOGIC; -- sygnał zegarowy 10 MHz
    in_signal : IN STD_LOGIC; -- sygnał mierzony
    freq : OUT STD_LOGIC_VECTOR(16 DOWNTO 0); -- wyjście wyświetlające częstotliwość (max 100 kHz -> 17 bit)
    -- count_ck_out : out std_logic_vector(13 downto 0); -- licznik pomocniczy (długość testu = 10000 -> 14 bit) !!!
    -- count_in_out : out std_logic_vector(6 downto 0); -- licznik pomocniczy (max 100 -> 7 bit)
    duty : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- (zakres 0-100% -> 7 bit)
  );

END;

ARCHITECTURE seq OF miernik IS

  SIGNAL s_count_ck : STD_LOGIC_VECTOR(13 DOWNTO 0); -- łącznik pomiędzy procesami CK_COUNT i COMPARE
  SIGNAL s_count_in : STD_LOGIC_VECTOR(6 DOWNTO 0); -- łącznik pomiędzy procesami IN_COUNT i COMPARE
  SIGNAL reset_count_in : STD_LOGIC;

  CONSTANT ck_freq : NATURAL := 10000000; -- częstotliwość zegara
  CONSTANT max_in_freq : NATURAL := 100000; -- maksymalna częstotliwośc sygnału mierzonego - 100 kHz

  CONSTANT test_len : NATURAL := 10000; -- długość pomiaru

  CONSTANT const_f : NATURAL := (ck_freq/test_len); -- stała do skalowania częstotliwości [freq = const_f * counter_in]
  CONSTANT max_count_in : NATURAL := (max_in_freq/const_f); -- maksymalna ilość cykli sygnału wejściowego (do zmiany)
  CONSTANT const_d : NATURAL := (test_len/100); -- stała do skalowania wypełnienia, (długość pomiaru/100%), (((teraz każde 100 impulsów = 1%)))
BEGIN
  -- FREUQENCY
  --
  -- ************************************************************************************************************
  -- proces zlicza impulsy sygnału zegarowego do momentu oosiągnięcia zamierzonej długości pomiaru (ilości próbek)

  ck_count : PROCESS (ck)
    VARIABLE count_ck : INTEGER RANGE 0 TO (test_len + 1) := 0; -- licznik impulsów zegara
  BEGIN
    IF rising_edge(ck) THEN
      count_ck := count_ck + 1;
      IF count_ck = (test_len + 1) THEN
        count_ck := 0;
        reset_count_in <= '0';
      ELSE
        reset_count_in <= '1';
      END IF;
    END IF;
    s_count_ck <= STD_LOGIC_VECTOR(to_unsigned(count_ck, 14));
  END PROCESS;
  -- ************************************************************************************************************

  --

  -- ************************************************************************************************************
  -- proces zlicza impulsy sygnału mierzonego do momentu gdy process CK_COUNT zliczy zamierzoną ilość próbek

  in_count : PROCESS (reset_count_in, in_signal) -- najmniejszy możliwy sygnał do zmierzenia - 1 kHz do 10khz
    VARIABLE count_in : INTEGER RANGE 0 TO (max_count_in + 1) := 0;
  BEGIN
    IF reset_count_in = '1' THEN
      IF ((rising_edge(in_signal))) THEN
        count_in := count_in + 1;
      END IF;
    ELSE
      count_in := 0;
    END IF;
    s_count_in <= STD_LOGIC_VECTOR(to_unsigned(count_in, 7));
  END PROCESS;
  -- ************************************************************************************************************

  --

  -- ************************************************************************************************************
  -- po zliczeniu przez CK_COUNT określonej ilości próbek process ten mnoż ilość impulsów sygnału wejściowego
  -- przez stałą CONST_F, uzyskiwana jest w ten sposób częstotliwość sygnału

  compare : PROCESS (ck, s_count_ck, s_count_in)
    VARIABLE count_ck : INTEGER RANGE 0 TO test_len := 0;
    VARIABLE count_in : INTEGER RANGE 0 TO max_count_in := 0;
    VARIABLE out_freq : INTEGER RANGE 0 TO max_in_freq := 0;
  BEGIN
    IF rising_edge(ck) THEN
      count_ck := to_integer(unsigned(s_count_ck));
      count_in := to_integer(unsigned(s_count_in));
      IF count_ck = test_len THEN
        out_freq := count_in * const_f;
      END IF;
      freq <= STD_LOGIC_VECTOR(to_unsigned(out_freq, 17));
    END IF;
  END PROCESS;
  -- ************************************************************************************************************

  --

  -- ************************************************************************************************************
  -- proces obsługujący pomiar wypełnienia sygnału

  duty_proc : PROCESS (ck, in_signal, s_count_in, reset_count_in)
    VARIABLE counter : INTEGER RANGE 0 TO (const_d + 1) := 0; -- zmienna zliczająca impulsy zegara podczas gdy sygnał mierzony ma wartość '1'
    VARIABLE n_count_duty : INTEGER RANGE 0 TO 200 := 0; -- zmienna reprezentująca wynik współczynnika wypwłnienia w %
    VARIABLE c_count_duty : INTEGER RANGE 0 TO 200 := 0;
    VARIABLE reset_duty : STD_LOGIC := '0';
  BEGIN
    IF (reset_count_in = '1') THEN -- asynchroniczny reset liczników

      IF (rising_edge(ck)) THEN -- podczas każdego zbocza narastającego zegara

        IF reset_duty = '1' THEN -- reset licznika % wypełnienia
          n_count_duty := 0;
          reset_duty := '0';
        END IF;

        IF ((in_signal = '1')) THEN -- jeśli sygnał wejściowy jest pozytywny
          counter := (counter + 1); -- następuje zliczanie impulsów zegara
          IF (counter = const_d) THEN -- gdy zostanie zliczona odpowiedznia ilość impulsów [const_d]
            n_count_duty := (n_count_duty + 1); -- do licznika % wypełnienia dodajemy 1%
            counter := 0; -- i zerujemy licznik
          END IF;
        END IF;
      END IF;
    ELSE
      c_count_duty := n_count_duty; -- stan licznika % jest zapamiętywany
      -- n_count_duty := 0;
      reset_duty := '1'; -- teraz można zresetować licznik % wypełnienia
      counter := 0; -- zerowanie licznika
    END IF;

    duty <= STD_LOGIC_VECTOR(to_unsigned(c_count_duty, 7));
  END PROCESS;
  -- ************************************************************************************************************

  --
END seq;