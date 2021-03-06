:
eval 'exec perl -wS $0 ${1+"$@"}'
    if 0;
#
# This file is part of the LibreOffice project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This file incorporates work covered by the following license notice:
#
#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements. See the NOTICE file distributed
#   with this work for additional information regarding copyright
#   ownership. The ASF licenses this file to you under the Apache
#   License, Version 2.0 (the "License"); you may not use this file
#   except in compliance with the License. You may obtain a copy of
#   the License at http://www.apache.org/licenses/LICENSE-2.0 .
#

#
# packimages.pl - pack images into archives
#

use strict;
use Getopt::Long;
use File::Find;
use File::Basename;
use File::Copy qw(copy);
use File::Path qw(make_path);
require File::Temp;
use File::Temp qw(tempdir);

#### globals ####

my $img_global = '%GLOBALRES%';  # 'global' image prefix
my $img_module = '%MODULE%';  # 'module' image prefix
my $img_help = '%HELPCONTENT%';  # 'help' image prefix

my $out_file;                # path to output archive
my $tmp_out_file;            # path to temporary output file
my $global_path;             # path to global images directory
my $module_path;             # path to module images directory
my $helpimg_path;            # path to help images directory
my $sort_file;               # path to file containing sorting data
my @custom_path;             # path to custom images directory
my $imagelist_file;          # file containing list of image list files
my $verbose;                 # be verbose
my $extra_verbose;           # be extra verbose
my $do_rebuild = 0;          # is rebuilding zipfile required?

my @custom_list;
#### script id #####

( my $script_name = $0 ) =~ s/^.*\b(\w+)\.pl$/$1/;

print "$script_name -- version: 1.17\n" if $verbose;

#### main #####

parse_options();
my $image_lists_ref = get_image_lists();
my %image_lists_hash;
foreach ( @{$image_lists_ref} ) {
    $image_lists_hash{$_}="";
}
$do_rebuild = is_file_newer(\%image_lists_hash) if $do_rebuild == 0;
my ($global_hash_ref, $module_hash_ref, $custom_hash_ref, $help_hash_ref) = iterate_image_lists($image_lists_ref);
# custom_hash filled from filesystem lookup
find_custom($custom_hash_ref);

# build a consolidated set of links
my %links;
read_links(\%links, $global_path);
for my $path (@custom_path) {
    read_links(\%links, $path);
}
check_links(\%links);

# rebuild if links.txt has been modified
for my $path (@custom_path) {
    my $links_file = $path."/links.txt";
    if ((-e $links_file ) && ( -e $out_file )){
        if ((stat($out_file))[9] < (stat($links_file))[9]){
            $do_rebuild = 1;
            print_message("$links_file has been modified.") if $verbose;
        }
    }
}

my $zip_hash_ref = create_zip_list($global_hash_ref, $module_hash_ref, $custom_hash_ref, $help_hash_ref);

remove_links_from_zip_list($zip_hash_ref, \%links);

$do_rebuild = is_file_newer($zip_hash_ref) if $do_rebuild == 0;
if ( $do_rebuild == 1 ) {
    my $tmpdir = copy_images($zip_hash_ref);
    create_zip_archive($zip_hash_ref, \%links, $tmpdir);
    replace_file($tmp_out_file, $out_file);
    print_message("packing  $out_file finished.") if $verbose;
} else {
    print_message("$out_file up to date. nothing to do.") if $verbose;
}

exit(0);

#### subroutines ####

