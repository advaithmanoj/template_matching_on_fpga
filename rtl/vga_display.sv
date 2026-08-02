

`timescale 1ns/1ps
// =============================================================
// vga_display.sv
//   Displays the binary input image over VGA (640x480 @ 60 Hz)
//   and overlays a 100x40 pixel bounding box at the match
//   position (xpos, ypos) reported by processor_array.
//
// Inputs
//   clk25   - 25.175 MHz VGA pixel clock
//   sys_clk - system clock (domain of xpos/ypos from processor_array)
//   rst     - active-low async reset
//   xpos    - match top-left X, sys_clk domain (from processor_array)
//   ypos    - match top-left Y, sys_clk domain (from processor_array)
//
// Outputs
//   red/green/blue - 4-bit per channel to VGA DAC
//   hsync / vsync  - VGA sync, negative polarity
//
// Pipeline (2 stages, aligned with ROM latency)
//   Stage 0  hCounter/vCounter → address → rom_addr_r
//            active/bbox detection → active_r / on_bbox_r
//   Stage 1  ROM outputs pixel_data
//            Pixel colour selected and registered to output
//
// Sync is also 2-stage registered (matches reference code style)
// so sync and colour arrive at the output in the same clock cycle.
// =============================================================

module vga_display (
    input  wire        clk25,
    input  wire        sys_clk,
    input  wire        rst,
    input  wire [9:0]  xpos,
    input  wire [9:0]  ypos,
    input  wire        match_found,
    output reg  [3:0]  red,
    output reg  [3:0]  green,
    output reg  [3:0]  blue,
    output reg         hsync,
    output reg         vsync
);

    // ----------------------------------------------------------------
    // VGA 640x480 @ 60 Hz timing (identical to reference)
    // ----------------------------------------------------------------
    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800
    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525
    localparam HSYNC_POL = 1'b0;
    localparam VSYNC_POL = 1'b0;

    // Bounding box dimensions (must match template ROM dimensions)
    localparam TMPL_W = 40;
    localparam TMPL_H = 100;
    localparam BOX_THICK = 2;   // border thickness in pixels

    // ----------------------------------------------------------------
    // Pixel counters
    // ----------------------------------------------------------------
    reg [9:0] hCounter = 10'd0;
    reg [9:0] vCounter = 10'd0;

    always @(posedge clk25) begin
        if (hCounter == H_TOTAL - 1) begin
            hCounter <= 10'd0;
            vCounter <= (vCounter == V_TOTAL - 1) ? 10'd0 : vCounter + 10'd1;
        end else begin
            hCounter <= hCounter + 10'd1;
        end
    end

    // ----------------------------------------------------------------
    // CDC: 2-FF synchronizer for xpos/ypos (sys_clk → clk25)
    //
    // xpos/ypos change at most once per matched frame (~60 Hz).
    // The synchronizer may glitch for one clk25 cycle on update;
    // at 25 MHz this is invisible to the viewer.
    // ----------------------------------------------------------------
    reg [9:0] xpos_m = 10'd0, xpos_s = 10'd0;
    reg [9:0] ypos_m = 10'd0, ypos_s = 10'd0;

    always @(posedge clk25) begin
        if (!rst) begin
            xpos_m <= 10'd0;  xpos_s <= 10'd0;
            ypos_m <= 10'd0;  ypos_s <= 10'd0;
        end else begin
            xpos_m <= xpos;   xpos_s <= xpos_m;
            ypos_m <= ypos;   ypos_s <= ypos_m;
        end
    end

    // ----------------------------------------------------------------
    // Stage 0: ROM address computation
    //   pixel address = row * 640 + col
    //   640 = 512 + 128 = 2^9 + 2^7  (shift-add, avoids DSP block)
    //
    //   During blanking the address is held at 0 (safe, not displayed).
    // ----------------------------------------------------------------
    wire active_now = (hCounter < H_DISPLAY) && (vCounter < V_DISPLAY);

    
  //  wire [18:0] col_base = {hCounter, 7'b0}   ;     // hCounter * 128 (not enough - need *480)
// 480 = 256 + 128 + 64 + 32
   wire [18:0] col_base = ({1'b0, hCounter, 8'b0}
                      + {2'b0, hCounter, 7'b0}
                      + {3'b0, hCounter, 6'b0}
                      + {4'b0, hCounter, 5'b0});
   wire [18:0] pixel_addr = active_now?(col_base + {9'b0, vCounter}):19'd0;
    reg  [18:0] rom_addr_r = 19'd0;

    always @(posedge clk25)
        rom_addr_r <= pixel_addr;   // latch address; ROM output valid next cycle

    // ROM instance dedicated to VGA display (separate from linebuffer ROM)
    // clken tied high - always reading during display
    wire [0:0] pixel_data;

    rom_input vga_rom_inst (
        .address (rom_addr_r),
        .clken   (1'b1),
        .clock   (clk25),
        .q       (pixel_data)
    );

    // ----------------------------------------------------------------
    // Stage 0: bounding box edge detection (combinatorial)
    //
    // Box top-left  : (xpos_s, ypos_s)
    // Box bottom-right (inclusive): (xpos_s + TMPL_W - 1, ypos_s + TMPL_H - 1)
    // Border drawn BOX_THICK pixels wide on all four sides.
    //
    // Note: if the box extends past the screen edge it clips naturally
    // because active_r will be 0 for those pixels.
    // ----------------------------------------------------------------
 // FIX (hCounter=col maps to ypos; vCounter=row maps to xpos):
wire h_in_box = (hCounter >= ypos_s) && (hCounter < ypos_s + TMPL_W);
wire v_in_box = (vCounter >= xpos_s) && (vCounter < xpos_s + TMPL_H);

    wire on_left  = h_in_box && v_in_box
                    && (hCounter < ypos_s + BOX_THICK);
    wire on_right = h_in_box && v_in_box
                    && (hCounter >= ypos_s + TMPL_W - BOX_THICK);
    wire on_top   = h_in_box && v_in_box
                    && (vCounter < xpos_s + BOX_THICK);
    wire on_bot   = h_in_box && v_in_box
                    && (vCounter >= xpos_s + TMPL_H - BOX_THICK);
    // BEFORE
//wire on_bbox  = on_left | on_right | on_top | on_bot;

// AFTER
wire on_bbox  = match_found & (on_left | on_right | on_top | on_bot);

    // Pipeline Stage 0 → Stage 1 (match 1-cycle ROM latency)
    reg active_r  = 1'b0;
    reg on_bbox_r = 1'b0;

    always @(posedge clk25) begin
        active_r  <= active_now;
        on_bbox_r <= on_bbox;
    end

    // ----------------------------------------------------------------
    // Stage 1: pixel colour output (aligned with ROM data)
    //
    // Priority:  blank > bounding box border > image pixel
    //   Image 1 (white object) → R=F G=F B=F
    //   Image 0 (black bg)     → R=0 G=0 B=0
    //   Box border             → R=F G=0 B=0  (bright red)
    // ----------------------------------------------------------------
    always @(posedge clk25) begin
        if (!active_r) begin
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else if (on_bbox_r) begin
            red   <= 4'hF;   // bright red bounding box
            green <= 4'h0;
            blue  <= 4'h0;
        end else begin
            // Replicate 1-bit pixel to all 4 colour bits
            red   <= {4{pixel_data[0]}};
            green <= {4{pixel_data[0]}};
            blue  <= {4{pixel_data[0]}};
        end
    end

    // ----------------------------------------------------------------
    // Sync generation - 2-stage registered (matches reference style)
    // Both active_r and sync arrive at outputs after 2 clock cycles,
    // so colour and sync remain frame-aligned.
    // ----------------------------------------------------------------
    reg hsync_reg = ~HSYNC_POL;
    reg vsync_reg = ~VSYNC_POL;

    always @(posedge clk25) begin
        hsync_reg <= ((hCounter >= (H_DISPLAY + H_FRONT)) &&
                      (hCounter <  (H_DISPLAY + H_FRONT + H_SYNC)))
                      ? HSYNC_POL : ~HSYNC_POL;
        vsync_reg <= ((vCounter >= (V_DISPLAY + V_FRONT)) &&
                      (vCounter <  (V_DISPLAY + V_FRONT + V_SYNC)))
                      ? VSYNC_POL : ~VSYNC_POL;
        hsync <= hsync_reg;
        vsync <= vsync_reg;
    end

endmodule
