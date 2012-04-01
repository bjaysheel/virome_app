#!/usr/bin/perl -w
# blast-imager.pl
use strict;
use GD;

# Parse tabular data
my ($Q, %S, @S);
my ($MAX, $MIN, $HSPs) = (0, 1e20, 0);
my ($maxIDWidth) = (-1e20);

open (DAT, "$ARGV[0]") || die "Can't open file $ARGV[0]";
my ($p, $qb, $qe, $sb, $se, $e, $b);

while (<DAT>) {
	if ($_ =~ /^#/){ 
		print ""; 
	} else {
	
        #percent_identity,query_name, hit_id, query_begin, query_end,
        #subject_begin, subject_end, e_value, bit_score
	($p, $qb, $qe, $sb, $se, $e, $b) = split;
	
        if ($qb > $qe) {($qb, $qe, $sb, $se) = ($qe, $qb, $se, $sb)}
	
	$MAX = $se;
        $MIN = $sb;
	$HSPs++;
	}
}

# Setup graph

#length, height, mid-region, height of overlay
my ($L, $B, $R, $H) = (50, 20, 10, 2.5);
my $vsize = 20;
my $hsize = 50;
my $FACTOR = $MAX/$hsize;
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

#init image.
$image->filledRectangle(0, 0, $hsize, $vsize, $White);

# Alignments orfs
my @Depth;
my $v = 10;

# Header
#main line in the middle of the image.
$image->line(0, $R, $hsize, $R, $Black);

#scale query_start and end
my ($x1, $x2) = (scale($qb), scale($qe));

#get color based on percent_similarity
my $c = colormap($p);

#draw rectengle based on scale factor of query_start and end
$image->filledRectangle($x1, $R-$H, $x2, $R+$H, $c);

# Output (edit this for your installation/taste)
print $image->gif;

my $jpg_data = $image->gif;
open (DISPLAY,"> mini_temp.gif") || die "Can not create gif file";
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
	my $scale = (($x - 1)/$FACTOR) + 1;
	return $scale;
}