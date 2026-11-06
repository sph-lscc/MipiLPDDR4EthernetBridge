#!/usr/bin/env python3
"""Generate the SVG block diagram in docs/images/.

Usage:  python3 scripts/make_diagrams.py
Plain SVG 1.1, no external fonts or scripts, explicit white background so the
image reads the same in light and dark repository viewers. The drawing helper
follows ../MIPI2Ethernet/scripts/make_diagrams.py so both projects look alike.

Content: docs/design_proposal.md, Sections 4 to 6 (revision 3) and the pinout
check build (Section 14).
"""
from pathlib import Path
from xml.sax.saxutils import escape

OUT = Path(__file__).resolve().parent.parent / "docs" / "images"

C_DATA = "#1f6feb"     # video / packet / memory data path
C_CTRL = "#c45f00"     # control and set-up path
C_CLK = "#1a7f37"      # clocks
C_TEXT = "#1f2328"
C_MUTED = "#59636e"
C_BOX = "#ffffff"
C_LINE = "#59636e"
DOMAIN = {             # clock-domain tints
    "byte": "#fff4e5",
    "axi": "#eaf2ff",
    "ddr": "#f3eaff",
    "eth": "#eefbf1",
    "ctl": "#fdf0f0",
    "clk": "#f6f8fa",
    "ext": "#f6f8fa",
}


class Svg:
    def __init__(self, w, h, title):
        self.w, self.h = w, h
        self.items = []
        self.title = title

    def add(self, s):
        self.items.append(s)

    def text(self, x, y, s, size=13, weight="normal", fill=C_TEXT, anchor="start"):
        self.add(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" '
                 f'text-anchor="{anchor}">{escape(s)}</text>')

    def domain(self, x, y, w, h, tint, label, dashed=True):
        dash = ' stroke-dasharray="6 4"' if dashed else ""
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{tint}" '
                 f'stroke="{C_LINE}" stroke-width="1"{dash}/>')
        self.text(x + 12, y + 20, label, size=12, weight="bold", fill=C_MUTED)

    def block(self, x, y, w, h, name, lines=(), tag="", fill=C_BOX):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{fill}" '
                 f'stroke="{C_TEXT}" stroke-width="1.2"/>')
        self.text(x + w / 2, y + 20, name, size=13, weight="bold", anchor="middle")
        for i, l in enumerate(lines):
            self.text(x + w / 2, y + 37 + 15 * i, l, size=11, fill=C_MUTED, anchor="middle")
        if tag:
            tw = 10 + 7 * len(tag)
            self.add(f'<rect x="{x + w - tw - 4}" y="{y - 9}" width="{tw}" height="16" rx="3" '
                     f'fill="{C_TEXT}"/>')
            self.text(x + w - tw / 2 - 4, y + 3, tag, size=10, weight="bold", fill="#ffffff",
                      anchor="middle")

    def path(self, pts, color, width=2.0, dashed=False, arrow=True, both=False):
        d = "M " + " L ".join(f"{x} {y}" for x, y in pts)
        dash = ' stroke-dasharray="6 4"' if dashed else ""
        mid = {C_DATA: "d", C_CTRL: "c", C_CLK: "k"}[color]
        end = f' marker-end="url(#a{mid})"' if arrow else ""
        start = f' marker-start="url(#s{mid})"' if both else ""
        self.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}"'
                 f'{dash}{end}{start}/>')

    def label(self, x, y, s, color, anchor="start", size=11):
        self.text(x, y, s, size=size, fill=color, anchor=anchor)

    def write(self, name):
        defs = []
        for key, col in (("d", C_DATA), ("c", C_CTRL), ("k", C_CLK)):
            defs.append(f'<marker id="a{key}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" '
                        f'markerHeight="7" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="{col}"/></marker>')
            defs.append(f'<marker id="s{key}" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" '
                        f'markerHeight="7" orient="auto"><path d="M10 0 L0 5 L10 10 z" fill="{col}"/></marker>')
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}" font-family="Helvetica, Arial, sans-serif">\n'
               f'<title>{escape(self.title)}</title>\n<defs>{"".join(defs)}</defs>\n'
               f'<rect width="100%" height="100%" fill="#ffffff"/>\n' + "\n".join(self.items) + "\n</svg>\n")
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / name).write_text(svg, encoding="utf-8")
        print(OUT / name)


def legend(s, x, y, entries):
    for i, (col, dashed, txt) in enumerate(entries):
        yy = y + 18 * i
        s.path([(x, yy), (x + 36, yy)], col, dashed=dashed)
        s.label(x + 44, yy + 4, txt, C_TEXT)


