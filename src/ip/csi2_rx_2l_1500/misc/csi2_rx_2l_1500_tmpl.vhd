component csi2_rx_2l_1500 is
    port(
        rxcsr_vcx_on_i: in std_logic;
        rxcsr_dropnull_i: in std_logic;
        pll_lock_i: in std_logic;
        sync_clk_i: in std_logic;
        sync_rst_i: in std_logic;
        ready_o: out std_logic;
        clk_byte_o: out std_logic;
        clk_byte_hs_o: out std_logic;
        clk_byte_fr_i: in std_logic;
        reset_n_i: in std_logic;
        reset_byte_fr_n_i: in std_logic;
        clk_p_io: inout std_logic;
        clk_n_io: inout std_logic;
        d_p_io: inout std_logic_vector(1 downto 0);
        d_n_io: inout std_logic_vector(1 downto 0);
        lp_d_rx_p_o: out std_logic_vector(1 downto 0);
        lp_d_rx_n_o: out std_logic_vector(1 downto 0);
        bd_o: out std_logic_vector(15 downto 0);
        hs_sync_o: out std_logic;
        payload_en_o: out std_logic;
        payload_o: out std_logic_vector(15 downto 0);
        dt_o: out std_logic_vector(5 downto 0);
        vc_o: out std_logic_vector(1 downto 0);
        vcx_o: out std_logic_vector(1 downto 0);
        wc_o: out std_logic_vector(15 downto 0);
        ecc_o: out std_logic_vector(5 downto 0);
        payload_bytevld_o: out std_logic_vector(7 downto 0);
        payload_crc_o: out std_logic_vector(15 downto 0);
        payload_crcvld_o: out std_logic;
        ecc_check_o: out std_logic;
        ecc_byte_error_o: out std_logic;
        ecc_1bit_error_o: out std_logic;
        ecc_2bit_error_o: out std_logic;
        dphy_rxdatawidth_hs_o: out std_logic_vector(1 downto 0);
        dphy_cfg_num_lanes_o: out std_logic_vector(1 downto 0);
        ref_dt_i: in std_logic_vector(5 downto 0);
        tx_rdy_i: in std_logic;
        sp_en_o: out std_logic;
        lp_en_o: out std_logic;
        lp_av_en_o: out std_logic
    );
end component;

__: csi2_rx_2l_1500 port map(
    rxcsr_vcx_on_i=>,
    rxcsr_dropnull_i=>,
    pll_lock_i=>,
    sync_clk_i=>,
    sync_rst_i=>,
    ready_o=>,
    clk_byte_o=>,
    clk_byte_hs_o=>,
    clk_byte_fr_i=>,
    reset_n_i=>,
    reset_byte_fr_n_i=>,
    clk_p_io=>,
    clk_n_io=>,
    d_p_io=>,
    d_n_io=>,
    lp_d_rx_p_o=>,
    lp_d_rx_n_o=>,
    bd_o=>,
    hs_sync_o=>,
    payload_en_o=>,
    payload_o=>,
    dt_o=>,
    vc_o=>,
    vcx_o=>,
    wc_o=>,
    ecc_o=>,
    payload_bytevld_o=>,
    payload_crc_o=>,
    payload_crcvld_o=>,
    ecc_check_o=>,
    ecc_byte_error_o=>,
    ecc_1bit_error_o=>,
    ecc_2bit_error_o=>,
    dphy_rxdatawidth_hs_o=>,
    dphy_cfg_num_lanes_o=>,
    ref_dt_i=>,
    tx_rdy_i=>,
    sp_en_o=>,
    lp_en_o=>,
    lp_av_en_o=>
);
