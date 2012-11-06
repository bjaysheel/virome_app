#! /usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
BEGIN{foreach (@INC) {s/\/usr\/local\/packages/\/local\/platform/}};

=head1 NAME

   expand_uniref100P_btab.pl

=head1 SYNOPSIS

    USAGE: expand_uniref100P_btab.pl --input filename.btab --ouput outputfile.modified.btab

=head1 OPTIONS

B<--input,-i>
   Input file name

B<--help,-h>
   This help message


=head1  DESCRIPTION

    Expand UNIREF100P btab blast output with KEGG, COG, SEED and ACLAME
    results.


=head1  INPUT

    The input is defined with --input.  Input must be a btab blast output
    --output is the full path to output file

    Input is expected to have 21 fields and output of blast2btab

    1   query_name
    2   date
    3   query_length
    4   algorithm
    5   database_name
    6   hit_name
    7   qry_start
    8   qry_end
    9   hit_start
    10  hit_end
    11  percent_identity
    12  percent_similarity
    13  raw_score
    14  bit_score
    15  NULL
    16  hit_description
    17  blast_frame
    18  qry_strand (Plus | Minus)
    19  hit_length
    20  e_value
    21  p_value

=head1  OUTPUT

    Clean btab file, if METAGENOMES hit update hit description

    1   query_name
    2   query_length
    3   algorithm
    4   database_name
    5   hit_name
    6   qry_start
    7   qry_end
    8   hit_start
    9   hit_end
    10  percent_identity
    11  percent_similarity
    12  raw_score
    13  bit_score
    14  hit_description
    15  blast_frame
    16  qry_strand (Plus | Minus)
    17  hit_length
    18  e_value

    if UNIREF100P blast expanded btab blast output with
    KEGG, COG, SEED and ACLAME results and append taxonomy data.

    19  domain
    20  kingdom
    21  phylum
    22  class
    23  order
    24  family
    25  genus
    26  species
    27  organism
	28  functional hit

=head1  CONTACT

  Jaysheel D. Bhavsar @ bjaysheel[at]gmail[dot]com


==head1 EXAMPLE

  expand_uniref100P_btab.pl -i input_file_name -ld lookup/file/dir -o output/dir -e igs

=cut


use strict;
use warnings;
use DBI;
use Pod::Usage;
use MLDBM 'DB_File';
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use UTILS_V;
use Data::Dumper;

BEGIN {
  use Ergatis::Logger;
}

