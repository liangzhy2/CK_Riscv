#!/usr/bin/perl
###############################################################################
# Synopsys(R) IC Compiler(TM) II Reference Methodology Unpack Utility
# Version: L-2016.03-SP4 (October 10, 2016)
# Copyright (C) 2016-2017 Synopsys, Inc. All rights reserved.
##########################################################################################
## Please change perl path if it's not correct

## Ensure there are two arguments, otherwise print syntax info
if ($ARGV[0] =~ /(-h|-help|--help)/ || $#ARGV != 1) {
    print "\nSYNTAX\n";
    print "unpack_rm.pl <config_file> <install_dir>\n";
    print "    <config_file>: Path to design hierarchy configuration file\n";
    print "    <install_dir>: Installation directory for unpacking RM flow scripts and run directories (must exist)\n";
    print "\nPlease read README.ICC2-UNPACK-RM.txt in the ICC II RM scripts directory for more usage instructions.\n";
    die "\n";
}

my $config_file = $ARGV[0];
my $install_dir = $ARGV[1];

## Track indent of previous line to identify parent / child block relationships
my $prev_line_indent = -1;

## Track parent blocks to update their child block list as the children are encountered
my @parent_stack;

## Contains all block names, block children, hierarchy style, and hierarchy level
my %blocks;


## Various startup error checks
if (! -d "rm_setup" || ! -d "rm_icc2_dp_scripts" || ! -d "rm_icc2_pnr_scripts") {
    die "\nunpack_rm.pl must be run from the RM scripts directory that is to be installed.  Aborting.\n";
}
if (! -e $config_file) {
    die "\nSpecified design hierarchy configuration file $config_file does not exist.  Aborting.\n";
}
if (! -d $install_dir) {
    die "\nSpecified installation directory $install_dir must exist before unpacking into it.  Aborting.\n";
}
if (-d "$install_dir/dp" || -d "$install_dir/pnr") {
    die "\nBlock run directories 'dp' and/or 'pnr' already exist in the install directory $install_dir.  Please unpack RM flow into a clean location.  Aborting.\n";
}
if ($ARGV[1] =~ /$ENV{'PWD'}/ || $ARGV[1] =~ /^\.$/) {
    die "\nCannot unpack into the RM scripts directory.  Please specify a different install directory.  Aborting.\n";
}

open FILE, "< $config_file";

print "\nReading configuration file $config_file\n";

while (<FILE>) {

    ## Gobble any trailing whitespace
    s/\s*$//;

    ## Error check config file format: Zero or more tabs or spaces followed by a string of alphanumeric characters or underscore
    if (!/^(\t*| *)[A-Za-z0-9_]+$/) {
	chomp $_;
	die "\nIllegal format for line: $_\nRefer to README.ICC2-UNPACK-RM.txt for explanation of design hierarchy configuration file format.\n";
    }

    ## Get indentations of current line to determine hierarchy level
    my $indent = $_ =~ tr/\t //;

    ## Error check hierarchy levels
    if ($indent > $prev_line_indent + 1) {
	die "\nIllegal format for line: $_\nA block cannot be more than one hierarchy level below its parent.\nRefer to README.ICC2-UNPACK-RM.txt for explanation of design hierarchy configuration file format.\n";
    }
    if ($indent == 0 && $prev_line_indent != -1) {
	die "\nIllegal format for line: $_\nOnly one top hierarchy can exist per config file.\nRefer to README.ICC2-UNPACK-RM.txt for explanation of design hierarchy configuration file format.\n";
    }

    ## Get block name
    $_ =~ /([A-Za-z0-9_]+)/;
    my $design_name = $1;

    ## Initially assume this is a bottom hierarchy block with no children
    $blocks{$design_name}{children} = "";
    $blocks{$design_name}{descendants} = "";
    $blocks{$design_name}{style} = "hier";
    $blocks{$design_name}{level} = "bottom";

    ## Pop $parent_stack so top element is the parent of the current block
    my $pop_count = $prev_line_indent - $indent + 1;
    for ($i = 1; $i <= $pop_count; $i++) {
	pop @parent_stack;
    }
    
    ## Loop parent stack to set attributes of block's ancestors
    if (@parent_stack != "") {
	for ($i = 0; $i <= $#parent_stack; $i++) {

	    ## For every ancestor, set this block as a descendant
	    if ($blocks{$parent_stack[$i]}{descendants} !~ /$design_name /) {
		$blocks{$parent_stack[$i]}{descendants} =  $blocks{$parent_stack[$i]}{descendants} . $design_name . " ";
	    }

	    ## Set block's immediate parent as intermediate level, and add this block as the parent's child
	    if ($i == $#parent_stack) {
		$blocks{$parent_stack[-1]}{level} = "intermediate";
		if ($blocks{$parent_stack[-1]}{children} !~ /$design_name /) {
		    $blocks{$parent_stack[-1]}{children} =  $blocks{$parent_stack[-1]}{children} . $design_name . " ";
		}
	    }

	}
    }

    ## Update previous line indent value and push current block to parent block stack to prepare for next loop iteration
    $prev_line_indent = $indent;
    push @parent_stack, $design_name;

    ## DEBUG Print current line with hierarchy level
#    print "$indent $_\n";
    
}

