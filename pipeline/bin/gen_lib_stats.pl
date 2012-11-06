#! /usr/bin/perl

=head1 NAME

  gen_lib_stats.pl

=head1 SYNOPSIS

   USAGE: gen_lib_stats.pl --server server-name --env dbi [--library libraryId]

=head1 OPTIONS

B<--server,-s>
  Server name that need to be processed.

B<--library,-l>
   Specific libraryId whoes taxonomy info to collect

B<--env,-e>
   Specific environment where this script is executed.  Based on these values
   db connection and file locations are set.  Possible values are
   igs, dbi, ageek or test

B<--help,-h>
  This help message


=head1  DESCRIPTION

  This script will process all libraries on a given server.  Get a
  break down of
     ORF types (missing 3', missing 5', incomplete, complete)
     ORF model (bacteria, archaea, phage)
     LIB type (viral only, microbial only, top viral, top microbial)
     FUNCTIONAL and UNClassified

  Counts for each categories are stored in _cnt field, and all sequenceIds
  for each categories are stored in an external file.

=head1  INPUT

  The input is defined with --server which is a domain name only.
     e.g.: calliope (if server name is calliope.dbi.udel.edu)


=head1  OUTPUT

  All counts for each category are stored in "statistics" table on the "server"
  given as input.  All sequenceIds for each category are stored in an
  external file, and its location is stored in db.

=head1  CONTACT

 Jaysheel D. Bhavsar @ bjaysheel[at]gmail[dot]com


==head1 EXAMPLE

 gen_lib_stats.pl --server calliope --env dbi --library 31

=cut


use strict;
use warnings;
use DBI;
use Switch;
use LIBInfo;
use Pod::Usage;
use Data::Dumper;
use UTILS_V;
use MLDBM 'DB_File';
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);

BEGIN {
  use Ergatis::Logger;
}

my %options = ();
my $results = GetOptions (\%options,
			  'server|s=s',
			  'library|b=s',
			  'env|e=s',
			  'input|i=s',
			  'lookupDir|ld=s',
			  'outdir|o=s',
			  'log|l=s',
			  'debug|d=s',
			  'help|h') || pod2usage();

## display documentation
if( $options{'help'} ) {
  pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} );
}

my $logfile = $options{'log'} || Ergatis::Logger::get_default_logfilename();
my $logger = new Ergatis::Logger('LOG_FILE'=>$logfile,
				 'LOG_LEVEL'=>$options{'debug'});
$logger = $logger->get_logger();
##############################################################################
#### DEFINE GLOBAL VAIRABLES.
##############################################################################
my $db_user;
my $db_pass;
my $dbname;
my $db_host;
my $host;

my $dbh0;
my $dbh1;
my $dbh;

my $libinfo = LIBInfo->new();
my $libObject;

my $file_loc = $options{outdir};

## make sure everything passed was peachy
&check_parameters(\%options, \$dbh0, \$dbh1, \$dbh);

my $utils = new UTILS_V;
tie(my %aclame_lkp, 'MLDBM', $options{lookupDir}."/aclame.ldb");
tie(my %seed_lkp, 'MLDBM', $options{lookupDir}."/seed.ldb");
tie(my %kegg_lkp, 'MLDBM', $options{lookupDir}."/kegg.ldb");
tie(my %cog_lkp, 'MLDBM', $options{lookupDir}."/cog.ldb");
tie(my %mgol_lkp, 'MLDBM', $options{lookupDir}."/mgol.ldb");

#set class obj
$utils->aclame_lookup(\%aclame_lkp);
$utils->seed_lookup(\%seed_lkp);
$utils->kegg_lookup(\%kegg_lkp);
$utils->cog_lookup(\%cog_lkp);
$utils->mgol_lookup(\%mgol_lkp);
##########################################################################
timer(); #call timer to see when process ended.