sub parse_options
{
    my $opt_help;
    my $p = Getopt::Long::Parser->new();
    my @custom_path_list;
    my $success =$p->getoptions(
                             '-h' => \$opt_help,
                             '-o=s' => \$out_file,
                             '-g=s' => \$global_path,
                 '-s=s' => \$sort_file,
                             '-m=s' => \$module_path,
                             '-e=s' => \$helpimg_path,
                             '-c=s' => \@custom_path_list,
                             '-l=s' => \$imagelist_file,
                             '-v'   => \$verbose,
                             '-vv'  => \$extra_verbose
                            );
    if ( $opt_help || !$success || !$out_file || !$global_path
        || !$module_path || !@custom_path_list || !$imagelist_file )
    {
        usage();
        exit(1);
    }
    #define intermediate output file
    $tmp_out_file="$out_file"."$$".".tmp";
    # Sanity checks.

    # Check if out_file can be written.
    my $out_dir = dirname($out_file);

    # Check paths.
    print_error("no such file '$_'", 2) if ! -f $imagelist_file;

    my @check_directories = ($out_dir, $global_path, $module_path);
    push @check_directories, $helpimg_path if ($helpimg_path ne '');

    foreach (@check_directories) {
        print_error("no such directory: '$_'", 2) if ! -d $_;
        print_error("can't search directory: '$_'", 2) if ! -x $_;
    }
    print_error("directory is not writable: '$out_dir'", 2) if ! -w $out_dir;

    # Use just the working paths
    @custom_path = ();
    foreach (@custom_path_list) {
        if ( ! -d $_ ) {
            print_warning("skipping non-existing directory: '$_'", 2);
        }
        elsif ( ! -x $_ ) {
            print_error("can't search directory: '$_'", 2);
        }
        else {
            push @custom_path, $_;
        }
    }
}

sub get_image_lists
{
    my @image_lists;

    open (my $fh, $imagelist_file) or die "cannot open imagelist file $imagelist_file\n";
    while (<$fh>) {
        chomp;
        next if /^\s*$/;
        my @ilsts = split ' ';
        push @image_lists, @ilsts;
    }
    close $fh;

    return wantarray ? @image_lists : \@image_lists;
}

sub iterate_image_lists
{
    my $image_lists_ref = shift;

    my %global_hash;
    my %module_hash;
    my %custom_hash;
    my %help_hash;

    foreach my $i ( @{$image_lists_ref} ) {
        parse_image_list($i, \%global_hash, \%module_hash, \%custom_hash, \%help_hash);
    }

    return (\%global_hash, \%module_hash, \%custom_hash, \%help_hash);
}

sub parse_image_list
{
    my $image_list      = shift;
    my $global_hash_ref = shift;
    my $module_hash_ref = shift;
    my $custom_hash_ref = shift;
    my $help_hash_ref = shift;

    print_message("parsing '$image_list' ...") if $verbose;
    my $linecount = 0;
    open(IMAGE_LIST, "< $image_list") or die "ERROR: can't open $image_list: $!";
    while ( <IMAGE_LIST> ) {
        $linecount++;
        next if /^\s*#/;
        next if /^\s*$/;
        # clean up trailing whitespace
        tr/\r\n//d;
        s/\s+$//;
        # clean up backslashes and double slashes
        tr{\\}{/}s;
        tr{/}{}s;
        # hack "res" back into globals
        if ( /^\Q$img_global\E\/(.*)$/o ) {
            $global_hash_ref->{"res/".$1}++;
            next;
        }
        if ( /^\Q$img_module\E\/(.*)$/o ) {
            $module_hash_ref->{$1}++;
            next;
        }
        if ( /^\Q$img_help\E\/(.*)$/o ) {
            $help_hash_ref->{$1}++;
            next;
        }
        # parse failed if we reach this point, bail out
        close(IMAGE_LIST);
        print_error("can't parse line $linecount from file '$image_list'", 4);
    }
    close(IMAGE_LIST);

    return ($global_hash_ref, $module_hash_ref, $custom_hash_ref, $help_hash_ref);
}

sub find_custom
{
    my $custom_hash_ref = shift;
    my $keep_back;
    for my $path (@custom_path) {
    find({ wanted => \&wanted, no_chdir => 0 }, $path);
    foreach ( @custom_list ) {
        if ( /^\Q$path\E\/(.*)$/ ) {
        $keep_back=$1;
        if (!defined $custom_hash_ref->{$keep_back}) {
            $custom_hash_ref->{$keep_back} = $path;
        }
        }
    }
    }
}

sub wanted
{
    my $file = $_;

    if ( $file =~ /.*\.png$/ && -f $file ) {
        push @custom_list, $File::Find::name;
    }
}