close FILE;


## Previous loop assumed all blocks are bottom hierarchies, and changed to intermediate hierarchies if children were found
## Now correct this assumption for the top hierarchy, or for flat designs
if ($#parent_stack == 0) {
    $blocks{$parent_stack[0]}{style} = "flat";
    $blocks{$parent_stack[0]}{level} = "";
} else {
    $blocks{$parent_stack[0]}{level} = "top";
}

## DEBUG Print results of parsing the config file
#for (keys %blocks) {
#    print "$_   $blocks{$_}{style}   $blocks{$_}{level}   $blocks{$_}{children}\n";
#    print "     $blocks{$_}{descendants}\n";
#}

## Construct the $DP_INTERMEDIATE_LEVEL_BLOCK_REFS RM variable fields for the top block
## This consists of all intermediate hierarchies
my $dp_design_block_refs = "";
for (keys %blocks) {
    if ($blocks{$_}{level} =~ /intermediate/) {
	$dp_design_block_refs = $dp_design_block_refs . $_ . " ";
    }
}
## Strip trailing space
$dp_design_block_refs =~ s/ $//;

print "Configuration file successfully loaded.\n";
print "Installing to directory \"$install_dir\"\n";

my @rm_script_dir = split("/",$ENV{'PWD'});

## Don't overwrite top RM scripts dir if it already exists in the install dir
if (-d "$install_dir/$rm_script_dir[-1]") {
    print "Master RM scripts directory $rm_script_dir[-1] found already in install directory \"$install_dir\", will not overwrite it.\n";
} else {
    print "Copying $rm_script_dir[-1] to $install_dir\n";
    system("cp -r $ENV{'PWD'} $install_dir");
}

print "Creating DP run area $install_dir/dp\n";
system("mkdir $install_dir/dp");
print "Creating PNR run area $install_dir/pnr\n";
system("mkdir $install_dir/pnr");

my $orig_dir = $ENV{'PWD'};

