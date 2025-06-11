transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Julien/OneDrive/Bureau/Julien/Master 1/Q2/Micro elec/projet/test_div/snes.vhd}
vcom -93 -work work {C:/Users/Julien/OneDrive/Bureau/Julien/Master 1/Q2/Micro elec/projet/test_div/SharedTypes.vhd}
vcom -93 -work work {C:/Users/Julien/OneDrive/Bureau/Julien/Master 1/Q2/Micro elec/projet/test_div/Division.vhd}
vcom -93 -work work {C:/Users/Julien/OneDrive/Bureau/Julien/Master 1/Q2/Micro elec/projet/test_div/raycast.vhd}
vcom -93 -work work {C:/Users/Julien/OneDrive/Bureau/Julien/Master 1/Q2/Micro elec/projet/test_div/player.vhd}
vcom -93 -work work {C:/Users/Julien/OneDrive/Bureau/Julien/Master 1/Q2/Micro elec/projet/test_div/wolfenstein3D.vhd}

