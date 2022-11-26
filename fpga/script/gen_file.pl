#!/usr/bin/perl -w
use File::Copy qw(copy cp);
use Cwd;

copy("./../../verification/regress_fun/config/modules_list","./") or die "Copy failed: $!";

    if(-e "module_file_list"){
	    #print "t.txt exist. \n";
        system"rm -rf module_file_list"
    }


open(MODULE_LIST ,"<modules_list") or die "Open modules_list failed: $!";



@module_line=<MODULE_LIST>;

foreach $input (@module_line){
    chomp($input);
    $input =~ s/\s//g;
    #print "main:$input\n";
    $_= $input;
    s/\:/\//;
    $MODULE_HEAD_PATH="../../module/$_";
    &module_list_gen($MODULE_HEAD_PATH);
}

close MODULE_LIST;



#=====================================================================================
open(LIB_LIST,"<../rtl/lib_list") or die "Open lib_list failed: $!";
open(NEW_LIST,">>module_file_list");

    @lib_line=<LIB_LIST>;
    foreach $input (@lib_line){
        chomp($input);
        say NEW_LIST "add_file $input";
    }

close LIB_LIST;
close NEW_LIST;





#=====================================================================================
#
#=====================================================================================
sub module_list_gen{
    open(FILE_LIST ,"<$_[0]/file_list") or die "Open file_list failed: $!";
    open(NEW_LIST,">>module_file_list");
    @file_line=<FILE_LIST>;
    #print "@file_line";
    foreach $input (@file_line){
        chomp($input);
        say NEW_LIST "add_file $_[0]/$input";
    }

    close NEW_LIST;
    close FILE_LIST;
}