sub create_zip_list
{
    my $global_hash_ref = shift;
    my $module_hash_ref = shift;
    my $custom_hash_ref = shift;
    my $help_hash_ref = shift;

    my %zip_hash;
    my @warn_list;

    print_message("assemble image list ...") if $verbose;
    foreach ( keys %{$global_hash_ref} ) {
        # check if in 'global' and in 'module' list and add to warn list
        if ( exists $module_hash_ref->{$_} ) {
            push(@warn_list, $_);
            next;
        }
        if ( exists $custom_hash_ref->{$_} ) {
            $zip_hash{$_} = $custom_hash_ref->{$_};
            next;
        }
        # it's neither in 'module' nor 'custom', record it in zip hash
        $zip_hash{$_} = $global_path;
    }
    foreach ( keys %{$module_hash_ref} ) {
        if ( exists $custom_hash_ref->{$_} ) {
            $zip_hash{$_} = $custom_hash_ref->{$_};
            next;
        }
        # it's not in 'custom', record it in zip hash
        $zip_hash{$_} = $module_path;
    }
    foreach ( keys %{$help_hash_ref} ) {
        $zip_hash{$_} = $helpimg_path;
    }

    if ( @warn_list ) {
        foreach ( @warn_list ) {
            print_warning("$_ is duplicated in 'global' and 'module' list");
        }
    }

    return \%zip_hash
}

sub is_file_newer
{
    my $test_hash_ref = shift;
    my $reference_stamp = 0;

    print_message("checking timestamps ...") if $verbose;
    if ( -e $out_file ) {
        $reference_stamp = (stat($out_file))[9];
        print_message("found $out_file with $reference_stamp ...") if $verbose;
    }
    return 1 if $reference_stamp == 0;

    foreach ( sort keys %{$test_hash_ref} ) {
        my $path = $test_hash_ref->{$_};
        $path .= "/" if "$path" ne "";
        $path .= "$_";
        print_message("checking '$path' ...") if $extra_verbose;
        my $mtime = (stat($path))[9];
        return 1 if $reference_stamp < $mtime;
    }
    return 0;
}

sub optimize_zip_layout($)
{
    my $zip_hash_ref = shift;

    if (!defined $sort_file) {
    print_message("no sort file - sorting alphabetically ...") if $verbose;
    return sort keys %{$zip_hash_ref};
    }
    print_message("sorting from $sort_file ...") if $verbose;

    my $orderh;
    my %included;
    my @sorted;
    open ($orderh, $sort_file) || die "Can't open $sort_file: $!";
    while (<$orderh>) {
    /^\#.*/ && next; # comments
    s/[\r\n]*$//;
    /^\s*$/ && next;
    my $file = $_;
    if (!defined $zip_hash_ref->{$file}) {
        print "unknown file '$file'\n" if ($extra_verbose);
    } else {
        push @sorted, $file;
        $included{$file} = 1;
    }
    }
    close ($orderh);

    for my $img (sort keys %{$zip_hash_ref}) {
    push @sorted, $img if (!$included{$img});
    }

    print_message("done sort ...") if $verbose;

    return @sorted;
}

sub copy_images($)
{
    my ($zip_hash_ref) = @_;
    my $dir = tempdir();
    foreach (keys %$zip_hash_ref) {
        my $path = $zip_hash_ref->{$_} . "/$_";
        my $outpath = $dir . "/$_";
        print_message("copying '$path' to '$outpath' ...") if $extra_verbose;
        if ( -e $path) {
            my $dirname = dirname($outpath);
            if (!-d $dirname) {
                make_path($dirname);
            }
            copy($path, $outpath)
                or print_error("can't add file '$path' to image dir: $!", 5);
        }
    }
    return $dir;
}

sub create_zip_archive($$$)
{
    my ($zip_hash_ref, $links_hash_ref, $image_dir_ref) = @_;

    print_message("creating image archive ...") if $verbose;

    chdir $image_dir_ref;

    if (keys %{$links_hash_ref}) {
        write_links($links_hash_ref, $image_dir_ref);
        system "zip $tmp_out_file links.txt";
            # print_error("failed to add links file: $!", 5);
    }

    my @sorted_list = optimize_zip_layout($zip_hash_ref);
    my $sorted_file = File::Temp->new();
    foreach my $item (@sorted_list) {
        print $sorted_file "$item\n";
    }
    binmode $sorted_file; # flush

    system "cat $sorted_file | zip -0 -@ $tmp_out_file";
        # print_error("write image zip archive '$tmp_out_file' failed. Reason: $!", 6);
    chdir; # just go out of the temp dir
}

