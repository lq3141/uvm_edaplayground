`ifndef RAL_TRAFFIC
`define RAL_TRAFFIC

import uvm_pkg::*;

class ral_cfg_ctl extends uvm_reg;
	rand uvm_reg_field mod_en;      // Enables the module
	rand uvm_reg_field bl_yellow;   // Blinks yellow
	rand uvm_reg_field bl_red;      // Blinks red
  rand uvm_reg_field profile;     // 1 : Peak, 0 : Off-Peak

	`uvm_object_utils(ral_cfg_ctl)

	function new(string name = "traffic_cfg_ctrl");
		super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
	endfunction: new

  // Build all register field objects
  virtual function void build();
    this.mod_en     = uvm_reg_field::type_id::create("mod_en",,   get_full_name());
    this.bl_yellow  = uvm_reg_field::type_id::create("bl_yellow",,get_full_name());
    this.bl_red     = uvm_reg_field::type_id::create("bl_red",,   get_full_name());
    this.profile    = uvm_reg_field::type_id::create("profile",,  get_full_name());

    // configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible); 
    this.mod_en.configure(this, 1, 0, "RW", 0, 1'h0, 1, 0, 0);
    this.bl_yellow.configure(this, 1, 1, "RW", 0, 3'h4, 1, 0, 0);
    this.bl_red.configure(this, 1, 2, "RW", 0, 1'h0, 1, 0, 0);
    this.profile.configure(this, 1, 3, "RW", 0, 1'h0, 1, 0, 0);
  endfunction
endclass 

class ral_cfg_stat extends uvm_reg;
  uvm_reg_field state;    // Current state of the design
  
  `uvm_object_utils(ral_cfg_stat)
  function new(string name = "ral_cfg_stat");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.state = uvm_reg_field::type_id::create("state",, get_full_name());

    // configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible); 
    this.state.configure(this, 2, 0, "RO", 0, 1'h0, 0, 0, 0);
  endfunction
endclass

class ral_cfg_timer extends uvm_reg;
	uvm_reg_field timer;     // Time for which it blinks

	`uvm_object_utils(ral_cfg_timer)
	function new(string name = "traffic_cfg_timer");
		super.new(name, 32,build_coverage(UVM_NO_COVERAGE));
	endfunction

  virtual function void build();
     this.timer = uvm_reg_field::type_id::create("timer",,get_full_name());

    // configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible); 
     this.timer.configure(this, 32, 0, "RW", 0, 32'hCAFE1234, 1, 0, 1);
     this.timer.set_reset('h0, "SOFT");
  endfunction
endclass

class ral_block_traffic_cfg extends uvm_reg_block;
	rand ral_cfg_ctl    ctrl;       // RW
	rand ral_cfg_timer  timer[2];   // RW
       ral_cfg_stat   stat;       // RO

	`uvm_object_utils(ral_block_traffic_cfg)

	function new(string name = "traffic_cfg");
		super.new(name, build_coverage(UVM_NO_COVERAGE));
	endfunction

  virtual function void build();
    default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);
    ctrl = ral_cfg_ctl::type_id::create("ctrl",,get_full_name());
    ctrl.configure(this, null, "");
    ctrl.build();
    ctrl.add_hdl_path_slice("ctl_reg", 0, ctrl.get_n_bits());
    default_map.add_reg(this.ctrl, `UVM_REG_ADDR_WIDTH'h0, "RW", 0);
    
    timer[0] = ral_cfg_timer::type_id::create("timer[0]",,get_full_name());
    timer[0].configure(this, null, "");
    timer[0].build();
    timer[0].add_hdl_path_slice("timer_0", 0, timer[0].get_n_bits());
    default_map.add_reg(this.timer[0], `UVM_REG_ADDR_WIDTH'h4, "RW", 0);

    timer[1] = ral_cfg_timer::type_id::create("timer[1]",,get_full_name());
    timer[1].configure(this, null, "");
    timer[1].build();
    timer[1].add_hdl_path_slice("timer_1", 0, timer[1].get_n_bits());
    default_map.add_reg(this.timer[1], `UVM_REG_ADDR_WIDTH'h8, "RW", 0);

    stat = ral_cfg_stat::type_id::create("stat",,get_full_name());
    stat.configure(this, null, "");
    stat.build();
    stat.add_hdl_path_slice("stat_reg", 0, stat.get_n_bits());
    default_map.add_reg(this.stat, `UVM_REG_ADDR_WIDTH'hc, "RO", 0);
    add_hdl_path("DUT");
  endfunction 
endclass 

class ral_sys_traffic extends uvm_reg_block;
  rand ral_block_traffic_cfg cfg;

	`uvm_object_utils(ral_sys_traffic)
	function new(string name = "traffic");
		super.new(name);
	endfunction

	function void build();
    default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);
    cfg = ral_block_traffic_cfg::type_id::create("cfg",,get_full_name());
    cfg.configure(this, "DUT");
    cfg.build();
    add_hdl_path("tb");
    default_map.add_submap(this.cfg.default_map, `UVM_REG_ADDR_WIDTH'h0);
	endfunction
endclass

`endif