##CHNAGE IN LOGIC
my $inst_fxn = $dbh->prepare(qq{INSERT INTO statistics (libraryId,fxn_cnt, fxn_id,
										  unassignfxn_cnt, unassignfxn_id)
							    VALUES(?,?,?,?,?)
							   });

my $upd_env = $dbh->prepare(qq{UPDATE statistics set allviral_cnt=?, allviral_id=?, topviral_cnt=?,
						   topviral_id=?, allmicrobial_cnt=?, allmicrobial_id=?, topmicrobial_cnt=?,
						   topmicrobial_id=?
				  WHERE libraryId=?});

my $upd_orf_mod = $dbh->prepare(qq{UPDATE statistics set complete_cnt=?,complete_mb=?,complete_id=?,
						incomplete_cnt=?,incomplete_mb=?,incomplete_id=?,
						lackstart_cnt=?,lackstart_mb=?,lackstart_id=?,
						lackstop_cnt=?,lackstop_mb=?,lackstop_id=?
				  WHERE libraryId=?});

my $upd_orf_type = $dbh->prepare(qq{UPDATE statistics set archaea_cnt=?,archaea_mb=?,archaea_id=?,
					 bacteria_cnt=?,bacteria_mb=?,bacteria_id=?,
					 phage_cnt=?,phage_mb=?,phage_id=?
				  WHERE libraryId=?});

my $upd_orfan = $dbh->prepare(qq{UPDATE statistics set orfan_cnt=?, orfan_id=? WHERE libraryId=?});

my $upd_rest = $dbh->prepare(qq{UPDATE statistics set read_cnt=?,read_mb=?,
						tRNA_cnt=?, tRNA_id=?,
						rRNA_cnt=?, rRNA_id=?,
						lineage=?
				  WHERE libraryId=?});

my $tax = $dbh->prepare(qq{SELECT b.domain, count(b.domain)
		       FROM blastp b inner join sequence s on s.id=b.sequenceId
		       WHERE b.deleted=0
				  and s.deleted=0
				  and b.database_name LIKE 'UNIREF100P'
				  and s.libraryId = ?
				  and b.sys_topHit = 1
				  and b.e_value <= 0.001
		       GROUP BY b.domain ORDER BY b.domain desc});

my $all_seq = $dbh->prepare(qq{SELECT distinct s.id,s.header,s.size,s.basepair
			   FROM sequence s
			   WHERE s.deleted=0
			     and s.orf=1
			     and s.rRNA=0
			     and s.libraryId=?});

my $sig_seq = $dbh->prepare(qq{SELECT distinct s.id, s.header, s.size
			  FROM blastp b inner join sequence s on b.sequenceId=s.id
			  WHERE b.deleted=0
			    and s.deleted=0
			    and b.e_value <= 0.001
			    and s.orf=1 and s.rRNA=0
			    and (b.database_name like 'UNIREF100P' OR
				b.database_name like 'METAGENOMES')
			    and s.libraryId=?});

my $read = $dbh->prepare(qq{SELECT count(s.id), sum(s.size)
			FROM sequence s
			WHERE s.deleted=0
			  and s.orf=0
			  and s.rRNA=0
			  and s.libraryId=?});

my $tRNA = $dbh->prepare(qq{SELECT t.sequenceId
			FROM tRNA t INNER JOIN sequence s on t.sequenceId=s.id
			WHERE s.libraryId=?
			  and s.deleted=0
			  and s.orf=0
			  and s.rRNA=0});

my $rRNA = $dbh->prepare(qq{SELECT s.id
			FROM sequence s
			WHERE s.libraryId=?
			  and s.deleted=0
			  and s.orf=0
			  and s.rRNA=1});

my $lib_sel = $dbh0->prepare(q{SELECT id FROM library WHERE deleted=0 and server=?});

my $rslt = '';
my @libArray;

#set library array to process
if ($options{library} <= 0) {
   $lib_sel->execute($options{server});
   $rslt = $lib_sel->fetchall_arrayref({});

   foreach my $lib (@$rslt) {
      push @libArray, $lib->{'id'};
   }
} else {
   push @libArray, $options{library};
}

