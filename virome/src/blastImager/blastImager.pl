#!/usr/bin/perl -w
# blast-imager.pl
use strict;
use GD;

# Parse tabular data
my ($Q, %S, @S);
my ($MAX, $MIN, $HSPs) = (0, 1e20, 0);
my ($maxIDWidth) = (-1e20);

open (DAT, "$ARGV[0]") || die "Can't open file $ARGV[0]";

while (<DAT>) {
	if ($_ =~ /^#/){ 
		print ""; 
	} else {
	#print $_;
	my ($o_r, $q, $id, $p, $l, $f, $g, $qb, $qe, $sb, $se, $e, $b) = split;
	$Q =$q;
	
	if (length($q) > $maxIDWidth) {$maxIDWidth = length($q);}
	if ($qb > $qe) {($qb, $qe, $sb, $se) = ($qe, $qb, $se, $sb)}
	
	$MAX = $qe if $qe > $MAX;
	$MIN = $qb if $qb < $MIN;
	push @S, $id if not defined $S{$id};
	push @{$S{$id}}, [$qb, $qe, $sb, $se, $p, $o_r, $f, $e];
	$HSPs++;
	}
}

# Setup graph
my ($L, $B, $R, $H, $F) = (150, 500, 50, 20, 20); # graph regions
my ($W, $Hsep, $Ssep) = (3, 22, 18); # line width and spacing
my $vsize = $H + $F + ($Hsep * $HSPs) + ($Ssep * (keys %S));
$vsize = 100 if $vsize < 100;
$vsize = 700 if $vsize > 700;
$maxIDWidth = 11 if $maxIDWidth > 11;
my $hsize = $L + $B + $R;
my $SCALE = $B / ($MAX - $MIN + 1);
my $image = new GD::Image($hsize, $vsize);

# Colors
my @Color;
my @data = ([0,0,0], [196,0,255], [0,0,255], [0,255,255], [0,255,0], 
	[255,255,0], [255,196,0], [255,0,0], [128,128,128]);
for (my $i = 0; $i < @data; $i++) {
	$Color[$i] = $image->colorAllocate(@{$data[$i]});
}
my $White = $image->colorAllocate(255,255,255);
my $Black = $Color[0];

my @orfColor;
@data = ([51,255,0], [255,102,0],[0,102,255],[255,0,204]);
for (my $i=0; $i<@data; $i++){
	$orfColor[$i] = $image->colorAllocate(@{$data[$i]});
}

#init image.
$image->filledRectangle(0, 0, $hsize, $vsize, $White);


# Alignments orfs
my @Depth;
my $v = 10;
my $orfFlag = 0;

foreach my $id (@S) {
	foreach my $hsp (@{$S{$id}}) {
	    my ($qb, $qe, $sb, $se, $pct, $o_r, $f, $e) = @$hsp;
        if ($o_r eq "ORF"){
	        $orfFlag = 1;
	        $v += 10;
	        $image->string(gdSmallFont, 10, $H+$v, substr($id,0,$maxIDWidth), $Black);
                    
            my $strand = $sb < $se ? '+' : '-';
            my ($x1, $x2, $y) = (scale($qb)+$maxIDWidth-50, scale($qe)+$maxIDWidth-50, $H+$v+4);
            
            foreach my $x ($x1..$x2) {$Depth[$x]++}
            
            my $c = $orfColor[$pct];
            
            $image->filledRectangle($x1, $y, $x2, $y+$W, $c);
            $image->string(gdTinyFont, $x1-(5*length($qb)), $y-5, $qb, $Black);
            $image->string(gdTinyFont, $x2+2, $y-5, $qe, $Black);
            ###$image->string(gdTinyFont, $x1-(5*length($e)), $y+2, $e, $Black);
            $image->string(gdTinyFont, $x2+2, $y+2, $f, $Black);
            
            # for the first line v-space is of 10 there after v-space of 20
            $v += 10;
        }
    }
}

