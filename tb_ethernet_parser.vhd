-- ============================================================
-- Testbench : tb_ethernet_parser.vhd
-- Xilinx ISE 9 / ISim
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ethernet_parser is
end tb_ethernet_parser;

architecture Behavioral of tb_ethernet_parser is

    component ethernet_parser
        Port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            data_in     : in  STD_LOGIC_VECTOR(7 downto 0);
            data_valid  : in  STD_LOGIC;
            frame_start : in  STD_LOGIC;
            mac_dst     : out STD_LOGIC_VECTOR(47 downto 0);
            mac_src     : out STD_LOGIC_VECTOR(47 downto 0);
            frame_type  : out STD_LOGIC_VECTOR(15 downto 0);
            is_ipv4     : out STD_LOGIC;
            is_arp      : out STD_LOGIC;
            is_ipv6     : out STD_LOGIC;
            is_vlan     : out STD_LOGIC;
            is_unknown  : out STD_LOGIC;
            frame_done  : out STD_LOGIC
        );
    end component;

    signal clk         : STD_LOGIC := '0';
    signal rst         : STD_LOGIC := '1';
    signal data_in     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal data_valid  : STD_LOGIC := '0';
    signal frame_start : STD_LOGIC := '0';
    signal mac_dst     : STD_LOGIC_VECTOR(47 downto 0);
    signal mac_src     : STD_LOGIC_VECTOR(47 downto 0);
    signal frame_type  : STD_LOGIC_VECTOR(15 downto 0);
    signal is_ipv4     : STD_LOGIC;
    signal is_arp      : STD_LOGIC;
    signal is_ipv6     : STD_LOGIC;
    signal is_vlan     : STD_LOGIC;
    signal is_unknown  : STD_LOGIC;
    signal frame_done  : STD_LOGIC;

    constant CLK_PERIOD : time := 10 ns;

    -- Procedure pour envoyer 1 octet
    procedure send_byte(
        constant b      : in STD_LOGIC_VECTOR(7 downto 0);
        signal clk      : in STD_LOGIC;
        signal data_in  : out STD_LOGIC_VECTOR(7 downto 0);
        signal data_valid : out STD_LOGIC
    ) is
    begin
        data_in    <= b;
        data_valid <= '1';
        wait until rising_edge(clk);
    end procedure;

begin

    UUT: ethernet_parser
        port map (
            clk => clk, rst => rst,
            data_in => data_in, data_valid => data_valid,
            frame_start => frame_start,
            mac_dst => mac_dst, mac_src => mac_src,
            frame_type => frame_type,
            is_ipv4 => is_ipv4, is_arp => is_arp,
            is_ipv6 => is_ipv6, is_vlan => is_vlan,
            is_unknown => is_unknown, frame_done => frame_done
        );

    clk_process: process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    stim_process: process
    begin
        -- RESET
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        wait for 20 ns;
        wait until rising_edge(clk);

        -- ================================================
        -- TEST 1 : Trame ARP
        -- EtherType = 0x0806
        -- ================================================
        report "=== TEST 1 : Envoi trame ARP ===";

        -- Pulse frame_start
        frame_start <= '1';
        wait until rising_edge(clk);
        frame_start <= '0';

        -- MAC DST : FF:FF:FF:FF:FF:FF
        send_byte(x"FF", clk, data_in, data_valid);
        send_byte(x"FF", clk, data_in, data_valid);
        send_byte(x"FF", clk, data_in, data_valid);
        send_byte(x"FF", clk, data_in, data_valid);
        send_byte(x"FF", clk, data_in, data_valid);
        send_byte(x"FF", clk, data_in, data_valid);
        -- MAC SRC : AA:BB:CC:DD:EE:FF
        send_byte(x"AA", clk, data_in, data_valid);
        send_byte(x"BB", clk, data_in, data_valid);
        send_byte(x"CC", clk, data_in, data_valid);
        send_byte(x"DD", clk, data_in, data_valid);
        send_byte(x"EE", clk, data_in, data_valid);
        send_byte(x"FF", clk, data_in, data_valid);
        -- EtherType ARP : 08 06
        send_byte(x"08", clk, data_in, data_valid);
        send_byte(x"06", clk, data_in, data_valid);

        data_valid <= '0';

        -- Attendre frame_done
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        if is_arp = '1' then
            report "OK : Trame ARP detectee correctement !";
        else
            report "ERREUR : Trame ARP non detectee !" severity error;
        end if;

        wait for 50 ns;

        -- ================================================
        -- TEST 2 : Trame IPv4
        -- EtherType = 0x0800
        -- ================================================
        report "=== TEST 2 : Envoi trame IPv4 ===";

        frame_start <= '1';
        wait until rising_edge(clk);
        frame_start <= '0';

        -- MAC DST : 00:11:22:33:44:55
        send_byte(x"00", clk, data_in, data_valid);
        send_byte(x"11", clk, data_in, data_valid);
        send_byte(x"22", clk, data_in, data_valid);
        send_byte(x"33", clk, data_in, data_valid);
        send_byte(x"44", clk, data_in, data_valid);
        send_byte(x"55", clk, data_in, data_valid);
        -- MAC SRC : 66:77:88:99:AA:BB
        send_byte(x"66", clk, data_in, data_valid);
        send_byte(x"77", clk, data_in, data_valid);
        send_byte(x"88", clk, data_in, data_valid);
        send_byte(x"99", clk, data_in, data_valid);
        send_byte(x"AA", clk, data_in, data_valid);
        send_byte(x"BB", clk, data_in, data_valid);
        -- EtherType IPv4 : 08 00
        send_byte(x"08", clk, data_in, data_valid);
        send_byte(x"00", clk, data_in, data_valid);

        data_valid <= '0';

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        if is_ipv4 = '1' then
            report "OK : Trame IPv4 detectee correctement !";
        else
            report "ERREUR : Trame IPv4 non detectee !" severity error;
        end if;

        wait for 50 ns;

        -- ================================================
        -- TEST 3 : Trame VLAN 802.1Q
        -- EtherType = 0x8100
        -- ================================================
        report "=== TEST 3 : Envoi trame VLAN 802.1Q ===";

        frame_start <= '1';
        wait until rising_edge(clk);
        frame_start <= '0';

        -- MAC DST : 01:00:5E:00:00:01
        send_byte(x"01", clk, data_in, data_valid);
        send_byte(x"00", clk, data_in, data_valid);
        send_byte(x"5E", clk, data_in, data_valid);
        send_byte(x"00", clk, data_in, data_valid);
        send_byte(x"00", clk, data_in, data_valid);
        send_byte(x"01", clk, data_in, data_valid);
        -- MAC SRC : DE:AD:BE:EF:CA:FE
        send_byte(x"DE", clk, data_in, data_valid);
        send_byte(x"AD", clk, data_in, data_valid);
        send_byte(x"BE", clk, data_in, data_valid);
        send_byte(x"EF", clk, data_in, data_valid);
        send_byte(x"CA", clk, data_in, data_valid);
        send_byte(x"FE", clk, data_in, data_valid);
        -- EtherType VLAN : 81 00
        send_byte(x"81", clk, data_in, data_valid);
        send_byte(x"00", clk, data_in, data_valid);

        data_valid <= '0';

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        if is_vlan = '1' then
            report "OK : Trame VLAN detectee correctement !";
        else
            report "ERREUR : Trame VLAN non detectee !" severity error;
        end if;

        wait for 50 ns;
        report "=== FIN SIMULATION ===";
        wait;
    end process;

end Behavioral;