my %options = ();
my $results = GetOptions (\%options,
                          'input|i=s',
						  'lookupDir|ld=s',
						  'output|o=s',
						  'env|e=s',
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
#### DEFINE GLOBAL VAIRABLES.
##############################################################################
my $db_user;
my $db_pass;
my $dbname;
my $db_host;
my $host;

my $dbh1;

## make sure everything passed was peachy
&check_parameters(\%options);

##############################################################################

my $utils = new UTILS_V;

#tie lookup files
tie(my %kegg_lkp, 'MLDBM', $options{lookupDir}."/kegg.ldb");
tie(my %cog_lkp, 'MLDBM', $options{lookupDir}."/cog.ldb");
tie(my %seed_lkp, 'MLDBM', $options{lookupDir}."/seed.ldb");
tie(my %aclame_lkp, 'MLDBM', $options{lookupDir}."/aclame.ldb");
tie(my %uniref_lkp, 'MLDBM', $options{lookupDir}."/uniref.ldb");
tie(my %mgol_lkp, 'MLDBM', $options{lookupDir}."/mgol.ldb");

#set class obj
$utils->kegg_lookup(\%kegg_lkp);
$utils->cog_lookup(\%cog_lkp);
$utils->seed_lookup(\%seed_lkp);
$utils->aclame_lookup(\%aclame_lkp);
$utils->uniref_lookup(\%uniref_lkp);
$utils->mgol_lookup(\%mgol_lkp);

open (BTAB, "<", $options{input}) or die "Can not open file $options{input}\n";
open (OUT, ">", $options{output}) or die "Can not open file to write $options{output}\n";

my $prev = "";
my $curr = "";
my @seqarray = ();
my @unirefarray = ();
my @keggarray =();
my @cogarray = ();
my @aclamearray = ();
my @seedarray = ();

my $db_name = "UNIREF100P";

while (<BTAB>){
  my $btabline = $_;
  chomp $btabline;

  my @tmp = split(/\t/,$btabline);

  #remove date, p-value and null value from the original blast2btab output.
  #this will create an array of length 17 or 18 items instead of 21 items.
  my @arr = @tmp[0,2..13,15..19];

  #$btabline = '';
  $btabline = join("\t", @arr);
  $db_name = $arr[3];

  if($db_name =~ /uniref100p/i){
	$curr = $arr[0];
	if($curr eq $prev){
		push (@seqarray, $btabline);
	} else{
		expand();

		#reset array after expansion for new set of seq.
		@seqarray = ();
		@unirefarray = ();
		@keggarray = ();
		@cogarray = ();
		@seedarray = ();
		@aclamearray = ();

		#insert the first new seq info.
		push (@seqarray, $btabline);
		$prev = $curr;
	}##END OF ELSE CONDITION
  } elsif ($db_name =~ /metagenomes/i){
	print OUT modifyDescription($btabline)."\n";
  } else {
	print OUT $btabline."\n";
  }
}##END OF BTAB file

#expand last set of sequences.
if($db_name =~ /UNIREF100P/i){
  expand();
}

untie(%kegg_lkp);
untie(%seed_lkp);
untie(%aclame_lkp);
untie(%uniref_lkp);

close(OUT);
exit(0);

###############################################################################
####  SUBS
###############################################################################
sub check_parameters {
  my $options = shift;

  ## make sure sample_file and output_dir were passed
  unless ($options{input} && $options{lookupDir} && $options{output} && $options{env}) {
	$logger->logdie("No input defined, plesae read perldoc $0\n\n");
    exit(1);
  }

  if ($options{env} eq 'dbi') {
	$db_user = q|bhavsar|;
	$db_pass = q|P3^seus|;
	$db_name = q|VIROME|;
	$db_host = $options{server}.q|.dbi.udel.edu|;
	$host = q|virome.dbi.udel.edu|;
  } elsif ($options{env} eq 'igs') {
	$db_user = q|dnasko|;
	$db_pass = q|dnas_76|;
	$db_name = q|virome_processing|;
	$db_host = q|dnode001.igs.umaryland.edu|;
	$host = q|dnode001.igs.umaryland.edu|;
  } elsif ($options{env} eq 'ageek') {
	$db_user = q|bhavsar|;
	$db_pass = q|Application99|;
	$db_name = $options{server};
	$db_host = q|10.254.0.1|;
	$host = q|10.254.0.1|;
  } elsif ($options{env} =~ /camera/){
	$db_user = q|virome_app|;
	$db_pass = q|camera123|;
	$db_name = $options{server};
	$db_host = q|dory.internal.crbs.ucsd.edu|;
	$host = q|dory.internal.crbs.ucsd.edu|;
  } else {
	$db_user = q|kingquattro|;
	$db_pass = q|Un!c0rn|;
	$db_name = q|VIROME|;
	$db_host = q|localhost|;
	$host = q|localhost|;
  }

  $dbh1 = DBI->connect("DBI:mysql:database=uniref_lookup2;host=$host",
  	       "$db_user", "$db_pass",{PrintError=>1, RaiseError =>1, AutoCommit =>1});
}

##############################################################################
sub expand {

	my ($sFxn,$kFxn,$cFxn,$aFxn,$gFxn)=(0,0,0,0,0);

    foreach my $seqline(@seqarray){
	  chomp $seqline;

	  #split blast output.
	  my @arr1 = split(/[\t]/,$seqline);

	  #get hit_name/accession.
	  my $unirefId = $arr1[4];

	  #get uniref lookup record
	  my $u_acc_hash = $utils->get_acc_from_lookup("uniref",$unirefId);
	  my $u_hash = $u_acc_hash->{acc_data}[0];

	  #prepare taxonomy
	  my $taxonomy = ((defined $u_hash->{domain}) ? $u_hash->{domain} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{kingdom}) ? $u_hash->{kingdom} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{phylum}) ? $u_hash->{phylum} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{n_class}) ? $u_hash->{n_class} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{n_order}) ? $u_hash->{n_order} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{family}) ? $u_hash->{family} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{genus}) ? $u_hash->{genus} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{species}) ? $u_hash->{species} : 'UNKNOWN')."\t";
	  $taxonomy .= ((defined $u_hash->{organism}) ? $u_hash->{organism} : 'UNKNOWN');

	  #replace hit_description in arr_id 14 and then append taxonomy data.
	  $arr1[13] = (defined $u_hash->{desc}) ? $utils->trim($u_hash->{desc}) : 'UNKNOWN';
	  my $resultrow = join("\t",@arr1)."\t".$taxonomy;

	  if (!$gFxn) {
		my $go_fxn_stmt = qq{SELECT gc.name
							FROM gofxn g INNER JOIN go_chains gc ON g.chain_id=gc.chain_id
							WHERE gc.level=1 and g.realAcc = ?
							LIMIT 1};
		my $go_fxn_qry = $dbh1->prepare($go_fxn_stmt);
		$go_fxn_qry->execute($unirefId);

		while (my $result = $go_fxn_qry->fetchrow_hashref()) {
		  if ($$result{name} !~ /unknown|unclassified|unassigned|uncharacterized/i){
			$resultrow .= "\t1\n";
			$gFxn=1;
		  }
		}
		if (!$gFxn){
		  $resultrow .= "\t0\n";
		}
	  } else { $resultrow .= "\t0\n"; }

	  push (@unirefarray, $resultrow);

	  ## CHECK IF KEGGID IS NOT NULL
	  if(defined $u_hash->{kegg_acc} && length($utils->trim($u_hash->{kegg_acc})) > 1){
		  #reset array.
		  @arr1 = ();
		  @arr1 = split(/[\t]/,$seqline);

		  #split accession by ; if there are multiple acc's
		  my @k_arr = split(/;/,$u_hash->{kegg_acc});

		  # get acc array from lookup hash
		  my $k_acc_hash = $utils->get_acc_from_lookup("kegg",$k_arr[0]);
		  my $k_hash = $k_acc_hash->{acc_data}[0];

		  $arr1[3] = q|KEGG|; #replace database name
		  $arr1[4] = $k_arr[0]; #replace hit_name
		  #replace hit_description
		  $arr1[13] = (defined $k_hash->{desc}) ? $utils->trim($k_hash->{desc}) : 'UNKNOWN';

		  my $kegg_row = join("\t",@arr1)."\t".$taxonomy;

		  # if acc has meaning full fxn 1 then set fxnal hit at 1 else 0
		  if ((!$kFxn) && (defined $k_hash->{fxn1}) && ($k_hash->{fxn1} !~ /unknown|unclassified|unassigned|uncharacterized/i)){
			$kegg_row .= "\t1\n";
			$kFxn=1;
		  } else { $kegg_row .= "\t0\n"; }

		  push(@keggarray, $kegg_row);
	  }

	  ## CHECK IF COGID IS NOT NULL
	  $resultrow = "";
	  if(defined $u_hash->{cog_acc} && length($utils->trim($u_hash->{cog_acc})) > 1){
		  #reset array.
		  @arr1 = ();
		  @arr1 = split(/[\t]/,$seqline);

		  #split accession by ; if there are multiple acc's
		  my @c_arr = split(/;/,$u_hash->{cog_acc});

		  # get acc array from lookup hash
		  my $c_acc_hash = $utils->get_acc_from_lookup("cog",$c_arr[0]);
		  my $c_hash = $c_acc_hash->{acc_data}[0];

		  $arr1[3] = q|COG|; #replace database name
		  $arr1[4] = $c_arr[0]; #replace hit_name,
		  #no desc in COG table use uniref description
		  $arr1[13] = $utils->trim($u_hash->{desc});

		  my $cog_row .= join("\t",@arr1)."\t".$taxonomy;

		  # if acc has meaning full fxn 1 then set fxnal hit at 1 else 0
		  if ((!$cFxn) && (defined $c_hash->{fxn1}) && ($c_hash->{fxn1} !~ /unknown|unclassified|unassigned|uncharacterized/i)){
			$cog_row .= "\t1\n";
			$cFxn=1;
		  } else { $cog_row .= "\t0\n"; }

		  push(@cogarray, $cog_row);
	  }

	  ## CHECK IF SEED IS NOT NULL
	  if(defined $u_hash->{seed_acc} && length($utils->trim($u_hash->{seed_acc})) > 1){
		  #reset array.
		  @arr1 = ();
		  @arr1 = split(/[\t]/,$seqline);

		  #split accession by ; if there are multiple acc's
		  my @s_arr = split(/;/,$u_hash->{seed_acc});

		  # get acc lookup hash
		  my $s_acc_hash = $utils->get_acc_from_lookup("seed",$s_arr[0]);
		  my $s_hash = $s_acc_hash->{acc_data}[0];

		  $arr1[3] = q|SEED|; #replace database name
		  $arr1[4] = $s_arr[0]; #replace hit_name
		  #replace hit_description
		  $arr1[13] = (defined $s_hash->{desc}) ? $utils->trim($s_hash->{desc}) : 'UNKNOWN';

		  my $seed_row .= join("\t",@arr1)."\t".$taxonomy;

		  # if acc has meaning full fxn 1 then set fxnal hit at 1 else 0
		  if ((!$sFxn) && (defined $s_hash->{fxn1}) && ($s_hash->{fxn1} !~ /unknown|unclassified|unassigned|uncharacterized/i)){
			$seed_row .= "\t1\n";
			$sFxn=1;
		  } else { $seed_row .= "\t0\n"; }

		  push(@seedarray, $seed_row);
	  }

	  ## CHECK IF ACLAME IS NOT NULL
	  if(defined $u_hash->{aclame_acc} && length($utils->trim($u_hash->{aclame_acc})) > 1){
		  #reset array.
		  @arr1 = ();
		  @arr1 = split(/[\t]/,$seqline);

		  #split accession by ; if there are multiple acc's
		  my @a_arr = split(/;/,$u_hash->{aclame_acc});

		  # get acc lookup hash
		  my $a_acc_hash = $utils->get_acc_from_lookup("aclame",$a_arr[0]);
		  my $a_hash = $a_acc_hash->{acc_data}[0];

		  $arr1[3] = q|ACLAME|; #replace database name
		  $arr1[4] = $a_arr[0]; #replace hit_name
		  #replace hit_description
		  $arr1[13] = (defined $a_hash->{desc}) ? $utils->trim($a_hash->{desc}) : 'UNKNOWN';

		  my $aclame_row = join("\t",@arr1)."\t".$taxonomy;

		  # if acc has meaning full fxn 1 then set fxnal hit at 1 else 0
		  if ((!$aFxn) && (defined $a_hash->{fxn1}) && ($a_hash->{fxn1} !~ /unknown|unclassified|unassigned|uncharacterized/i)){
			$aclame_row .= "\t1\n";
			$aFxn=1;
		  } else { $aclame_row .= "\t0\n"; }

		  push(@aclamearray, $aclame_row);
	  }

    }##END OF ITERATING THROUGH ALL UNIREF RECORDS FOR A ACCESSION

    ##PRINT UNIREF FIRST
    foreach my $unirefline(@unirefarray){
	  print OUT $unirefline;
    }

    foreach my $aclameline(@aclamearray){
	  print OUT $aclameline;
    }

    foreach my $seedline(@seedarray){
	  print OUT $seedline;
    }

    foreach my $keggline(@keggarray){
	  print OUT $keggline;
    }

    foreach my $cogline(@cogarray){
	  print OUT $cogline;
    }
}

##############################################################################
sub modifyDescription{
  my $seqline = $_[0];
  my @arr = split(/[\t]/,$seqline);

  my $str = "";

  #get mgol hash entry from hit_name ($arr[4]) prefix
  my $mgol_acc_hash = $utils->get_acc_from_lookup("mgol",substr($arr[4],0,3));

  if (defined $mgol_acc_hash){
    my $mgol_hash = $mgol_acc_hash->{acc_data}[0];
    my $dwel = "N/A";

    if ($mgol_hash->{org_subst} ne "UNKNOWN"){
	$dwel = 'dwelling ' .$mgol_hash->{org_subst};
    } else {
	$dwel = $mgol_hash->{phys_subst};
    }

    $str = "$mgol_hash->{lib_type} metagenome from $mgol_hash->{ecosystem} $dwel ".
	      "near $mgol_hash->{geog_place_name}, $mgol_hash->{country} [library: $mgol_hash->{lib_shortname}]";
    $str =~ s/'|"//g;
  }

  $arr[13] = $str;
  return join("\t",@arr);
}