## For each block, make block rundirs, local copies of RM scripts, and update RM flow variables
for my $name (keys %blocks) {

    ## Strip trailing space from children and descendants fields
    $blocks{$name}{children} =~ s/ $//;
    $blocks{$name}{descendants} =~ s/ $//;
    
    ## For DP, only create rundir and update flow variables for top block
    if ($blocks{$name}{style} =~ /flat/ || $blocks{$name}{level} =~ /top/) {
	print "Creating DP top block run directory, copying RM scripts to $install_dir/dp/$name, and updating RM flow variables\n";
	system("mkdir $install_dir/dp/$name");
	system("cp -r ./rm_setup $install_dir/dp/$name");
	system("cp -r ./rm_icc2_dp_scripts $install_dir/dp/$name");

	## Populate $DESIGN_NAME, $DESIGN_STYLE, $PHYSICAL_HIERARCHY_LEVEL, $RELEASE_DIR_DP, $RELEASE_DIR_PNR in $install_dir/dp/$name/rm_setup/icc2_common_setup.tcl
	system("mv $install_dir/dp/$name/rm_setup/icc2_common_setup.tcl $install_dir/dp/$name/rm_setup/icc2_common_setup.temp");
	open my $infile, '<',  "$install_dir/dp/$name/rm_setup/icc2_common_setup.temp" or die "Can't open temporary RM script file $install_dir/dp/$name/rm_setup/icc2_common_setup.temp to parse\n";
	open my $outfile, '>', "$install_dir/dp/$name/rm_setup/icc2_common_setup.tcl" or die "Can't open RM script file $install_dir/dp/$name/rm_setup/icc2_common_setup.tcl to write changes\n";
	while (<$infile>) {
	    s/(set\s+DESIGN_NAME\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"$name"\2/;
	    s/(set\s+DESIGN_STYLE\s+)"[ a-z]*?"(.*)/\1"$blocks{$name}{style}"\2/;
	    s/(set\s+PHYSICAL_HIERARCHY_LEVEL\s+)"[ a-z]*?"(.*)/\1"$blocks{$name}{level}"\2/;
	    s/(set\s+RELEASE_DIR_DP\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"..\/..\/release\/dp"\2/;
	    s/(set\s+RELEASE_DIR_PNR\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"..\/..\/release\/pnr"\2/;
	    print $outfile $_;
	}
	close $infile;
	close $outfile;
	system("rm $install_dir/dp/$name/rm_setup/icc2_common_setup.temp");
	
	## Populate $DP_BLOCK_REFS and $DP_INTERMEDIATE_LEVEL_BLOCK_REFS in $install_dir/dp/$name/rm_setup/icc2_dp_setup.tcl
	system("mv $install_dir/dp/$name/rm_setup/icc2_dp_setup.tcl $install_dir/dp/$name/rm_setup/icc2_dp_setup.temp");
	open my $infile, '<',  "$install_dir/dp/$name/rm_setup/icc2_dp_setup.temp" or die "Can't open temporary RM script file $install_dir/dp/$name/rm_setup/icc2_dp_setup.temp to parse\n";
	open my $outfile, '>', "$install_dir/dp/$name/rm_setup/icc2_dp_setup.tcl" or die "Can't open RM script file $install_dir/dp/$name/rm_setup/icc2_dp_setup.tcl to write changes\n";
	while (<$infile>) {
	    ## Substitute for either "" or [list ] style of listing block references
	    s/(set\s+DP_BLOCK_REFS\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"$blocks{$name}{descendants}"\2/;
	    s/(set\s+DP_BLOCK_REFS\s+)\[list[ a-zA-Z0-9_]*?\](.*)/\1\[list $blocks{$name}{descendants}\]\2/;
	    s/(set\s+DP_INTERMEDIATE_LEVEL_BLOCK_REFS\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"$dp_design_block_refs"\2/;
	    s/(set\s+DP_INTERMEDIATE_LEVEL_BLOCK_REFS\s+)\[list[ a-zA-Z0-9_]*?\](.*)/\1\[list $dp_design_block_refs\]\2/;
            s/(set\s+DP_FLOW\s+)"[ a-z]*?"(.*)/\1"$blocks{$name}{style}"\2/;
	    print $outfile $_;
	}
	close $infile;
	close $outfile;
	system("rm $install_dir/dp/$name/rm_setup/icc2_dp_setup.temp");

	## Link DP Makefile, and delete PNR related files
	chdir "$install_dir/dp/$name";
	system("ln -s rm_setup/Makefile_dp_$blocks{$name}{style} ./Makefile");
	if ($blocks{$name}{style} =~ /flat/) {
	    system("rm rm_setup/Makefile_dp_hier");
	} else {
	    system("rm rm_setup/Makefile_dp_flat");	    
	}
	system("rm rm_setup/Makefile_pnr");
	system("rm rm_setup/icc2_pnr_setup.tcl");
	chdir $orig_dir;

    }

    ## For PNR, create rundirs and update flow variables for all blocks
    print "Creating PNR block run directory, copying RM scripts to $install_dir/pnr/$name, and updating RM flow variables\n";
    system("mkdir $install_dir/pnr/$name");
    system("cp -r ./rm_setup $install_dir/pnr/$name");
    system("cp -r ./rm_icc2_pnr_scripts $install_dir/pnr/$name");
    
    ## Populate $DESIGN_NAME, $DESIGN_STYLE, $PHYSICAL_HIERARCHY_LEVEL, $RELEASE_DIR_DP, $RELEASE_DIR_PNR in $install_dir/pnr/$name/rm_setup/icc2_common_setup.tcl
    system("mv $install_dir/pnr/$name/rm_setup/icc2_common_setup.tcl $install_dir/pnr/$name/rm_setup/icc2_common_setup.temp");
    open my $infile, '<',  "$install_dir/pnr/$name/rm_setup/icc2_common_setup.temp" or die "Can't open temporary RM script file $install_dir/pnr/$name/rm_setup/icc2_common_setup.temp to parse\n";
    open my $outfile, '>', "$install_dir/pnr/$name/rm_setup/icc2_common_setup.tcl" or die "Can't open RM script file $install_dir/pnr/$name/rm_setup/icc2_common_setup.tcl to write changes\n";
    while (<$infile>) {
	s/(set\s+DESIGN_NAME\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"$name"\2/;
        s/(set\s+DESIGN_STYLE\s+)"[ a-z]*?"(.*)/\1"$blocks{$name}{style}"\2/;
        s/(set\s+PHYSICAL_HIERARCHY_LEVEL\s+)"[ a-z]*?"(.*)/\1"$blocks{$name}{level}"\2/;
        s/(set\s+RELEASE_DIR_DP\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"..\/..\/release\/dp"\2/;
        s/(set\s+RELEASE_DIR_PNR\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"..\/..\/release\/pnr"\2/;
	print $outfile $_;
    }
    close $infile;
    close $outfile;
    system("rm $install_dir/pnr/$name/rm_setup/icc2_common_setup.temp");

    ## Populate $USE_ABSTRACT_FOR_BLOCKS in $install_dir/pnr/$name/rm_setup/icc2_pnr_setup.tcl
    system("mv $install_dir/pnr/$name/rm_setup/icc2_pnr_setup.tcl $install_dir/pnr/$name/rm_setup/icc2_pnr_setup.temp");
    open my $infile, '<',  "$install_dir/pnr/$name/rm_setup/icc2_pnr_setup.temp" or die "Can't open temporary RM script file $install_dir/pnr/$name/rm_setup/icc2_pnr_setup.temp to parse\n";
    open my $outfile, '>', "$install_dir/pnr/$name/rm_setup/icc2_pnr_setup.tcl" or die "Can't open RM script file $install_dir/pnr/$name/rm_setup/icc2_pnr_setup.tcl to write changes\n";
    while (<$infile>) {
	## Substitute for either "" or [list ] style of listing block references
        s/(set\s+USE_ABSTRACTS_FOR_BLOCKS\s+)"[ a-zA-Z0-9_]*?"(.*)/\1"$blocks{$name}{children}"\2/;
        s/(set\s+USE_ABSTRACTS_FOR_BLOCKS\s+)\[list[ a-zA-Z0-9_]*?\](.*)/\1\[list $blocks{$name}{children}\]\2/;
	s/(set\s+SUB_BLOCK_REFS\s+)"[a-zA-Z0-9_]*?"(.*)/\1"$blocks{$name}{descendants}"\2/;
	s/(set\s+SUB_BLOCK_REFS\s+)\[list[ a-zA-Z0-9_]*?\](.*)/\1\[list $blocks{$name}{descendants}\]\2/;
        s/(set\s+INIT_DESIGN_INPUT\s+)"[a-zA-Z0-9_]*?"(.*)/\1"DP_RM_NDM"\2/;
	print $outfile $_;
    }
    close $infile;
    close $outfile;
    system("rm $install_dir/pnr/$name/rm_setup/icc2_pnr_setup.temp");

    ## Link DP Makefile, and delete PNR related files
    chdir "$install_dir/pnr/$name";
    system("ln -s rm_setup/Makefile_pnr ./Makefile");
    system("rm rm_setup/Makefile_dp_flat");
    system("rm rm_setup/Makefile_dp_hier");
    system("rm rm_setup/icc2_dp_setup.tcl");
    chdir $orig_dir;

}
