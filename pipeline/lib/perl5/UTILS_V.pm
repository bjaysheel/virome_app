package UTILS_V;

use strict;
use warnings;
use Data::Dumper;

sub new {
    my ($class) = @_;
    my $self = {};

    $self->{db_user} = undef;
    $self->{db_pass} = undef;
    $self->{db_name} = undef;
    $self->{db_host} = undef;
    $self->{v_name} = undef;
    $self->{v_host} = undef;
    $self->{u_host} = undef;
    $self->{seq_lookup} = undef;
    $self->{uniref_lookup} = undef;
    $self->{aclame_lookup} = undef;
    $self->{seed_lookup} = undef;
    $self->{kegg_lookup} = undef;
    $self->{cog_lookup} = undef;
    $self->{mgol_lookup} = undef;

    bless($self,$class);
    return $self;
}

###############################################################################
sub set_sequence_lookup{
    my $self = shift;
    $self->{seq_lookup} = $_[0];
}

#set lookup dbs to class obj
sub uniref_lookup{
    my $self = shift;

   if (@_ > 0){
        $self->{uniref_lookup} = $_[0];
    } else {
        return $self->{uniref_lookup};
    }
}

sub aclame_lookup{
    my $self = shift;

   if (@_ > 0){
        $self->{aclame_lookup} = $_[0];
    } else {
        return $self->{aclame_lookup};
    }
}

sub seed_lookup{
    my $self = shift;

   if (@_ > 0){
        $self->{seed_lookup} = $_[0];
    } else {
        return $self->{seed_lookup};
    }
}

sub kegg_lookup{
    my $self = shift;

   if (@_ > 0){
        $self->{kegg_lookup} = $_[0];
    } else {
        return $self->{kegg_lookup};
    }
}

sub cog_lookup{
    my $self = shift;

   if (@_ > 0){
        $self->{cog_lookup} = $_[0];
    } else {
        return $self->{cog_lookup};
    }
}

sub mgol_lookup{
    my $self = shift;

   if (@_ > 0){
        $self->{mgol_lookup} = $_[0];
    } else {
        return $self->{mgol_lookup};
    }
}

# retrieve info frm lookup dbs
sub get_sequenceId{
    my $self = shift;
    my $seq_name = $_[0];

    my $hash = $self->{seq_lookup};
    return $hash->{$seq_name}->{id};
}

sub get_sequence{
    my $self = shift;
    my $seq_name = $_[0];

    my $hash = $self->{seq_lookup};

    return $hash->{$seq_name};
}

sub get_acc_from_lookup{
    my $self = shift;
    my $table = $_[0];
    my $acc = $_[1];

    my $hash = $self->{$table."_lookup"};
    return $hash->{$acc};
}

###############################################################################
sub get_libraryId_from_list_file{
    my $self = shift;
    my $input = $_[0];
    my $libListFile = $_[1];
    my $type = $_[2];

    my $libraryId = 0;
    my $prefix = '';

    # input in multifasta file
    if ($type =~ /fasta/i){
       $prefix = `grep -m 1 '^>' $input`;
       $prefix = $self->trim(substr($prefix,1,3));
    } elsif ($type =~ /blast|tRNAScan/i){
        #input is a blast btab file
        my $line = `head -1 $input`;
        #my @info = split(/\t/,$line);
        $prefix = $self->trim(substr($line,0,3));
    } elsif ($type =~ /metagene/i){
        my $line = `grep -m 1 "\$1" $input`;
        $prefix = $self->trim(substr($line,2,3));
    }

    if (!length($prefix)){
        die ("No sequences in input file $input.\n");
    }

    # open library list file
    open (LFILE, "<", $libListFile) or die("Cannot open file $libListFile\n");

    while(<LFILE>){
        chomp $_;

        # get the first line in the library info output file.
        # check if prefix's match.
        my $line = `head -1 $_`;
        chomp $line;

        my @info = split(/\t/,$line);
        if ($info[2] =~ /$prefix/i){
            $libraryId = $info[0];
			last;
        }
    }

    close LFILE;
    return $libraryId;
}

