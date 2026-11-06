component lpddr4_mc is
    port(
        pll_refclk_i: in std_logic;
        pll_rst_n_i: in std_logic;
        areset_n_i: in std_logic;
        aclk_i: in std_logic;
        rst_n_i: in std_logic;
        pclk_i: in std_logic;
        preset_n_i: in std_logic;
        pll_lock_o: out std_logic;
        sclk_o: out std_logic;
        irq_o: out std_logic;
        init_done_o: out std_logic;
        trn_err_o: out std_logic;
        axi_arvalid_i: in std_logic;
        axi_arid_i: in std_logic_vector(3 downto 0);
        axi_arlen_i: in std_logic_vector(7 downto 0);
        axi_arburst_i: in std_logic_vector(1 downto 0);
        axi_araddr_i: in std_logic_vector(29 downto 0);
        axi_arqos_i: in std_logic_vector(3 downto 0);
        axi_arsize_i: in std_logic_vector(2 downto 0);
        axi_arready_o: out std_logic;
        axi_rdata_o: out std_logic_vector(127 downto 0);
        axi_rresp_o: out std_logic_vector(1 downto 0);
        axi_rid_o: out std_logic_vector(3 downto 0);
        axi_rvalid_o: out std_logic;
        axi_rlast_o: out std_logic;
        axi_rready_i: in std_logic;
        axi_awvalid_i: in std_logic;
        axi_awid_i: in std_logic_vector(3 downto 0);
        axi_awlen_i: in std_logic_vector(7 downto 0);
        axi_awburst_i: in std_logic_vector(1 downto 0);
        axi_awaddr_i: in std_logic_vector(29 downto 0);
        axi_awqos_i: in std_logic_vector(3 downto 0);
        axi_awsize_i: in std_logic_vector(2 downto 0);
        axi_awready_o: out std_logic;
        axi_wvalid_i: in std_logic;
        axi_wdata_i: in std_logic_vector(127 downto 0);
        axi_wstrb_i: in std_logic_vector(15 downto 0);
        axi_wlast_i: in std_logic;
        axi_wready_o: out std_logic;
        axi_bvalid_o: out std_logic;
        axi_bready_i: in std_logic;
        axi_bresp_o: out std_logic_vector(1 downto 0);
        axi_bid_o: out std_logic_vector(3 downto 0);
        apb_penable_i: in std_logic;
        apb_psel_i: in std_logic;
        apb_pwrite_i: in std_logic;
        apb_paddr_i: in std_logic_vector(11 downto 0);
        apb_pwdata_i: in std_logic_vector(31 downto 0);
        apb_pready_o: out std_logic;
        apb_pslverr_o: out std_logic;
        apb_prdata_o: out std_logic_vector(31 downto 0);
        ddr_ck_o: out std_logic_vector(0 to 0);
        ddr_cke_o: out std_logic_vector(0 to 0);
        ddr_cs_o: out std_logic_vector(0 to 0);
        ddr_ca_o: out std_logic_vector(5 downto 0);
        ddr_reset_n_o: out std_logic;
        ddr_dq_io: inout std_logic_vector(15 downto 0);
        ddr_dqs_io: inout std_logic_vector(1 downto 0);
        ddr_dmi_io: inout std_logic_vector(1 downto 0)
    );
end component;

__: lpddr4_mc port map(
    pll_refclk_i=>,
    pll_rst_n_i=>,
    areset_n_i=>,
    aclk_i=>,
    rst_n_i=>,
    pclk_i=>,
    preset_n_i=>,
    pll_lock_o=>,
    sclk_o=>,
    irq_o=>,
    init_done_o=>,
    trn_err_o=>,
    axi_arvalid_i=>,
    axi_arid_i=>,
    axi_arlen_i=>,
    axi_arburst_i=>,
    axi_araddr_i=>,
    axi_arqos_i=>,
    axi_arsize_i=>,
    axi_arready_o=>,
    axi_rdata_o=>,
    axi_rresp_o=>,
    axi_rid_o=>,
    axi_rvalid_o=>,
    axi_rlast_o=>,
    axi_rready_i=>,
    axi_awvalid_i=>,
    axi_awid_i=>,
    axi_awlen_i=>,
    axi_awburst_i=>,
    axi_awaddr_i=>,
    axi_awqos_i=>,
    axi_awsize_i=>,
    axi_awready_o=>,
    axi_wvalid_i=>,
    axi_wdata_i=>,
    axi_wstrb_i=>,
    axi_wlast_i=>,
    axi_wready_o=>,
    axi_bvalid_o=>,
    axi_bready_i=>,
    axi_bresp_o=>,
    axi_bid_o=>,
    apb_penable_i=>,
    apb_psel_i=>,
    apb_pwrite_i=>,
    apb_paddr_i=>,
    apb_pwdata_i=>,
    apb_pready_o=>,
    apb_pslverr_o=>,
    apb_prdata_o=>,
    ddr_ck_o=>,
    ddr_cke_o=>,
    ddr_cs_o=>,
    ddr_ca_o=>,
    ddr_reset_n_o=>,
    ddr_dq_io=>,
    ddr_dqs_io=>,
    ddr_dmi_io=>
);