foreach my $libId (@libArray) {
   print "Processing libraryId: $libId\n";

   # get all top blast hits for a given library
   my $top_hits_stmt = qq{SELECT b.sequenceId, MAX(b.db_ranking_code) AS db_ranking_code
							  FROM blastp b INNER JOIN sequence s ON s.id=b.sequenceId
							  WHERE s.deleted=0
							   and  b.deleted=0
							   and  s.libraryId = ?
							   and 	(b.database_name = 'UNIREF100P'
									 OR b.database_name = 'METAGENOMES')
							   and 	b.sys_topHit=1
							   and 	b.e_value <= 0.001
							  GROUP BY b.sequenceId, b.database_name
							  ORDER BY db_ranking_code desc};
   my $top_hits_qry = $dbh->prepare($top_hits_stmt);
   $top_hits_qry->execute($libId);

   ########################################
   # SPLIT SEQUENCE INTO UNIREF100P ONLY
   # AND METAGENOMES ONLY SET AT
   # EVALUE CUTOFF AT 0.001
   ########################################
   # get uniref and metagenomes exclusive sequences.
   # top_hits_qry returnes only one row per sequence
   # db_ranking_code 10=UNIREF100P
   #				  5=METAGENOMES
   my(@uniref_arr,@meta_arr);
   while (my $result = $top_hits_qry->fetchrow_hashref()) {
	  if ($$result{db_ranking_code} == 10){
		 push @uniref_arr, $$result{sequenceId};
	  } else {
		 push @meta_arr , $$result{sequenceId};
	  }
   }

   ###########################################
   # GET FUNCTIONAL AND UNASSIGNED FUNCTIONAL
   # CATEGORIES FOR ALL UNIREF100P SEQUENCES
   # AT EVALUE CUTOFF OF 0.001
   ###########################################

   # for all uniref only sequences get functional/unassigned protein info.
   my $functional_count = 0;
   my $functional_list = "";
   my $unclassified_count = 0;
   my $unclassified_list = "";
   my $null_str = "NULL";

	foreach my $sequenceId(@uniref_arr) {
		#divide all hits in fxn and unclassified.
		if (hasFunctionalHit($sequenceId)){
			$functional_count++;
			$functional_list .= $sequenceId . ",";
		} else {
			$unclassified_count++;
			$unclassified_list .= $sequenceId . ",";
		}
	}

   #remove last comma
   $functional_list =~ s/,$//;
   $unclassified_list =~ s/,$//;

   ###############################################
   # CALCULATE ENVIRONMENTAL CATEGORIES FOR
   # EACH LIBRARY, VIRAL ONLY, TOP VIRAL,
   # MICORBIAL ONLY, TOP MICORBIAL
   # AT EVALUE CUTOFF AT 0.001
   ###############################################
   my %env=();
   $env{'top_viral'}=0;
   $env{'top_viral_list'}="";
   $env{'top_micro'}=0;
   $env{'top_micro_list'}="";
   $env{'viral'}=0;
   $env{'viral_list'}="";
   $env{'micro'}=0;
   $env{'micro_list'}="";

   foreach my $seqid (@meta_arr) {
	  # get all blast hits for a seq.
	  my $sth = $dbh->prepare(qq{SELECT b.id, b.hit_name, b.sys_topHit, b.query_name
				  FROM blastp b
				  WHERE b.sequenceId=?
					 and b.e_value<=0.001
					 and b.deleted=0
					 and b.database_name='METAGENOMES'
				  ORDER BY b.id,b.sys_topHit});
	  $sth->execute(($seqid));

	  my $top_hit="";
	  my $same_hit=1;

      # loop through all blast results for a sequence
      while (my $row = $sth->fetchrow_hashref) {
		 my $mgol_acc_hash = $utils->get_acc_from_lookup("mgol",substr($$row{hit_name},0,3));

		 if (defined $mgol_acc_hash) {
			my $mgol_hash = $mgol_acc_hash->{acc_data}[0];
			my $lib_type = ($mgol_hash->{lib_type} =~ /viral/i) ? "viral" : "micro";

			if ($$row{sys_topHit} == 1) {
			   if ($lib_type =~ /viral/i) {
				  $top_hit = "viral";
			   } else { $top_hit = $lib_type; }
			}

			if (($lib_type !~ /$top_hit/i) && ($same_hit)) {
			   $same_hit = 0;
			}
		 } else {
			print STDERR "Cannot find mgol entry for $$row{hit_name}\n";
		 }
      }

      # viral or microbial only assignment.
      # if both $top_hit and $other_hits are same or
      # $other_hit is empyt i.e only one hit
      my $env_type = $top_hit;
      my $env_type_list = $env_type ."_list";

      # have multiple hits and top hit is different form other hits.
      # it is possible for $top_hit ne $other_hit if only one hit
      if (!$same_hit) {
		 $env_type = "top_" . $top_hit;
		 $env_type_list = $env_type ."_list";
      }

      $env{$env_type} += 1;
	  if (length($env{$env_type_list})) {
		 $env{$env_type_list} .= "," . $seqid;
      } else {
		 $env{$env_type_list} = $seqid;
      }
   }

	#################################################
	# CALCULATE TAXONOMY LINEAGE AT DOMAIN LEVEL
	# AT EVALUE CUTOFF AT 0.001
	#################################################
	## get domain taxonomy count.
	my ($type,$count,$lineage);
	$tax->execute(($libId));
	$tax->bind_col(1,\$type);
	$tax->bind_col(2,\$count);
	$lineage = "";

	while($tax->fetch) {
		if (!length($type)) {
			$type = "Unclassified";
		}
		if (length($lineage)) {
			$lineage = $lineage.";".$type.":".$count;
		}
		else { $lineage = $type.":".$count; }
	}

	##################################################
	# CALCULATE ORF CATEGORIES and TYPES
	# FOR EACH LIBRARY AT EVALUE CUTOFF OF 0.001
	##################################################
	my %orf=();
	$orf{'comp_cnt'}=0;
	$orf{'comp_lst'}="";
	$orf{'comp_mb'}=0;
	$orf{'incomp_cnt'}=0;
	$orf{'incomp_lst'}="";
	$orf{'incomp_mb'}=0;
	$orf{'start_cnt'}=0;
	$orf{'start_lst'}="";
	$orf{'start_mb'}=0;
	$orf{'stop_cnt'}=0;
	$orf{'stop_lst'}="";
	$orf{'stop_mb'}=0;
	$orf{'bacteria_cnt'}=0;
	$orf{'bacteria_lst'}="";
	$orf{'bacteria_mb'}=0;
	$orf{'archaea_cnt'}=0;
	$orf{'archaea_lst'}="";
	$orf{'archaea_mb'}=0;
	$orf{'phage_cnt'}=0;
	$orf{'phage_lst'}="";
	$orf{'phage_mb'}=0;

	$all_seq->execute(($libId));
	while (my $row = $all_seq->fetchrow_hashref) {

		map { $opts{$1} = $2 if( /([^=]+)\s*=\s*([^=]+)/ ) } split(/\s+/, $$row{header});

		if ($opts{type} =~ /lack[_|\s]stop/i){
			$opts{type} = "stop";
		} elsif ($opts{type} =~ /lack[_|\s]start/i){
			$opts{type} = "start";
		} elsif ($opts{type} =~ /incomplete/i){
			$opts{type} = "incomp";
		} elsif ($opts{type} =~ /complete/i){
			$opts{type} = "comp";
		}

		# set model stats.
		$orf{$opts{model}.'_cnt'}++;

		#if * at the end of bases, don't count it
		if ($$row{basepair} =~ /\*$/) {
			$orf{$opts{model}.'_mb'} += ($$row{size}-1);
		}else {
			$orf{$opts{model}.'_mb'} += $$row{size};
		}

		if (length($orf{$opts{model}.'_lst'})) {
			$orf{$opts{model}.'_lst'} = $orf{$opts{model}.'_lst'} . "," . $$row{id};
		} else { $orf{$opts{model}.'_lst'} = $$row{id}; }

		# set type stats.
		$orf{$opts{type}.'_cnt'}++;

		#do not count * in bases
		if ($$row{basepair} =~ /\*$/) {
			$orf{$opts{type}.'_mb'} += ($$row{size} - 1);
		} else { $orf{$opts{type}.'_mb'} += $$row{size}; }

		if (length($orf{$opts{type}.'_lst'})) {
			$orf{$opts{type}.'_lst'} = $orf{$opts{type}.'_lst'} . "," . $$row{id};
		} else { $orf{$opts{type}.'_lst'} = $$row{id}; }
	}

   ##################################################
   # GET ORFAN COUNT AT EVALUE CUTOFF OF 0.001
   ##################################################
   my $sigcnt = 0;
   my $siglst = "";

   $sig_seq->execute(($libId));
   my $rslt = $sig_seq->fetchall_arrayref({});
   foreach my $val (@$rslt) {
	  $sigcnt ++;
      # get all significant hit ids.
      if (length($siglst)) {
		 $siglst .= "," . $val->{id};
      } else { $siglst = $val->{id}; }
   }

   $all_seq->execute(($libId));
   $rslt = $all_seq->fetchall_arrayref({});
   my $allcount = 0;
   my %orfan=();
   $orfan{'count'}=0;
   $orfan{'lst'}="";
   foreach my $val (@$rslt) {
      $allcount++;
      if (index($siglst, $val->{id}) < 0) {
		 $orfan{'count'}++;
		 if (length($orfan{'lst'})) {
			$orfan{'lst'} .= "," . $val->{id};
		 } else { $orfan{'lst'} = $val->{id}; }
      }
   }

   ##################################################
   # GET READ COUNT AND MEGABASES
   ##################################################
   $read->execute(($libId));
   my $read_row = $read->fetchall_arrayref([],1);
   my %read_s=();
   $read_s{'count'}=$read_row->[0]->[0];
   $read_s{'mb'} = $read_row->[0]->[1];

   ##################################################
   # GET TRNA COUNT AND LIST
   ##################################################
   $tRNA->execute(($libId));
   my %tRNA_s=();
   $tRNA_s{'count'}=0;
   $tRNA_s{'lst'}="";
   while (my @rslt = $tRNA->fetchrow_array()) {
      $tRNA_s{'count'}++;
      if (length($tRNA_s{'lst'})) {
		 $tRNA_s{'lst'} = $tRNA_s{'lst'} . "," . $rslt[0];
      } else { $tRNA_s{'lst'} = $rslt[0]; }
   }

   ###################################################
   # GET RRNA COUNT AND LIST
   ###################################################
   $rRNA->execute(($libId));
   my %rRNA_s=();
   $rRNA_s{'count'}=0;
   $rRNA_s{'lst'}="";
   while (my @rslt = $rRNA->fetchrow_array()) {
      $rRNA_s{'count'}++;
      if (length($rRNA_s{'lst'})) {
		 $rRNA_s{'lst'} = $rRNA_s{'lst'} . "," . $rslt[0];
      } else { $rRNA_s{'lst'} = $rslt[0]; }
   }


   #################################################
   # INSERT STATISTICS INTO TABLE
   #################################################

   #create output file for functional_id list and unclass_id list
   my $output_dir = $file_loc;

   my %file_output_list= (
	 "functional_list" => $output_dir."/idFiles/fxnIdList_".$libId.".txt",
	 "unclassified_list" => $output_dir."/idFiles/unClassIdList_".$libId.".txt",
	 "viral_list" => $output_dir."/idFiles/viralList_".$libId.".txt",
	 "top_viral_list" => $output_dir."/idFiles/topViralList_".$libId.".txt",
	 "micro_list" => $output_dir."/idFiles/microList_".$libId.".txt",
	 "top_micro_list" => $output_dir."/idFiles/topMicroList_".$libId.".txt",
	 "comp_lst" => $output_dir."/idFiles/compORFList_".$libId.".txt",
	 "incomp_lst" => $output_dir."/idFiles/incompORFList_".$libId.".txt",
	 "start_lst" => $output_dir."/idFiles/startORFList_".$libId.".txt",
	 "stop_lst" => $output_dir."/idFiles/stopORFList_".$libId.".txt",
	 "archaea_lst" => $output_dir."/idFiles/arcORFList_".$libId.".txt",
	 "bacteria_lst" => $output_dir."/idFiles/bacORFList_".$libId.".txt",
	 "phage_lst" => $output_dir."/idFiles/phgORFList_".$libId.".txt",
	 "orfan" => $output_dir."/idFiles/orfanList_".$libId.".txt",
	 "tRNA" => $output_dir."/idFiles/tRNAList_".$libId.".txt",
	 "rRNA" => $output_dir."/idFiles/rRNAList_".$libId.".txt"
   );

   foreach my $key (keys %file_output_list) {

	  open(OUT, ">", $file_output_list{$key} ) or
		 die "Could not open file $file_output_list{$key} to write\n";

      if ($key =~ /functional_list/i) {
		 print OUT $functional_list;
      } elsif ($key =~ /unclassified_list/i) {
		 print OUT $unclassified_list;
      } elsif ($key =~ /viral_list|top_viral_list|micro_list|top_micro_list/i) {
		 print OUT $env{$key};
      } elsif ($key =~ /comp_lst|incomp_lst|start_lst|stop_lst|archaea_lst|bacteria_lst|phage_lst/i) {
		 print OUT $orf{$key};
      } elsif ($key =~ /orfan/i){
		 print OUT $orfan{'lst'};
      } elsif ($key =~ /tRNA/i){
		 print OUT $tRNA_s{'lst'};
      } elsif ($key =~ /rRNA/i){
		 print OUT $rRNA_s{'lst'};
      }

      close OUT;
   }

   $inst_fxn->execute(($libId,$functional_count,"fxnIdList_$libId.txt",
			$unclassified_count,"unClassIdList_$libId.txt"));

   $upd_env->execute(($env{'viral'},"viralList_$libId.txt",
		       $env{'top_viral'},"topViralList_$libId.txt",
		       $env{'micro'},"idFiles/microList_$libId.txt",
		       $env{'top_micro'},"topMicroList_$libId.txt",$libId));

   $upd_orf_mod->execute(($orf{'comp_cnt'},$orf{'comp_mb'},"compORFList_$libId.txt",
			   $orf{'incomp_cnt'},$orf{'incomp_mb'},"incompORFList_$libId.txt",
			   $orf{'start_cnt'},$orf{'start_mb'},"startORFList_$libId.txt",
			   $orf{'stop_cnt'},$orf{'stop_mb'},"stopORFList_$libId.txt",$libId));

   $upd_orf_type->execute(($orf{'archaea_cnt'},$orf{'archaea_mb'},"arcORFList_$libId.txt",
			    $orf{'bacteria_cnt'},$orf{'bacteria_mb'},"bacORFList_$libId.txt",
			    $orf{'phage_cnt'},$orf{'phage_mb'},"phgORFList_$libId.txt",$libId));

   $upd_orfan->execute(($orfan{'count'},"orfanList_$libId.txt",$libId));

   $upd_rest->execute(($read_s{'count'},$read_s{'mb'},
			$tRNA_s{'count'},"tRNAList_$libId.txt",
			$rRNA_s{'count'},"rRNAList_$libId.txt",
			$lineage,$libId));
}