sub replace_file
{
    my $source_file = shift;
    my $dest_file = shift;
    my $result = 0;

    $result = unlink($dest_file) if -f $dest_file;
    if ( $result != 1 && -f $dest_file ) {
        unlink $source_file;
        print_error("couldn't remove '$dest_file'",1);
    }  else {
        if ( !rename($source_file, $dest_file)) {
            unlink $source_file;
            print_error("couldn't rename '$source_file'",1);
        }
    }
    return;
}

sub usage
{
    print STDERR "Usage: packimages.pl [-h] -o out_file -g g_path -m m_path -c c_path -l imagelist_file\n";
    print STDERR "Creates archive of images\n";
    print STDERR "Options:\n";
    print STDERR "    -h                 print this help\n";
    print STDERR "    -o out_file        path to output archive\n";
    print STDERR "    -g g_path          path to global images directory\n";
    print STDERR "    -m m_path          path to module images directory\n";
    print STDERR "    -c c_path          path to custom images directory\n";
    print STDERR "    -s sort_file       path to image sort order file\n";
    print STDERR "    -l imagelist_file  file containing list of image list files\n";
    print STDERR "    -v                 verbose\n";
    print STDERR "    -vv                very verbose\n";
}

sub print_message
{
    my $message     = shift;

    print "$script_name: ";
    print "$message\n";
    return;
}

sub print_warning
{
    my $message     = shift;

    print STDERR "$script_name: ";
    print STDERR "WARNING $message\n";
    return;
}

sub print_error
{
    my $message     = shift;
    my $error_code  = shift;

    print STDERR "$script_name: ";
    print STDERR "ERROR: $message\n";

    if ( $error_code ) {
        print STDERR "\nFAILURE: $script_name aborted.\n";
        exit($error_code);
    }
    return;
}

sub read_links($$)
{
    my $links = shift;
    my $path = shift;

    my $fname = "$path/links.txt";
    if (!-f "$fname") {
        return;
    }

    my $fh;
    open ($fh, $fname) || die "Can't open: $fname: $!";
    # Syntax of links file:
    # # comment
    # missing-image image-to-load-instead
    while (<$fh>) {
        my $line = $_;
        $line =~ s/\r//g;   # DOS line-feeds
        $line =~ s/\#.*$//; # kill comments
        $line =~ m/^\s*$/ && next; # blank lines
        if ($line =~ m/^([^\s]+)\s+(.*)$/) {
            my ($missing, $replace) = ($1, $2);
            # enter into hash, and overwrite previous layer if necessary
            $links->{$1} = $2;
        } else {
            die "Malformed links line: '$line'\n";
        }
    }
    close ($fh);
}

# write out the links
sub write_links($$)
{
    my ($links, $out_dir_ref) = @_;
    open (my $fh, ">", "$out_dir_ref/links.txt")
        || die "can't create links.txt";
    for my $missing (sort keys %{$links}) {
        my $line = $missing . " " . $links->{$missing} . "\n";
        print $fh $line;
    }
    close $fh;
}

# Ensure that no link points to another link
sub check_links($)
{
    my $links = shift;
    my $stop_die = 0;

    for my $link (keys %{$links}) {
        my $value = $links->{$link};
        if (defined $links->{$value}) {
            print STDERR "\nLink: $link -> $value -> " . $links->{$value};
            $stop_die = 1;
        }
    }
    if ( $stop_die ) {
        die "\nSome icons in links.txt were found to link to other linked icons.\n\n";
    }

}

# remove any files from our zip list that are linked
sub remove_links_from_zip_list($$)
{
    my $zip_hash_ref = shift;
    my $links = shift;
    for my $link (keys %{$links}) {
        if (defined $zip_hash_ref->{$link}) {
            delete $zip_hash_ref->{$link};
        }
    }
}
