// cerasite_ocflash.v

// Generated using ACDS version 16.0 211

`timescale 1 ps / 1 ps
module cerasite_ocflash (
		input  wire        clock,                   //    clk.clk
		input  wire [11:0] avmm_data_addr,          //   data.address
		input  wire        avmm_data_read,          //       .read
		output wire [31:0] avmm_data_readdata,      //       .readdata
		output wire        avmm_data_waitrequest,   //       .waitrequest
		output wire        avmm_data_readdatavalid, //       .readdatavalid
		input  wire [1:0]  avmm_data_burstcount,    //       .burstcount
		input  wire        reset_n                  // nreset.reset_n
	);

	altera_onchip_flash #(
		.INIT_FILENAME                       (""),
		.INIT_FILENAME_SIM                   (""),
		.DEVICE_FAMILY                       ("MAX 10"),
		.PART_NAME                           ("10M02DCV36C8G"),
		.DEVICE_ID                           ("02"),
		.SECTOR1_START_ADDR                  (0),
		.SECTOR1_END_ADDR                    (1535),
		.SECTOR2_START_ADDR                  (1536),
		.SECTOR2_END_ADDR                    (3071),
		.SECTOR3_START_ADDR                  (0),
		.SECTOR3_END_ADDR                    (0),
		.SECTOR4_START_ADDR                  (0),
		.SECTOR4_END_ADDR                    (0),
		.SECTOR5_START_ADDR                  (0),
		.SECTOR5_END_ADDR                    (0),
		.MIN_VALID_ADDR                      (0),
		.MAX_VALID_ADDR                      (3071),
		.MIN_UFM_VALID_ADDR                  (0),
		.MAX_UFM_VALID_ADDR                  (3071),
		.SECTOR1_MAP                         (1),
		.SECTOR2_MAP                         (2),
		.SECTOR3_MAP                         (0),
		.SECTOR4_MAP                         (0),
		.SECTOR5_MAP                         (0),
		.ADDR_RANGE1_END_ADDR                (3071),
		.ADDR_RANGE1_OFFSET                  (512),
		.ADDR_RANGE2_OFFSET                  (0),
		.AVMM_DATA_ADDR_WIDTH                (12),
		.AVMM_DATA_DATA_WIDTH                (32),
		.AVMM_DATA_BURSTCOUNT_WIDTH          (2),
		.SECTOR_READ_PROTECTION_MODE         (31),
		.FLASH_SEQ_READ_DATA_COUNT           (4),
		.FLASH_ADDR_ALIGNMENT_BITS           (2),
		.FLASH_READ_CYCLE_MAX_INDEX          (4),
		.FLASH_RESET_CYCLE_MAX_INDEX         (1),
		.FLASH_BUSY_TIMEOUT_CYCLE_MAX_INDEX  (8),
		.FLASH_ERASE_TIMEOUT_CYCLE_MAX_INDEX (2537500),
		.FLASH_WRITE_TIMEOUT_CYCLE_MAX_INDEX (2211),
		.PARALLEL_MODE                       (0),
		.READ_AND_WRITE_MODE                 (0),
		.WRAPPING_BURST_MODE                 (0),
		.IS_DUAL_BOOT                        ("False"),
		.IS_ERAM_SKIP                        ("True"),
		.IS_COMPRESSED_IMAGE                 ("False")
	) onchip_flash_0 (
		.clock                   (clock),                                //    clk.clk
		.reset_n                 (reset_n),                              // nreset.reset_n
		.avmm_data_addr          (avmm_data_addr),                       //   data.address
		.avmm_data_read          (avmm_data_read),                       //       .read
		.avmm_data_readdata      (avmm_data_readdata),                   //       .readdata
		.avmm_data_waitrequest   (avmm_data_waitrequest),                //       .waitrequest
		.avmm_data_readdatavalid (avmm_data_readdatavalid),              //       .readdatavalid
		.avmm_data_burstcount    (avmm_data_burstcount),                 //       .burstcount
		.avmm_data_writedata     (32'b00000000000000000000000000000000), // (terminated)
		.avmm_data_write         (1'b0),                                 // (terminated)
		.avmm_csr_addr           (1'b0),                                 // (terminated)
		.avmm_csr_read           (1'b0),                                 // (terminated)
		.avmm_csr_writedata      (32'b00000000000000000000000000000000), // (terminated)
		.avmm_csr_write          (1'b0),                                 // (terminated)
		.avmm_csr_readdata       ()                                      // (terminated)
	);

endmodule