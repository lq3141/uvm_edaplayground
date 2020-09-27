`include "uvm_macros.svh"
import uvm_pkg::*;

class base_test extends uvm_test;
   `uvm_component_utils (base_test)

   my_env         m_env;
   my_sequence    m_seq;
   reset_seq      m_reset_seq;
   uvm_status_e   status;

   function new (string name = "base_test", uvm_component parent);
      super.new (name, parent);
   endfunction

   virtual function void build_phase (uvm_phase phase);
      super.build_phase (phase);
      m_env = my_env::type_id::create ("m_env", this);
      m_seq = my_sequence::type_id::create ("m_seq", this);
      m_reset_seq = reset_seq::type_id::create ("m_reset_seq", this);
//      factory.set_type_override_by_type(ral_sample1::get_type(), my_sample::get_type()); 
//      factory.print();
   endfunction

   virtual task reset_phase (uvm_phase phase);
      super.reset_phase (phase);
      phase.raise_objection (this);
      m_reset_seq.start (m_env.m_agent.m_seqr);
      phase.drop_objection (this);
   endtask

   virtual task main_phase (uvm_phase phase);
      phase.raise_objection (this);
      m_seq.start (m_env.m_agent.m_seqr);
      phase.drop_objection (this);
   endtask
endclass

class reg_backdoor_test extends base_test;
   `uvm_component_utils (reg_backdoor_test)
   function new (string name="reg_backdoor_test", uvm_component parent);
      super.new (name, parent);
   endfunction

   virtual task main_phase(uvm_phase phase);
      ral_sys_traffic   m_ral_model;
      uvm_status_e      status;
      int               rdata;

      phase.raise_objection(this);

      m_env.m_reg_env.set_report_verbosity_level (UVM_HIGH);
      uvm_config_db#(ral_sys_traffic)::get(null, "uvm_test_top", "m_ral_model", m_ral_model);

      // Perform a normal frontdoor access -> write some data first and then read it back
      m_ral_model.cfg.timer[1].write(status, 32'h1234_5678);
      m_ral_model.cfg.timer[1].read(status, rdata);
      `uvm_info(get_type_name(), $sformatf("desired=0x%0h mirrored=0x%0h", m_ral_model.cfg.timer[1].get(), m_ral_model.cfg.timer[1].get_mirrored_value()), UVM_MEDIUM)
      
      // Perform a backdoor access for write and then do a frontdoor read 
      m_ral_model.cfg.timer[1].write(status, 32'ha5a5_a5a5, UVM_BACKDOOR);
      m_ral_model.cfg.timer[1].read(status, rdata);
      `uvm_info(get_type_name(), $sformatf("desired=0x%0h mirrored=0x%0h", m_ral_model.cfg.timer[1].get(), m_ral_model.cfg.timer[1].get_mirrored_value()), UVM_MEDIUM)

      // Perform a frontdoor write and then do a backdoor read
      m_ral_model.cfg.timer[1].write(status, 32'hface_face);
     // Wait for a time unit so that backdoor access reads update value
     #1;  
      m_ral_model.cfg.timer[1].read(status, rdata, UVM_BACKDOOR);
      `uvm_info(get_type_name(), $sformatf("desired=0x%0h mirrored=0x%0h", m_ral_model.cfg.timer[1].get(), m_ral_model.cfg.timer[1].get_mirrored_value()), UVM_MEDIUM)

      phase.drop_objection(this);
   endtask

  virtual task shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    phase.raise_objection(this);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

