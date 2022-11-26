
initial begin
    #10ns;
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[1] == 32'hFFFF_F000);
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[2] == 32'hFF);
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[3] == 32'hFFF);
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[4] == 32'hFFFF_FFFF);
    wait(tbtop.U_CHIP_TOP.u_riscv_core.u_regfile.reg_bank[5] == 32'hFF_F014);

    TEST_PASS;

end

initial begin
    #100us;
    $display("\n----------------------------------------\n");
    $display("\t Timeout Error !!!!\n");
    TEST_FAIL;
end

