-- ============================================================
-- Projet : Analyseur de Trames Ethernet
-- Fichier : ethernet_parser.vhd
-- Xilinx ISE 9 / ISim
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ethernet_parser is
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
end ethernet_parser;

architecture Behavioral of ethernet_parser is

    signal byte_count    : INTEGER range 0 to 13 := 0;
    signal active        : STD_LOGIC := '0';
    signal reg_mac_dst   : STD_LOGIC_VECTOR(47 downto 0) := (others => '0');
    signal reg_mac_src   : STD_LOGIC_VECTOR(47 downto 0) := (others => '0');
    signal reg_etype_hi  : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal reg_etype_lo  : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal ethertype     : STD_LOGIC_VECTOR(15 downto 0);

begin

    ethertype <= reg_etype_hi & reg_etype_lo;

    process(clk, rst)
    begin
        if rst = '1' then
            byte_count   <= 0;
            active       <= '0';
            frame_done   <= '0';
            is_ipv4      <= '0';
            is_arp       <= '0';
            is_ipv6      <= '0';
            is_vlan      <= '0';
            is_unknown   <= '0';
            reg_mac_dst  <= (others => '0');
            reg_mac_src  <= (others => '0');
            reg_etype_hi <= (others => '0');
            reg_etype_lo <= (others => '0');

        elsif rising_edge(clk) then
            frame_done <= '0';

            if frame_start = '1' then
                active     <= '1';
                byte_count <= 0;
                is_ipv4    <= '0';
                is_arp     <= '0';
                is_ipv6    <= '0';
                is_vlan    <= '0';
                is_unknown <= '0';
            end if;

            if active = '1' and data_valid = '1' then

                if byte_count = 0 then reg_mac_dst(47 downto 40) <= data_in;
                elsif byte_count = 1 then reg_mac_dst(39 downto 32) <= data_in;
                elsif byte_count = 2 then reg_mac_dst(31 downto 24) <= data_in;
                elsif byte_count = 3 then reg_mac_dst(23 downto 16) <= data_in;
                elsif byte_count = 4 then reg_mac_dst(15 downto 8)  <= data_in;
                elsif byte_count = 5 then reg_mac_dst(7 downto 0)   <= data_in;
                elsif byte_count = 6  then reg_mac_src(47 downto 40) <= data_in;
                elsif byte_count = 7  then reg_mac_src(39 downto 32) <= data_in;
                elsif byte_count = 8  then reg_mac_src(31 downto 24) <= data_in;
                elsif byte_count = 9  then reg_mac_src(23 downto 16) <= data_in;
                elsif byte_count = 10 then reg_mac_src(15 downto 8)  <= data_in;
                elsif byte_count = 11 then reg_mac_src(7 downto 0)   <= data_in;
                elsif byte_count = 12 then reg_etype_hi <= data_in;
                elsif byte_count = 13 then
                    reg_etype_lo <= data_in;
                    active       <= '0';
                    frame_done   <= '1';

                    if (reg_etype_hi & data_in) = x"0800" then
                        is_ipv4 <= '1';
                    elsif (reg_etype_hi & data_in) = x"0806" then
                        is_arp  <= '1';
                    elsif (reg_etype_hi & data_in) = x"86DD" then
                        is_ipv6 <= '1';
                    elsif (reg_etype_hi & data_in) = x"8100" then
                        is_vlan <= '1';
                    else
                        is_unknown <= '1';
                    end if;
                end if;

                if byte_count < 13 then
                    byte_count <= byte_count + 1;
                end if;

            end if;
        end if;
    end process;

    mac_dst    <= reg_mac_dst;
    mac_src    <= reg_mac_src;
    frame_type <= ethertype;

end Behavioral;