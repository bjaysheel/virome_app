#!/usr/bin/perl -w

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
BEGIN{foreach (@INC) {s/\/usr\/local\/packages/\/local\/platform/}};

=head1 NAME

sequence-prep.pl - prepare sequence info for upload to db

=head1 SYNOPSIS

USAGE: sequence-prep.pl
			--input=/library/list/file
            --outdir=/output/dir
          [ --log=/path/to/logfile
            --debug=N ]

=head1 OPTIONS

B<--outdir, -od>
    Output dir where sequence prep file is uploaded

B<--input, -i>
    tab delimited library info file.

B<--debug,-d>
    Debug level.  Use a large number to turn on verbose debugging.

B<--log,-l>
    Log file

B<--help,-h>
    This help message

=head1  DESCRIPTION

This script is used to prepare sequence for mysql upload.

=head1  INPUT

Create a sequence relationship mysql batch file for a given library.

=head1  CONTACT

    Jaysheel D. Bhavsar
    bjaysheel@gmail.com

=cut

use strict;
use DBI;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use Pod::Usage;
use UTILS_V;
use Bio::SeqIO;

BEGIN {
  use Ergatis::Logger;
}

##############################################################################
my %options = ();
my $results = GetOptions (\%options,
						  'output|o=s',
                          'input|i=s',
						  'env|e=s',
                          'log|l=s',
                          'debug|d=s',
                          'help|h') || pod2usage();

my $logfile = $options{'log'} || Ergatis::Logger::get_default_logfilename();
my $logger = new Ergatis::Logger('LOG_FILE'=>$logfile,
                                  'LOG_LEVEL'=>$options{'debug'});
$logger = $logger->get_logger();

## display documentation
if( $options{'help'} ){
    pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} );
}
##############################################################################

## make sure everything passed was peachy
&check_parameters(\%options);

##############################################################################

#utility moduel
my $utils = new UTILS_V;
my $libraryId = $utils->get_libraryId_from_file($options{input});

$utils->set_db_params($options{env});

#set output file
open (OUT, ">", $optios{output}) || die $logger->logdie("Could not open file $options{output}");

#init db connection
my $dbh = DBI->connect("DBI:mysql:database=".$utils->db_name.";host=".$utils->db_host,
	    $utils->db_user, $utils->db_pass,{PrintError=>1, RaiseError =>1, AutoCommit =>1});

$sel_qry = qq|SELECT id,name FROM sequence WHERE deleted=0 and libraryId=? and typeId=?|

#setup hashes
my %read_hash=();
my %orf_hash=();

#get all reads.
my $seq_sth = $dbh->prepare($sel_qry);
$seq_sth->execute($libraryId,1);

while (my $row = $seq_sth->fetchrow_hashref){
	print OUT ($$row{id}."\t".$$row{id}."\t".1."\n");
	$read_hash{$$row{name}} = $$row{id};
}

#get all rRNAs.
my $seq_sth = $dbh->prepare($sel_qry);
$seq_sth->execute($libraryId,2);

while (my $row = $seq_sth->fetchrow_hashref){
	print OUT ($$row{id}."\t".$$row{id}."\t".2."\n");
	$read_hash{$$row{name}} = $$row{id};
}

#get all orfs (aa).
my $seq_sth = $dbh->prepare($sel_qry);
$seq_sth->execute($libraryId,3);

while (my $row = $seq_sth->fetchrow_hashref){
	$read_name = $$row{name};
	$read_name =~ s/(_\d+_\d+_\d+)$//;

	print OUT ($read_hash{read_name}."\t".$$row{id}."\t".3."\n");
	$orf_hash{$$row{name}} = $$row{id};
}

#remove read hash (help with memory requirement)
my %read_hash=();

#get all orfs (dna).
my $seq_sth = $dbh->prepare($sel_qry);
$seq_sth->execute($libraryId,4);

while (my $row = $seq_sth->fetchrow_hashref){
	print OUT ($orf_hash{$$row{name}}."\t".$$row{id}."\t".4."\n");
}

close(OUT);
exit(0);

###############################################################################
sub check_parameters {
	## at least one input type is required
	unless ($options{output} && $options{input} && $options{env}) {
		pod2usage({-exitval => 2, -message => "error message", -verbose => 1, -output => \*STDERR});
		$logger->logdie("No input defined, plesae read perldoc $0\n\n");
		exit(1);
	}
}
