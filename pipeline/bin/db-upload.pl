#!/usr/bin/perl -w

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
BEGIN{foreach (@INC) {s/\/usr\/local\/packages/\/local\/platform/}};

=head1 NAME

db-upload.pl: Uplaod file into mysql db

=head1 SYNOPSIS

USAGE: db-upload.pl
            --input=/file/preped/for/mysqlimport
			--table=/tablename
			--env=/env/where/executing
			--outdir=/output/dir/loc
			[ --log=/path/to/logfile
			--debug=N]

=head1 OPTIONS

B<--input, -i>
    The full path to tab delimited file prepared for mysqlimport.

B<--table, -t>
    mysql db table name

B<--env, -e>
    env where is the script beeing executed igs,dbi,test

B<--outdir, -o>
    output directory

B<--debug,-d>
    Debug level.  Use a large number to turn on verbose debugging.

B<--log,-l>
    Log file

B<--help,-h>
    This help message

=head1  DESCRIPTION

This script is used to upload info into db.

=head1  INPUT

=head1  CONTACT

    Jaysheel D. Bhavsar
    bjaysheel@gmail.com

=cut

use strict;
use DBI;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use Pod::Usage;
use Data::Dumper;
use UTILS_V;

BEGIN {
  use Ergatis::Logger;
}

##############################################################################
my %options = ();
my $results = GetOptions (\%options,
                          'input|i=s',
						  'outdir|o=s',
						  'table|t=s',
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

# check if the file is empty.
unless(-s $options{input} > 0){
  print STDERR "This file $options{input} seem to be empty nothing therefore nothing to do.";
  $logger->debug("This file $options{input} seem to be empty nothing therefore nothing to do.");
  exit(0);
}

###############################################################################

my $utils = new UTILS_V;
my $column_list = '';

$utils->set_db_params($options{env});

$options{table} = lc $options{table};

if ($options{table} =~ /sequence/i){
	$column_list =  "sequence.libraryId,sequence.name,sequence.header,";
	$column_list .= "sequence.gc,sequence.basepair,sequence.size,sequence.type";

} elsif ($options{table} =~ /orf/i){
	$column_list =  "orf.readId,orf.seqId,orf.seq_name,orf.gene_num,";
	$column_list .= "orf.gc_percent,orf.rbs_percent,orf.start,orf.end,";
	$column_list .= "orf.strand,orf.frame,orf.type,orf.score,orf.model,";
	$column_list .= "orf.rbs_start,orf.rbs_end,orf.rbs_score,";
	$column_list .= "orf.caller";

} elsif ($options{table} =~ /blast(x|n|p)/i){
	$column_list =  "$options{table}.query_name,$options{table}.query_length,";
	$column_list .= "$options{table}.algorithm,$options{table}.database_name,";
	$column_list .= "$options{table}.hit_name,$options{table}.qry_start,";
	$column_list .= "$options{table}.qry_end,$options{table}.hit_start,";
	$column_list .= "$options{table}.hit_end,$options{table}.percent_identity,";
	$column_list .= "$options{table}.percent_similarity,$options{table}.raw_score,";
	$column_list .= "$options{table}.bit_score,$options{table}.hit_description,";
	$column_list .= "$options{table}.blast_frame,$options{table}.qry_strand,";
	$column_list .= "$options{table}.subject_length,$options{table}.e_value,";
	$column_list .= "$options{table}.domain,$options{table}.kingdom,";
	$column_list .= "$options{table}.phylum,$options{table}.class,";
	$column_list .= "$options{table}.order,$options{table}.family,";
	$column_list .= "$options{table}.genus,$options{table}.species,";
	$column_list .= "$options{table}.organism,$options{table}.sequenceId,";
	$column_list .= "$options{table}.sys_topHit,$options{table}.db_ranking_code,";
	$column_list .= "$options{table}.fxn_topHit";

} elsif ($options{table} =~ /tRNA/i){
	$column_list =  "tRNA.sequenceId,tRNA.num,tRNA.tRNA_start,";
	$column_list .= "tRNA.tRNA_end,tRNA.anti,tRNA.intron,tRNA.cove_start,";
	$column_list .= "tRNA.cove_end,tRNA.score";

	$options{table} = "tRNA";

} elsif ($options{table} =~ /sequence_relationship/i){
	$column_list = "sequence_relationship.subjectId,sequence_relationship.objectId,sequence_relationship.typeId";
}

my $filename = $options{outdir}."/".$options{table}.".txt";

my $cmd = "ln -s $options{input} $filename";
system($cmd);

#setup mysql import command
$cmd = '';
$cmd = "mysqlimport --columns=$column_list --compress --fields-terminated-by='\\t'";
$cmd .= " --lines-terminated-by='\\n' --ignore --host=". $utils->db_host ." --user=". $utils->db_user;
$cmd .= " --password=". $utils->db_pass ." ". $utils->db_name ." -L $filename";

#execute mysql import
system($cmd);

if (( $? >> 8 ) != 0 ){
	print STDERR "command failed: $!\n";
	print STDERR $cmd."\n";
	exit($?>>8);
}

#remove link file, prevent error if there is more than one file in the group.
$cmd = "rm $filename";
system($cmd);

exit(0);

###############################################################################
sub check_parameters {
  ## at least one input type is required
	unless ( $options{input} && $options{table} && $options{env} && $options{outdir}) {
		pod2usage({-exitval => 2,  -message => "error message", -verbose => 1, -output => \*STDERR});
		$logger->logdie("No input defined, plesae read perldoc $0\n\n");
		exit(1);
	}
}
