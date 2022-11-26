#!/usr/bin/perl
use File::Copy qw(copy cp);
use Cwd(getcwd,cwd);


copy("./../../verification/regress_fun/config/modules_list","./") or die "Copy failed: $!";





open(MODULE_LIST ,"<modules_list") or die "Open modules_list failed: $!";

    if(-e "module_file_list"){
	    #print "module_file_list exist, rm now! \n";
        system"rm -rf module_file_list"
    }else{
	    #print "module_file_list do not exist. \n";
    }

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


sub module_list_gen{



    open(FILE_LIST ,"<$_[0]/file_list") or die "Open file_list failed: $!";
    open(NEW_LIST,">>module_file_list");
    @file_line=<FILE_LIST>;
    foreach $input (@file_line){
        chomp($input);
        say NEW_LIST "$_[0]/$input";
    }
    close NEW_LIST;
    close FILE_LIST;
}