sub get_libraryId_from_file{
    my $self = shift;
    my $input = $_[0];
    my $ids = 0;

    # open library list file
    open (LFILE, "<", $input) or die("Cannot open file $input\n");

    while(<LFILE>){
        chomp $_;

        my @info = split(/\t/,$_);
		if (length($info[0]) && $info[0]  > 0){
			$ids = $info[0];
		}
    }

    close LFILE;
    return $ids;
}

###############################################################################
sub set_db_params{
    my $self=shift;
    my $env = $_[0];
    my $server = (defined $_[1]) ? $_[1] : '';

    if ($env =~ /dbi/i){
        $self->{db_user} = q|bhavsar|;
        $self->{db_pass} = q|P3^seus|;
        $self->{db_name} = q|VIROME|;
        $self->{db_host} = $server.q|.dbi.udel.edu|;
        $self->{v_host} = q|virome.dbi.udel.edu|;
        $self->{v_name} = q|VIROME|;
    }elsif ($env =~ /igs/i){
		$self->{db_user} = q|dnasko|;
        $self->{db_pass} = q|dnas_76|;
        $self->{db_name} = q|virome_processing|;
        $self->{db_host} = q|dnode001.igs.umaryland.edu|;
        $self->{v_host} = q|dnode001.igs.umaryland.edu|;
        $self->{v_name} = q|VIROME|;
        $self->{u_name} = q|uniref_lookup2|;
    }elsif ($env =~ /camera/i){
                $self->{db_user} = q|virome_app|;
        $self->{db_pass} = q|camera123|;
        $self->{db_name} = q|virome_stage|;
        $self->{db_host} = q|dory.internal.crbs.ucsd.edu|;
        $self->{v_host} = q|dory.internal.crbs.ucsd.edu|;
        $self->{v_name} = q|VIROME|;
        $self->{u_name} = q|uniref_lookup2|;
    }elsif ($env =~ /ageek/i) {
        $self->{db_user} = q|bhavsar|;
        $self->{db_pass} = q|Application99|;
        $self->{db_name} = $server;
        $self->{db_host} = q|10.254.0.1|;
        $self->{v_host} = q|10.254.0.1|;
        $self->{v_name} = q|VIROME|;
    }else {
        $self->{db_user} = q|kingquattro|;
        $self->{db_pass} = q|Un!c0rn|;
        $self->{db_name} = q|VIROME|;
        $self->{db_host} = q|localhost|;
        $self->{v_host} = q|localhost|;
        $self->{v_name} = q|VIROME|;
    }
}

sub db_user{
    my $self=shift;
    if (@_ > 0){
        $self->{db_user} = $_[0];
    } else {
        return $self->{db_user};
    }
}
sub db_pass{
    my $self=shift;
    if (@_ > 0){
        $self->{db_pass} = $_[0];
    } else {
        return $self->{db_pass};
    }
}
sub db_name{
    my $self=shift;
    if (@_ > 0){
        $self->{db_name} = $_[0];
    } else {
        return $self->{db_name};
    }
}
sub db_host{
    my $self=shift;
    if (@_ > 0){
        $self->{db_host} = $_[0];
    } else {
        return $self->{db_host};
    }
}
sub v_name{
    my $self=shift;
    if (@_ > 0){
        $self->{v_name} = $_[0];
    } else {
        return $self->{v_name};
    }
}
sub u_name{
    my $self=shift;
    if (@_ > 0){
        $self->{u_name} = $_[0];
    } else {
        return $self->{u_name};
    }
}
sub v_host{
    my $self=shift;
    if (@_ > 0){
        $self->{v_host} = $_[0];
    } else {
        return $self->{v_host};
    }
}

###############################################################################
sub trim {
  my $self = shift;
  my $string = $_[0];

  $string =~ s/^\s+//;
  $string =~ s/\s+$//;

  return $string;
}


1;
