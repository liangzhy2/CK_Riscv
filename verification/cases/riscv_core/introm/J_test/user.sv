
initial begin
    #10ns;
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[1] == 32'h14);
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[6] == 32'h01234000);
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[7] == 32'h08765004);

    //wait(`TB_DRAM.ram[0] == 32'h01004000);
    //wait(`TB_DRAM.ram[1] == 32'h04765004);

    TEST_PASS;

end

initial begin
    #100us;
    $display("\n----------------------------------------\n");
    $display("\t Timeout Error !!!!\n");
    TEST_FAIL;
end