if ($orfFlag == 1){
	my $orf_ident_lab = 100;
	# Percent identity key
	$image->string(gdSmallFont, 10, 5, "ORF Identity", $Black);
	for (my $i = 0; $i <= 3; $i += 1) {
		$image->filledRectangle($orf_ident_lab, 5, $orf_ident_lab+10, 15, $orfColor[$i]);
		$orf_ident_lab += ($i*2) + 20;
	}
	$image->string(gdTinyFont, 98, 17, "com", $Black);
	$image->string(gdTinyFont, 119, 17, "-3'", $Black);
	$image->string(gdTinyFont, 140, 17, "-5'", $Black);
	$image->string(gdTinyFont, 160, 17, "incom", $Black);
	
	# if orf are added move the header line a bit down.
	$v += 10;
}
else {
	# Percent identity key
	$image->string(gdSmallFont, $B-150, 5, "% Identity", $Black);
	for (my $i = 20; $i <= 100; $i += 10) {
		my $x = ($L+$B/2 + $i*2);
		$image->filledRectangle($x, 5, $x+10, 15, colormap($i));
		$image->string(gdTinyFont, $x, 17, $i, $Black);
	}
	$v += 10;
}

# Header
$image->string(gdMediumBoldFont, 5, $v+$H-5, substr($Q,0,$maxIDWidth), $Black);
$image->line($L+$maxIDWidth-50, $v+$H, $L+$B+$maxIDWidth-50, $v+$H, $Black);
$image->string(gdSmallFont, $L+$maxIDWidth-65, $v+$H-6, $MIN, $Black);
$image->string(gdSmallFont, $L+$B+$maxIDWidth-48, $v+$H-6, $MAX, $Black);

my $depth_v = $v;
if (! $orfFlag){
	$v += $HSPs + 10;	
}

# Alignments reads
foreach my $id (@S) {
	foreach my $hsp (@{$S{$id}}) {
		my ($qb, $qe, $sb, $se, $pct, $o_r, $f) = @$hsp;		
		if ($o_r eq "READ"){
			$v += 10;
			$image->string(gdSmallFont, 10, $v+$H, substr($id,0,$maxIDWidth), $Black);
			my $strand = $sb < $se ? '+' : '-';
			my ($x1, $x2, $y) = (scale($qb)+$maxIDWidth-50, scale($qe)+$maxIDWidth-50, $v+$H+4);
			foreach my $x ($x1..$x2) {$Depth[$x]++}
			my $c = colormap($pct);
			$image->filledRectangle($x1, $y, $x2, $y+$W, $c);		
			$image->string(gdTinyFont, $x1 -(5*length($qb)), $y-5, $qb, $Black);
			$image->string(gdTinyFont, $x2+2, $y-5, $qe, $Black);
			#$image->string(gdTinyFont, $x1 -(5*length($sb)), $y+2, $sb, $Black);
			#$image->string(gdTinyFont, $x2-4, $y+2, $se, $Black);
		}
		# for the first line v-space of 10, there after space of 20
		$v += 10;
	}
}

# Alignment depth
my $MaxDepth = 0;
foreach my $d (@Depth) {$MaxDepth = $d if defined $d and $d > $MaxDepth}
my $Dscale = int($MaxDepth/10) +1;
$image->string(gdTinyFont, $L+$B-40, $depth_v+$H+9, "$Dscale/line", $Black);
for (my $i = 0; $i < @Depth; $i++) {
	next unless defined $Depth[$i];
	my $level = $Depth[$i]/$Dscale +1;
	for (my $j = 0; $j < $level; $j++) {
		$image->line($i, $depth_v+$H+$j*2, $i, $depth_v+$H+$j*2, $Black);
	}
}


# Output (edit this for your installation/taste)
#print $image->png;
# print $image->jpeg;
print $image->gif;

my $jpg_data = $image->gif;
open (DISPLAY,"> temp.gif") || die "Can not create gif file";
binmode DISPLAY;
print DISPLAY $jpg_data;
close DISPLAY;

print $jpg_data;

exit (0);

sub colormap {
	my ($value) = @_;
	my $n = ($value >= 100) ? 0: int((109 - $value) / 10);
	return defined $Color[$n] ? $Color[$n] : $Color[@Color-1];
}

sub scale {
	my ($x) = @_;
	my $scale = ($x - $MIN) * $SCALE + $L;
	return $scale;
}