component eth_2p5g_lane0 is
    port(
        reset_n_i: in std_logic;
        sysbus_clk_i: in std_logic;
        axis_tx_tvalid_i: in std_logic;
        axis_tx_tlast_i: in std_logic;
        axis_tx_tkeep_i: in std_logic_vector(7 downto 0);
        axis_tx_tdata_i: in std_logic_vector(63 downto 0);
        axis_tx_tuser_i: in std_logic;
        axis_tx_tready_o: out std_logic;
        axis_rx_tvalid_o: out std_logic;
        axis_rx_tlast_o: out std_logic;
        axis_rx_tkeep_o: out std_logic_vector(7 downto 0);
        axis_rx_tdata_o: out std_logic_vector(63 downto 0);
        axis_rx_tuser_o: out std_logic;
        tx_statvec_o: out std_logic_vector(27 downto 0);
        tx_staten_o: out std_logic;
        rx_statvec_o: out std_logic_vector(27 downto 0);
        rx_staten_o: out std_logic;
        apb_psel_i: in std_logic;
        apb_paddr_i: in std_logic_vector(31 downto 0);
        apb_pwdata_i: in std_logic_vector(31 downto 0);
        apb_pwrite_i: in std_logic;
        apb_penable_i: in std_logic;
        apb_pready_o: out std_logic;
        apb_prdata_o: out std_logic_vector(31 downto 0);
        apb_pslverr_o: out std_logic;
        pad_refclkn_i: in std_logic;
        pad_refclkp_i: in std_logic;
        pad_rxn_i: in std_logic;
        pad_rxp_i: in std_logic;
        pad_txn_o: out std_logic;
        pad_txp_o: out std_logic;
        phy_pcs_clkin_i: in std_logic;
        phy_tx_clk_o: out std_logic;
        phy_rx_clk_o: out std_logic;
        debug_link_timer_short: in std_logic;
        mr_adv_ability: in std_logic_vector(15 downto 0);
        mr_an_enable: in std_logic;
        mr_main_reset: in std_logic;
        mr_restart_an: in std_logic;
        mr_an_complete: out std_logic;
        mr_lp_adv_ability: out std_logic_vector(15 downto 0);
        mr_page_rx: out std_logic;
        an_link_ok: out std_logic;
        phy_rxval_o: out std_logic;
        phy_txrdy_o: out std_logic;
        phyrdy_o: out std_logic;
        phy_link_sync_o: out std_logic;
        phy_rxidle_o: out std_logic
    );
end component;

__: eth_2p5g_lane0 port map(
    reset_n_i=>,
    sysbus_clk_i=>,
    axis_tx_tvalid_i=>,
    axis_tx_tlast_i=>,
    axis_tx_tkeep_i=>,
    axis_tx_tdata_i=>,
    axis_tx_tuser_i=>,
    axis_tx_tready_o=>,
    axis_rx_tvalid_o=>,
    axis_rx_tlast_o=>,
    axis_rx_tkeep_o=>,
    axis_rx_tdata_o=>,
    axis_rx_tuser_o=>,
    tx_statvec_o=>,
    tx_staten_o=>,
    rx_statvec_o=>,
    rx_staten_o=>,
    apb_psel_i=>,
    apb_paddr_i=>,
    apb_pwdata_i=>,
    apb_pwrite_i=>,
    apb_penable_i=>,
    apb_pready_o=>,
    apb_prdata_o=>,
    apb_pslverr_o=>,
    pad_refclkn_i=>,
    pad_refclkp_i=>,
    pad_rxn_i=>,
    pad_rxp_i=>,
    pad_txn_o=>,
    pad_txp_o=>,
    phy_pcs_clkin_i=>,
    phy_tx_clk_o=>,
    phy_rx_clk_o=>,
    debug_link_timer_short=>,
    mr_adv_ability=>,
    mr_an_enable=>,
    mr_main_reset=>,
    mr_restart_an=>,
    mr_an_complete=>,
    mr_lp_adv_ability=>,
    mr_page_rx=>,
    an_link_ok=>,
    phy_rxval_o=>,
    phy_txrdy_o=>,
    phyrdy_o=>,
    phy_link_sync_o=>,
    phy_rxidle_o=>
);