#$dbh0->disconnect;
#$dbh1->disconnect;
#$dbh->disconnect;

timer(); #call timer to see when process ended.
exit(0);

###############################################################################
####  SUBS
###############################################################################

sub check_parameters {
  my $options = shift;

  my $flag = 0;

   # if library list file or library file has been specified
   # get library info. server, id and library name.
   if ((defined $options{input}) && (length($options{input}))) {
	  $libObject = $libinfo->getLibFileInfo($options{input});
	  $flag = 1;
   }

   # if server is not specifed and library file is not specifed show error
   if (!$options{server} && !$flag) {
	  pod2usage({-exitval => 2,  -message => "error message", -verbose => 1, -output => \*STDERR});
	  exit(-1);
   }

   # if exec env is not specified show error
   unless ($options{env} && $options{lookupDir}) {
	  pod2usage({-exitval => 2,  -message => "error message", -verbose => 1, -output => \*STDERR});
	  exit(-1);
   }

   # if no library info set library to -1;
   unless ($options{library}) {
	  $options{library} = -1;
   }

   # if getting info from library file set server and library info.
   if ($flag) {
	  $options{library} = $libObject->{id};
	  $options{server} = $libObject->{server};
   }

   if ($options{env} eq 'dbi') {
	  $db_user = q|bhavsar|;
	  $db_pass = q|P3^seus|;
	  $dbname = q|VIROME|;
	  $db_host = $options{server}.q|.dbi.udel.edu|;
	  $host = q|virome.dbi.udel.edu|;
   } elsif ($options{env} eq 'camera') {
      $db_user = q|virome_app|;
          $db_pass = q|camera123|;
          $dbname = q|virome_stage|;
          $db_host = q|dory.internal.crbs.ucsd.edu|;
          $host = q|dory.internal.crbs.ucsd.edu|;
   } elsif ($options{env} eq 'igs') {
      $db_user = q|dnasko|;
	  $db_pass = q|dnas_76|;
	  $dbname = q|virome_processing|;
	  $db_host = q|dnode001.igs.umaryland.edu|;
	  $host = q|dnode001.igs.umaryland.edu|;
   } elsif ($options{env} eq 'ageek') {
	  $db_user = q|bhavsar|;
	  $db_pass = q|Application99|;
	  $dbname = $options{server};
	  $db_host = q|10.254.0.1|;
	  $host = q|10.254.0.1|;
   } else {
	  $db_user = q|kingquattro|;
	  $db_pass = q|Un!c0rn|;
	  $dbname = q|VIROME|;
	  $db_host = q|localhost|;
	  $host = q|localhost|;
   }

   $dbh0 = DBI->connect("DBI:mysql:database=virome_stage;host=$host",
   	       "$db_user", "$db_pass",{PrintError=>1, RaiseError =>1, AutoCommit =>1});

   $dbh1 = DBI->connect("DBI:mysql:database=uniref_lookup2;host=$host",
   	       "$db_user", "$db_pass",{PrintError=>1, RaiseError =>1, AutoCommit =>1});

   $dbh = DBI->connect("DBI:mysql:database=$dbname;host=$db_host",
   	      "$db_user", "$db_pass",{PrintError=>1, RaiseError =>1, AutoCommit =>1});
}

