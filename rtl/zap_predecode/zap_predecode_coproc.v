`default_nettype none
`include "config.vh"

module zap_predecode_coproc #(
        parameter PHY_REGS = 46
)
(
        input wire              i_clk,
        input wire              i_reset,

        // Stall signals
        

        input wire [31:0]       i_instruction,
        input wire              i_valid,

        input wire [31:0]       i_cpsr_ff,

        input wire              i_irq,
        input wire              i_fiq,

         // Clear and stall signals.
        input wire              i_clear_from_writeback, // | High Priority
        input wire              i_data_stall,           // |
        input wire              i_clear_from_alu,       // |
        input wire              i_stall_from_shifter,   // |
        input wire              i_stall_from_issue,     // V Low Priority

        input wire              i_pipeline_dav,

        input wire              i_copro_done,           // Coprocessor done indicator.

        output reg              o_irq,
        output reg              o_fiq,

        output reg [31:0]       o_instruction,
        output reg              o_valid,

        output reg              o_stall_from_decode,      // Stall from decode.

        output reg                        o_copro_dav_ff,           // Are we really asking for the coprocessor.
        output reg  [31:0]                o_copro_word_ff,         // The entire instruction is passed to the coprocessor.

        output wire                     o_unused_ok
);

`include "cpsr.vh"
`include "regs.vh"
`include "modes.vh"
`include "instruction_patterns.vh"
`include "cc.vh"
`include "global_functions.vh"

localparam IDLE = 0;
localparam BUSY = 1;

reg state_ff, state_nxt;
reg cp_dav_nxt;
reg [31:0] cp_word_nxt;

always @*
begin
        cp_dav_nxt              = o_copro_dav_ff;
        cp_word_nxt             = o_copro_word_ff;
        o_stall_from_decode     = 1'd0;
        o_instruction           = i_instruction;
        o_valid                 = i_valid;
        state_nxt               = state_ff;
        o_irq                   = i_irq;
        o_fiq                   = i_fiq;

        case ( state_ff )
        IDLE:
                // Activate only if no thumb.
                casez ( (!i_cpsr_ff[T]) ? i_instruction : 32'd0 )
                MRC, MCR, LDC, STC, CDP:
                begin
                        o_instruction = {4'b1111, 28'd0}; // Pump out NV instruction.
                        o_valid       = 1'd0;
                        o_irq         = 1'd0;
                        o_fiq         = 1'd0;

                        // As long as there is an instruction to process
                        if ( i_pipeline_dav )
                        begin
                                o_valid                 = 1'd0;
                                o_stall_from_decode     = 1'd1;
                                cp_dav_nxt              = 1'd0;
                                cp_word_nxt             = 32'd0;
                        end
                        else
                        begin
                                o_valid                 = 1'd0;
                                o_stall_from_decode     = 1'd1;
                                cp_word_nxt             = i_instruction;
                                cp_dav_nxt              = 1'd1;
                                state_nxt               = BUSY;
                        end
                end
                default:
                begin
                        // Remain transparent.
                        o_valid                 = i_valid;
                        o_instruction           = i_instruction;
                        o_irq                   = i_irq;
                        o_fiq                   = i_fiq;
                        cp_dav_nxt              = 0;
                        o_stall_from_decode     = 0;
                        cp_word_nxt             = {32{1'dx}}; // Don't care.
                end
                endcase

        BUSY:
        begin
                cp_word_nxt             = o_copro_word_ff;
                cp_dav_nxt              = o_copro_dav_ff;
                o_stall_from_decode     = 1'd1;
                o_valid = 1'd0;
                o_instruction = 32'd0;

                o_irq = 1'd0;
                o_fiq = 1'd0;

                if ( i_copro_done )
                begin
                        cp_dav_nxt              = 1'd0;
                        cp_word_nxt             = 32'd0;
                        state_nxt               = IDLE;
                        o_stall_from_decode     = 1'd0;
                end
        end
        endcase
end

always @ (posedge i_clk)
begin
        if ( i_reset )
        begin
                clear;
        end
        else if ( i_clear_from_writeback )
        begin
                clear;
        end
        else if ( i_data_stall )
        begin
                // Preserve values.
        end
        else if ( i_clear_from_alu )
        begin
                clear;
        end
        else if ( i_stall_from_shifter )
        begin
                // Preserve values.
        end
        else if ( i_stall_from_issue )
        begin
                // Preserve values.
        end
        else
        begin
                state_ff        <= state_nxt;
                o_copro_word_ff <= cp_word_nxt;
                o_copro_dav_ff  <= cp_dav_nxt;
        end
end

task clear;
begin
                state_ff            <= IDLE;
                o_copro_dav_ff      <= 1'd0; 
end
endtask

assign o_unused_ok =    i_cpsr_ff[4:0]  || 
                        i_cpsr_ff[31:6];

endmodule