def block_diagram():
    s = Svg(1500, 960, "MIPI CSI-2 to 2.5GbE bridge with LPDDR4 buffer - block diagram")
    s.text(20, 30, "MIPI CSI-2 to 2.5GbE UDP bridge with LPDDR4 buffer", size=18, weight="bold")
    s.text(20, 50, "CertusPro-NX LFCPNX-100-9CBG256I  -  design proposal revision 3  -  "
                   "IP = Lattice IP, M2E = derived from MIPI2Ethernet, new = new RTL",
           size=12, fill=C_MUTED)

    # ---- FPGA outline ------------------------------------------------------
    s.domain(200, 70, 1060, 740, "#ffffff", "FPGA  LFCPNX-100-9CBG256I", dashed=False)

    # ---- clock domains -----------------------------------------------------
    s.domain(220, 100, 240, 300, DOMAIN["byte"], "byte_clk 187.5 MHz")
    s.domain(480, 100, 330, 430, DOMAIN["axi"], "aclk 150 MHz (AXI4, 128-bit)")
    s.domain(480, 550, 330, 170, DOMAIN["ddr"], "sclk 133.33 MHz")
    s.domain(830, 100, 240, 430, DOMAIN["eth"], "PCS clocks 156.25 MHz")
    s.domain(830, 550, 410, 170, DOMAIN["ctl"], "pclk 50 MHz (set-up, no CPU)")
    s.domain(220, 550, 240, 200, DOMAIN["clk"], "Clocking")

    # ---- external devices --------------------------------------------------
    s.block(20, 150, 150, 90, "Camera sensor", ["MIPI CSI-2", "2 lanes x 1.5 Gbps", "I2C set-up"],
            fill=DOMAIN["ext"])
    s.block(500, 840, 300, 90, "LPDDR4  MT53E512M16D1",
            ["8 Gb, x16, single rank", "1066 Mbps, VDDQ 1.1 V", "frame FIFO (ring buffer)"],
            fill=DOMAIN["ext"])
    s.block(1290, 395, 180, 100, "2.5GBASE-T PHY",
            ["external PHY", "2500BASE-X host side", "link fixed at 2.5 Gbps"], fill=DOMAIN["ext"])
    s.block(1290, 560, 180, 60, "RJ45 / host", ["UDP stream, MTU 1500"], fill=DOMAIN["ext"])

    # ---- byte_clk domain ---------------------------------------------------
    s.block(240, 150, 200, 90, "u_dphy", ["csi2_rx_2l_1500", "dphy_rx 2.2.0, soft D-PHY",
                                          "CSI-2 parser, fixed DT/VC"], tag="IP")
    s.block(240, 290, 200, 90, "u_cap", ["CSI-2 line capture", "16 -> 128-bit packing",
                                         "line descriptors"], tag="M2E")

    # ---- aclk domain ---------------------------------------------------------
    s.block(500, 150, 130, 90, "u_wfifo", ["async FIFO", "byte_clk -> aclk", "data + descriptors"],
            tag="new")
    s.block(660, 150, 130, 90, "u_ring", ["ring-buffer", "manager: pointers,", "drop whole frames"],
            tag="new")
    s.block(500, 290, 130, 90, "u_wdma", ["write DMA", "AXI4 bursts", "up to 64 beats"], tag="new")
    s.block(660, 290, 130, 90, "u_rdma", ["read DMA", "AXI4 bursts", "lines in order"], tag="new")
    s.block(520, 430, 240, 80, "u_axi_arb", ["AXI4 write / read arbitration",
                                             "128-bit, about 5.4 Gbps peak load"], tag="new")

    # ---- sclk domain -------------------------------------------------------
    s.block(540, 590, 220, 100, "u_mc", ["lpddr4_mc", "memory_controller 2.7.1",
                                         "x16, 1066 Mbps (533 MHz)", "AXI4 slave, gear 8"], tag="IP")

    # ---- PCS clock domain --------------------------------------------------
    s.block(850, 150, 200, 80, "u_rfifo", ["async FIFO", "aclk -> PCS TX clock"], tag="new")
    s.block(850, 260, 200, 100, "u_udp", ["UDP/IPv4 packetizer", "32-byte stream header",
                                          "ARP and ping replies", "static IP/MAC/port"], tag="M2E")
    s.block(850, 400, 200, 100, "u_eth", ["eth_2p5g_lane0", "eth_2p5g 1.2.0",
                                          "MAC + 2500BASE-X PCS", "SERDES lane 0"], tag="IP")

    # ---- set-up domain -----------------------------------------------------
    s.block(850, 590, 180, 100, "u_i2c_init", ["I2C master", "fixed sensor", "register list"], tag="new")
    s.block(1045, 590, 180, 100, "u_mdio_init", ["MDIO master", "fixed PHY", "register list"], tag="new")

    # ---- clocking ------------------------------------------------------------
    s.label(235, 600, "osc_clk 150 MHz (internal)", C_CLK)
    s.label(235, 616, "  D-PHY sync, PCS calibration", C_MUTED)
    s.label(235, 638, "sys_pll -> aclk 150, pclk 50 MHz", C_CLK)
    s.label(235, 660, "100 MHz HCSL -> LPDDR4 PLL", C_CLK)
    s.label(235, 676, "  ball N9/M9 (PCLKT4_1)", C_MUTED)
    s.label(235, 698, "156.25 MHz -> SERDES quad", C_CLK)
    s.label(235, 714, "  ball D10/E10 (SDQ0_REFCLK)", C_MUTED)
    s.label(235, 736, "byte_clk from MIPI clock lane", C_CLK)

    # ---- data path ---------------------------------------------------------
    s.path([(170, 195), (240, 195)], C_DATA)                                   # camera -> dphy
    s.path([(340, 240), (340, 290)], C_DATA)                                   # dphy -> cap
    s.path([(440, 335), (470, 335), (470, 195), (500, 195)], C_DATA)          # cap -> wfifo
    s.path([(565, 240), (565, 290)], C_DATA)                                   # wfifo -> wdma
    s.path([(565, 380), (565, 430)], C_DATA)                                   # wdma -> arb
    s.path([(725, 430), (725, 380)], C_DATA)                                   # arb -> rdma
    s.path([(700, 510), (700, 590)], C_DATA, both=True)                        # arb <-> mc
    s.label(708, 540, "AXI4", C_DATA)
    s.path([(650, 690), (650, 840)], C_DATA, both=True)                        # mc <-> LPDDR4
    s.path([(790, 335), (815, 335), (815, 190), (850, 190)], C_DATA)          # rdma -> rfifo
    s.path([(950, 230), (950, 260)], C_DATA)                                   # rfifo -> udp
    s.path([(950, 360), (950, 400)], C_DATA)                                   # udp -> eth
    s.path([(1050, 445), (1290, 445)], C_DATA, both=True)                      # eth <-> PHY
    s.path([(1380, 495), (1380, 560)], C_DATA, both=True)                      # PHY <-> RJ45

    # ---- control path ------------------------------------------------------
    s.path([(630, 320), (645, 320), (645, 215), (660, 215)], C_CTRL, dashed=True)   # wdma -> ring
    s.path([(725, 240), (725, 290)], C_CTRL, dashed=True)                           # ring -> rdma
    s.path([(940, 690), (940, 795), (60, 795), (60, 240)], C_CTRL, dashed=True)     # i2c -> camera
    s.path([(1225, 640), (1485, 640), (1485, 445), (1470, 445)], C_CTRL, dashed=True)  # mdio -> PHY

    # ---- pin and interface annotations --------------------------------------
    s.label(70, 268, "Bank 5, 1.2 V", C_TEXT, size=11)
    s.label(70, 284, "CLK R14/R13", C_MUTED)
    s.label(70, 300, "D0 P14/P13", C_MUTED)
    s.label(70, 316, "D1 N12/P12", C_MUTED)
    s.label(660, 742, "Banks 3 + 4, 1.1 V (LVSTL)", C_TEXT)
    s.label(660, 758, "DQ[15:0], DQS[1:0], DMI[1:0]: bank 3", C_MUTED)
    s.label(660, 774, "CA[5:0], CK, CKE, CS, RESET_N: bank 4", C_MUTED)
    s.label(820, 860, "Ball R5 (VREF3_1) reserved;", C_MUTED)
    s.label(820, 876, "DQ uses the internal, trained VREF", C_MUTED)
    s.label(1075, 432, "2500BASE-X, 3.125 Gbaud", C_DATA)
    s.label(1075, 468, "SD0 TX A15/A14, RX C14/B13", C_MUTED)
    s.label(70, 828, "I2C to sensor (1.8 V wide-range bank)", C_CTRL)
    s.label(1300, 658, "MDC/MDIO (1.8 V)", C_CTRL)

    # ---- legend --------------------------------------------------------------
    legend(s, 1270, 700, [
        (C_DATA, False, "data path (arrow = direction)"),
        (C_CTRL, True, "control / set-up"),
        (C_CLK, False, "clock (text)"),
    ])
    s.label(1270, 772, "Tinted boxes are clock domains.", C_MUTED)

    s.write("block_diagram.svg")


if __name__ == "__main__":
    block_diagram()