###############################################################################
sub hasFunctionalHit {
   my $seqId = shift;

   my $fxn_hit = $dbh->prepare(qq{SELECT	b.id
								  FROM		blastp b
								  WHERE 	b.fxn_topHit=1
									and		b.sequenceId=?});
   $fxn_hit->execute($seqId);

   while (my $hits = $fxn_hit->fetchrow_hashref()) {
	  return 1;
   }

   return 0;
}

###############################################################################
sub getFunctionalList {

   my ($db,$seqId,$functional_count,$functional_list,$found,$seqadded) = @_;
   my $null_str = "NULL";
   my $flag = 0;
   my $fxn_hit_info;

   my $db_hits = $dbh->prepare(qq{SELECT b.id, b.hit_name
			    FROM blastp b
			    WHERE b.database_name=?
			     and b.sequenceId=?
			     and b.e_value<=0.001
			     and b.deleted=0
			    ORDER BY b.e_value asc});
   my $update_fxn_flag = $dbh->prepare(qq{update blastp set fxn_topHit = 1 WHERE id = ?});

   # hit_name is already set to realacc from clean_expand_btab
   # script so just check if fxn1 has a meaningfull value .
   # no lookup required for acc.
   # if its uniref100p get information from database else from lookup file
     # go database is too large to create a lookup file
   if ($db =~ /uniref100p/i) {
      $fxn_hit_info = $dbh1->prepare(get_fxn_query($db));
   }

   # get all blast hits for a sequence ($sequenceId) and a given database
   $db_hits->execute($db,$seqId);
   my $result = $db_hits->fetchall_arrayref({});

   # loop through each blast hit against given database
   foreach my $blst_row (@$result) {
	  my @tmp = split(/;/,$blst_row->{hit_name});
	  $blst_row->{hit_name} = $tmp[0];

	  # check if blast hit has a accession.
	  if (($blst_row->{hit_name} ne $null_str) && (length($blst_row->{hit_name}))) {
		 my $fxn_rslt = "";
		 # get hit information. from db or lookup file
		 if ($db =~ /uniref100p/i) {
			$fxn_hit_info->execute($blst_row->{hit_name});
			$fxn_rslt = $fxn_hit_info->fetchall_arrayref({});
		 } else {
			my $hash = $utils->get_acc_from_lookup(lc($db),$blst_row->{hit_name});
			$fxn_rslt = $hash->{acc_data};
		 }

		 # for each records if there is a informative data
		 # update fxn value.
		 foreach my $fxn_row (@{$fxn_rslt}) {
			if ( (defined $fxn_row->{fxn1}) && (length($fxn_row->{fxn1}) > 0) && ($fxn_row->{fxn1} ne $null_str) &&
				 !($fxn_row->{fxn1} =~ /unknown|unclassified|unassigned|uncharacterized/i) &&
				 ($flag eq 0)) {

					 $update_fxn_flag->execute($blst_row->{id});
					 $flag = 1;
					 $found = 1;
			}
			last if ($flag);
		 }
	  }

	  #if fxn flag updated no need to continue further.
	  last if ($flag);
   }

   #SEQUENCE HAD AN FUNCTIONAL ASSIGNMENT
   if (($found eq 1) && ($seqadded eq 0)) {
	  #ADD TO THE LIST
      $functional_count++;
      if (length($functional_list)) {
		 $functional_list = $functional_list. "," . $seqId;
	  } else {
		 $functional_list = $seqId;
      }
      $seqadded = 1;
   }

   $db_hits->finish();
   return ($functional_count,$functional_list,$found,$seqadded);
}

###############################################################################
sub get_fxn_query{
   my $db = $_[0];

   switch ($db) {
	  case "UNIREF100P"{ return q|SELECT gc.name as fxn1 FROM gofxn g INNER JOIN go_chains gc ON g.chain_id=gc.chain_id
			      WHERE gc.level=1 and g.realAcc = ?|; }
	  case "ACLAME" { return q|SELECT mc.name as fxn1 FROM aclamefxn a INNER JOIN mego_chains mc ON a.chain_id=mc.chain_id
			      WHERE mc.level=1 and a.realAcc = ?|; } # not used
	  case "SEED" { return q|SELECT fxn1 from seed where realacc = ?|; } # not used
	  case "KEGG" { return q|SELECT fxn1 from kegg where realacc = ?|; } # not used
	  case "COG" { return q|SELECT fxn1 from cog where realacc = ?|; }  # not used
	  else { return ""; }
   }
}

###############################################################################
sub timer {
   my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
   my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
   my $year = 1900 + $yearOffset;
   my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
   print "Time now: " . $theTime."\n";
}
